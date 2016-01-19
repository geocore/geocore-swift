//
//  GeocoreObject.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 4/15/15.
//
//

import Foundation
import SwiftyJSON
import PromiseKit
import Alamofire
#if os(iOS)
    import UIKit
    import AlamofireImage
#endif

// MARK: - Object Operations and Queries

/**
    Base class for all operations that can be used to interact with Geocore services
    to fetch and manipulate Geocore objects.
 */
public class GeocoreObjectOperation {
    
    private(set) public var id: String?
    private(set) public var customDataValue: String?
    private(set) public var customDataKey: String?
    
    public init() {
    }
    
    /**
     Assign the object ID to operate on.
     
     - parameter id: Object ID
     
     - returns: The updated operation object to be chain-called.
     */
    public func withId(id: String) -> Self {
        self.id = id
        return self
    }
    
    public func withCustomDataKey(customDataKey: String) -> Self {
        self.customDataKey = customDataKey
        return self
    }
    
    public func havingCustomData(value: String, forKey: String) -> Self {
        self.customDataValue = value
        self.customDataKey = forKey
        return self
    }
    
    public func buildPath(forService: String) -> String {
        if let id = self.id {
            return "\(forService)/\(id)";
        } else {
            return forService;
        }
    }
    
    public func buildPath(forService: String, withSubPath: String) -> String? {
        if let id = self.id {
            return "\(forService)/\(id)\(withSubPath)";
        } else {
            return nil;
        }
    }
    
    public func buildQueryParameters() -> [String: AnyObject] {
        return [String: AnyObject]();
    }
    
    public func save<TI: GeocoreIdentifiable, TO: GeocoreInitializableFromJSON>(obj: TI, forService: String) -> Promise<TO> {
        if let sid = obj.sid {
            // use sid to determine whether this 'save' is for 'create' or 'update'
            // withId will only work for 'update'
            withId("\(sid)")
        }
        let params = buildQueryParameters()
        if params.count > 0 {
            return Geocore.sharedInstance.promisedPOST(buildPath(forService), parameters: params, body: obj.toDictionary())
        } else {
            return Geocore.sharedInstance.promisedPOST(buildPath(forService), parameters: obj.toDictionary())
        }
    }
    
    public func delete<T: GeocoreIdentifiable>(obj: T, forService: String) -> Promise<T> {
        if let id = obj.id {
            withId(id)
            return Geocore.sharedInstance.promisedDELETE(buildPath(forService))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Unsaved object cannot be deleted")) }
        }
    }
    
    public func deleteCustomData() -> Promise<GeocoreObject> {
        if let _ = self.id, customDataKey = self.customDataKey {
            return Geocore.sharedInstance.promisedDELETE(buildPath("/objs", withSubPath: "/customData/\(customDataKey)")!)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id, custom data key")) }
        }
    }
    
}

public class GeocoreObjectQuery: GeocoreObjectOperation {
    
    private(set) public var unlimitedRecords: Bool
    private(set) public var name: String?
    private(set) public var fromDate: NSDate?
    private(set) public var page: Int?
    private(set) public var numberPerPage: Int?
    private(set) public var recentlyCreated: Bool?
    private(set) public var recentlyUpdated: Bool?
    private(set) public var associatedWithUnendingEvent: Bool?
    
    public override init() {
        self.unlimitedRecords = false
    }
    
    public func withName(name: String) -> Self {
        self.name = name
        return self
    }
    
    public func updatedAfter(date: NSDate) -> Self {
        self.fromDate = date
        return self
    }
    
    public func page(page: Int) -> Self {
        self.page = page
        return self
    }
    
    public func numberPerPage(numberPerPage: Int) -> Self {
        self.numberPerPage = numberPerPage
        return self
    }
    
    public func orderByRecentlyCreated() -> Self {
        self.recentlyCreated = true
        return self
    }
    
    public func orderByRecentlyUpdated() -> Self {
        self.recentlyUpdated = true
        return self
    }
    
    public func onlyObjectsAssociatedWithUnendingEvent() -> Self {
        self.associatedWithUnendingEvent = true
        return self
    }
    
