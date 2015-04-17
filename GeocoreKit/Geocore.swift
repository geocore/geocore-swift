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

public let GeocoreErrorDomain = "jp.geocore.error"
private let HTTPHEADER_ACCESS_TOKEN_NAME = "Geocore-Access-Token"

public enum GeocoreError: Int {
    case INVALID_STATE
    case INVALID_SERVER_RESPONSE
    case SERVER_ERROR
    case TOKEN_UNDEFINED
    case UNAUTHORIZED_ACCESS
}

public protocol GeocoreInitializableFromJSON {
    init(json: JSON)
}

public protocol GeocoreSerializableToJSON {
    func toDictionary() -> [String: AnyObject]
}

public class GeocoreGenericResult: GeocoreInitializableFromJSON {
    var json: JSON
    
    public required init(json: JSON) {
        self.json = json
    }
}

public class Geocore: NSObject {
    
    public static let sharedInstance = Geocore()
    
    public private(set) var baseURL: String?
    public private(set) var projectId: String?
    private var token: String?
    
    private override init() {
    }
    
    public func setup(baseURL: String, projectId: String) -> Geocore {
        self.baseURL = baseURL;
        self.projectId = projectId;
        return self;
    }
    
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
    
    /**
        Build and customize Alamofire request with Geocore token and optional parameter/body specification.
     */
    private func requestBuilder(method: Alamofire.Method, parameters: [String: AnyObject]? = nil, body: [String: AnyObject]? = nil) -> ((String) -> Request) {
        if let token = self.token {
            // if token is available (user already logged-in), use NSMutableURLRequest to customize HTTP header
            return { (path: String) -> Request in
                // NSMutableURLRequest with customized HTTP header
                var mutableURLRequest = self.mutableURLRequest(method, path: path, token: token)
                if let someParameters = parameters, someBody = body {
                    
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
                        mutableURLRequest.URL = URLComponents.URL
                    }
                    
                    // pass body to be processed by Alamofire
                    return Alamofire.request(self.parameterEncoding(method).encode(mutableURLRequest, parameters: someBody).0)
                } else {
                    // set parameters according to standard Alamofire's encode processing
                    return Alamofire.request(self.parameterEncoding(method).encode(mutableURLRequest, parameters: parameters).0)
                }
            }
        } else {
            // otherwise do a normal Alamofire request
            return { (path: String) -> Request in Alamofire.request(method, path, parameters: parameters) }
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
                onError(error)
            } else if let data = optData as? NSData {
                if let statusCode = res?.statusCode {
                    switch statusCode {
                    case 200:
                        let json = JSON(data: data)
                        if let status = json["status"].string {
                            if status == "success" {
                                onSuccess(json["result"])
                            } else {
                                // TODO: should pass along server error as userInfo
                                onError(NSError(domain: GeocoreErrorDomain, code: GeocoreError.SERVER_ERROR.rawValue, userInfo: nil))
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
    func request<T: GeocoreInitializableFromJSON>(path: String, requestBuilder: (String) -> Request, callback: (T?, NSError?) -> Void) {
        self.request(path, requestBuilder: requestBuilder,
            onSuccess: { (json: JSON) -> Void in callback(T(json: json), nil) },
            onError: { (error: NSError) -> Void in callback(nil, error) })
    }
    
    /**
        Request resulting multiple result in an array of objects of type T
     */
    func request<T: GeocoreInitializableFromJSON>(path: String, requestBuilder: (String) -> Request, callback: ([T]?, NSError?) -> Void) {
        self.request(path, requestBuilder: requestBuilder,
            onSuccess: { (json: JSON) -> Void in
                if let result = json.array {
                    callback(result.map { T(json: $0) }, nil)
                } else {
                    callback([], nil)
                }
            },
            onError: { (error: NSError) -> Void in callback(nil, error) })
    }
    
    /**
        Do an HTTP GET request expecting one result of type T
     */
    func GET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, callback: (T?, NSError?) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.GET, parameters: parameters), callback: callback)
    }
    
    /**
        Promise a single result of type T from an HTTP GET request.
     */
    func promisedGET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil) -> Promise<T> {
        return Promise { (fulfiller, rejecter) in
            self.GET(path, parameters: parameters) { (optObj: T?, optError: NSError?) -> Void in
                if let obj = optObj {
                    fulfiller(obj)
                } else {
                    if let error = optError {
                        rejecter(error)
                    } else {
                        rejecter(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_STATE.rawValue, userInfo: nil))
                    }
                }
            }
        }
    }
    
    /**
        Do an HTTP GET request expecting an multiple result in an array of objects of type T
     */
    func GET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, callback: ([T]?, NSError?) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.GET, parameters: parameters), callback: callback)
    }
    
    /**
        Promise multiple result of type T from an HTTP GET request.
     */
    func promisedGET<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil) -> Promise<[T]> {
        return Promise { (fulfiller, rejecter) in
            self.GET(path, parameters: parameters) { (optObj: [T]?, optError: NSError?) -> Void in
                if let obj = optObj {
                    fulfiller(obj)
                } else {
                    if let error = optError {
                        rejecter(error)
                    } else {
                        rejecter(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_STATE.rawValue, userInfo: nil))
                    }
                }
            }
        }
    }
    
    /**
        Do an HTTP POST request expecting one result of type T
     */
    func POST<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, body: [String: AnyObject]? = nil, callback: (T?, NSError?) -> Void) {
        self.request(path, requestBuilder: self.requestBuilder(.POST, parameters: parameters, body: body), callback: callback)
    }
    
    /**
        Promise a single result of type T from an HTTP POST request.
     */
    func promisedPOST<T: GeocoreInitializableFromJSON>(path: String, parameters: [String: AnyObject]? = nil, body: [String: AnyObject]? = nil) -> Promise<T> {
        return Promise { (fulfiller, rejecter) in
            self.POST(path, parameters: parameters, body: body) { (optObj: T?, optError: NSError?) -> Void in
                if let obj = optObj {
                    fulfiller(obj)
                } else {
                    if let error = optError {
                        rejecter(error)
                    } else {
                        rejecter(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_STATE.rawValue, userInfo: nil))
                    }
                }
            }
        }
    }
    
    /**
        Login to Geocore with callback.
     */
    public func login(userId: String, password: String, callback:(String?, NSError?) -> Void) {
        self.POST("/auth", parameters: ["id": userId, "password": password, "project_id": self.projectId!]) { (optResult: GeocoreGenericResult?, error: NSError?) -> Void in
            if let result = optResult {
                self.token = result.json["token"].string
                callback(self.token, nil)
            } else {
                callback(nil, error)
            }
        }
    }
    
    /**
        Login to Geocore with promise.
     */
    public func login(userId: String, password: String) -> Promise<String> {
        return Promise { (fulfiller, rejecter) in
            self.login(userId, password: password, callback: { (optToken, optError) -> Void in
                if let error = optError {
                    rejecter(error)
                } else {
                    fulfiller(optToken!)
                }
            })
        }
    }
    
}


