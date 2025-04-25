// TEST_CONFIG ARCH=arm64e

import Darwin

var didFail = false

func fail(_ msg: String) {
    print("BAD: \(msg)")
    didFail = true
}

class Generic<T> {}

// Ensure that a Swift generic metaclass has properly signed isa/superclass
// pointers. Work with raw pointers to avoid retain/release on the class
// objects, which Swift ARC likes to do.
let genericRaw = unsafeBitCast(Generic<Int>.self, to: UnsafeRawPointer.self)

let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
typealias classToClassFn = @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?

let object_getClassRaw = dlsym(RTLD_DEFAULT, "object_getClass")
let object_getClass = unsafeBitCast(object_getClassRaw, to: classToClassFn.self)

let class_getSuperClassRaw = dlsym(RTLD_DEFAULT, "class_getSuperclass")
let class_getSuperClass = unsafeBitCast(class_getSuperClassRaw, to: classToClassFn.self)

// Check for nil, but we're really checking for ptrauth failures in the call.

if object_getClass(object_getClass(genericRaw)) == nil {
    fail("metaclass of metaclass is nil")
}

if class_getSuperClass(object_getClass(genericRaw)) == nil {
    fail("superclass of metaclass is nil")
}

if !didFail {
    print("OK:", #file.split(separator: "/").last!)
}
