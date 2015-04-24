//
//  GeocoreUtil.swift
//  GeocoreKit
//
//  Created by Purbo Mohamad on 4/23/15.
//
//

import Foundation

extension NSDateFormatter {
    
    class func dateFormatterWithEnUsPosixLocaleGMT() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        return dateFormatter
    }
    
    class func dateFormatterForGeocore() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter.dateFormatterWithEnUsPosixLocaleGMT()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateFormatter
    }
}

extension NSDate {
    
    public func geocoreFormattedString() -> String {
        return Geocore.geocoreDateFormatter.stringFromDate(self)
    }
    
    public class func fromGeocoreFormattedString(string: String?) -> NSDate? {
        if let unwrappedString = string {
            return Geocore.geocoreDateFormatter.dateFromString(unwrappedString)
        } else {
            return nil
        }
    }
    
}

// adapted from:
// https://gist.github.com/yuchi/b6d751272cf4cb2b841f
extension Dictionary {
    
    func map<K: Hashable, V>(transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
        var results: Dictionary<K, V> = [:]
        for key in self.keys {
            if let value = self[key] {
                let (u, w) = transform(key, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
    
    func filter(includeElement: (Key, Value) -> Bool) -> Dictionary<Key, Value> {
        var results: Dictionary<Key, Value> = [:]
        for key in self.keys {
            if let value = self[key] {
                if includeElement(key, value) {
                    results.updateValue(value, forKey: key)
                }
            }
        }
        return results
    }
}
