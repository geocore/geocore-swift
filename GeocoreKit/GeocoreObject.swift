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
#endif

// MARK: - Common Objects

/**
    Geographical point in WGS84.
 */
public struct GeocorePoint: GeocoreSerializableToJSON {
    public var latitude: Float?
    public var longitude: Float?
    
    public init() {
    }
    
    public init(latitude: Float?, longitude: Float?) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(_ json: JSON) {
        self.latitude = json["latitude"].float
        self.longitude = json["longitude"].float
    }
    
    public func toDictionary() -> [String: AnyObject] {
        if let latitude = self.latitude, longitude = self.longitude {
            return ["latitude": NSNumber(float: latitude), "longitude": NSNumber(float: longitude)]
        } else {
            return [String: AnyObject]()
        }
    }
}

/**
    Tag-related parameters to be submitted as part of a request.
*/
public class GeocoreTagParameters: GeocoreSerializableToJSON {
    private var tagIds: [String]?
    private var tagNames: [String]?
    
    public init() {
    }
    
    public func toDictionary() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        if let tagIds = self.tagIds { dict["tag_ids"] = ",".join(tagIds) }
        if let tagNames = self.tagNames { dict["tag_names"] = ",".join(tagNames) }
        return dict
    }
    
    /**
        Set tag IDs to be submitted as request parameter.
    
        :param: tagIds Tag IDs to be submitted
    
        :returns: The updated parameter object to be chain-called.
    */
    public func tagIds(tagIds: [String]) -> GeocoreTagParameters {
        self.tagIds = tagIds
        return self
    }

    /**
        Set tag names to be submitted as request parameter.
    
        :param: tagNames Tag names to be submitted
    
        :returns: The updated parameter object to be chain-called.
    */
    public func tagNames(tagNames: [String]) -> GeocoreTagParameters {
        self.tagNames = tagNames
        return self
    }
}

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

/**
    Base class of all objects managed by Geocore providing basic properties
    and services.
 */
public class GeocoreObject: GeocoreSerializableToJSON, GeocoreInitializableFromJSON {
    
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
    
    // MARK: Callback version
    
    private func doWithSid<T>(errorMessage: String, callback: (GeocoreResult<T>) -> Void, closure: (Int64)->Void) {
        if let sid = self.sid {
            closure(sid)
        } else {
            callback(.Failure(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_PARAMETER.rawValue, userInfo: ["message": errorMessage])))
        }
    }
    
    public class func get(id: String, callback: (GeocoreResult<GeocoreObject>) -> Void) {
        Geocore.sharedInstance.GET("/objs/\(id)", callback: callback)
    }
    
    func delete<T: GeocoreInitializableFromJSON>(path: String, callback: (GeocoreResult<T>) -> Void) {
        self.doWithSid("Unsaved object cannot be deleted", callback: callback) { (sid) -> Void in
            Geocore.sharedInstance.DELETE("/\(path)/\(sid)", callback: callback)
        }
    }
    
    public func upload(key: String, data: NSData, mimeType: String, callback: (GeocoreResult<GeocoreBinaryDataInfo>) -> Void) {
        self.doWithSid("Unsaved object cannot have binary data", callback: callback) { (sid) -> Void in
            Geocore.sharedInstance.uploadPOST("/objs/\(sid)/bins/\(key)", parameters: nil, fieldName: "data", fileName: "data", mimeType: mimeType, fileContents: data, callback: callback)
        }
    }
    
    public func binaries(callback: (GeocoreResult<[GeocoreBinaryDataInfo]>) -> Void) {
        self.doWithSid("Unsaved object cannot have binary data", callback: callback) { (sid) -> Void in
            Geocore.sharedInstance.GET("/objs/\(sid)/bins", parameters: nil, callback: callback)
        }
    }
    
    public func binary(key: String, callback: (GeocoreResult<GeocoreBinaryDataInfo>) -> Void) {
        self.doWithSid("Unsaved object cannot have binary data", callback: callback) { (sid) -> Void in
            Geocore.sharedInstance.GET("/objs/\(sid)/bins/\(key)/url", parameters: nil, callback: callback)
        }
    }
    
    // MARK: Promise version
    
    private func doWithSid<T>(errorMessage: String, closure: (Int64)->Promise<T>) -> Promise<T> {
        if let sid = self.sid {
            return closure(sid)
        } else {
            return Promise { (fulfiller, rejecter) in
                rejecter(NSError(domain: GeocoreErrorDomain, code: GeocoreError.INVALID_PARAMETER.rawValue, userInfo: ["message": "Unsaved object cannot be deleted"]))
            }
        }
    }
    
    public class func get(id: String) -> Promise<GeocoreObject> {
        return Geocore.sharedInstance.promisedGET("/objs/\(id)")
    }
    
    func delete<T: GeocoreInitializableFromJSON>(path: String) -> Promise<T> {
        return self.doWithSid("Unsaved object cannot be deleted") { (sid) -> Promise<T> in
            return Geocore.sharedInstance.promisedDELETE("/\(path)/\(sid)")
        }
    }
    
    public func upload(key: String, data: NSData, mimeType: String) -> Promise<GeocoreBinaryDataInfo> {
        return self.doWithSid("Unsaved object cannot have binary data") { (sid) -> Promise<GeocoreBinaryDataInfo> in
            return Geocore.sharedInstance.promisedUploadPOST("/objs/\(sid)/bins/\(key)", parameters: nil, fieldName: "data", fileName: "data", mimeType: mimeType, fileContents: data)
        }
    }
    
    public func binaries() -> Promise<[GeocoreBinaryDataInfo]> {
        return self.doWithSid("Unsaved object cannot have binary data") { (sid) -> Promise<[GeocoreBinaryDataInfo]> in
            return Geocore.sharedInstance.promisedGET("/objs/\(sid)/bins", parameters: nil)
        }
    }
    
    public func binary(key: String) -> Promise<GeocoreBinaryDataInfo> {
        return self.doWithSid("Unsaved object cannot have binary data") { (sid) -> Promise<GeocoreBinaryDataInfo> in
            return Geocore.sharedInstance.promisedGET("/objs/\(sid)/bins/\(key)/url", parameters: nil)
        }
    }
    
}

