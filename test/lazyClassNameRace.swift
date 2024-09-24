// TEST_ENV MallocProbGuard=1 MallocProbGuardMemoryBudgetInKB=10000 MallocProbGuardSampleRate=1

import ObjectiveC
import Dispatch

// Race to be the first to get the name of a bunch of different generic classes.
// This tests the thread safety of lazy name installation. The MallocProbGuard
// variables help to more deterministically catch use-after-frees from this
// race. rdar://130280263
class C<T, U> {
  func doit(depth: Int, names: inout [String]) {
    if depth <= 0 { return }

    DispatchQueue.concurrentPerform(iterations: 2, execute: { _ in
      class_getName(object_getClass(self))
    })

    names.append(String(cString: class_getName(object_getClass(self))))

    C<T, C<T, U>>().doit(depth: depth - 1, names: &names)
    C<C<T, U>, U>().doit(depth: depth - 1, names: &names)
  }
}

var names: [String] = []
C<Int, Int>().doit(depth: 10, names: &names)

for name in names {
  _ = objc_getClass(name)
}

print("OK:", #file.split(separator: "/").last!)
