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

## Notes

- The framework initial structure was constructed based on [Swift, Frameworks and Cocoapods](https://medium.com/@sorenlind/swift-frameworks-and-cocoapods-9d24f4432ed6).
- This framework is using [Alamofire](https://github.com/Alamofire/Alamofire) for HTTP networking, [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for JSON processing, and [PromiseKit](https://github.com/mxcl/PromiseKit) for promises.
