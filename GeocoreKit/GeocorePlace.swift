//
//  GeocorePlace.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/21/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

public class GeocorePlaceOperation: GeocoreTaggableOperation {
    
}

public class GeocorePlaceQuery: GeocoreObjectQuery {
    
    public func get() -> Promise<GeocorePlace> {
        return self.get("/places")
    }
    
    public func all() -> Promise<[GeocorePlace]> {
        return self.all("/places")
    }
    
    public func events() -> Promise<[GeocoreEvent]> {
        if let path = buildPath("/places", withSubPath: "/events") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
    public func eventRelationships() -> Promise<[GeocorePlaceEvent]> {
        if let path = buildPath("/places", withSubPath: "/events/relationships") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
}

public class GeocorePlace: GeocoreTaggable {
    
    public var shortName: String?
    public var shortDescription: String?
    public var point: GeocorePoint?
    public var distanceLimit: Float?
    
    // TODO: clumsy but will do for now
    // probably should immutabilize all the things
    public var operation: GeocorePlaceOperation?
    
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
    
    public override func query() -> GeocorePlaceQuery {
        if let id = self.id {
            return GeocorePlaceQuery().withId(id)
        } else {
            return GeocorePlaceQuery()
        }
    }
    
    public class func all() -> Promise<[GeocorePlace]> {
        return GeocorePlaceQuery().all()
    }
    
    public func events() -> Promise<[GeocoreEvent]> {
        return query().events()
    }
    
    public func tag(tagIdsOrNames: [String]) -> Self {
        if self.operation == nil {
            self.operation = GeocorePlaceOperation()
        }
        self.operation?.tag(tagIdsOrNames)
        return self
    }
    
    public func save() -> Promise<GeocorePlace> {
        if let operation = self.operation {
            return operation.save(self, forService: "/places")
        } else {
            return GeocoreObjectOperation().save(self, forService: "/places")
        }
    }
    
    public func delete() -> Promise<GeocorePlace> {
        return GeocoreObjectOperation().delete(self, forService: "/places")
    }
    
}

public class GeocorePlaceEvent: GeocoreRelationship {
    
    public var place: GeocorePlace?
    public var event: GeocoreEvent?
    
    public required init(_ json: JSON) {
        super.init(json)
        if let pk = json["pk"].dictionary {
            if let placeDict = pk["place"] {
                self.place = GeocorePlace(placeDict)
            }
            if let eventDict = pk["event"] {
                self.event = GeocoreEvent(eventDict)
            }
        }
    }
    
}
