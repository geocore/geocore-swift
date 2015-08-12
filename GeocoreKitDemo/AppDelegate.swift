//
//  AppDelegate.swift
//  GeocoreKitDemo
//
//  Created by Purbo Mohamad on 4/14/15.
//  Copyright (c) 2015 Geocore. All rights reserved.
//

import UIKit
import PromiseKit
import GeocoreKit
import SwiftyJSON

/*
private let GEOCORE_BASEURL = "http://put.geocore.api.server.url.here"
private let GEOCORE_PROJECTID = "#PUT_PROJECT_ID_HERE#"
private let GEOCORE_USERID = "#PUT_USER_ID_HERE#"
private let GEOCORE_USERPASSWORD = "#PUT_USER_PASSWORD_HERE#"
*/

class Madu {
    var kadaluarsa: Bool?
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        /*
        Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD) { (result: GeocoreResult<String>) -> Void in
                if let token = result.value {
                    println("Access Token = \(token)")
                    GeocoreObject.get(GEOCORE_USERID, callback: { (result: GeocoreResult<GeocoreObject>) -> Void in
                        if let obj = result.value {
                            println("Id = \(obj.id!), Name = \(obj.name!), Description = \(obj.desc!)")
                            GeocorePlace.get() { (result: GeocoreResult<[GeocorePlace]>) -> Void in
                                if let places = result.value {
                                    for place in places {
                                        println("Id = \(place.id!), Name = \(place.name!), Point = (\(place.point!.latitude!), \(place.point!.longitude!))")
                                    }
                                } else {
                                    println(result.error)
                                }
                            }
                        } else {
                            println(result.error)
                        }
                    })
                } else {
                    println(result.error)
                }
            }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocoreObject> in
                println("Access Token = \(accessToken)")
                return GeocoreObject.get(GEOCORE_USERID)
            }
            .then { (obj: GeocoreObject) -> Promise<[GeocorePlace]> in
                println("--- The object as promised:")
                println("Id = \(obj.id!), Name = \(obj.name!), Description = \(obj.desc!)")
                return GeocorePlace.get()
            }
            .then { (places: [GeocorePlace]) -> Void in
                println("--- Some places as promised:")
                for place in places {
                    println("Id = \(place.id!), Name = \(place.name!), Point = (\(place.point!.latitude!), \(place.point!.longitude!))")
                }
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocoreObject> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocoreObject.get(GEOCORE_USERID)
            }
            .then { (obj: GeocoreObject) -> Void in
                println("--- The object as promised:")
                println("    sid = \(obj.sid)")
                println("    id = \(obj.id)")
                println("    name = \(obj.name)")
                println("    desc = \(obj.desc)")
                println("    createTime = \(obj.createTime)")
                println("    updateTime = \(obj.updateTime)")
                println("    upvotes = \(obj.upvotes)")
                println("    downvotes = \(obj.downvotes)")
                println("    customData = \(obj.customData)")
                println("    jsonData = \(obj.jsonData)")
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocorePlace> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocorePlace.get("PLA-EKIDATA-1110101")
            }
            .then { (place: GeocorePlace) -> Void in
                println("--- The place as promised:")
                println("    sid = \(place.sid)")
                println("    id = \(place.id)")
                println("    name = \(place.name)")
                println("    desc = \(place.desc)")
                println("    createTime = \(place.createTime)")
                println("    updateTime = \(place.updateTime)")
                println("    upvotes = \(place.upvotes)")
                println("    downvotes = \(place.downvotes)")
                println("    customData = \(place.customData)")
                println("    jsonData = \(place.jsonData)")
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocorePlace> in
                return GeocorePlace.get("PLA-EKIDATA-1110102")
            }
            .then { (place: GeocorePlace) -> Promise<GeocorePlace> in
                println("--- The place as promised:")
                println("    sid = \(place.sid)")
                println("    id = \(place.id)")
                println("    name = \(place.name)")
                
                // test update custom data & JSON
                place.customData = ["key1": "ばば", "key2": "ぶぶ"]
                place.jsonData = JSON(["key1": "ばば", "key2": "ぶぶ"])
                
                return place.save()
            }
            .then { (place: GeocorePlace) -> Void in
                println("--- The updated place as promised:")
                println("    customData = \(place.customData)")
                println("    jsonData = \(place.jsonData)")
                
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        /*
        if let image = UIImage(named:"logo-mm") {
            let data = UIImagePNGRepresentation(image)
            
            let _:() = Geocore.sharedInstance
                .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
                .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
                .then { (accessToken: String) -> Promise<GeocorePlace> in
                    return GeocorePlace.get("PLA-EKIDATA-1110102")
                }
                .then { (place: GeocorePlace) -> Promise<(GeocoreBinaryDataInfo, GeocorePlace)> in
                    println("--- The place as promised:")
                    println("    sid = \(place.sid)")
                    println("    id = \(place.id)")
                    println("    name = \(place.name)")
                    
                    // test upload an image
                    return when(place.upload("test", data: data, mimeType: "image/png"), Promise { (fulfiller, rejecter) in fulfiller(place) })
                }
                .then { (binaryDataInfo: GeocoreBinaryDataInfo, place: GeocorePlace) -> Promise<[GeocoreBinaryDataInfo]> in
                    println("--- The uploaded binary data as promised:")
                    println("    sid = \(place.sid)")
                    println("    key = \(binaryDataInfo.key)")
                    
                    return place.binaries()
                }
                .then { (binaryDataInfos: [GeocoreBinaryDataInfo]) -> Void in
                    println("--- Lists of uploaded binary data:")
                    for binaryDataInfo in binaryDataInfos {
                        println("    key = \(binaryDataInfo.key)")
                        println("    url = \(binaryDataInfo.url)")
                    }
                }
                .catch { error -> Void in
                    println(error)
                }
        }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocorePlace> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocorePlace.get("PLA-EKIDATA-1110102")
            }
            .then { (place: GeocorePlace) -> Promise<[GeocoreBinaryDataInfo]> in
                println("--- The place as promised:")
                println("    sid = \(place.sid)")
                println("    id = \(place.id)")
                println("    name = \(place.name)")
                return place.binaries()
            }
            .then { (binaryDataInfos: [GeocoreBinaryDataInfo]) -> Void in
                println("--- Lists of uploaded binary data:")
                var test: String
                for binaryDataInfo in binaryDataInfos {
                    println("    key = \(binaryDataInfo.key)")
                    test = binaryDataInfo.key!
                }
            }
            .catch { error -> Void in
                println(error)
        }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocorePlace> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocorePlace.get("PLA-EKIDATA-1110102")
            }
            .then { (place: GeocorePlace) -> Promise<GeocoreBinaryDataInfo> in
                println("--- The place as promised:")
                println("    sid = \(place.sid)")
                println("    id = \(place.id)")
                println("    name = \(place.name)")
                return place.binary("test")
            }
            .then { (binaryDataInfo: GeocoreBinaryDataInfo) -> Void in
                println("--- The binary data as promised:")
                println("    key = \(binaryDataInfo.key)")
                println("    url = \(binaryDataInfo.url)")
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .loginWithDefaultUser()
            .then { (accessToken: String) -> Void in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .loginWithDefaultUser()
            .then { (accessToken: String) -> Promise<GeocorePlace> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocorePlace.get("PLA-EKIDATA-1110102")
            }
            .then { (place: GeocorePlace) -> Promise<GeocoreBinaryDataInfo> in
                println("--- The place as promised:")
                println("    sid = \(place.sid)")
                println("    id = \(place.id)")
                println("    name = \(place.name)")
                return place.binary("test")
            }
            .then { (binaryDataInfo: GeocoreBinaryDataInfo) -> Void in
                println("--- The binary data as promised:")
                println("    key = \(binaryDataInfo.key)")
                println("    url = \(binaryDataInfo.url)")
            }
            .catch { error -> Void in
                println(error)
        }
        */
        
