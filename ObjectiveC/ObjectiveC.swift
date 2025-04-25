//
//  ObjectiveC.swift
//  ObjectiveC
//
//  Copyright © 2014-2017, 2024 Apple Inc. All rights reserved.
//

@_exported
import ObjectiveC

@_implementationOnly
import ObjectiveC_Private.objc_internal

@_implementationOnly
import MachO_Private.dyld

//===----------------------------------------------------------------------===//
// Objective-C Primitive Types
//===----------------------------------------------------------------------===//

/// The Objective-C BOOL type.
///
/// On 64-bit iOS, the Objective-C BOOL type is a typedef of C/C++
/// bool. Elsewhere, it is "signed char". The Clang importer imports it as
/// ObjCBool.
@frozen @available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public struct ObjCBool : ExpressibleByBooleanLiteral, Sendable {
#if (os(macOS) && arch(x86_64)) || (os(iOS) && (arch(i386) || arch(arm) || targetEnvironment(macCatalyst)))
    // On Intel OS X and 32-bit iOS, Objective-C's BOOL type is a "signed char".
    @usableFromInline var _value: Int8
    
    @_transparent
    init(_ value: Int8) {
        self._value = value
    }
    
    @_transparent
    public init(_ value: Bool) {
        self._value = value ? 1 : 0
    }
    
#else
    // Everywhere else it is C/C++'s "Bool"
    @usableFromInline var _value: Bool
    
    @_transparent
    public init(_ value: Bool) {
        self._value = value
    }
#endif
    
    /// The value of `self`, expressed as a `Bool`.
    @_transparent
    public var boolValue: Bool {
#if (os(macOS) && arch(x86_64)) || (os(iOS) && (arch(i386) || arch(arm) || targetEnvironment(macCatalyst)))
        return _value != 0
#else
        return _value
#endif
    }
    
    /// Create an instance initialized to `value`.
    @_transparent
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

#if !targetEnvironment(exclaveKit)
@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension ObjCBool : CustomReflectable {
    /// Returns a mirror that reflects `self`.
    public var customMirror: Mirror {
        return Mirror(reflecting: boolValue)
    }
}
#endif

@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension ObjCBool : CustomStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        return self.boolValue.description
    }
}

// Functions used to implicitly bridge ObjCBool types to Swift's Bool type.

@_transparent @available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public // COMPILER_INTRINSIC
func _convertBoolToObjCBool(_ x: Bool) -> ObjCBool {
    return ObjCBool(x)
}

@_transparent @available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public // COMPILER_INTRINSIC
func _convertObjCBoolToBool(_ x: ObjCBool) -> Bool {
    return x.boolValue
}

/// The Objective-C SEL type.
///
/// The Objective-C SEL type is typically an opaque pointer. Swift
/// treats it as a distinct struct type, with operations to
/// convert between C strings and selectors.
///
/// The compiler has special knowledge of this type.
@frozen @available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public struct Selector : ExpressibleByStringLiteral, @unchecked Sendable {
    var ptr: OpaquePointer
    
    /// Create a selector from a string.
    public init(_ str : String) {
        ptr = str.withCString { sel_registerName($0).ptr }
    }
    
    // FIXME: Fast-path this in the compiler, so we don't end up with
    // the sel_registerName call at compile time.
    /// Create an instance initialized to `value`.
    public init(stringLiteral value: String) {
        self = sel_registerName(value)
    }
}

@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension Selector: Equatable, Hashable {
    // Note: The implementations for `==` and `hash(into:)` are synthesized by the
    // compiler. The generated implementations use the value of `ptr` as the basis
    // for equality.
}

@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension Selector : CustomStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        return String(_sel: self)
    }
}

@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension String {
    /// Construct the C string representation of an Objective-C selector.
    public init(_sel: Selector) {
        // FIXME: This misses the ASCII optimization.
        self = String(cString: sel_getName(_sel))
    }
}

#if !targetEnvironment(exclaveKit)
@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension Selector : CustomReflectable {
    /// Returns a mirror that reflects `self`.
    public var customMirror: Mirror {
        return Mirror(reflecting: String(_sel: self))
    }
}
#endif

//===----------------------------------------------------------------------===//
// NSZone
//===----------------------------------------------------------------------===//

@frozen @available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public struct NSZone {
    var pointer: OpaquePointer
}

@available(*, unavailable)
extension NSZone: Sendable {}

// Note: NSZone becomes Zone in Swift 3.
typealias Zone = NSZone

//===----------------------------------------------------------------------===//
// @autoreleasepool substitute
//===----------------------------------------------------------------------===//

@_silgen_name("_objc_autoreleasePoolPush")
@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public func _autoreleasePoolPush() -> UnsafeMutableRawPointer

@_silgen_name("_objc_autoreleasePoolPop")
@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public func _autoreleasePoolPop(_: UnsafeMutableRawPointer)

@inline(__always)
@_alwaysEmitIntoClient
@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
public func autoreleasepool<E, Result: ~Copyable>(
    invoking body: () throws(E) -> Result
) throws(E) -> Result {
    let pool = _autoreleasePoolPush()
    defer {
        _autoreleasePoolPop(pool)
    }
    return try body()
}

// The old entrypoint without ~Copyable. This was not AEIC so clients may have
// a reference to the symbol.
@_silgen_name("$s10ObjectiveC15autoreleasepool8invokingxxyKXE_tKlF")
@_spi(ObjectiveCLegacyABI)
@available(swift, obsoleted: 1)
public func __autoreleasepool_old_abi<Result>(
    invoking body: () throws -> Result
) rethrows -> Result {
    try autoreleasepool(invoking: body)
}