    public override func buildQueryParameters() -> [String: AnyObject] {
        var dict = super.buildQueryParameters()
        if unlimitedRecords {
            dict["num"] = 0
        } else {
            if let page = self.page {
                dict["page"] = page
            }
            if let numberPerPage = self.numberPerPage {
                dict["num"] = numberPerPage
            }
        }
        if let fromDate = self.fromDate {
            dict["from_date"] = NSDateFormatter.dateFormatterForGeocore().stringFromDate(fromDate)
        }
        if let recentlyCreated = self.recentlyCreated {
            dict["recent_created"] = recentlyCreated
        }
        if let recentlyUpdated = self.recentlyUpdated {
            dict["recent_updated"] = recentlyUpdated
        }
        if let associatedWithUnendingEvent = self.associatedWithUnendingEvent {
            if (associatedWithUnendingEvent) {
                dict["bf_ev_end"] = NSDateFormatter.dateFormatterForGeocore().stringFromDate(NSDate())
            }
        }
        
        return dict
    }
    
    public func get<T: GeocoreInitializableFromJSON>(forService: String) -> Promise<T> {
        if id != nil {
            return Geocore.sharedInstance.promisedGET(buildPath(forService), parameters: buildQueryParameters())
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
    public func all<T: GeocoreInitializableFromJSON>(forService: String) -> Promise<[T]> {
        return Geocore.sharedInstance.promisedGET(buildPath(forService), parameters: buildQueryParameters())
    }
    
    public func get() -> Promise<GeocoreObject> {
        return self.get("/objs")
    }
    
    public func lastUpdate(forService: String) -> Promise<NSDate> {
        return Promise { fulfill, reject in
            Geocore.sharedInstance.GET("\(forService)/lastUpdate", callback: { (result: GeocoreResult<GeocoreGenericResult>) -> Void in
                switch result {
                case .Success(let value):
                    if let lastUpdate = value.json["lastUpdate"].string {
                        if let lastUpdateDate = NSDateFormatter.dateFormatterForGeocore().dateFromString(lastUpdate) {
                            fulfill(lastUpdateDate)
                        } else {
                            reject(GeocoreError.UnexpectedResponse(message: "Unable to convert lastUpdate to NSDate: \(lastUpdate)"))
                        }
                    } else {
                        reject(GeocoreError.UnexpectedResponse(message: "Unable to find lastUpdate in response"))
                    }
                case .Failure(let error):
                    reject(error)
                }
            })
        }
    }  
    
}

public class GeocoreObjectBinaryOperation: GeocoreObjectOperation {
    
    private(set) public var key: String?
    private(set) public var mimeType: String = "application/octet-stream"
    private(set) public var data: NSData?
    
    public func withKey(key: String) -> Self {
        self.key = key
        return self
    }
    
    public func withMimeType(mimeType: String) -> Self {
        self.mimeType = mimeType
        return self
    }
    
    public func withData(data: NSData) -> Self {
        self.data = data
        return self
    }
    
    public func upload() -> Promise<GeocoreBinaryDataInfo> {
        if let id = self.id, let key = self.key, let data = self.data {
            return Geocore.sharedInstance.promisedUploadPOST(
                "/objs/\(id)/bins/\(key)",
                fieldName: "data",
                fileName: "data",
                mimeType: self.mimeType,
                fileContents: data)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting both key and data")) }
        }
    }
    
    public func binaries() -> Promise<[String]> {
        if let path = buildPath("/objs", withSubPath: "/bins") {
            let generics: Promise<[GeocoreGenericResult]> = Geocore.sharedInstance.promisedGET(path, parameters: nil)
            return generics.then { (generics) -> [String] in
                var bins = [String]()
                for generic in generics {
                    bins.append(generic.json.string!)
                }
                return bins
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
    public func binary() -> Promise<GeocoreBinaryDataInfo> {
        if let key = self.key {
            if let path = buildPath("/objs", withSubPath: "/bins/\(key)/url") {
                return Geocore.sharedInstance.promisedGET(path, parameters: nil)
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting key")) }
        }
    }
    
    public func url() -> Promise<String> {
        return self.binary().then { (binaryDataInfo) -> Promise<String> in
            if let url = binaryDataInfo.url {
                // TODO: should support https!
                // for now just replace https with http
                var finalUrl = url
                if (url.hasPrefix("https")) {
                    finalUrl = "http\((url as NSString).substringFromIndex(5))"
                }
                //print("url -> \(finalUrl)")
                return Promise(finalUrl)
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.UnexpectedResponse(message: "url is nil")) }
            }
        }
    }
    
    public func url<T>(transform: (String?, String) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.url()
                .then { (url) -> Void in
                    fulfill(transform(self.id, url))
                }
                .error { error in
                    print("error getting url for id -> \(self.id)")
                    reject(error)
                }
        }
    }
    
#if os(iOS)
    public func image() -> Promise<UIImage> {
        return Promise { fulfill, reject in
            self.url()
                .then { (url) -> Void in
                    Alamofire.request(.GET, url).responseImage { response in
                        if let image = response.result.value {
                            fulfill(image)
                        } else if let error = response.result.error {
                            reject(GeocoreError.UnexpectedResponse(message: "Error downloading image: \(error)"))
                        } else {
                            reject(GeocoreError.UnexpectedResponse(message: "Error downloading image: unknown error"))
                        }
                    }
                }
                .error { error in
                    reject(error)
                }
        }
    }
    
    public func image<T>(transform: (String?, GeocoreBinaryDataInfo, UIImage) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            self.binary()
                .then { (binaryDataInfo) -> Void in
                    //print("binaryDataInfo -> \(binaryDataInfo)")
                    if let url = binaryDataInfo.url {
                        // TODO: should support https!
                        // for now just replace https with http
                        var finalUrl = url
                        if (url.hasPrefix("https")) {
                            finalUrl = "http\((url as NSString).substringFromIndex(5))"
                        }
                        //print("url -> \(finalUrl)")
                        Alamofire.request(.GET, finalUrl).responseImage { response in
                            if let image = response.result.value {
                                fulfill(transform(self.id, binaryDataInfo, image))
                            } else if let error = response.result.error {
                                reject(GeocoreError.UnexpectedResponse(message: "Error downloading image: \(error)"))
                            } else {
                                reject(GeocoreError.UnexpectedResponse(message: "Error downloading image: unknown error"))
                            }
                        }
                    } else {
                        reject(GeocoreError.UnexpectedResponse(message: "Error downloading image: URL unavailable"))
                    }
                }
                .error { error in
                    reject(error)
                }
        }
    }
#endif
    
}

// MARK: -

/**
    Information about binary data uploads.
 */
public class GeocoreBinaryDataInfo: GeocoreInitializableFromJSON {
    
    private(set) public var key: String?
    private(set) public var url: String?
    private(set) public var contentLength: Int64?
    private(set) public var contentType: String?
    private(set) public var lastModified: NSDate?
    
    public required init(_ json: JSON) {
        if json.type == .String {
            self.key = json.string
        } else {
            self.key = json["key"].string
            self.url = json["url"].string
            self.contentLength = json["metadata"]["contentLength"].int64
            self.contentType = json["metadata"]["contentType"].string
            self.lastModified = NSDate.fromGeocoreFormattedString(json["metadata"]["lastModified"].string)
        }
    }
    
}

// MARK: -

public class GeocoreRelationshipOperation {
    
    private(set) public var id1: String?
    private(set) public var id2: String?
    private(set) public var customData: [String: String?]?
    
    public func withObject1Id(id1: String) -> Self {
        self.id1 = id1
        return self
    }
    
    public func withObject2Id(id2: String) -> Self {
        self.id2 = id2
        return self
    }
    
    public func withCustomData(customData: [String: String?]) -> Self {
        self.customData = customData
        return self
    }
    
    public func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1 {
            if let id2 = self.id2 {
                return "\(forService)/\(id1)\(withSubPath)/\(id2)"
            } else {
                return "\(forService)/\(id1)\(withSubPath)"
            }
        } else {
            return forService
        }
    }
    
}

public class GeocoreRelationshipQuery: GeocoreRelationshipOperation {
    
}

// MARK: -

/**
    Base class of all objects managed by Geocore providing basic properties
    and services.
 */
public class GeocoreObject: GeocoreIdentifiable {
    
