//
//  TestUtils.swift
//  MobileMessaging
//
//  Created by Andrey K. on 21/03/16.
//

import Foundation
@testable import MobileMessaging

struct MMTestConstants {
	static let kTestInvalidInternalID = "someNonexistentInternalID"
	static let kTestCorrectInternalID = "someExistingInternalID"
	static let kTestValidMSISDN = "79697162937"
	static let kTestInvalidMSISDN = "9697162937"
	static let kTestValidEmail = "john@mail.com"
	static let kTestInvalidEmail = "john@mail,com"
	static let kTestCorrectApplicationCode = "someCorrectApplicationID"
	static let kTestWrongApplicationCode = "someWrongApplicationID"
	static let kTestCurrentRegistrationId = "fffe73006f006d00650054006f006b0065006e003200"
	static let kTestOldRegistrationId = "fffe73006f006d00650054006f006b0065006e00"
//	static let kTestBaseURLString = "http://127.0.0.1:18080"
	static let kTestBaseURLString = "https://oneapi.ioinfobip.com"
}

enum TestResult {
	case Success()
	case Failure(error: NSError?)
	case Cancel
}

final class MMRemoteAPIMock : MMRemoteAPIQueue {
	
	var performRequestCompanionBlock : (Any) -> Void
	
	init(baseURLString: String, appCode: String, performRequestCompanionBlock: (Any) -> Void) {
		self.performRequestCompanionBlock = performRequestCompanionBlock
		super.init(baseURL: baseURLString, applicationCode: appCode)
	}
	
	override func perform<R: MMHTTPRequestData>(request request: R, completion: (Result<R.ResponseType>) -> Void) {
		super.perform(request: request, completion: completion)
		performRequestCompanionBlock(request)
	}
}

func timeTravel(to date: NSDate, block: () -> Void) {
	let customDateBlock: @convention(block) (AnyObject) -> NSDate = { _ in date }
	let implementation = imp_implementationWithBlock(unsafeBitCast(customDateBlock, AnyObject.self))
	let method = class_getInstanceMethod(NSClassFromString("__NSPlaceholderDate"), #selector(NSObject.init))
	let oldImplementation = method_getImplementation(method)
	method_setImplementation(method, implementation)
	block()
	method_setImplementation(method, oldImplementation)
}