//
//  GeocoreTag.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 11/22/15.
//
//

import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

public enum GeocoreTagType: String {
    case System = "SYSTEM_TAG"
    case User = "USER_TAG"
    case Unknown = ""
}

public class GeocoreTaggableOperation: GeocoreObjectOperation {
    
    private var tagIdsToAdd: [String]?
    private var tagIdsToDelete: [String]?
    private var tagNamesToAdd: [String]?
    private var tagNamesToDelete: [String]?
    
    public func tag(tagIdsOrNames: [String]) -> Self {
        for tagIdOrName in tagIdsOrNames {
            // for now, assume that if the tag starts with 'TAG-', it's a tag id, otherwise it's a name
            if tagIdOrName.hasPrefix("TAG-") {
                if self.tagIdsToAdd == nil {
                    self.tagIdsToAdd = [tagIdOrName]
                } else {
                    self.tagIdsToAdd?.append(tagIdOrName)
                }
            } else {
                if self.tagNamesToAdd == nil {
                    self.tagNamesToAdd = [tagIdOrName]
                } else {
                    self.tagNamesToAdd?.append(tagIdOrName)
                }
            }
        }
        return self
    }
    
    public func untag(tagIdsOrNames: [String]) -> Self {
        for tagIdOrName in tagIdsOrNames {
            // for now, assume that if the tag starts with 'TAG-', it's a tag id, otherwise it's a name
            if tagIdOrName.hasPrefix("TAG-") {
                if self.tagIdsToDelete == nil {
                    self.tagIdsToDelete = [tagIdOrName]
                } else {
                    self.tagIdsToDelete?.append(tagIdOrName)
                }
            } else {
                if self.tagNamesToDelete == nil {
                    self.tagNamesToDelete = [tagIdOrName]
                } else {
                    self.tagNamesToDelete?.append(tagIdOrName)
                }
            }
        }
        return self
    }
    
    public override func buildQueryParameters() -> [String : AnyObject] {
        var dict = super.buildQueryParameters()
        if let tagIdsToAdd = self.tagIdsToAdd {
            if tagIdsToAdd.count > 0 {
                dict["tag_ids"] = tagIdsToAdd.joinWithSeparator(",")
            }
        }
        if let tagNamesToAdd = self.tagNamesToAdd {
            if tagNamesToAdd.count > 0 {
                dict["tag_names"] = tagNamesToAdd.joinWithSeparator(",")
            }
        }
        if let tagIdsToDelete = self.tagIdsToDelete {
            if tagIdsToDelete.count > 0 {
                dict["del_tag_ids"] = tagIdsToDelete.joinWithSeparator(",")
            }
        }
        if let tagNamesToDelete = self.tagNamesToDelete {
            if tagNamesToDelete.count > 0 {
                dict["del_tag_names"] = tagNamesToDelete.joinWithSeparator(",")
            }
        }
        return dict;
    }
    
}

public class GeocoreTaggableQuery: GeocoreObjectOperation {
    
    private var tagIds: [String]?
    private var tagNames: [String]?
    private var tagDetails = false
    
    /**
     Set tag IDs to be submitted as request parameter.
     
     - parameter tagIds: Tag IDs to be submitted
     
     - returns: The updated query object to be chain-called.
     */
    public func withTagIds(tagIds: [String]) -> GeocoreTaggableQuery {
        self.tagIds = tagIds
        return self
    }
    
    /**
     Set tag names to be submitted as request parameter.
     
     - parameter tagNames: Tag names to be submitted
     
     - returns: The updated query object to be chain-called.
     */
    public func tagNames(tagNames: [String]) -> GeocoreTaggableQuery {
        self.tagNames = tagNames
        return self
    }
    
    public func withTagDetails() -> GeocoreTaggableQuery {
        self.tagDetails = true
        return self
    }
    
    public override func buildQueryParameters() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        if let tagIds = self.tagIds { dict["tag_ids"] = tagIds.joinWithSeparator(",") }
        if let tagNames = self.tagNames { dict["tag_names"] = tagNames.joinWithSeparator(",") }
        if tagDetails { dict["tag_detail"] = "true" }
        return dict
    }

}

public class GeocoreTaggable: GeocoreObject {
    
    public var tags: [GeocoreTag]?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        if let tagsJSON = json["tags"].array {
            self.tags = tagsJSON.map({ GeocoreTag($0) })
        }
        super.init(json)
    }
    
}

public class GeocoreTag: GeocoreObject {
    
    public var type: GeocoreTagType?
    
    public override init() {
        super.init()
    }
    
    public required init(_ json: JSON) {
        if let type = json["type"].string { self.type = GeocoreTagType(rawValue: type) }
        super.init(json)
    }
    
    public override func toDictionary() -> [String : AnyObject] {
        var dict = super.toDictionary()
        if let type = self.type { dict["type"] = type.rawValue }
        return dict
    }
}
