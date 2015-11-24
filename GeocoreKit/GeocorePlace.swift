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
    
    public override class func query() -> GeocorePlaceQuery {
        return GeocorePlaceQuery()
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