//===----------------------------------------------------------------------===//
// Mark YES and NO unavailable.
//===----------------------------------------------------------------------===//

@available(*, unavailable, message: "Use 'Bool' value 'true' instead")
public var YES: ObjCBool {
    fatalError("can't retrieve unavailable property")
}
@available(*, unavailable, message: "Use 'Bool' value 'false' instead")
public var NO: ObjCBool {
    fatalError("can't retrieve unavailable property")
}

//===----------------------------------------------------------------------===//
// NSObject
//===----------------------------------------------------------------------===//

// NSObject implements Equatable's == as -[NSObject isEqual:]
// NSObject implements Hashable's hashValue as -[NSObject hash]
// FIXME: what about NSObjectProtocol?

@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension NSObject : Equatable, Hashable {
    /// Returns a Boolean value indicating whether two values are
    /// equal. `NSObject` implements this by calling `lhs.isEqual(rhs)`.
    ///
    /// Subclasses of `NSObject` can customize Equatable conformance by overriding
    /// `isEqual(_:)`. If two objects are equal, they must have the same hash
    /// value, so if you override `isEqual(_:)`, make sure you also override the
    /// `hash` property.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: NSObject, rhs: NSObject) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    /// The hash value.
    ///
    /// `NSObject` implements this by returning `self.hash`.
    ///
    /// `NSObject.hashValue` is not overridable; subclasses can customize hashing
    /// by overriding the `hash` property.
    ///
    /// **Axiom:** `x == y` implies `x.hashValue == y.hashValue`
    ///
    /// - Note: the hash value is not guaranteed to be stable across
    ///   different invocations of the same program.  Do not persist the
    ///   hash value across program runs.
    @nonobjc
    public var hashValue: Int {
        return hash
    }
    
    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// NSObject implements this by feeding `self.hash` to the hasher.
    ///
    /// `NSObject.hash(into:)` is not overridable; subclasses can customize
    /// hashing by overriding the `hash` property.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.hash)
    }
    
    public func _rawHashValue(seed: Int) -> Int {
        return self.hash._rawHashValue(seed: seed)
    }
}

@available(macOS 10.0, iOS 1.0, tvOS 1.0, watchOS 1.0, *)
extension NSObject : CVarArg {
    /// Transform `self` into a series of machine words that can be
    /// appropriately interpreted by C varargs
    public var _cVarArgEncoding: [Int] {
        _autorelease(self)
        return _encodeBitsAsWords(self)
    }
}

//===----------------------------------------------------------------------===//
// objc_enumerateClasses()
//===----------------------------------------------------------------------===//

/// Tells `objc_enumerateClasses` which images to search.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public enum ObjCEnumerationImage {
    case dynamicClasses               /// Search dynamically registered classes
    case image(UnsafeRawPointer)      /// Search the specified image (given a handle from dlopen(3))
    case machHeader(UnsafeRawPointer) /// Search the specified image (given a `mach_header` pointer)
}

@available(*, unavailable)
extension ObjCEnumerationImage: Sendable {}

/// A Sequence of AnyClass
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public struct ObjCClassList: Sequence {
    public typealias Element = AnyClass
    
    var fromImage: ObjCEnumerationImage
    var matchingNamePrefix: String?
    var conformingTo: Protocol?
    var subclassing: AnyClass?
    
    public class Iterator: IteratorProtocol {
        var enumerator = objc_class_enumerator_t()
        let namePrefix: UnsafeMutablePointer<CChar>?
        
        init(fromImage: ObjCEnumerationImage,
             matchingNamePrefix: String?,
             conformingTo: Protocol?,
             subclassing: AnyClass?) {
            var image: UnsafeRawPointer
            switch fromImage {
            case .dynamicClasses:
                image = UnsafeRawPointer(bitPattern: -1)!
            case let .image(handle):
                image = UnsafeRawPointer(_dyld_get_dlopen_image_header(UnsafeMutableRawPointer(mutating: handle))!)
            case let .machHeader(img):
                image = img
            }
            if let np = matchingNamePrefix {
                namePrefix = strdup(np)
            } else {
                namePrefix = nil
            }
            _objc_beginClassEnumeration(image,
                                        namePrefix,
                                        conformingTo,
                                        subclassing,
                                        &enumerator)
        }
        
        deinit {
            _objc_endClassEnumeration(&enumerator);
            free(namePrefix)
        }
        
        public func next() -> AnyClass? {
            return _objc_enumerateNextClass(&enumerator);
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(fromImage: fromImage,
                        matchingNamePrefix: matchingNamePrefix,
                        conformingTo: conformingTo,
                        subclassing: subclassing)
    }
}

@available(*, unavailable)
extension ObjCClassList: Sendable {}

/**
 * Enumerates classes, filtering by image, name, protocol conformance and superclass.
 *
 * - Parameter fromImage: The image to search; defaults to the caller's image.
 * - Parameter matchingNamePrefix: If specified, a required prefix for the class name.
 * - Parameter conformingTo: If specified, a protocol to which the enumerated classes must conform.
 * - Parameter subclassing: If specified, a class which the enumerated classes must subclass.
 *
 * - Returns: A `Sequence` of classes that match the search criteria.
 */
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func objc_enumerateClasses(fromImage: ObjCEnumerationImage = .machHeader(#dsohandle),
                                  matchingNamePrefix: String? = nil,
                                  conformingTo: Protocol? = nil,
                                  subclassing: AnyClass? = nil) -> ObjCClassList {
    return ObjCClassList(fromImage: fromImage,
                         matchingNamePrefix: matchingNamePrefix,
                         conformingTo: conformingTo,
                         subclassing: subclassing)
}