    public var sid: Int64?
    public var id: String?
    public var name: String?
    public var desc: String?
    private(set) public var createTime: NSDate?
    private(set) public var updateTime: NSDate?
    private(set) public var upvotes: Int64?
    private(set) public var downvotes: Int64?
    public var customData: [String: String?]?
    public var jsonData: JSON?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        self.sid = json["sid"].int64
        self.id = json["id"].string
        self.name = json["name"].string
        self.desc = json["description"].string
        self.createTime = NSDate.fromGeocoreFormattedString(json["createTime"].string)
        self.updateTime = NSDate.fromGeocoreFormattedString(json["updateTime"].string)
        self.upvotes = json["upvotes"].int64
        self.downvotes = json["downvotes"].int64
        self.customData = json["customData"].dictionary?.map { ($0, $1.string) }
        self.jsonData = json["jsonData"]
        if self.jsonData?.type == .Null { self.jsonData = nil }
    }
    
    public func toDictionary() -> [String: AnyObject] {
        // wish this can be automatic
        var dict = [String: AnyObject]()
        if let sid = self.sid { dict["sid"] = NSNumber(longLong: sid) }
        if let id = self.id { dict["id"] = id }
        if let name = self.name { dict["name"] = name }
        if let desc = self.desc { dict["description"] = desc }
        if let customData = self.customData { dict["customData"] = customData.filter{ $1 != nil }.map{ ($0, $1!) } }
        if let jsonData = self.jsonData { dict["jsonData"] = jsonData.rawString() }
        return dict
    }
    
