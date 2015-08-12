//
//  Geocore.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 4/14/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

/**
    GeocoreKit error domain.
*/
public let GeocoreErrorDomain = "jp.geocore.error"

private let MMG_SETKEY_BASE_URL = "GeocoreBaseURL"
private let MMG_SETKEY_PROJECT_ID = "GeocoreProjectId"
private let HTTPHEADER_ACCESS_TOKEN_NAME = "Geocore-Access-Token"

/**
    GeocoreKit jjmjjjjjjerror code.

    - INVALID_STATE:           Unexpected internal state. Possibly a bug.
    - INVALID_SERVER_RESPONSE: Unexpected server response. Possibly a bug.
    - SERVER_ERROR:            Server returns an error.
    - TOKEN_UNDEFINED:         Token is unavailable. Possibly the library is left uninitialized or user is not logged in.
    - UNAUTHORIZED_ACCESS:     Access to the specified resource is forbidden. Possibly the user is not logged in.
    - INVALID_PARAMETER:       One of the parameter passed to the API is invalid
*/
public enum GeocoreError: Int {
    case INVALID_STATE
    case INVALID_SERVER_RESPONSE
    case SERVER_ERROR
    case TOKEN_UNDEFINED
    case UNAUTHORIZED_ACCESS
    case INVALID_PARAMETER
}

/**
    Representing an object that can be initialized from JSON data.
 */
public protocol GeocoreInitializableFromJSON {
    init(_ json: JSON)
}

/**
    Representing an object that can be serialized to JSON.
*/
public protocol GeocoreSerializableToJSON {
    func toDictionary() -> [String: AnyObject]
}

/**
    A raw JSON value returned by Geocore service.
*/
public class GeocoreGenericResult: GeocoreInitializableFromJSON {
    var json: JSON
    
    public required init(_ json: JSON) {
        self.json = json
    }
}

// Work-around for Swift compiler unimplemented feature error: 'unimplemented IR generation feature non-fixed multi-payload enum layout'
// see:
// http://owensd.io/2014/07/09/error-handling.html
// https://github.com/owensd/SwiftLib/blob/master/Source/Failable.swift
// ultimately this wrapper will not be necessary once the compiler is fixed.
public class GeocoreResultValueWrapper<T> {
    let value: T
    public init(_ value: T) { self.value = value }
}

/**
    Representing a result returned by Geocore service.

    - Success: Containing value of the result.
    - Failure: Containing an error.
*/
public enum GeocoreResult<T> {
    case Success(GeocoreResultValueWrapper<T>)
    case Failure(NSError)
    
    public init(_ value: T) {
        self = .Success(GeocoreResultValueWrapper(value))
    }
    
    public init(_ error: NSError) {
        self = .Failure(error)
    }
    
    public var failed: Bool {
        switch self {
        case .Failure(let error):
            return true
            
        default:
            return false
        }
    }
    
    public var error: NSError? {
        switch self {
        case .Failure(let error):
            return error
            
        default:
            return nil
        }
    }
    
    public var value: T? {
        switch self {
        case .Success(let wrapper):
            return wrapper.value
        default:
            return nil
        }
    }
    
    public func propagateTo(fulfiller: (T) -> Void, rejecter: (NSError) -> Void) -> Void {
        switch self {
        case .Success(let wrapper):
            fulfiller(wrapper.value)
        case .Failure(let error):
            rejecter(error)
        }
    }
}

// MARK: -

/**
 *  Main singleton class.
 */
public class Geocore: NSObject {
    
    /// Singleton instance
    public static let sharedInstance = Geocore()
    public static let geocoreDateFormatter = NSDateFormatter.dateFormatterForGeocore()
    
    public private(set) var baseURL: String?
    public private(set) var projectId: String?
    private var token: String?
    
    private override init() {
        self.baseURL = NSBundle.mainBundle().objectForInfoDictionaryKey(MMG_SETKEY_BASE_URL) as? String
        self.projectId = NSBundle.mainBundle().objectForInfoDictionaryKey(MMG_SETKEY_PROJECT_ID) as? String
    }
    
