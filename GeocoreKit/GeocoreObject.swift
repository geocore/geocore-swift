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

public class GeocoreObject: GeocoreInitializableFromJSON {
    
    public var sid: Int64?
    public var id: String?
    public var name: String?
    public var description: String?
    
    public init() {
    }
    
    public required init(json: JSON) {
        self.sid = json["sid"].int64
        self.id = json["id"].string
        self.name = json["name"].string
        self.description = json["description"].string
    }
    
    public class func get(id: String, callback: (GeocoreObject?, NSError?) -> Void) {
        Geocore.sharedInstance.GET("/objs/\(id)", callback: callback)
    }
    
    public class func get(id: String) -> Promise<GeocoreObject> {
        return Geocore.sharedInstance.promisedGET("/objs/\(id)")
    }
}


public struct GeocorePoint {
    public var latitude: Float?
    public var longitude: Float?
}

public class GeocorePlace: GeocoreObject {
    
    public var shortName: String?
    public var shortDescription: String?
    public var point: GeocorePoint?
    
    public required init(json: JSON) {
        self.shortName = json["shortName"].string
        self.shortDescription = json["shortDescription"].string
        self.point = GeocorePoint(
            latitude: json["point"]["latitude"].float,
            longitude: json["point"]["longitude"].float)
        super.init(json: json)
    }
    
    public override class func get(id: String, callback: (GeocorePlace?, NSError?) -> Void) {
        Geocore.sharedInstance.GET("/places/\(id)", callback: callback)
    }
    
    public class func get(callback: ([GeocorePlace]?, NSError?) -> Void) {
        Geocore.sharedInstance.GET("/places", callback: callback)
    }
    
    public class func get(id: String) -> Promise<GeocorePlace> {
        return Geocore.sharedInstance.promisedGET("/places/\(id)")
    }
    
    public class func get() -> Promise<[GeocorePlace]> {
        return Geocore.sharedInstance.promisedGET("/places")
    }
    
}
