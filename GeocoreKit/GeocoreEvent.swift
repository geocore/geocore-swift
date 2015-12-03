//
//  GeocoreEvent.swift
//  Asutomo
//
//  Created by Purbo Mohamad on 11/30/15.
//  Copyright © 2015 MapMotion. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

public enum GeocoreUserEventRelationshipType: Int {
    case Organizer = 0
    case Performer = 1
    case Participant = 2
    case Attendant = 3
    case Custom01 = 4
    case Custom02 = 5
    case Custom03 = 6
    case Custom04 = 7
    case Custom05 = 8
    case Custom06 = 9
    case Custom07 = 10
    case Custom08 = 11
    case Custom09 = 12
    case Custom10 = 13
    case Unknown = 9223372036854775807
}

public class GeocoreEventQuery: GeocoreObjectQuery {
    
    public func get() -> Promise<GeocoreEvent> {
        return self.get("/events")
    }
    
    public func all() -> Promise<[GeocoreEvent]> {
        return self.all("/events")
    }
    
    public func places() -> Promise<[GeocorePlace]> {
        if let path = buildPath("/events", withSubPath: "/places") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
    public func placeRelationships() -> Promise<[GeocorePlaceEvent]> {
        if let path = buildPath("/events", withSubPath: "/places/relationships") {
            return Geocore.sharedInstance.promisedGET(path)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
}

public class GeocoreEvent: GeocoreTaggable {
    
    private(set) public var timeStart: NSDate?
    private(set) public var timeEnd: NSDate?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.timeStart = NSDate.fromGeocoreFormattedString(json["timeStart"].string)
        self.timeEnd = NSDate.fromGeocoreFormattedString(json["timeEnd"].string)
        super.init(json)
    }
    
    public override func toDictionary() -> [String: AnyObject] {
        var dict = super.toDictionary()
        if let timeStart = self.timeStart { dict["timeStart"] = timeStart.geocoreFormattedString() }
        if let timeEnd = self.timeEnd { dict["timeEnd"] = timeEnd.geocoreFormattedString() }
        return dict
    }
    
    public override func query() -> GeocoreEventQuery {
        if let id = self.id {
            return GeocoreEventQuery().withId(id)
        } else {
            return GeocoreEventQuery()
        }
    }
    
    public class func all() -> Promise<[GeocoreEvent]> {
        return GeocoreEventQuery().all()
    }
    
    public func places() -> Promise<[GeocorePlace]> {
        return query().places()
    }
    
}