    /**
        Setting up the library.
    
        :param: baseURL   Geocore server endpoint
        :param: projectId Project ID
    
        :returns: Geocore object
    */
    public func setup(baseURL: String, projectId: String) -> Geocore {
        self.baseURL = baseURL;
        self.projectId = projectId;
        return self;
    }
    
    // MARK: Private utilities
    
    private func path(servicePath: String) -> String? {
        if let baseURL = self.baseURL {
            return baseURL + servicePath
        } else {
            return nil
        }
    }
    
    private func mutableURLRequest(method: Alamofire.Method, path: String, token: String) -> NSMutableURLRequest {
        let ret = NSMutableURLRequest(URL: NSURL(string: path)!)
        ret.HTTPMethod = method.rawValue
        ret.setValue(token, forHTTPHeaderField: HTTPHEADER_ACCESS_TOKEN_NAME)
        return ret
    }
    
    private func generateMultipartBoundaryConstant() -> String {
        return NSString(format: "Boundary+%08X%08X", arc4random(), arc4random()) as String
    }
    
    private func multipartURLRequest(method: Alamofire.Method, path: String, token: String, fieldName: String, fileName: String, mimeType: String, fileContents: NSData) -> NSMutableURLRequest {
        
        let mutableURLRequest = self.mutableURLRequest(.POST, path: path, token: token)
        
        let boundaryConstant = self.generateMultipartBoundaryConstant()
        let boundaryStart = "--\(boundaryConstant)\r\n"
        let boundaryEnd = "--\(boundaryConstant)--\r\n"
        let contentDispositionString = "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
        let contentTypeString = "Content-Type: \(mimeType)\r\n\r\n"
        
        let requestBodyData : NSMutableData = NSMutableData()
        requestBodyData.appendData(boundaryStart.dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(contentTypeString.dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(fileContents)
        requestBodyData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(boundaryEnd.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        mutableURLRequest.setValue("multipart/form-data; boundary=\(boundaryConstant)", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = requestBodyData
        
        return mutableURLRequest
    }
    
    private func parameterEncoding(method: Alamofire.Method) -> Alamofire.ParameterEncoding {
        switch method {
        case .GET, .HEAD, .DELETE:
            return .URL
        default:
            return .JSON
        }
    }
    
    // from Alamofire internal
    func escape(string: String) -> String {
        let legalURLCharactersToBeEscaped: CFStringRef = ":&=;+!@#$()',*"
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    
    // from Alamofire internal
    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.extend([(escape(key), escape("\(value)"))])
        }
        
        return components
    }
    
    private func multipartInfo(_ body: [String: AnyObject]? = nil) -> (fileContents: NSData, fileName: String, fieldName: String, mimeType: String)? {
        if let fileContents = body?["$fileContents"] as? NSData {
            if let fileName = body?["$fileName"] as? String, fieldName = body?["$fieldName"] as? String, mimeType = body?["$mimeType"] as? String {
                return (fileContents, fileName, fieldName, mimeType)
            }
        }
        return nil
    }
    
    private func validateRequestBody(_ body: [String: AnyObject]? = nil) -> Bool {
        if let fileContent = body?["$fileContents"] as? NSData {
            // uploading file, make sure all required parameters are specified as well
            if let fileName = body?["$fileName"] as? String, fieldName = body?["$fieldName"] as? String, mimeType = body?["$mimeType"] as? String {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    private func buildQueryParameter(mutableURLRequest: NSMutableURLRequest, parameters: [String: AnyObject]?) -> NSURL? {
        
        if let someParameters = parameters {
            // from Alamofire internal
            func query(parameters: [String: AnyObject]) -> String {
                var components: [(String, String)] = []
                for key in sorted(Array(parameters.keys), <) {
                    let value: AnyObject! = parameters[key]
                    components += self.queryComponents(key, value)
                }
                
                return join("&", components.map{"\($0)=\($1)"} as [String])
            }
            
            // since we have both non-nil parameters and body,
            // the parameters should go to URL query parameters,
            // and the body should go to HTTP body
            if let URLComponents = NSURLComponents(URL: mutableURLRequest.URL!, resolvingAgainstBaseURL: false) {
                URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(someParameters)
                return URLComponents.URL
            }
        }
        
        return nil
    }
    
    /**
        Build and customize Alamofire request with Geocore token and optional parameter/body specification.
    
        :param: method Alamofire Method enum representing HTTP request method
        :param: parameters parameters to be used as URL query parameters (for GET, DELETE) or POST parameters in the body except is body parameter is not nil. For POST, ff body parameter is not nil it will be encoded as POST body (JSON or multipart) and parameters will become URL query parameters.
        :param: body POST JSON or multipart content. For multipart content, the body will have to contain following key-values: ("$fileContents" => NSData), ("$fileName" => String), ("$fieldName" => String), ("$mimeType" => String)
    
        :returns: function that given a URL path will generate appropriate Alamofire Request object.
    */
    private func requestBuilder(method: Alamofire.Method, parameters: [String: AnyObject]? = nil, body: [String: AnyObject]? = nil) -> ((String) -> Request)? {
        
        if !self.validateRequestBody(body) {
            return nil
        }
        
        if let token = self.token {
            // if token is available (user already logged-in), use NSMutableURLRequest to customize HTTP header
            return { (path: String) -> Request in
                
                // NSMutableURLRequest with customized HTTP header
                var mutableURLRequest: NSMutableURLRequest
                
                if let multipartInfo = self.multipartInfo(body) {
                    mutableURLRequest = self.multipartURLRequest(method, path: path, token: token, fieldName: multipartInfo.fieldName, fileName: multipartInfo.fileName, mimeType: multipartInfo.mimeType, fileContents: multipartInfo.fileContents)
                } else {
                    mutableURLRequest = self.mutableURLRequest(method, path: path, token: token)
                }
                
                if let someBody = body {
                    // pass parameters as query parameters, body to be processed by Alamofire
                    if let url = self.buildQueryParameter(mutableURLRequest, parameters: parameters) {
                        mutableURLRequest.URL = url
                    }
                    return Alamofire.request(self.parameterEncoding(method).encode(mutableURLRequest, parameters: someBody).0)
                } else {
                    // set parameters according to standard Alamofire's encode processing
                    return Alamofire.request(self.parameterEncoding(method).encode(mutableURLRequest, parameters: parameters).0)
                }
            }
        } else {
            if let someBody = body {
                // no token but with body & parameters separate
                return { (path: String) -> Request in
                    let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: path)!)
                    mutableURLRequest.HTTPMethod = method.rawValue
                    if let url = self.buildQueryParameter(mutableURLRequest, parameters: parameters) {
                        mutableURLRequest.URL = url
                    }
                    return Alamofire.request(self.parameterEncoding(method).encode(mutableURLRequest, parameters: someBody).0)
                }
            } else {
                // otherwise do a normal Alamofire request
                return { (path: String) -> Request in Alamofire.request(method, path, parameters: parameters) }
            }
        }
    }
    
    /**
        The ultimate generic request method.
    
        :param: path Path relative to base API URL.
        :param: requestBuilder Function to be used to create Alamofire request.
        :param: onSuccess What to do when the server successfully returned a result.
        :param: onError What to do when there is an error.
     */
    private func request(
            path: String,
            requestBuilder: (String) -> Request,
            onSuccess: (JSON) -> Void,
            onError: (NSError) -> Void) {
                
                requestBuilder(self.path(path)!).response { (_, res, optData, optError) -> Void in
                    if let error = optError {
                        println("[ERROR] \(error)")
                        onError(error)
                    } else if let data = optData {
                        if let statusCode = res?.statusCode {
                            switch statusCode {
                            case 200:
                                let json = JSON(data: data)
                                if let status = json["status"].string {
                                    if status == "success" {
                                        onSuccess(json["result"])
                                    } else {
                                        // pass on server error info as userInfo
                                        onError(
                                            NSError(
                                                domain: GeocoreErrorDomain,
                                                code: GeocoreError.SERVER_ERROR.rawValue,
                                                userInfo: [
                                                    "code": json["code"].string ?? "",
                                                    "message": json["message"].string ?? ""
                                                ]))
                                    }
                                } else {
                                    onError(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_SERVER_RESPONSE.rawValue, userInfo: nil))
                                }
                            case 403:
                                onError(NSError(domain: GeocoreErrorDomain, code: GeocoreError.UNAUTHORIZED_ACCESS.rawValue, userInfo: nil))
                            default:
                                onError(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_SERVER_RESPONSE.rawValue, userInfo: ["statusCode": statusCode]))
                            }
                        } else {
                            // TODO: should specify the error futher in userInfo
                            onError(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_SERVER_RESPONSE.rawValue, userInfo: nil))
                        }
                    }
                }
    }
    
    /**
        Request resulting a single result of type T.
     */
    func request<T: GeocoreInitializableFromJSON>(path: String, requestBuilder optRequestBuilder: ((String) -> Request)?, callback: (GeocoreResult<T>) -> Void) {
        if let requestBuilder = optRequestBuilder {
            self.request(path, requestBuilder: requestBuilder,
                onSuccess: { (json: JSON) -> Void in callback(GeocoreResult(T(json))) },
                onError: { (error: NSError) -> Void in callback(.Failure(error)) })
        } else {
            callback(.Failure(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_PARAMETER.rawValue, userInfo: ["message": "Unable to build request, likely because of unexpected parameters."])))
        }
    }
    
