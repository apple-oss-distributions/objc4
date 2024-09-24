// TEST_CONFIG

import Darwin
import ObjectiveC

var didFail = false

func fail(_ msg: String) {
    print("BAD: \(msg)")
    didFail = true
}

func basePointer(class cls: AnyClass) -> UnsafeRawPointer {
    let ptr = unsafeBitCast(cls, to: UnsafeRawPointer.self)

    // The classAddressOffset comes after the ObjC class structure (5 pointers),
    // then after 4 uint32_t's and 2 uint16_t's.
    let classAddressOffsetOffset =
        MemoryLayout<UnsafeRawPointer>.size * 5
        + MemoryLayout<UInt32>.size * 4
        + MemoryLayout<UInt16>.size * 2;
    let classAddressOffset = ptr.load(fromByteOffset: classAddressOffsetOffset, as: UInt32.self)
    return ptr - Int(classAddressOffset)
}

class SwiftClass {}

// Track how many times malloc_zone_from_ptr returned something for a disposed
// class. This could happen if something else allocated something new in that
// location, but that should not happen 100 times in a row, so we'll tolerate
// false positives but not 100% false positives.
var disposedZoneCount = 0
let iterations = 100
for _ in 0..<iterations {
    let dynamicClass: AnyClass = objc_allocateClassPair(SwiftClass.self, "SwiftClassDynamicSubclass", 0)!
    let dynamicClassBasePtr = basePointer(class: dynamicClass)
    let size1 = malloc_size(dynamicClassBasePtr)
    if size1 == 0 {
        fail("Could not get size for class pointer")
    }

    objc_registerClassPair(dynamicClass)
    objc_disposeClassPair(dynamicClass)
    let size2 = malloc_size(dynamicClassBasePtr)
    if size2 == 0 {
        disposedZoneCount += 1
    }
}

if disposedZoneCount == 0 {
    fail("Disposed class was never freed.")
}

if !didFail {
    print("OK:", #file.split(separator: "/").last!)
}