        /*
        let _:() = Geocore.sharedInstance
            .loginWithDefaultUser()
            .then { (accessToken: String) -> Promise<[GeocorePlace]> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocorePlace.get(minLat: 35.66617440081799, minLon: 139.7126117348629, maxLat: 35.67753978462231, maxLon: 139.72917705773887)
            }
            .then { (places: [GeocorePlace]) -> Void in
                println("--- Some places as promised:")
                for place in places {
                    println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
                }
            }
            .catch { error -> Void in
                println(error)
            }
        */
        
        Geocore.sharedInstance
            .loginWithDefaultUser()
            .then { (accessToken: String) -> Promise<[GeocorePlace]> in
                println("Access Token = \(accessToken), thread = \(NSThread.currentThread())")
                return GeocorePlace.get(centerLat: 35.66617440081799, centerLon: 139.7126117348629)
            }
            .then { (places: [GeocorePlace]) -> Void in
                println("--- Some places as promised:")
                for place in places {
                    println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
                }
            }
            .catch { error -> Void in
                println(error)
        }
        
        /*
        Geocore.sharedInstance.loginWithDefaultUser().then { accessToken -> Void in
            println("Logged in to Geocore successfully, with access token = \(accessToken)")
        }
        */
        
        /*
        GeocorePlace
            .get(minLat: 35.66617440081799, minLon: 139.7126117348629, maxLat: 35.67753978462231, maxLon: 139.72917705773887)
            .then { (places: [GeocorePlace]) -> Void in
                println("--- Some places as promised:")
                for place in places {
                    println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
                }
            }
        */
        
        /*
        GeocorePlace
            .get(centerLat: 35.66617440081799, centerLon: 139.7126117348629)
            .then { (places: [GeocorePlace]) -> Void in
                println("--- Some places as promised:")
                for place in places {
                    println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
                }
        }
        */
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

