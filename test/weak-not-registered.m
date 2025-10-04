// TEST_CONFIG MEM=mrc
// TEST_CRASHES
/*
TEST_RUN_OUTPUT
objc\[\d+\]: Weak reference at 0x[0-9a-fA-f]+ contains 0x[0-9a-fA-f]+, should contain 0x[0-9a-fA-f]+
objc\[\d+\]: Weak reference loaded from 0x[0-9a-fA-f]+ contains 0x[0-9a-fA-f]+ which is not in the weak references table
objc\[\d+\]: HALTED
END
*/

#include "test.h"
#include <objc/NSObject.h>
#include <objc/objc-internal.h>

int main() {
    id obj = [NSObject new];

    // Create a weak reference, corrupt it, then load from it to trigger the
    // fatal error.
    objc_storeWeak(&obj, obj);
    obj = (id)((uintptr_t)obj | 2);
    objc_loadWeak(&obj);
    fail("objc_loadweak should have raised a fatal error.");
}
