// TEST_CONFIG

#include "test.h"

// Just barely exceed the 8 capacity cache size, to end up with something pretty
// sparsely filled.
#define METHODS(X) \
    X(one) \
    X(two) \
    X(three) \
    X(four) \
    X(five) \
    X(six) \
    X(seven) \
    X(eight) \
    X(nine)

@interface C: NSObject @end
@implementation C
#define DEFINE_METHOD(n) - (void)n {}
METHODS(DEFINE_METHOD)
@end

// IMP that will be subbed in to trap uncached msgSends.
void trapIMP(__unused id self, SEL _cmd) {
    fail("method '%s' was not correctly cached", sel_getName(_cmd));
}

int main()
{
    id obj = [C new];

    // Loop several times to ensure all selectors have been cached, since
    // growing the cache throws away old entries.
    for (int i = 0; i < 10; i++) {
#define CALL_METHOD(n) [obj n];
        METHODS(CALL_METHOD)
    }

    // Swap out the IMP for each method with the trap IMP. Using
    // _method_setImplementationRawUnsafe avoids clearing the method cache when
    // doing this.
    Class c = object_getClass(obj);
#define SWAP_METHOD(n) \
    Method method_ ## n = class_getInstanceMethod(c, @selector(n)); \
    testassert(method_ ## n); \
    _method_setImplementationRawUnsafe(method_ ## n, (IMP)trapIMP);
    METHODS(SWAP_METHOD)

    // Call all of the methods again. They should all be cached and should all
    // call the original no-op implementations. If the cache is broken then this
    // will call the trap IMP instead.
    METHODS(CALL_METHOD)

    succeed(__FILE__);
}

