//
//  SignalsTests.swift
//  SignalsTests
//
//  Created by Tuomas Artman on 16.8.2014.
//  Copyright (c) 2014 Tuomas Artman. All rights reserved.
//

import UIKit
import XCTest

class SignalsTests: XCTestCase {
    
    var emitter:SignalEmitter = SignalEmitter();
    
    override func setUp() {
        super.setUp()
        emitter = SignalEmitter()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testBasicFiring() {
        var intSignalResult = 0
        var stringSignalResult = ""
        
        emitter.onInt.listen(self, callback: { (argument) in
            intSignalResult = argument;
        })
        emitter.onString.listen(self, callback: { (argument) in
            stringSignalResult = argument;
        })
        
        emitter.onInt.fire(1);
        emitter.onString.fire("test");
        
        XCTAssertEqual(intSignalResult, 1, "IntSignal catched")
        XCTAssertEqual(stringSignalResult, "test", "StringSignal catched")
    }
    
    func testNoArgumentFiring() {
        var signalCount = 0
        
        emitter.onNoParams.listen(self, callback: { () -> Void in
            signalCount += 1;
        })
        
        emitter.onNoParams.fire();
        
        XCTAssertEqual(signalCount, 1, "Signal catched")
    }

    func testMultiArgumentFiring() {
        var intSignalResult = 0
        var stringSignalResult = ""
        
        emitter.onIntAndString.listen(self, callback: { (argument1, argument2) -> Void in
            intSignalResult = argument1
            stringSignalResult = argument2
        })
        
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")
        
        XCTAssertEqual(intSignalResult, 1, "argument1 catched")
        XCTAssertEqual(stringSignalResult, "test", "argument2 catched")
    }
    
    func testMultiFiring() {
        var dispatchCount = 0
        var lastArgument = 0
        
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount++
            lastArgument = argument
        })
        
        emitter.onInt.fire(1)
        emitter.onInt.fire(2)

        XCTAssertEqual(dispatchCount, 2, "Dispatched two times")
        XCTAssertEqual(lastArgument, 2, "Last argument catched with value 2")
    }
    
    func testMultiListenersOneObject() {
        var dispatchCount = 0
        var lastArgument = 0
        
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount++
            lastArgument = argument
        })
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount++
            lastArgument = argument + 1
        })
        
        emitter.onInt.fire(1)

        XCTAssertEqual(dispatchCount, 2, "Dispatched two times")
        XCTAssertEqual(lastArgument, 2, "Last argument catched with value 2")
    }
    
    func testMultiListenersManyObjects() {
        var testListeners = [
            TestListener(),
            TestListener(),
            TestListener()
        ]
        
        for listener in testListeners {
            listener.listenTo(emitter)
        }
        
        emitter.onInt.fire(1)
        emitter.onInt.fire(2)
        
        for listener in testListeners {
            XCTAssertEqual(listener.dispatchCount, 2, "Dispatched two times")
            XCTAssertEqual(listener.lastArgument, 2, "Last argument catched with value 2")
        }
    }
    
    func testListeningOnce() {
        let listener1 = TestListener()
        let listener2 = TestListener()
        let listener3 = TestListener()
        
        listener1.listenTo(emitter)
        listener2.listenOnceTo(emitter)
        listener3.listenPastTo(emitter)
        
        emitter.onInt.fire(1)
        emitter.onInt.fire(2)
        
        XCTAssertEqual(listener1.dispatchCount, 2, "Dispatched two times")
        XCTAssertEqual(listener2.dispatchCount, 1, "Dispatched one time")
        XCTAssertEqual(listener3.dispatchCount, 2, "Dispatched two times")
    }
    
    
    func testRemovingListeners() {
        var dispatchCount: Int = 0
        
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount += 1
        })
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount += 1
        })
        
        emitter.onInt.removeListener(self)
        emitter.onInt.fire(1)
        
        XCTAssertEqual(dispatchCount, 0, "Shouldn't have catched signal fire")
    }
    
    func testRemovingAllListeners() {
        var dispatchCount: Int = 0
        
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount += 1
        })
        emitter.onInt.listen(self, callback: { (argument) in
            dispatchCount += 1
        })
        
        emitter.onInt.removeAllListeners()
        emitter.onInt.fire(1)
        
        XCTAssertEqual(dispatchCount, 0, "Shouldn't have catched signal fire")
    }
    
    func testAutoRemoveWeakListeners() {
        var dispatchCount: Int = 0

        var listener: TestListener? = TestListener()
        listener!.listenTo(emitter)
        listener = nil
        
        emitter.onInt.fire(1)

        XCTAssertEqual(emitter.onInt.listeners.count, 0, "Weak listener should have been collected")
    }
    
    func testPostListening() {
        var intSignalResult = 0
        var stringSignalResult = ""
        var dispatchCount = 0
        
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")
        
        emitter.onIntAndString.listenPast(self, callback: { (argument1, argument2) -> Void in
            intSignalResult = argument1
            stringSignalResult = argument2
            dispatchCount += 1
        })

        XCTAssertEqual(intSignalResult, 1, "argument1 catched")
        XCTAssertEqual(stringSignalResult, "test", "argument2 catched")
        
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")
        
        XCTAssertEqual(dispatchCount, 2, "Second fire catched")
    }
    
    func testConditionalListening() {
        var intSignalResult = 0
        var stringSignalResult = ""
        var dispatchCount = 0
        
        let listener = emitter.onIntAndString.listen(self, callback: { (argument1, argument2) -> Void in
            intSignalResult = argument1
            stringSignalResult = argument2
            dispatchCount += 1
        }).filter { (intArgument, stringArgument) -> Bool in
            return intArgument == 2 && stringArgument == "test2"
        }
        
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test2")
        emitter.onIntAndString.fire(intArgument:2, stringArgument:"test2")
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test3")
        
        XCTAssertEqual(dispatchCount, 1, "Filtered fires")
        XCTAssertEqual(intSignalResult, 2, "argument1 catched")
        XCTAssertEqual(stringSignalResult, "test2", "argument2 catched")
    }
    
    func testConditionalListeningOnce() {
        var intSignalResult = 0
        var stringSignalResult = ""
        var dispatchCount = 0
        
        let listener = emitter.onIntAndString.listenOnce(self, callback: { (argument1, argument2) -> Void in
            intSignalResult = argument1
            stringSignalResult = argument2
            dispatchCount += 1
        }).filter { $0 == 2 && $1 == "test2" }
        
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")
        emitter.onIntAndString.fire(intArgument:2, stringArgument:"test2")
        emitter.onIntAndString.fire(intArgument:2, stringArgument:"test2")
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test3")
        
        XCTAssertEqual(dispatchCount, 1, "Filtered fires")
        XCTAssertEqual(intSignalResult, 2, "argument1 catched")
        XCTAssertEqual(stringSignalResult, "test2", "argument2 catched")
    }
    
    func testCancellingListeners() {
        var dispatchCount = 0
        
        let listener = emitter.onIntAndString.listen(self, callback: { (argument1, argument2) -> Void in
            dispatchCount += 1
        })
     
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")
        listener.cancel()
        emitter.onIntAndString.fire(intArgument:1, stringArgument:"test")

        XCTAssertEqual(dispatchCount, 1, "Filtered fires")
    }
    
    func testPostListeningNoData() {
        var dispatchCount = 0
        
        emitter.onNoParams.fire()
        
        emitter.onNoParams.listenPast(self, callback: { () -> Void in
            dispatchCount += 1
        })
        
        XCTAssertEqual(dispatchCount, 1, "Catched signal fire")
    }
}
