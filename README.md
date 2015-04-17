# GeocoreKit

**This is a very early version that is not really useful except for some basic operations.**

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
```

A less modern approach is to use nested callbacks:
```swift
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
``` 

## Notes

- The framework initial structure was constructed based on [Swift, Frameworks and Cocoapods](https://medium.com/@sorenlind/swift-frameworks-and-cocoapods-9d24f4432ed6).
- This framework is using [Alamofire](https://github.com/Alamofire/Alamofire) for HTTP networking, [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for JSON processing, and [PromiseKit](https://github.com/mxcl/PromiseKit) for promises.
