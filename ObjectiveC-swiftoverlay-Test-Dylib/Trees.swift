//
//  Trees.swift
//  Trees
//
//  Created by Alastair Houghton on 02/09/2021.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation

@objc
protocol Tree {
    func name() -> String
    func isEvergreen() -> Bool
}

@objc
class Oak: NSObject, Tree {
    public func name() -> String { return "oak" }
    public func isEvergreen() -> Bool { return false }
}

@objc
class Birch: NSObject, Tree {
    public func name() -> String { return "birch" }
    public func isEvergreen() -> Bool { return false }
}

@objc
class Pine: NSObject, Tree {
    public func name() -> String { return "birch" }
    public func isEvergreen() -> Bool { return false }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
@_cdecl("testEnumerateClassesFromDylib")
public func testEnumerateClassesFromDylib() -> Bool {
    // This should enumerate the classes *in the dylib*
    let trees = objc_enumerateClasses().map{ "\($0)" }
    if trees == [ "Oak", "Birch", "Pine" ] {
        return true
    } else {
        print("FAILED: trees was \(trees)!")
        return false
    }
}
