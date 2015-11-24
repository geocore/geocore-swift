//
//  GeocoreKitTests.swift
//  GeocoreKitTests
//
//  Created by Purbo Mohamad on 4/14/15.
//
//

import UIKit
import XCTest
import GeocoreKit
import PromiseKit

private let GEOCORE_BASEURL = "http://put.geocore.api.server.url.here"
private let GEOCORE_PROJECTID = "#PUT_PROJECT_ID_HERE#"
private let GEOCORE_USERID = "#PUT_USER_ID_HERE#"
private let GEOCORE_USERPASSWORD = "#PUT_USER_PASSWORD_HERE#"

private let PLACE_TEST_1_ID = "PLA-TEST-1-SWIFTTEST-1"
private let PLACE_TEST_1_NAME = "Test Swift 1"
private let PLACE_TEST_1_PT = GeocorePoint(latitude: 35.65858, longitude: 139.745433)

class GeocoreKitTests: XCTestCase {
    
    override class func setUp() {
        Geocore.sharedInstance.setup(GEOCORE_BASEURL, projectId: GEOCORE_PROJECTID)
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Security
    
    func testA1_loginFailure() {
        let expectation = expectationWithDescription("Login failure expectation")
        
        Geocore.sharedInstance
            .login("dummy_userid", password: "dummy_password")
            .error { error in
                switch error {
                case GeocoreError.ServerError(let code, _):
                    XCTAssert(code == "Auth.0001")
                default:
                    XCTFail("Unexpected server error: \(error)")
                }
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for failed login = \(error)")
        })
    }
    
    func testA2_loginSuccessful() {
        let expectation = expectationWithDescription("Login successful expectation")
        
        Geocore.sharedInstance
            .login(GEOCORE_USERID, password: GEOCORE_USERPASSWORD)
            .then { (accessToken: String) -> Void in
                print("Access Token = \(accessToken)")
                XCTAssert(accessToken.characters.count > 0)
                expectation.fulfill()
            }
            .error { error in
                XCTFail("Error logging in: \(error)")
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for successful login = \(error)")
        })
    }
    
    // MARK: - Object
    
    func testB1_getObject() {
        let expectation = expectationWithDescription("Get single object expectation")
        
        GeocoreObject.get(GEOCORE_USERID)
            .then { (object: GeocoreObject) -> Void in
                XCTAssertEqual(object.id!, GEOCORE_USERID)
                expectation.fulfill()
            }
            .error { error in
                XCTFail("Error getting object: \(error)")
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for single object = \(error)")
        })
    }
    
    // MARK: - Place
    
    func testC1_createPlace() {
        let expectation = expectationWithDescription("Create place expectation")
        
        let tags = ["駅", "テゴリー1", "カテゴリー2"]
        
        let place = GeocorePlace()
        place.id = PLACE_TEST_1_ID
        place.name = PLACE_TEST_1_NAME
        place.point = PLACE_TEST_1_PT
        place
            .tag(tags)
            .save()
            .then { (place: GeocorePlace) -> Void in
                XCTAssertEqual(place.id!, PLACE_TEST_1_ID)
                XCTAssertEqual(place.name!, PLACE_TEST_1_NAME)
                for tag in place.tags! {
                    if  tags.indexOf(tag.name!) == nil {
                        XCTFail("Unexpected tag: \(tag.name!)")
                    }
                }
                expectation.fulfill()
            }
            .error { error in
                XCTFail("Error creating place: \(error)")
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for place creation = \(error)")
        })
    }
    
    func testC2_getAndUpdatePlace() {
        let expectation = expectationWithDescription("Update place expectation")
        
        let newName = "Test Swift 2"
        
        GeocorePlace.query().withId(PLACE_TEST_1_ID).get()
            .then { (place: GeocorePlace) -> Promise<GeocorePlace> in
                place.name = newName
                return place.save()
            }
            .then { (place: GeocorePlace) -> Void in
                XCTAssertEqual(place.id!, PLACE_TEST_1_ID)
                XCTAssertEqual(place.name!, newName)
                expectation.fulfill()
            }
            .error { error in
                XCTFail("Error creating place: \(error)")
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for place update = \(error)")
        })
    }
    
    func testC3_deletePlace() {
        let expectation = expectationWithDescription("Delete place expectation")
        
        GeocorePlace.query().withId(PLACE_TEST_1_ID).get()
            .then { (place: GeocorePlace) -> Promise<GeocorePlace> in
                XCTAssertEqual(place.id!, PLACE_TEST_1_ID)
                return place.delete()
            }
            .then { (place: GeocorePlace) -> Void in
                XCTAssertEqual(place.id!, PLACE_TEST_1_ID)
                expectation.fulfill()
            }
            .error { error in
                XCTFail("Error deleting place: \(error)")
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for place delete = \(error)")
        })
    }
    
    func testC3_deletePlaceConfirm() {
        let expectation = expectationWithDescription("Delete place confirm expectation")
        
        GeocorePlace.query().withId(PLACE_TEST_1_ID).get()
            .then { (place: GeocorePlace) -> Void in
                XCTFail("Deleted place found, shouldn't happen")
            }
            .error { error in
                switch error {
                case GeocoreError.ServerError(let code, _):
                    XCTAssert(code == "General.0011")
                default:
                    XCTFail("Unexpected server error: \(error)")
                }
                expectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(5.0, handler: { (error) -> Void in
            print("Error waiting for place delete confirmation = \(error)")
        })
    }
    
}
