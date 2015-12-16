//
//  GeocoreUser.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/21/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit
#if os(iOS)
    import UIKit
#endif

public enum GeocoreUserEventRelationshipType: String {
    case Organizer = "ORGANIZER"
    case Performer = "PERFORMER"
    case Participant = "PARTICIPANT"
    case Attendant = "ATTENDANT"
    case Custom01 = "CUSTOM01"
    case Custom02 = "CUSTOM02"
    case Custom03 = "CUSTOM03"
    case Custom04 = "CUSTOM04"
    case Custom05 = "CUSTOM05"
    case Custom06 = "CUSTOM06"
    case Custom07 = "CUSTOM07"
    case Custom08 = "CUSTOM08"
    case Custom09 = "CUSTOM09"
    case Custom10 = "CUSTOM10"
}

public class GeocoreUserOperation: GeocoreTaggableOperation {
    
    private var groupIds: [String]?
    
    public func addToGroups(groupIds: [String]) {
        self.groupIds = groupIds
    }
    
    public override func buildQueryParameters() -> [String : AnyObject] {
        var dict = super.buildQueryParameters()
        if let groupIds = self.groupIds {
            dict["group_ids"] = groupIds.joinWithSeparator(",")
        }
        return dict
    }
    
    public func register(user: GeocoreUser, callback: (GeocoreResult<GeocoreUser>) -> Void) {
        // TODO: a bit clumsy, but will do for now
        var params = buildQueryParameters()
        params["project_id"] = Geocore.sharedInstance.projectId
        Geocore.sharedInstance.POST("/register", parameters: params, body: user.toDictionary(), callback: callback)
    }
    
    public func register(user: GeocoreUser) -> Promise<GeocoreUser> {
        // TODO: a bit clumsy, but will do for now
        let params = buildQueryParameters()
        if params.count > 0 {
            return Geocore.sharedInstance.promisedPOST(buildPath("/register"), parameters: params, body: user.toDictionary())
        } else {
            return Geocore.sharedInstance.promisedPOST(buildPath("/register"), parameters: user.toDictionary())
        }
    }
    
}

public class GeocoreUserTagOperation: GeocoreTaggableOperation {
    
    public func update() -> Promise<[GeocoreTag]> {
        let params = buildQueryParameters()
        if params.count > 0 {
            if let path = buildPath("/users", withSubPath: "/tags") {
                // body cannot be nil, otherwise params will go to body
                return Geocore.sharedInstance.promisedPOST(path, parameters: params, body: [String: AnyObject]())
            } else {
                return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting tag parameters")) }
        }
    }
    
}

public class GeocoreUserQuery: GeocoreTaggableQuery {
    
    public func get() -> Promise<GeocoreUser> {
        
        return self.get("/users")
    }
    
    public func eventRelationships() -> Promise<[GeocoreUserEvent]> {
        if let userId = self.id {
            return GeocoreUserEventQuery().withObject1Id(userId).all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
    public func eventRelationships(event: GeocoreEvent) -> Promise<[GeocoreUserEvent]> {
        if let userId = self.id {
            return GeocoreUserEventQuery()
                .withObject1Id(userId)
                .withObject2Id(event.id!)
                .all()
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
}

public class GeocoreUser: GeocoreTaggable {
    
    public var password: String?
    public var email: String?
    private(set) public var lastLocationTime: NSDate?
    private(set) public var lastLocation: GeocorePoint?
    //var groupIds: [String]?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        self.email = json["email"].string
        self.lastLocationTime = NSDate.fromGeocoreFormattedString(json["lastLocationTime"].string)
        self.lastLocation = GeocorePoint(json["lastLocation"])
        super.init(json)
    }
    
    public override func toDictionary() -> [String: AnyObject] {
        var dict = super.toDictionary()
        if let password = self.password { dict["password"] = password }
        if let email = self.email { dict["email"] = email }
        return dict
    }
    
    private class func userIdWithSuffix(suffix: String) -> String {
        if let projectId = Geocore.sharedInstance.projectId {
            if projectId.hasPrefix("PRO") {
                // user ID pattern: USE-[project_suffix]-[user_id_suffix]
                return "USE\(projectId.substringFromIndex(projectId.startIndex.advancedBy(3)))-\(suffix)"
            } else {
                return suffix
            }
        } else {
            return suffix
        }
    }
    
    public class func defaultName() -> String {
        #if os(iOS)
            #if (arch(i386) || arch(x86_64))
                // iOS simulator
                return "IOS_SIMULATOR"
            #else
                // iOS device
                return UIDevice.currentDevice().identifierForVendor!.UUIDString
            #endif
        #else
            // TODO: generate ID on OSX based on user's device ID
            return "DEFAULT"
        #endif
    }
    
    public class func defaultId() -> String {
        return userIdWithSuffix(defaultName())
    }
    
    public class func defaultEmail() -> String {
        return "\(defaultName())@geocore.jp"
    }
    
    public class func defaultPassword() -> String {
        return String(defaultId().characters.reverse())
    }
    
    public class func defaultUser() -> GeocoreUser {
        let user = GeocoreUser()
        user.id = GeocoreUser.defaultId()
        user.name = GeocoreUser.defaultName()
        user.email = GeocoreUser.defaultEmail()
        user.password = GeocoreUser.defaultPassword()
        return user
    }
    
    public func register() -> Promise<GeocoreUser> {
        return GeocoreUserOperation().register(self)
    }
    
    public func save() -> Promise<GeocoreUser> {
        return GeocoreObjectOperation().save(self, forService: "/users")
    }
    
    public func eventRelationships() -> Promise<[GeocoreUserEvent]> {
        return GeocoreUserQuery().withId(self.id!).eventRelationships()
    }
    
    public func eventRelationships(event: GeocoreEvent) -> Promise<[GeocoreUserEvent]> {
        return GeocoreUserQuery().withId(self.id!).eventRelationships(event)
    }
    
    public func tagOperation() -> GeocoreUserTagOperation {
        return GeocoreUserTagOperation().withId(self.id!)
    }
    
}

public class GeocoreUserEventOperation: GeocoreRelationshipOperation {
    
    private(set) public var relationshipType: GeocoreUserEventRelationshipType?
    
    public func withUser(user: GeocoreUser) -> Self {
        super.withObject1Id(user.id!)
        return self
    }
    
    public func withEvent(event: GeocoreEvent) -> Self {
        super.withObject2Id(event.id!)
        return self
    }
    
    public func withRelationshipType(relationshipType: GeocoreUserEventRelationshipType) -> Self {
        self.relationshipType = relationshipType
        return self
    }
    
    public override func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1, id2 = self.id2, relationshipType = self.relationshipType {
            return "\(forService)/\(id1)\(withSubPath)/\(id2)/\(relationshipType.rawValue)"
        } else {
            return super.buildPath(forService, withSubPath: withSubPath)
        }
    }
    
    public func save() -> Promise<GeocoreUserEvent> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            if let customData = self.customData {
                return Geocore.sharedInstance.promisedPOST(buildPath("/users", withSubPath: "/events"),
                    parameters: nil, body: customData.filter{ $1 != nil }.map{ ($0, $1!) })
            } else {
                return Geocore.sharedInstance.promisedPOST(buildPath("/users", withSubPath: "/events"),
                    parameters: nil, body: [String: AnyObject]())
            }
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    public func organize() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Organizer).save()
    }
    
