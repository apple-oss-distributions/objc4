// TEST_CONFIG MEM=mrc

#include "test.h"

#include <objc/NSObject.h>
#include <objc/objc-internal.h>

bool didDealloc;

@interface TestClass: NSObject @end

@implementation TestClass

+ (void)initialize {
    // Verify that autoreleasing an object in +initialize doesn't leak.
    id instance = [[TestClass alloc] init];
    [instance autorelease];
}

- (void)dealloc {
    didDealloc = true;
    [super dealloc];
}

@end

int main()
{
    @autoreleasepool {
        // We need to get to objc_retainAutoreleaseReturnValue without
        // triggering initialization, but we do want it to be realized. Looking
        // up the class by name avoids initialization.
        Class c = objc_getClass("TestClass");

        // Getting the instance size triggers realization if needed.
        class_getInstanceSize(c);

        // Make the call.
        objc_retainAutoreleaseReturnValue(c);
    }
    testassert(didDealloc);

    succeed(__FILE__);
}
