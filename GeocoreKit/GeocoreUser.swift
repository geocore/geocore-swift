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
        let params = buildQueryParameters()
        if params.count > 0 {
            Geocore.sharedInstance.POST("/register", parameters: params, body: user.toDictionary(), callback: callback)
        } else {
            Geocore.sharedInstance.POST("/register", parameters: nil, body: user.toDictionary(), callback: callback)
        }
        
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
    
}