    public func query() -> GeocoreObjectQuery {
        if let id = self.id {
            return GeocoreObjectQuery().withId(id)
        } else {
            return GeocoreObjectQuery()
        }
    }
    
    public class func get(id: String) -> Promise<GeocoreObject> {
        return GeocoreObjectQuery().withId(id).get();
    }
    
    public func save() -> Promise<GeocoreObject> {
        return GeocoreObjectOperation().save(self, forService: "/objs")
    }
    
    public func delete() -> Promise<GeocoreObject> {
        return GeocoreObjectOperation().delete(self, forService: "/objs")
    }
    
    public func upload(key: String, data: NSData, mimeType: String) -> Promise<GeocoreBinaryDataInfo> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .withId(id)
                .withKey(key)
                .withMimeType(mimeType)
                .withData(data)
                .upload()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Unsaved object cannot upload binaries")) }
        }
    }
    
    public func binaries() -> Promise<[String]> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .withId(id)
                .binaries()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }
    
    public func binary(key: String) -> Promise<GeocoreBinaryDataInfo> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .withId(id)
                .withKey(key)
                .binary()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }

#if os(iOS)
    public func image(key: String) -> Promise<UIImage> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .withId(id)
                .withKey(key)
                .image()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }
#endif
    
    public func url(key: String) -> Promise<String> {
        if let id = self.id {
            return GeocoreObjectBinaryOperation()
                .withId(id)
                .withKey(key)
                .url()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Unsaved object doesn't have binaries")) }
        }
    }
    
    public func addCustomData(key: String, value: String) -> Self {
        if self.customData == nil {
            self.customData = [String: String?]()
        }
        self.customData![key] = value
        return self
    }
    
    public func deleteCustomData(key: String) -> Promise<GeocoreObject> {
        return GeocoreObjectOperation()
            .withId(self.id!)
            .withCustomDataKey(key)
            .deleteCustomData()
    }
    
}

public class GeocoreRelationship: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    
    private(set) public var updateTime: NSDate?
    public var customData: [String: String?]?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        self.updateTime = NSDate.fromGeocoreFormattedString(json["updateTime"].string)
        self.customData = json["customData"].dictionary?.map { ($0, $1.string) }
    }
    
    public func toDictionary() -> [String: AnyObject] {
        // wish this can be automatic
        var dict = [String: AnyObject]()
        if let customData = self.customData { dict["customData"] = customData.filter{ $1 != nil }.map{ ($0, $1!) } }
        return dict
    }

    
}
