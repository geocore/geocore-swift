//
//  GeocoreItem.swift
//  Asutomo
//
//  Created by Purbo Mohamad on 1/25/16.
//  Copyright © 2016 MapMotion. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

public enum GeocoreItemType: String {
    case NonConsumable = "NON_CONSUMABLE"
    case Consumable = "CONSUMABLE"
    case Unknown = ""
}

public class GeocoreItemQuery: GeocoreObjectQuery {
    
    public func get() -> Promise<GeocoreItem> {
        return self.get("/items")
    }
    
    public func all() -> Promise<[GeocoreItem]> {
        return self.all("/items")
    }
    
}

public class GeocoreItem: GeocoreTaggable {
    
    public var shortName: String?
    public var shortDescription: String?
    public var type: GeocoreItemType?
    public var validTimeStart: NSDate?
    public var validTimeEnd: NSDate?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.shortName = json["shortName"].string
        self.shortDescription = json["shortDescription"].string
        if let type = json["type"].string { self.type = GeocoreItemType(rawValue: type) }
        self.validTimeStart = NSDate.fromGeocoreFormattedString(json["validTimeStart"].string)
        self.validTimeEnd = NSDate.fromGeocoreFormattedString(json["validTimeEnd"].string)
        super.init(json)
    }
    
    public override func toDictionary() -> [String: AnyObject] {
        var dict = super.toDictionary()
        if let shortName = self.shortName { dict["shortName"] = shortName }
        if let shortDescription = self.shortDescription { dict["shortDescription"] = shortDescription }
        if let type = self.type { dict["type"] = type.rawValue }
        if let validTimeStart = self.validTimeStart { dict["validTimeStart"] = validTimeStart.geocoreFormattedString() }
        if let validTimeEnd = self.validTimeEnd { dict["validTimeEnd"] = validTimeEnd.geocoreFormattedString() }
        return dict
    }
    
    public override func query() -> GeocoreItemQuery {
        if let id = self.id {
            return GeocoreItemQuery().withId(id)
        } else {
            return GeocoreItemQuery()
        }
    }
    
    public class func all() -> Promise<[GeocoreItem]> {
        return GeocoreItemQuery().all()
    }
    
}