    /**
        Request resulting multiple result in an array of objects of type T
     */
    func request<T: GeocoreInitializableFromJSON>(path: String, requestBuilder optRequestBuilder: ((String) -> Request)?, callback: (GeocoreResult<[T]>) -> Void) {
        if let requestBuilder = optRequestBuilder {
            self.request(path, requestBuilder: requestBuilder,
                onSuccess: { (json: JSON) -> Void in
                    if let result = json.array {
                        callback(GeocoreResult(result.map { T($0) }))
                    } else {
                        callback(GeocoreResult([]))
                    }
                },
                onError: { (error: NSError) -> Void in callback(.Failure(error)) })
        } else {
            callback(.Failure(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_PARAMETER.rawValue, userInfo: ["message": "Unable to build request, likely because of unexpected parameters."])))
        }
    }
    
    // MARK: HTTP methods: GET, POST, DELETE, PUT
    
    /**
        Do an HTTP GET request expecting one result of type T
     */
    func GET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, callback: (GeocoreResult<T>) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.GET, parameters: parameters), callback: callback)
    }
    
    /**
        Promise a single result of type T from an HTTP GET request.
     */
    func promisedGET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil) -> Promise<T> {
        return Promise { (fulfiller, rejecter) in
            self.GET(path, parameters: parameters) { (result: GeocoreResult<T>) -> Void in
                result.propagateTo(fulfiller, rejecter: rejecter)
            }
        }
    }
    
    /**
        Do an HTTP GET request expecting an multiple result in an array of objects of type T
     */
    func GET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, callback: (GeocoreResult<[T]>) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.GET, parameters: parameters), callback: callback)
    }
    
    /**
        Promise multiple result of type T from an HTTP GET request.
     */
    func promisedGET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil) -> Promise<[T]> {
        return Promise { (fulfiller, rejecter) in
            self.GET(path, parameters: parameters) { (result: GeocoreResult<[T]>) -> Void in
                result.propagateTo(fulfiller, rejecter: rejecter)
            }
        }
    }
    
    /**
        Do an HTTP POST request expecting one result of type T
     */
    func POST<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, body: [String: AnyObject]? = nil, callback: (GeocoreResult<T>) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.POST, parameters: parameters, body: body), callback: callback)
    }
    
    func uploadPOST<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, fieldName: String, fileName: String, mimeType: String, fileContents: NSData, callback: (GeocoreResult<T>) -> Void) {
        self.POST(path, parameters: parameters, body: ["$fileContents": fileContents, "$fileName": fileName, "$fieldName": fieldName, "$mimeType": mimeType], callback: callback)
    }
    
    /**
        Promise a single result of type T from an HTTP POST request.
     */
    func promisedPOST<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, body: [String: AnyObject]? = nil) -> Promise<T> {
        return Promise { (fulfiller, rejecter) in
            self.POST(path, parameters: parameters, body: body) { (result: GeocoreResult<T>) -> Void in
                result.propagateTo(fulfiller, rejecter: rejecter)
            }
        }
    }
    
    func promisedUploadPOST<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, fieldName: String, fileName: String, mimeType: String, fileContents: NSData) -> Promise<T> {
        return self.promisedPOST(path, parameters: parameters, body: ["$fileContents": fileContents, "$fileName": fileName, "$fieldName": fieldName, "$mimeType": mimeType])
    }
    
    /**
        Do an HTTP DELETE request expecting one result of type T
     */
    func DELETE<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, callback: (GeocoreResult<T>) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.DELETE, parameters: parameters), callback: callback)
    }
    
    /**
        Promise a single result of type T from an HTTP DELETE request.
     */
    func promisedDELETE<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil) -> Promise<T> {
        return Promise { (fulfiller, rejecter) in
            self.DELETE(path, parameters: parameters) { (result: GeocoreResult<T>) -> Void in
                result.propagateTo(fulfiller, rejecter: rejecter)
            }
        }
    }
    
    // MARK: User management methods (callback version)
    
    /**
        Login to Geocore with callback.
    
        :param: userId   User's ID to be submitted.
        :param: password Password for authorizing user.
        :param: callback Closure to be called when the token string or an error is returned.
    */
    public func login(userId: String, password: String, callback:(GeocoreResult<String>) -> Void) {
        self.POST("/auth", parameters: ["id": userId, "password": password, "project_id": self.projectId!]) { (result: GeocoreResult<GeocoreGenericResult>) -> Void in
            switch result {
                case .Success(let wrapper):
                    self.token = wrapper.value.json["token"].string
                    if let token = self.token {
                        callback(GeocoreResult(token))
                    } else {
                        callback(.Failure(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_STATE.rawValue, userInfo: nil)))
                    }
                case .Failure(let error):
                    callback(.Failure(error))
            }
        }
    }
    
    public func loginWithDefaultUser(callback:(GeocoreResult<String>) -> Void) {
        // login using default id & password
        self.login(GeocoreUser.defaultId(), password: GeocoreUser.defaultPassword()) { result in
            switch result {
            case .Success(let wrapper):
                callback(result)
            case .Failure(let error):
                // oops! try to register first
                if let errorCode = error.userInfo?["code"] as? String {
                    if errorCode == "Auth.0001" {
                        // not registered, register the default user first
                        GeocoreUser.defaultUser().register() { result in
                            switch result {
                            case .Success(let wrapper):
                                // successfully registered, now login again
                                self.login(GeocoreUser.defaultId(), password: GeocoreUser.defaultPassword()) { result in
                                    callback(result)
                                }
                            case .Failure(let error):
                                callback(.Failure(error))
                            }
                        }
                    } else {
                        // unexpected error
                        callback(.Failure(error))
                    }
                } else {
                    // unexpected error
                    callback(.Failure(error))
                }
            }
        }
    }
    
    // MARK: User management methods (promise version)
    
    /**
        Login to Geocore with promise.
    
        :param: userId   User's ID to be submitted.
        :param: password Password for authorizing user.
    
        :returns: Promise for Geocore Access Token (as String).
     */
    public func login(userId: String, password: String) -> Promise<String> {
        return Promise { (fulfiller, rejecter) in
            self.login(userId, password: password) { result in
                result.propagateTo(fulfiller, rejecter: rejecter)
            }
        }
    }
    
    public func loginWithDefaultUser() -> Promise<String> {
        return Promise { (fulfiller, rejecter) in
            self.loginWithDefaultUser { result in
                result.propagateTo(fulfiller, rejecter: rejecter)
            }
        }
    }
    
}


