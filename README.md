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

## Basic Usage

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

Once you have configured the connection, the easiest way to login to Geocore is by using `loginWithDefaultUser` available from the Geocore singleton object. Most functions provided by Geocore return `Promise` object provided by [PromiseKit](https://github.com/mxcl/PromiseKit).
```swift
Geocore.sharedInstance.loginWithDefaultUser().then { accessToken -> Void in
    println("Logged in to Geocore successfully, with access token = \(accessToken)")
}
```

## Snippets

Here's a basic example showing how to chain promises to:
* Initialize the framework.
* Login to Geocore.
* Fetch user object.
* Fetch some places nearest to a coordinate.
```swift
import PromiseKit
import GeocoreKit

Geocore.sharedInstance
    .setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
    .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
    .then { accessToken -> Promise<GeocoreUser> in
        print("Access Token = \(accessToken)")
        return GeocoreUser.get(GEOCORE_USERID)
    }
    .then { user -> Promise<[GeocorePlace]> in
        print("--- The user as promised:")
        print("Id = \(user.id!), Name = \(user.name!)")
        return GeocorePlaceQuery()
            .withCenter(latitude: 35.666, longitude: 139.7126)
            .nearest()
    }
    .then { places -> Void in
        print("--- Some places as promised:")
        for place in places {
            print("Id = \(place.id!), Name = \(place.name!), Point = (\(place.point!.latitude!), \(place.point!.longitude!))")
        }
    }
```

Following example shows how to get places within a specified rectangle:
```swift
GeocorePlaceQuery()
    .withRectangle(
        minimumLatitude: 35.66617440081799,
        minimumLongitude: 139.7126117348629,
        maximumLatitude: 35.67753978462231,
        maximumLongitude: 139.72917705773887)
    .withinRectangle()
    .then { places -> Void in
        println("Id = \(place.id), Name = \(place.name), Point = (\(place.point?.latitude), \(place.point?.longitude))")
    }
```

## Notes

- The framework initial structure was constructed based on [Swift, Frameworks and Cocoapods](https://medium.com/@sorenlind/swift-frameworks-and-cocoapods-9d24f4432ed6).
- This framework is using [Alamofire](https://github.com/Alamofire/Alamofire) for HTTP networking, [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for JSON processing, and [PromiseKit](https://github.com/mxcl/PromiseKit) for promises.
