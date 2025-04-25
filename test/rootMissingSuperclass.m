/*
TEST_RUN_OUTPUT
objc\[[0-9]+\]: Superclass of TestClass at 0x[a-fA-f0-9]+ in .*rootMissingSuperclass.exe is set to 0x[0-9a-fA-F]*bad4007, indicating it is missing from an installed root
END
*/

#include "class-structures.h"
#include "test.h"

#include <objc/objc-abi.h>

#if __arm64e__
// dyld signs the 0xbad4007 sentinel. It's hard to get it to sign it for us
// in a test, but the runtime should just strip the signature anyway, so we'll
// fake it by manually setting a signature bit.
#define BAD_ROOT_ADDRESS 0x004000000bad4007
#else
#define BAD_ROOT_ADDRESS 0xbad4007
#endif

extern struct ObjCClass OBJC_METACLASS_$_NSObject;
extern struct ObjCClass OBJC_CLASS_$_NSObject;

static struct ObjCClass_ro TestClassMeta_ro __attribute__((section("__DATA,__objc_const"))) = {
    .flags = RO_META,
    .instanceStart = 40,
    .instanceSize = 40,
};

static struct ObjCClass TestClassMeta __attribute__((section("__DATA, __objc_data"))) = {
    .isa = &OBJC_METACLASS_$_NSObject,
    .superclass = &OBJC_METACLASS_$_NSObject,
    .cachePtr = &_objc_empty_cache,
    .data = &TestClassMeta_ro,
};

static struct ObjCClass_ro TestClass_ro __attribute__((section("__DATA,__objc_const"))) = {
    .instanceStart = sizeof(void *),
    .instanceSize = sizeof(void *),
    .name = "TestClass",
};

static struct ObjCClass TestClass __attribute__((section("__DATA, __objc_data"))) = {
    .isa = &TestClassMeta,
    .superclass = (struct ObjCClass *)BAD_ROOT_ADDRESS,
    .cachePtr = &_objc_empty_cache,
    .data = &TestClass_ro,
};

static struct ObjCClass *testClassListEntry __attribute__((used)) __attribute__((section("__DATA, __objc_classlist"))) = &TestClass;

int main() {
    fail("This test is supposed to crash before main()");
}
