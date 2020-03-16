//
//  ZeitgeistUITests.swift
//  ZeitgeistUITests
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import XCTest

class ZeitgeistUITests: XCTestCase {
  // TODO [#7]: Write UI tests
  // It seems fairly straightforward to write to E2E UI tests. It's well-documented
  // (e.g. on [Hacking With Swift](https://www.hackingwithswift.com/articles/148/xcode-ui-testing-cheat-sheet)
  // and mostly will require me to set up some mocks for ZEIT's API.

  override func setUp() {
    // Put setup code here. This method is called before the invocation of
    // each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure
    // occurs.
    continueAfterFailure = false

    // In UI tests it’s important to set the initial state - such as
    //interface orientation - required for your tests before they run. The
    // setUp method is a good place to do this.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation
    //of each test method in the class.
  }

  func testExample() {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the
    // correct results.
  }

  func testLaunchPerformance() {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
      // This measures how long it takes to launch your application.
      measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
        XCUIApplication().launch()
      }
    }
  }
}
