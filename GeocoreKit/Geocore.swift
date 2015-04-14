//
//  Geocore.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 4/14/15.
//
//

import Foundation

public class Geocore: NSObject {
    
    public static let sharedInstance = Geocore()
    
    public private(set) var baseURL: String?
    public private(set) var projectId: String?
    
    private override init() {
    }
    
    private func path(servicePath: String!) -> String? {
        if let baseURL = self.baseURL {
            return baseURL + "/" + servicePath
        } else {
            return nil
        }
    }
    
    public func hello() -> String! {
        return "Hello, Geocore!"
    }
   
}
