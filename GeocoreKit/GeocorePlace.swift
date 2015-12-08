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
    
    public func checkin(latitude latitude: Double, longitude: Double) -> Promise<GeocorePlaceCheckin> {
        let checkin = GeocorePlaceCheckin()
        checkin.userId = Geocore.sharedInstance.userId
        checkin.placeId = self.id
        checkin.latitude = latitude
        checkin.longitude = longitude
        checkin.accuracy = 0
        if let placeId = self.id {
            return Geocore.sharedInstance.promisedPOST("/places/\(placeId)/checkins", parameters: nil, body: checkin.toDictionary())
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
}

public class GeocorePlaceCheckin: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    
    public var userId: String?
    public var placeId: String?
    public var timestamp: UInt64?
    public var latitude: Double?
    public var longitude: Double?
    public var accuracy: Double?
    public var date: NSDate?
    
    public init() {
    }

    public required init(_ json: JSON) {
        self.userId = json["userId"].string
        self.placeId = json["placeId"].string
        self.timestamp = json["timestamp"].uInt64
        if let timestamp = self.timestamp {
            self.date = NSDate(timeIntervalSince1970: Double(timestamp)/1000.0)
        }
        self.latitude = json["latitude"].double
        self.longitude = json["longitude"].double
        self.accuracy = json["accuracy"].double
    }
    
    public func toDictionary() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        if let userId = self.userId { dict["userId"] = userId }
        if let placeId = self.placeId { dict["placeId"] = placeId }
        if let timestamp = self.timestamp { dict["timestamp"] = String(timestamp) }
        if let date = self.date {
            dict["timestamp"] = String(UInt64(date.timeIntervalSince1970 * 1000))
        }
        if let latitude = self.latitude, longitude = self.longitude {
            dict["latitude"] = String(latitude)
            dict["longitude"] = String(longitude)
        }
        if let accuracy = self.accuracy {
            dict["accuracy"] = String(accuracy)
        }
        return dict
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
