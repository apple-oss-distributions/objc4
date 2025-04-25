// TEST_CONFIG MEM=mrc
/*
TEST_RUN_OUTPUT
objc\[\d+\]: Class Sub1 is implemented in both.*
objc\[\d+\]: Class SubSub is implemented in both.*
OK: readClassPairIvarFixup.m
END
*/

#include "test.h"
#include <objc/NSObject.h>

@interface Bigger: NSObject {
    id a, b, c, d;
}
@end
@implementation Bigger
@end

@interface Sub1: NSObject {
    id x;
}
@end
@implementation Sub1 @end

@interface Sub2: NSObject {
    id x;
}
@end
@implementation Sub2 @end

@interface SubSub: Sub2 {
    id y;
}
@end
@implementation SubSub @end

int main() {
    objc_image_info info = {};

    extern char OBJC_CLASS_$_Sub1;
    Class sub1Ptr = (Class)&OBJC_CLASS_$_Sub1;

    // Make sure objc_readClassPair slides our ivars when needed.
    // Reading a class that's statically known to the runtime will emit a
    // duplicate class warning, but that's OK for our testing.
    class_setSuperclass(sub1Ptr, [Bigger class]);
    objc_readClassPair(sub1Ptr, &info);

    unsigned count1;
    Ivar *ivars1 = class_copyIvarList(sub1Ptr, &count1);
    testassertequal(count1, 1);
    testassert(ivars1);
    testassertequal(ivar_getOffset(ivars1[0]), 5 * sizeof(id));


    // And make sure it slides our ivars even when there's another unrealized
    // class in between.
    extern char OBJC_CLASS_$_Sub2;
    Class sub2Ptr = (Class)&OBJC_CLASS_$_Sub2;

    extern char OBJC_CLASS_$_SubSub;
    Class subSubPtr = (Class)&OBJC_CLASS_$_SubSub;

    class_setSuperclass(sub2Ptr, [Bigger class]);
    objc_readClassPair(subSubPtr, &info);

    unsigned count2;
    Ivar *ivars2 = class_copyIvarList(subSubPtr, &count2);
    testassertequal(count2, 1);
    testassert(ivars2);
    testassertequal(ivar_getOffset(ivars2[0]), 6 * sizeof(id));

    succeed(__FILE__);
}