    public func perform() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Performer).save()
    }
    
    public func participate() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Participant).save()
    }
    
    public func attend() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Attendant).save()
    }
    
    public func leaveAs(relationshipType: GeocoreUserEventRelationshipType) -> Promise<GeocoreUserEvent> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            return Geocore.sharedInstance.promisedDELETE(buildPath("/users", withSubPath: "/events"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
}

public class GeocoreUserEventQuery: GeocoreRelationshipQuery {
    
    private(set) public var relationshipType: GeocoreUserEventRelationshipType?
    
    public func withUser(user: GeocoreUser) -> Self {
        super.withObject1Id(user.id!)
        return self
    }
    
    public func withEvent(event: GeocoreEvent) -> Self {
        super.withObject2Id(event.id!)
        return self
    }
    
    public func withRelationshipType(relationshipType: GeocoreUserEventRelationshipType) -> Self {
        self.relationshipType = relationshipType
        return self
    }
    
    public override func buildPath(forService: String, withSubPath: String) -> String {
        if let id1 = self.id1, id2 = self.id2, relationshipType = self.relationshipType {
            return "\(forService)/\(id1)\(withSubPath)/\(id2)/\(relationshipType.rawValue)"
        } else {
            return super.buildPath(forService, withSubPath: withSubPath)
        }
    }
    
    public func get() -> Promise<GeocoreUserEvent> {
        if self.id1 != nil && id2 != nil && self.relationshipType != nil {
            return Geocore.sharedInstance.promisedGET(self.buildPath("/users", withSubPath: "/events"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting ids & relationship type")) }
        }
    }
    
    public func all() -> Promise<[GeocoreUserEvent]> {
        if self.id1 != nil {
            return Geocore.sharedInstance.promisedGET(super.buildPath("/users", withSubPath: "/events"))
        } else {
            return Promise { fulfill, reject in reject(GeocoreError.InvalidParameter(message: "Expecting id")) }
        }
    }
    
    public func organization() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Organizer).get()
    }
    
    public func performance() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Performer).get()
    }
    
    public func participation() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Participant).get()
    }
    
    public func attendance() -> Promise<GeocoreUserEvent> {
        return withRelationshipType(.Attendant).get()
    }
    
}

public class GeocoreUserEvent: GeocoreRelationship {
    
    public var user: GeocoreUser?
    public var event: GeocoreEvent?
    public var relationshipType: GeocoreUserEventRelationshipType?
    
    public required init(_ json: JSON) {
        super.init(json)
        if let pk = json["pk"].dictionary {
            if let userDict = pk["user"] {
                self.user = GeocoreUser(userDict)
            }
            if let eventDict = pk["event"] {
                self.event = GeocoreEvent(eventDict)
            }
            if let relationshipType = pk["relationship"]?.string {
                self.relationshipType = GeocoreUserEventRelationshipType(rawValue: relationshipType)!
            }
        }
    }
    
    public override func toDictionary() -> [String: AnyObject] {
        var dict = super.toDictionary()
        var pk = [String: AnyObject]()
        pk["user"] = user?.toDictionary()
        pk["event"] = event?.toDictionary()
        if let relationshipType = self.relationshipType { pk["relationship"] = relationshipType.rawValue }
        dict["pk"] = pk
        return dict
    }
    
    
    
}


