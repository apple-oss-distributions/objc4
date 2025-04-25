// These are used to test objc_enumerateClasses()

import Foundation

@objc
enum CreatureSize: Int {
    case Unknown
    case Minascule
    case Small
    case Medium
    case Big
    case Huge
}

@objc
enum StripeColor: Int {
    case BlackAndOrange
    case GrayAndBlack
    case Plaid
}

@objc
protocol Creature {
    var name: String { get }
    var size: CreatureSize { get }
}

@objc
protocol Claws {
    func retract()
    func extend()
}

@objc
protocol Stripes {
    var stripeColor: StripeColor { get }
}

@objc(Animal)
class Animal: NSObject, Creature {
    var name: String { return "animal"; }
    var size: CreatureSize { return .Unknown }
}

@objc(Dog)
class Dog: Animal {
    override var name: String { return "dog"; }
}

@objc(Datschund)
class Datschund: Dog {
    override var name: String { return "datschund" }
    override var size: CreatureSize { return .Medium }
}

@objc(Terrier)
class Terrier: Dog {
    override var name: String { return "terrier" }
    override var size: CreatureSize { return .Small }
}

@objc(Labrador)
class Labrador: Dog {
    override var name: String { return "labrador" }
    override var size: CreatureSize { return .Medium }
}

@objc(Mastiff)
class Mastiff: Dog {
    override var name: String { return "mastiff" }
    override var size: CreatureSize { return .Big }
}

@objc(Cat)
class Cat: Animal {
    override var name: String { return "cat" }
}

@objc(Tabby)
class Tabby: Cat, Stripes {
    override var name: String { return "tabby" }
    override var size: CreatureSize { return .Small }
    var stripeColor: StripeColor { return .GrayAndBlack }
}

@objc(Lion)
class Lion: Cat {
    override var name: String { return "lion" }
    override var size: CreatureSize { return .Big }
}

@objc(Tiger)
class Tiger: Cat, Stripes {
    override var name: String { return "tiger" }
    override var size: CreatureSize { return .Big }
    var stripeColor: StripeColor { return .BlackAndOrange }
}

@objc(Elephant)
class Elephant: Animal {
    override var name: String { return "elephant" }
    override var size: CreatureSize { return .Huge }
}

@objc(Woozle)
class Woozle: Elephant, Stripes {
    override var name: String { return "woozle" }
    var stripeColor: StripeColor { return .Plaid }
}

extension Cat: Claws {
    func retract() {}
    func extend() {}
}
