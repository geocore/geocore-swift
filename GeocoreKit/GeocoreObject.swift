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

public struct GeocorePoint {
    public var latitude: Float?
    public var longitude: Float?
    
    public init() {
    }
    
    public init(latitude: Float?, longitude: Float?) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

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
    
    :returns: Parameter object to be chain-called.
    */
    public func tagIds(tagIds: [String]) -> GeocoreTagParameters {
        self.tagIds = tagIds
        return self
    }
    
    public func tagNames(tagNames: [String]) -> GeocoreTagParameters {
        self.tagNames = tagNames
        return self
    }
}

// MARK: -

public class GeocoreObject: GeocoreSerializableToJSON, GeocoreInitializableFromJSON {
    
    public var sid: Int64?
    public var id: String?
    public var name: String?
    public var desc: String?
    
    public init() {
    }
    
    public required init(_ json: JSON) {
        self.sid = json["sid"].int64
        self.id = json["id"].string
        self.name = json["name"].string
        self.desc = json["description"].string
    }
    
    public func toDictionary() -> [String: AnyObject] {
        // wish this can be automatic
        var dict = [String: AnyObject]()
        if let sid = self.sid { dict["sid"] = NSNumber(longLong: sid) }
        if let id = self.id { dict["id"] = id }
        if let name = self.name { dict["name"] = name }
        if let desc = self.desc { dict["description"] = desc }
        return dict
    }
    
    // MARK: Callback version
    
    public class func get(id: String, callback: (GeocoreResult<GeocoreObject>) -> Void) {
        Geocore.sharedInstance.GET("/objs/\(id)", callback: callback)
    }
    
    // MARK: Promise version
    
    public class func get(id: String) -> Promise<GeocoreObject> {
        return Geocore.sharedInstance.promisedGET("/objs/\(id)")
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
        self.point = GeocorePoint(
            latitude: json["point"]["latitude"].float,
            longitude: json["point"]["longitude"].float)
        self.distanceLimit = json["distanceLimit"].float
        super.init(json)
    }
    
    public override func toDictionary() -> [String : AnyObject] {
        var dict = super.toDictionary()
        if let shortName = self.shortName { dict["shortName"] = shortName }
        if let shortDescription = self.shortDescription { dict["shortDescription"] = shortDescription }
        if let latitude = self.point?.latitude, longitude = self.point?.longitude {
            dict["point"] = ["latitude": NSNumber(float: latitude), "longitude": NSNumber(float: longitude)]
        }
        if let distanceLimit = self.distanceLimit { dict["distanceLimit"] = distanceLimit }
        return dict
    }
    
    private func savePath() -> String {
        if let sid = self.sid {
            return "/places/\(sid)"
        } else {
            return "/places"
        }
    }
    
    // MARK: Callback version
    
    public func save(callback: (GeocoreResult<GeocorePlace>) -> Void) {
        if let params = resolveTagParameters() {
            Geocore.sharedInstance.POST(savePath(), parameters: params.toDictionary(), body: self.toDictionary(), callback: callback)
        } else {
            Geocore.sharedInstance.POST(savePath(), parameters: self.toDictionary(), callback: callback)
        }
    }
    
    public class func get(id: String, callback: (GeocoreResult<GeocorePlace>) -> Void) {
        Geocore.sharedInstance.GET("/places/\(id)", callback: callback)
    }
    
    public class func get(callback: (GeocoreResult<[GeocorePlace]>) -> Void) {
        Geocore.sharedInstance.GET("/places", callback: callback)
    }
    
    // MARK: Promise version
    
    public func save() -> Promise<GeocorePlace> {
        if let params = resolveTagParameters() {
            return Geocore.sharedInstance.promisedPOST(savePath(), parameters: params.toDictionary(), body: self.toDictionary())
        } else {
            return Geocore.sharedInstance.promisedPOST(savePath(), parameters: self.toDictionary())
        }
    }
    
    public class func get(id: String) -> Promise<GeocorePlace> {
        return Geocore.sharedInstance.promisedGET("/places/\(id)")
    }
    
    public class func get() -> Promise<[GeocorePlace]> {
        return Geocore.sharedInstance.promisedGET("/places")
    }
    
}