// MARK: -

public enum GeocoreTagType: String {
    case SYSTEM_TAG = "SYSTEM_TAG"
    case USER_TAG = "USER_TAG"
}

public class GeocoreTag: GeocoreObject {
    
    public var type: GeocoreTagType?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        if let type = json["type"].string { self.type = GeocoreTagType(rawValue: type) }
        super.init(json)
    }
    
    public override func toDictionary() -> [String : AnyObject] {
        var dict = super.toDictionary()
        if let type = self.type { dict["type"] = type.rawValue }
        return dict
    }
}

// MARK: -

public class GeocoreTaggable: GeocoreObject {
    
    public var tags: [GeocoreTag]?
    
    var tagIds: [String]?
    var tagNames: [String]?
    var tagSids: [Int64]?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        if let tagsJSON = json["tags"].array {
            self.tags = tagsJSON.map({ GeocoreTag($0) })
        }
        super.init(json)
    }
    
    public override func toDictionary() -> [String : AnyObject] {
        return super.toDictionary()
    }
    
    public func tag(tagIdsOrNames: [String]) {
        for tagIdOrName in tagIdsOrNames {
            // for now, assume that if the tag starts with 'TAG', it's a tag id, otherwise it's a name
            if tagIdOrName.hasPrefix("TAG") {
                if self.tagIds == nil {
                   self.tagIds = [tagIdOrName]
                } else {
                   self.tagIds?.append(tagIdOrName)
                }
            } else {
                if self.tagNames == nil {
                    self.tagNames = [tagIdOrName]
                } else {
                    self.tagNames?.append(tagIdOrName)
                }
            }
        }
    }
    
    func resolveTagParameters() -> GeocoreTagParameters? {
        if self.tagIds != nil || self.tagNames != nil {
            var params = GeocoreTagParameters()
            if let tagIds = self.tagIds {
                params.tagIds(tagIds)
            }
            if let tagNames = self.tagNames {
                params.tagNames(tagNames)
            }
            return params
        } else {
            return nil
        }
    }
    
    func savePath(serviceName: String) -> String {
        if let sid = self.sid {
            return "/\(serviceName)/\(sid)"
        } else {
            return "/\(serviceName)"
        }
    }
    
    func save<T: GeocoreInitializableFromJSON>(path: String, callback: (GeocoreResult<T>) -> Void) {
        if let params = resolveTagParameters() {
            Geocore.sharedInstance.POST(savePath(path), parameters: params.toDictionary(), body: self.toDictionary(), callback: callback)
        } else {
            Geocore.sharedInstance.POST(savePath(path), parameters: self.toDictionary(), callback: callback)
        }
    }
    
    func save<T: GeocoreInitializableFromJSON>(path: String) -> Promise<T> {
        if let params = resolveTagParameters() {
            return Geocore.sharedInstance.promisedPOST(savePath(path), parameters: params.toDictionary(), body: self.toDictionary())
        } else {
            return Geocore.sharedInstance.promisedPOST(savePath(path), parameters: self.toDictionary())
        }
    }
    
}

// MARK: -

public class GeocoreUser: GeocoreTaggable {
    
