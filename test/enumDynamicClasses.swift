// TEST_CONFIG

import ObjectiveC

// Ensure that objc_enumerateClasses works with Swift classes allocated on the
// heap by the Swift runtime.
class Wrapper<T> {}

func endeepen(_ value: Any) -> Any {
  func helper<T>(value: T) -> Any {
    return Wrapper<T>()
  }
  return _openExistential(value, do: helper)
}

// Swift will place the first 64kB of dynamically created metadata into a static
// pool in libswiftCore. We need to get some metadata onto the heap, so allocate
// a lot of dynamic classes.
var value = Wrapper<Int>() as Any
for _ in 1...10000 {
  value = endeepen(value)
}

for c in objc_enumerateClasses(fromImage: .dynamicClasses, subclassing: NSObject.self) {
  print(c)
}

print("OK:", #file.split(separator: "/").last!)
