# GeocoreKit

**This is a very early version.**

GeocoreKit is a pure Swift framework for accessing Geocore API server.

## Installation

GeocoreKit is available either through [CocoaPods](http://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage). To install
it using CocoaPods simply add the following line to your Podfile:
```
pod "GeocoreKit"
```
To install it using Carthage, add the following line to your Cartfile:
```
github "geocore/geocore-swift"
```

## Usage

Before using the library, the easiest way to setup the connection is by adding following keys to the `Info.plist` file:

Key name | Value
----------|-------
GeocoreBaseURL | Base URL of the Geocore API
GeocoreProjectId | ID of the project provided by MapMotion

By importing `GeocoreKit`, the library's main singleton instance is accesible using `sharedInstance` static member as shown below:
```swift
import GeocoreKit

// ....

let geocore = Geocore.sharedInstance
```

Once you have configured the connection, the easiest way to login to Geocore is by using `loginWithDefaultUser` available from the Geocore singleton object. Most functions provided by Geocore return `Promise` object.
```swift
Geocore.sharedInstance.loginWithDefaultUser().then { accessToken -> Void in
    println("Logged in to Geocore successfully, with access token = \(accessToken)")
}
```

## Snippets

Here's a basic example showing how to chain promises to:
* Initialize the framework.
* Login to Geocore.
* Fetch an object.
* Fetch some places.
```swift
import PromiseKit
import GeocoreKit

Geocore.sharedInstance
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
```

A less modern approach is to use nested callbacks:
```swift
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
``` 

Following example shows how to get places within a specified rectangle:
```swift
GeocorePlace
    .get(minLat: 35.66617440081799, minLon: 139.7126117348629, maxLat: 35.67753978462231, maxLon: 139.72917705773887)
    .then { (places: [GeocorePlace]) -> Void in
        println("--- Some places as promised:")
        for place in places {
            println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
        }
    }
```

To get places nearest to a specific point:
```swift
GeocorePlace
    .get(centerLat: 35.66617440081799, centerLon: 139.7126117348629)
    .then { (places: [GeocorePlace]) -> Void in
        println("--- Some places as promised:")
        for place in places {
            println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
        }
}
```

## Notes

- The framework initial structure was constructed based on [Swift, Frameworks and Cocoapods](https://medium.com/@sorenlind/swift-frameworks-and-cocoapods-9d24f4432ed6).
- This framework is using [Alamofire](https://github.com/Alamofire/Alamofire) for HTTP networking, [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for JSON processing, and [PromiseKit](https://github.com/mxcl/PromiseKit) for promises.