    public var password: String?
    public var email: String?
    private(set) public var lastLocationTime: NSDate?
    private(set) public var lastLocation: GeocorePoint?
    var groupIds: [String]?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.email = json["email"].string
        self.lastLocationTime = NSDate.fromGeocoreFormattedString(json["lastLocationTime"].string)
        self.lastLocation = GeocorePoint(json["lastLocation"])
        super.init(json)
    }
    
    public override func toDictionary() -> [String: AnyObject] {
        var dict = super.toDictionary()
        if let password = self.password { dict["password"] = password }
        if let email = self.email { dict["email"] = email }
        return dict
    }
    
    private func registerParams() -> [String: AnyObject]? {
        var params = [String: AnyObject]()
        if let groupIds = self.groupIds { params["group_ids"] = ",".join(groupIds) }
        if let tagParams = resolveTagParameters() { params += tagParams.toDictionary() }
        return params.count > 0 ? params : nil
    }
    
    private class func userIdWithSuffix(suffix: String) -> String {
        if let projectId = Geocore.sharedInstance.projectId {
            if projectId.hasPrefix("PRO") {
                // user ID pattern: USE-[project_suffix]-[user_id_suffix]
                return "USE\(projectId.substringFromIndex(advance(projectId.startIndex, 3)))-\(suffix)"
            } else {
                return suffix
            }
        } else {
            return suffix
        }
    }
    
    public class func defaultName() -> String {
        #if os(iOS)
            #if (arch(i386) || arch(x86_64))
                // iOS simulator
                return "IOS_SIMULATOR"
                #else
                // iOS device
                return UIDevice.currentDevice().identifierForVendor.UUIDString
            #endif
            #else
            // TODO: generate ID on OSX based on user's device ID
            return "DEFAULT"
        #endif
    }
    
    public class func defaultId() -> String {
        return userIdWithSuffix(defaultName())
    }
    
    public class func defaultEmail() -> String {
        return "\(defaultName())@geocore.jp"
    }
    
    public class func defaultPassword() -> String {
        return String(reverse(defaultId()))
    }
    
    public class func defaultUser() -> GeocoreUser {
        let user = GeocoreUser()
        user.id = GeocoreUser.defaultId()
        user.name = GeocoreUser.defaultName()
        user.email = GeocoreUser.defaultEmail()
        user.password = GeocoreUser.defaultPassword()
        return user
    }
    
    // MARK: Callback version
    
    public func register(callback: (GeocoreResult<GeocoreUser>) -> Void) {
        Geocore.sharedInstance.POST("/register", parameters: registerParams(), body: self.toDictionary(), callback: callback)
    }
    
    public func save(callback: (GeocoreResult<GeocoreUser>) -> Void) {
        super.save("users", callback: callback)
    }
    
    // MARK: Promise version
    
    public func register() -> Promise<GeocoreUser> {
        return Geocore.sharedInstance.promisedPOST("/register", parameters: registerParams(), body: self.toDictionary())
    }
    
    public func save() -> Promise<GeocoreUser> {
        return super.save("users")
    }
        
}

// MARK: -

public class GeocorePlace: GeocoreTaggable {
    
    public var shortName: String?
    public var shortDescription: String?
    public var point: GeocorePoint?
    public var distanceLimit: Float?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.shortName = json["shortName"].string
        self.shortDescription = json["shortDescription"].string
        self.point = GeocorePoint(json["point"])
        self.distanceLimit = json["distanceLimit"].float
        super.init(json)
    }
    
    public override func toDictionary() -> [String : AnyObject] {
        var dict = super.toDictionary()
        if let shortName = self.shortName { dict["shortName"] = shortName }
        if let shortDescription = self.shortDescription { dict["shortDescription"] = shortDescription }
        if let point = self.point { dict["point"] = point.toDictionary() }
        if let distanceLimit = self.distanceLimit { dict["distanceLimit"] = distanceLimit }
        return dict
    }
    
    // MARK: Callback version
    
    public func save(callback: (GeocoreResult<GeocorePlace>) -> Void) {
        super.save("places", callback: callback)
    }
    
    public class func get(id: String, callback: (GeocoreResult<GeocorePlace>) -> Void) {
        Geocore.sharedInstance.GET("/places/\(id)", callback: callback)
    }
    
    public class func get(callback: (GeocoreResult<[GeocorePlace]>) -> Void) {
        Geocore.sharedInstance.GET("/places", callback: callback)
    }
    
    public class func get(#minLat: Double, minLon: Double, maxLat: Double, maxLon: Double, callback: (GeocoreResult<GeocorePlace>) -> Void) {
        Geocore.sharedInstance.GET("/places/search/within/rect?max_lat=\(maxLat)&min_lon=\(minLon)&min_lat=\(minLat)&max_lon=\(maxLon)", callback: callback)
    }
    
    public func delete(callback: (GeocoreResult<GeocorePlace>) -> Void) {
        super.delete("/places", callback: callback)
    }
    
    // MARK: Promise version
    
    public func save() -> Promise<GeocorePlace> {
        return super.save("places")
    }
    
    public class func get(id: String) -> Promise<GeocorePlace> {
        return Geocore.sharedInstance.promisedGET("/places/\(id)")
    }
    
    public class func get() -> Promise<[GeocorePlace]> {
        return Geocore.sharedInstance.promisedGET("/places")
    }
    
    public class func get(#minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) -> Promise<[GeocorePlace]> {
        return Geocore.sharedInstance.promisedGET("/places/search/within/rect?max_lat=\(maxLat)&min_lon=\(minLon)&min_lat=\(minLat)&max_lon=\(maxLon)")
    }
    
    public class func get(#centerLat: Double, centerLon: Double) -> Promise<[GeocorePlace]> {
        return Geocore.sharedInstance.promisedGET("/places/search/nearest?lat=\(centerLat)&lon=\(centerLon)")
    }
    
    public func delete() -> Promise<GeocorePlace> {
        return super.delete("/places")
    }
    
}
