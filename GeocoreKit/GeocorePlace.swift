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

public class GeocorePlacesSmallestBound: GeocoreInitializableFromJSON {
    
    private(set) public var minLatitude: Double?
    private(set) public var minLongitude: Double?
    private(set) public var maxLatitude: Double?
    private(set) public var maxLongitude: Double?
    
    public required init(_ json: JSON) {
        self.minLatitude = json["min_lat"].double
        self.minLongitude = json["min_lon"].double
        self.maxLatitude = json["max_lat"].double
        self.maxLongitude = json["max_lon"].double
    }
    
    public func center() -> (Double, Double)? {
        if let maxlat = self.maxLatitude, minlat = self.minLatitude, maxlon = self.maxLongitude, minlon = self.minLongitude {
            return ((maxlat + minlat)/2, (maxlon + minlon)/2)
        } else {
            return nil
        }
    }
    
    public func span() -> (Double, Double)? {
        if let maxlat = self.maxLatitude, minlat = self.minLatitude, maxlon = self.maxLongitude, minlon = self.minLongitude {
            return (abs(maxlat - minlat), abs(maxlon - minlon))
        } else {
            return nil
        }
    }

}

public class GeocorePlaceOperation: GeocoreTaggableOperation {
    
}

public class GeocorePlaceQuery: GeocoreTaggableQuery {
    
    private(set) public var centerLatitude: Double?
    private(set) public var centerLongitude: Double?
    private(set) public var radius: Double?
    
    private(set) public var minimumLatitude: Double?
    private(set) public var minimumLongitude: Double?
    private(set) public var maximumLatitude: Double?
    private(set) public var maximumLongitude: Double?
    
    private(set) public var checkinable: Bool?
    private(set) public var validItems: Bool?
    private var eventDetails = false
    
    public func withCenter(latitude latitude: Double, longitude: Double) -> Self {
        self.centerLatitude = latitude
        self.centerLongitude = longitude
        return self
    }
    
    public func withRadius(radius: Double) -> Self {
        self.radius = radius
        return self
    }
    
    public func withRectangle(minimumLatitude minimumLatitude: Double, minimumLongitude: Double, maximumLatitude: Double, maximumLongitude: Double) -> Self {
        self.minimumLatitude = minimumLatitude
        self.minimumLongitude = minimumLongitude
        self.maximumLatitude = maximumLatitude
        self.maximumLongitude = maximumLongitude
        return self
    }
    
    public func onlyCheckinable() -> Self {
        self.checkinable = true
        return self
    }
    
    public func onlyValidItems() -> Self {
        self.validItems = true
        return self
    }
    
    public func withEventDetails() -> Self {
        self.eventDetails = true
        return self
    }
    
    public func get() -> Promise<GeocorePlace> {
        return self.get("/places")
    }
    
    public func all() -> Promise<[GeocorePlace]> {
        return self.all("/places")
    }
    
    public override func buildQueryParameters() -> [String: AnyObject] {
        var dict = super.buildQueryParameters()
        if eventDetails { dict["event_detail"] = "true" }
        if let checkinable = self.checkinable { if checkinable { dict["checkinable"] = "true" } }
        return dict
    }
    
    public func nearest() -> Promise<[GeocorePlace]> {
        if let centerLatitude = self.centerLatitude, centerLongitude = self.centerLongitude {
            var dict = buildQueryParameters()
            dict["lat"] = centerLatitude
            dict["lon"] = centerLongitude
            return Geocore.sharedInstance.promisedGET("/places/search/nearest", parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting center lat-lon")) }
        }
    }
    
    public func smallestBounds() -> Promise<GeocorePlacesSmallestBound> {
        if let centerLatitude = self.centerLatitude, centerLongitude = self.centerLongitude {
            var dict = buildQueryParameters()
            dict["lat"] = centerLatitude
            dict["lon"] = centerLongitude
            return Geocore.sharedInstance.promisedGET("/places/search/smallestbounds", parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting center lat-lon")) }
        }
    }
    
    private func circleQuery(withPath: String) -> Promise<[GeocorePlace]> {
        if let centerLatitude = self.centerLatitude, centerLongitude = self.centerLongitude, radius = self.radius {
            var dict = buildQueryParameters()
            dict["lat"] = centerLatitude
            dict["lon"] = centerLongitude
            dict["radius"] = radius
            return Geocore.sharedInstance.promisedGET(withPath, parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting center lat-lon, radius")) }
        }
    }
    
    public func withinCircle() -> Promise<[GeocorePlace]> {
        return self.circleQuery("/places/search/within/circle")
    }
    
    public func intersectsCircle() -> Promise<[GeocorePlace]> {
        return self.circleQuery("/places/search/intersects/circle")
    }
    
    private func rectangleQuery(withPath: String) -> Promise<[GeocorePlace]> {
        if let minlat = self.minimumLatitude, maxlat = self.maximumLatitude, minlon = self.self.minimumLongitude, maxlon = self.maximumLongitude  {
            var dict = buildQueryParameters()
            dict["min_lat"] = minlat
            dict["max_lat"] = maxlat
            dict["min_lon"] = minlon
            dict["max_lon"] = maxlon
            return Geocore.sharedInstance.promisedGET(withPath, parameters: dict)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting min/max lat-lon")) }
        }
    }
    
    public func withinRectangle() -> Promise<[GeocorePlace]> {
        return self.rectangleQuery("/places/search/within/rect")
    }
    
    public func intersectsRectangle() -> Promise<[GeocorePlace]> {
        return self.rectangleQuery("/places/search/intersects/rect")
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
    
    public func items() -> Promise<[GeocoreItem]> {
        if let path = buildPath("/places", withSubPath: "/items") {
            var dict = buildQueryParameters()
            if let validItems = self.validItems { if validItems { dict["valid_only"] = "true" } }
            return Geocore.sharedInstance.promisedGET(path, parameters: dict)
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
    
    public var prefetchedEvents: [GeocoreEvent]?
    
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
        if let eventsJSON = json["events"].array {
            self.prefetchedEvents = eventsJSON.map({ GeocoreEvent($0) })
        }
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
        if let prefetchedEvents = self.prefetchedEvents {
            return Promise { fulfill, reject in fulfill(prefetchedEvents) }
        } else {
            return query()
                .events()
                .then { events -> [GeocoreEvent] in
                    self.prefetchedEvents = events
                    return events
                }
        }
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
        return self.checkin(latitude: latitude, longitude: longitude, unrestricted: false)
    }
    
    public func checkin(latitude latitude: Double, longitude: Double, unrestricted: Bool) -> Promise<GeocorePlaceCheckin> {
        let checkin = GeocorePlaceCheckin()
        checkin.userId = Geocore.sharedInstance.userId
        checkin.placeId = self.id
        checkin.latitude = latitude
        checkin.longitude = longitude
        checkin.accuracy = 0
        if let placeId = self.id {
            var params: [String: AnyObject]?
            if unrestricted {
                params = ["unrestricted": "true"]
            }
            return Geocore.sharedInstance.promisedPOST("/places/\(placeId)/checkins", parameters: params, body: checkin.toDictionary())
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
