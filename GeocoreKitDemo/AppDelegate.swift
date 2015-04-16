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

private let GEOCORE_BASEURL = "http://put.geocore.api.server.url.here"
private let GEOCORE_PROJECTID = "#PUT_PROJECT_ID_HERE#"
private let GEOCORE_USERID = "#PUT_USER_ID_HERE#"
private let GEOCORE_USERPASSWORD = "#PUT_USER_PASSWORD_HERE#"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        /*
        Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD) { (optToken, optError) -> Void in
                if let token = optToken {
                    println("Access Token = \(token)")
                    GeocoreObject.get(GEOCORE_USERID, callback: { (optObj, optError) -> Void in
                        if let obj = optObj {
                            println("Id = \(obj.id!), Name = \(obj.name!), Description = \(obj.description!)")
                            GeocorePlace.get() { (optPlaces, optError) -> Void in
                                if let places = optPlaces {
                                    for place in places {
                                        println("Id = \(place.id!), Name = \(place.name!), Point = (\(place.point!.latitude!), \(place.point!.longitude!))")
                                    }
                                } else {
                                    println(optError)
                                }
                            }
                        } else {
                            println(optError)
                        }
                    })
                } else {
                    println(optError)
                }
            }
        */
    
        Geocore.sharedInstance
            .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Promise<GeocoreObject> in
                println("Access Token = \(accessToken)")
                return GeocoreObject.get(GEOCORE_USERID)
            }
            .then { (obj: GeocoreObject) -> Promise<[GeocorePlace]> in
                println("--- The object as promised:")
                println("Id = \(obj.id!), Name = \(obj.name!), Description = \(obj.description!)")
                return GeocorePlace.get()
            }
            .then { (places: [GeocorePlace]) -> Void in
                println("--- Some places as promised:")
                for place in places {
                    println("Id = \(place.id!), Name = \(place.name!), Point = (\(place.point!.latitude!), \(place.point!.longitude!))")
                }
            }
        
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

