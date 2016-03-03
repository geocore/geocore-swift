//
//  GeocoreFeed.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 3/2/16.
//  Copyright © 2016 MapMotion. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit
#if os(iOS)
    import UIKit
#endif

public class GeocoreFeedOperation: GeocoreObjectOperation {
    
    private(set) public var type: String?
    private(set) public var idSpecifier: String?
    private(set) public var content: [String: AnyObject]?
    
    public func withType(type: String) -> Self {
        self.type = type
        return self
    }
    
    public func withIdSpecifier(idSpecifier: String) -> Self {
        self.idSpecifier = idSpecifier
        return self
    }
    
    public func withContent(content: [String: AnyObject]) -> Self {
        self.content = content
        return self
    }
    
    public override func buildQueryParameters() -> [String: AnyObject] {
        var dict = super.buildQueryParameters()
        if let type = self.type { dict["type"] = type }
        if let idSpecifier = self.idSpecifier { dict["spec"] = idSpecifier }
        return dict
    }
    
    public func post() -> Promise<GeocoreFeed> {
        if let path = self.buildPath("/objs", withSubPath: "/feed"), content = self.content {
            return Geocore.sharedInstance.promisedPOST(path, parameters: self.buildQueryParameters(), body: content)
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id, content")) }
        }
    }
    
}

public class GeocoreFeedQuery: GeocoreFeedOperation {
    
    private(set) public var earliestTimestamp: Int64?
    private(set) public var latestTimestamp: Int64?
    private(set) public var startTimestamp: Int64?
    private(set) public var endTimestamp: Int64?
    private(set) public var page: Int?
    private(set) public var numberPerPage: Int?
    
    public func notEarlierThan(earliestDate: NSDate) -> Self {
        self.earliestTimestamp = Int64(earliestDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    public func earlierThan(latestDate: NSDate) -> Self {
        self.latestTimestamp = Int64(latestDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    public func startingAt(startDate: NSDate) -> Self {
        self.startTimestamp = Int64(startDate.timeIntervalSince1970 * 1000)
        return self
    }
    
    public func endingAt(endDate: NSDate) -> Self {
        self.endTimestamp = Int64(endDate.timeIntervalSince1970 * 1000)
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
    
    public override func buildQueryParameters() -> [String: AnyObject] {
        var dict = super.buildQueryParameters()
        if let startTimestamp = self.startTimestamp, endTimestamp = self.endTimestamp {
            dict["from_timestamp"] = String(startTimestamp)
            dict["to_timestamp"] = String(endTimestamp)
        } else if let earliestTimestamp = self.earliestTimestamp {
            dict["from_timestamp"] = String(earliestTimestamp)
        } else if let latestTimestamp = self.latestTimestamp {
            dict["to_timestamp"] = String(latestTimestamp)
        }
        if let page = self.page {
            dict["page"] = page
        }
        if let numberPerPage = self.numberPerPage {
            dict["num"] = numberPerPage
        }
        return dict
    }
    
    public func all() -> Promise<[GeocoreFeed]> {
        if let path = self.buildPath("/objs", withSubPath: "/feed") {
            return Geocore.sharedInstance.promisedGET(path, parameters: self.buildQueryParameters())
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
}

public class GeocoreFeed: GeocoreInitializableFromJSON, GeocoreSerializableToJSON {
    
    public var id: String?
    public var type: String?
    public var timestamp: Int64?
    public var date: NSDate? {
        get {
            if let timestamp = self.timestamp {
                return NSDate(timeIntervalSince1970: Double(timestamp)/1000.0)
            } else {
                return nil
            }
        }
        set (newDate) {
            if let someNewDate = newDate {
                self.timestamp = Int64(someNewDate.timeIntervalSince1970 * 1000)
            }
        }
    }
    public var content: [String: AnyObject]?
    
    public required init(_ json: JSON) {
        self.id = json["id"].string
        self.type = json["type"].string
        self.timestamp = json["timestamp"].int64
        self.content = json["objContent"].dictionary?.map { ($0, $1.string!) }
    }
    
    public func toDictionary() -> [String: AnyObject] {
        if let content = self.content {
            return content
        } else {
            return [String: AnyObject]()
        }
    }
    
    private func resolveType() -> String? {
        if let type = self.type {
            return type
        } else if let id = self.id {
            if id.hasPrefix("PRO") {
               return "jp.geocore.entity.Project"
            } else if id.hasPrefix("USE") {
               return "jp.geocore.entity.User"
            } else if id.hasPrefix("GRO") {
                return "jp.geocore.entity.Group"
            } else if id.hasPrefix("PLA") {
                return "jp.geocore.entity.Place"
            } else if id.hasPrefix("EVE") {
                return "jp.geocore.entity.Event"
            } else if id.hasPrefix("ITE") {
                return "jp.geocore.entity.Item"
            } else if id.hasPrefix("TAG") {
                return "jp.geocore.entity.Tag"
            }
        }
        return nil
    }
    
    public func post() -> Promise<GeocoreFeed> {
        if let id = self.id, content = self.content {
            let op = GeocoreFeedOperation().withId(id).withContent(content)
            if let type = self.resolveType() {
                op.withType(type)
            }
            return op.post()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id, content")) }
        }
    }
    
}


