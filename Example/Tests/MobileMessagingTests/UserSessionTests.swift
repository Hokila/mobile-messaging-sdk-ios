//
//  UserSessionTests.swift
//  MobileMessagingExample
//
//  Created by Andrey Kadochnikov on 20.01.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import MobileMessaging

class UserSessionTests: MMTestCase {

	func testThatUserSessionDataPersisted() {
		MMTestCase.cleanUpAndStop()
		MMTestCase.startWithCorrectApplicationCode()
		weak var expectation = self.expectation(description: "case is finished")
		mobileMessagingInstance.pushRegistrationId = MMTestConstants.kTestCorrectInternalID
		let now = MobileMessaging.date.now.timeIntervalSince1970

		// when
		self.mobileMessagingInstance.userSessionService.performSessionTracking(doReporting: false) {

			timeTravel(to: Date(timeIntervalSince1970: now + 5), block: {

				self.mobileMessagingInstance.userSessionService.performSessionTracking(doReporting: false) {

					timeTravel(to: Date(timeIntervalSince1970: now + 10), block: {

						self.mobileMessagingInstance.userSessionService.performSessionTracking(doReporting: false) {
							expectation?.fulfill()
						}
					})
				}
			})
		}

		// then
		waitForExpectations(timeout: 20, handler: { _ in
			let ctx = self.storage.mainThreadManagedObjectContext!
			let sessions = UserSessionReportObject.MM_findAllInContext(ctx)!
			XCTAssertEqual(sessions.count, 1)
			XCTAssertEqual(sessions.first!.startDate.timeIntervalSince1970, now)
			XCTAssertEqual(sessions.first!.endDate.timeIntervalSince1970, now + 10)
		})
	}

	func testThatNewUserSessionStartsAfterTimeoutOldSessionRemovedAfterReporing() {
		MMTestCase.cleanUpAndStop()
		MMTestCase.startWithCorrectApplicationCode()
		weak var expectation = self.expectation(description: "case is finished")
		mobileMessagingInstance.pushRegistrationId = MMTestConstants.kTestCorrectInternalID

		let remoteApiProvider = RemoteAPIProviderStub()
		remoteApiProvider.sendUserSessionClosure = { _, _, _ in
			return UserSessionSendingResult.Success(EmptyResponse())
		}
		mobileMessagingInstance.remoteApiProvider = remoteApiProvider
		let now = MobileMessaging.date.now.timeIntervalSince1970

		// when
		self.mobileMessagingInstance.userSessionService.performSessionTracking(doReporting: false) {

			timeTravel(to: Date(timeIntervalSince1970: now + 5), block: {

				self.mobileMessagingInstance.userSessionService.performSessionTracking(doReporting: false) {

					timeTravel(to: Date(timeIntervalSince1970: now + 35), block: {

						self.mobileMessagingInstance.userSessionService.performSessionTracking(doReporting: true) {
							expectation?.fulfill()
						}
					})
				}
			})
		}

		// then
		waitForExpectations(timeout: 20, handler: { _ in
			let ctx = self.storage.mainThreadManagedObjectContext!
			let sessions = UserSessionReportObject.MM_findAllInContext(ctx)!
			XCTAssertEqual(sessions.count, 1)
			XCTAssertEqual(sessions.first!.startDate.timeIntervalSince1970, now + 35)
			XCTAssertEqual(sessions.first!.endDate.timeIntervalSince1970, now + 35)
		})
	}

	//TODO: tests for data format 2020-01-27T19:20:30.45Z

}
