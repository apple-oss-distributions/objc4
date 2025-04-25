// Ported to XCTest from swift/validation-test/stdlib/ObjectiveC.swift

import XCTest
import ObjectiveC

// Declare the entrypoint for the old, non-AEIC autoreleasepool function.
@_silgen_name("$s10ObjectiveC15autoreleasepool8invokingxxyKXE_tKlF")
func autoreleasepool_old_abi<Result>(
    invoking body: () throws -> Result
) rethrows -> Result

class NSObjectWithCustomHashable : NSObject {
    var _value: Int
    var _hashValue: Int
    
    init(value: Int, hashValue: Int) {
        self._value = value
        self._hashValue = hashValue
    }
    
    override func isEqual(_ other: Any?) -> Bool {
        let other_ = other as! NSObjectWithCustomHashable
        return self._value == other_._value
    }
    
    override var hash: Int {
        return _hashValue
    }
}

class ObjectiveCTests: XCTestCase {
    func test_Hashable() {
        let instances: [(order: Int, hashOrder: Int, object: NSObject)] = [
            (10, 1, NSObjectWithCustomHashable(value: 10, hashValue: 100)),
            (10, 1, NSObjectWithCustomHashable(value: 10, hashValue: 100)),
            (20, 1, NSObjectWithCustomHashable(value: 20, hashValue: 100)),
            (30, 2, NSObjectWithCustomHashable(value: 30, hashValue: 300)),
        ]
        checkHashable(
            instances.map { $0.object },
            equalityOracle: { instances[$0].order == instances[$1].order },
            hashEqualityOracle: { instances[$0].hashOrder == instances[$1].hashOrder })
    }
}

//===----------------------------------------------------------------------===//
// objc_enumerateClasses()
//===----------------------------------------------------------------------===//

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
class EnumerationTests: XCTestCase {
    func test_01_MatchNamePrefix() {
        let startingWithE =
        objc_enumerateClasses(matchingNamePrefix: "E").map{ "\($0)" }
        XCTAssertEqual(startingWithE, ["Elephant"])
    }
    
    func test_02_MultipleMatchCriteria() {
        let dogsStartingL: [String] =
        objc_enumerateClasses(matchingNamePrefix: "L",
                              subclassing: Dog.self).map{ "\($0)" }
        XCTAssertEqual(dogsStartingL, ["Labrador"])
    }
    
    func test_03_DirectConformance() {
        let stripeyThings =
        objc_enumerateClasses(conformingTo: Stripes.self).map{ "\($0)" }
        
        XCTAssertEqual(stripeyThings, ["Tabby", "Tiger", "Woozle"])
    }
    
    func test_04_ExtensionConformance() {
        let hasClaws =
        objc_enumerateClasses(conformingTo: Claws.self).map{ "\($0)" }
        
        XCTAssertEqual(hasClaws, ["Cat", "Tabby", "Lion", "Tiger"])
    }
    
    func test_05_Subclasses() {
        let animals =
        objc_enumerateClasses(subclassing: Animal.self).map{ "\($0)" }
        
        XCTAssertEqual(animals, ["Dog", "Datschund", "Terrier", "Labrador",
                                 "Mastiff", "Cat", "Tabby", "Lion", "Tiger",
                                 "Elephant", "Woozle"])
    }
    
    func test_06_EarlyExit() {
        let firstFour =
        objc_enumerateClasses(subclassing: Animal.self).prefix(4)
            .map{ "\($0)" }
        
        XCTAssertEqual(firstFour, ["Dog", "Datschund", "Terrier", "Labrador"])
    }
    
    func test_07_Dynamic() {
        let heffalump: AnyClass = objc_allocateClassPair(Elephant.self,
                                                         "Heffalump", 0)!
        
        // Shouldn't see it yet
        for cls in objc_enumerateClasses(fromImage: .dynamicClasses) {
            XCTAssertNotEqual(String(cString: class_getName(cls)), "Heffalump")
        }
        
        let heffalumpName: @convention(c) (AnyObject, Selector) -> String = {
            _,_ in return "heffalump"
        }
        let nameMethod = class_getInstanceMethod(heffalump.self,
                                                 #selector(getter: name))
        class_addMethod(heffalump, #selector(getter: name),
                        unsafeBitCast(heffalumpName, to: OpaquePointer.self),
                        method_getTypeEncoding(nameMethod!))
        
        // Register it
        objc_registerClassPair(heffalump)
        
        // Should now see it
        XCTAssert(objc_enumerateClasses(fromImage: .dynamicClasses)
            .map{ String(cString: class_getName($0)) }
            .contains("Heffalump"))
    }
    
    func test_08_Dylib() {
        let dylib = dlopen("libObjectiveC-swiftoverlay-Test-Dylib.dylib", RTLD_NOW)!
        
        let trees = objc_enumerateClasses(fromImage: .image(dylib)).map{ "\($0)" }
        
        XCTAssertEqual(trees, ["Oak", "Birch", "Pine"])
        
        dlclose(dylib);
    }
    
    func test_09_FromDylib() {
        let dylib = dlopen("libObjectiveC-swiftoverlay-Test-Dylib.dylib", RTLD_NOW)!
        
        let symbol = dlsym(dylib, "testEnumerateClassesFromDylib")!
        let testFunc = unsafeBitCast(symbol, to:(@convention(c) () -> Bool).self)
        
        XCTAssert(testFunc())
        
        dlclose(dylib)
    }
    
    func testAutoreleasepool() {
        weak var weakObj: NSObject?
        autoreleasepool {
            let obj = NSObject()
            weakObj = obj
            _ = Unmanaged.passRetained(obj).autorelease()
        }
        XCTAssertNil(weakObj)
    }
    
    func testAutoreleasepoolNoncopyable() {
        struct SomeNoncopyable: ~Copyable {
            var x: Int
        }
        
        let val: SomeNoncopyable = autoreleasepool { SomeNoncopyable(x: 42) }
        XCTAssertEqual(val.x, 42)
    }
    
    func testAutoreleasepoolThrows() {
        struct MyError: Error {
            var x: Int
        }
        
        do {
            try autoreleasepool { throw MyError(x: 42) }
        } catch {
            XCTAssertEqual((error as! MyError).x, 42)
        }
    }
    
    func testAutoreleasepoolTypedThrows() {
        struct MyError: Error {
            var x: Int
        }
        
        func throwit() throws(MyError) {
            throw MyError(x: 42)
        }
        
        do {
            try autoreleasepool(invoking: throwit)
        } catch {
            XCTAssertEqual(error.x, 42)
        }
    }
    
    func testAutoreleasepool_old_abi() {
        weak var weakObj: NSObject?
        autoreleasepool_old_abi {
            let obj = NSObject()
            weakObj = obj
            _ = Unmanaged.passRetained(obj).autorelease()
        }
        XCTAssertNil(weakObj)
    }
}
