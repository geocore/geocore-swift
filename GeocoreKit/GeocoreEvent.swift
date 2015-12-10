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

