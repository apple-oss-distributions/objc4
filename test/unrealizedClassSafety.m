// Make sure every libobjc API/SPI works with unrealized classes, possibly
// realizing them lazily when that's necessary.

// Don't use ARC to avoid triggering realization before we test what we want to test.
// TEST_CONFIG MEM=mrc LANGUAGE=objc
// Disable category merging so we can test categories.
// TEST_CFLAGS -framework Foundation -Wl,-no_objc_category_merging
// TEST_RUN_OUTPUT_FILTER Can't set( weak)? ivar layout

#include "test.h"

#include <objc/objc-sync.h>
#include <ptrauth.h>
#include <stdlib.h>
#include <spawn.h>
#include <sys/wait.h>
#include <TargetConditionals.h>

// We're going to test calls to deprecated functions, so silence the warnings.
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


// ***** UTILITIES *****

static bool isRealized(Class cls) {
    struct ClassInternals {
        Class __ptrauth_objc_isa_pointer metaclass;
        void *superclass;
        void *cache1;
        void *cache2;
        uintptr_t data;
    };

    struct ClassInternals *internals = (struct ClassInternals *)cls;
#if __LP64__
    uintptr_t mask = 0x0f007ffffffffff8UL;
#else
    uintptr_t mask = 0xfffffffcUL;
#endif

    uint32_t rw_realized = 1u<<31;

    uintptr_t maskedData = internals->data & mask;
    uint32_t *flagsPtr = (uint32_t *)maskedData;
    flagsPtr = ptrauth_strip(flagsPtr, ptrauth_key_process_independent_data);
    return *flagsPtr & rw_realized;
}

static void nothingMethod(id self __unused, SEL _cmd __unused) {}

@protocol NothingProtocol @end
@protocol NothingProtocol2 @end

@interface ClassWithAnIvar : NSObject {
@public
    id testIvar;
}
@end
@implementation ClassWithAnIvar
@end


// ***** TEST INFRASTRUCTURE *****

// When set to 1, this will run each test in a subprocess so that we can keep
// testing when something crashes. This is useful for development where we want
// a full list of failures so we can go fix a bunch in one go. For ongoing
// testing we may want to turn this off so that the test runs faster.
#define TEST_OUT_OF_PROCESS 1

// When set to 1, this will realize each test class (by sending the `self`
// message) before invoking the corresponding test. This is useful for ensuring
// that a failing test is caused by a problem with unrealized classes and not
// something else.
#define TEST_REALIZE_CLASSES 0

struct TestRecord {
    Class cls;
    Class metacls;
    const char *name;
    void (*testFn)(Class, Class, id);
};

size_t testRecordsCapacity = 0;
size_t testRecordsCount = 0;
static struct TestRecord *testRecords = NULL;

static void addTest(Class cls, Class metacls, const char *name, void (*testFn)(Class, Class, id)) {
    if (testRecordsCount >= testRecordsCapacity) {
        testRecordsCapacity *= 2;
        if (testRecordsCapacity == 0)
            testRecordsCapacity = 64;
        testRecords = realloc(testRecords, testRecordsCapacity * sizeof(*testRecords));
    }
    struct TestRecord record = { cls, metacls, name, testFn };
    testRecords[testRecordsCount++] = record;
}

// Create a test that receives a fresh, unrealized class. Follow the macro
// invocation with braced test code, which receives the unrealized class pointer
// in `cls`, the pointer to the metaclass in `metacls`, and an instance of that
// class in `obj`. `obj`'s lifetime cannot be extended beyond the call so don't
// escape it.
//
// Example usage: TEST(someTest) { [cls self]; [obj self]; }
#define TEST(name)                                                         \
@interface TestClass_##name : NSObject <NothingProtocol> {                 \
@public                                                                    \
    id testIvar;                                                           \
}                                                                          \
@property int testProperty;                                                \
@end                                                                       \
@implementation TestClass_##name                                           \
@dynamic testProperty;                                                     \
+ (void)testMethodClass {}                                                 \
- (void)testMethod {}                                                      \
@end                                                                       \
@interface TestClass_##name (Category)                                     \
@property int categoryProperty;                                            \
@end                                                                       \
@implementation TestClass_##name (Category)                                \
@dynamic categoryProperty;                                                 \
+ (void)categoryMethodClass {}                                             \
- (void)categoryMethod {}                                                  \
@end                                                                       \
extern char OBJC_CLASS_$_TestClass_##name;                                 \
extern char OBJC_METACLASS_$_TestClass_##name;                             \
void test_##name(Class, Class, TestClass_##name *);                        \
__attribute__((constructor)) void addTest_##name(void) {                   \
    addTest((Class) & OBJC_CLASS_$_TestClass_##name,                       \
            (Class) & OBJC_METACLASS_$_TestClass_##name,                   \
            #name, test_##name);                                           \
}                                                                          \
void test_##name(Class cls __unused,                                       \
                 Class metacls __unused,                                   \
                 TestClass_##name *obj __unused)


// ***** TESTS BEGIN HERE *****

TEST(_class_getIvarMemoryManagement) {
    Ivar ivar = NULL;
    _class_getIvarMemoryManagement(cls, ivar);
}

TEST(_class_getIvarMemoryManagement_meta) {
    Ivar ivar = NULL;
    _class_getIvarMemoryManagement(metacls, ivar);
}

TEST(_class_isFutureClass) {
    testassert(!_class_isFutureClass(cls));
}

TEST(_class_isFutureClass_meta) {
    testassert(!_class_isFutureClass(metacls));
}

TEST(_class_isSwift) {
    testassert(!_class_isSwift(cls));
}

TEST(_class_isSwift_meta) {
    testassert(!_class_isSwift(metacls));
}

TEST(_class_setCustomDeallocInitiation) {
    _class_setCustomDeallocInitiation(cls);
}

TEST(_class_setCustomDeallocInitiation_meta) {
    _class_setCustomDeallocInitiation(metacls);
}

#if OBJC_HAVE_TAGGED_POINTERS
TEST(_objc_registerTaggedPointerClass) {
    _objc_registerTaggedPointerClass(OBJC_TAG_Last52BitPayload, cls);
}

TEST(_objc_registerTaggedPointerClass_meta) {
    _objc_registerTaggedPointerClass(OBJC_TAG_Last52BitPayload-1, metacls);
}
#endif

TEST(class_addIvar) {
    testassert(!class_addIvar(cls, "ivar", 8, 8, "@"));
}

TEST(class_addIvar_meta) {
    testassert(!class_addIvar(metacls, "ivar", 8, 8, "@"));
}

TEST(class_addMethod) {
    testassert(class_addMethod(cls, @selector(nothingMethod), (IMP)nothingMethod, ""));
}

TEST(class_addMethod_meta) {
    testassert(class_addMethod(metacls, @selector(nothingMethod), (IMP)nothingMethod, ""));
}

TEST(class_addMethodsBulk) {
    SEL sel = @selector(nothingMethod);
    IMP imp = (IMP)nothingMethod;
    const char *types = "";
    uint32_t failed;
    testassertequal(class_addMethodsBulk(metacls, &sel, &imp, &types, 1, &failed), NULL);
    testassertequal(failed, 0);
    testassertequal(class_getMethodImplementation(metacls, sel), imp);
}

TEST(class_addMethodsBulk_meta) {
    SEL sel = @selector(nothingMethod);
    IMP imp = (IMP)nothingMethod;
    const char *types = "";
    uint32_t failed;
    testassertequal(class_addMethodsBulk(metacls, &sel, &imp, &types, 1, &failed), NULL);
    testassertequal(failed, 0);
    testassertequal(class_getMethodImplementation(metacls, sel), imp);
}

TEST(class_addProperty) {
    class_addProperty(cls, "someProperty", NULL, 0);
}

TEST(class_addProperty_meta) {
    class_addProperty(metacls, "someProperty", NULL, 0);
}

TEST(class_addProtocol) {
    class_addProtocol(cls, @protocol(NothingProtocol));
    class_addProtocol(cls, @protocol(NothingProtocol2));
}

TEST(class_addProtocol_meta) {
    class_addProtocol(metacls, @protocol(NothingProtocol));
    class_addProtocol(metacls, @protocol(NothingProtocol2));
}

TEST(class_conformsToProtocol) {
    testassert(class_conformsToProtocol(cls, @protocol(NothingProtocol)));
    testassert(!class_conformsToProtocol(cls, @protocol(NothingProtocol2)));
}

TEST(class_conformsToProtocol_meta) {
    testassert(class_conformsToProtocol(metacls, @protocol(NothingProtocol)));
    testassert(!class_conformsToProtocol(metacls, @protocol(NothingProtocol2)));
}

TEST(class_copyImpCache) {
    int count;
    testassertequal(class_copyImpCache(cls, &count), NULL);
    testassertequal(count, 0);
}

TEST(class_copyImpCache_meta) {
    int count;
    testassertequal(class_copyImpCache(metacls, &count), NULL);
    testassertequal(count, 0);
}

TEST(class_copyIvarList) {
    unsigned count;
    Ivar *ivars = class_copyIvarList(cls, &count);
    testassert(ivars);
    testassertequal(count, 1);
    testassertequalstr(ivar_getName(ivars[0]), "testIvar");
    free(ivars);
}

TEST(class_copyIvarList_meta) {
    unsigned count;
    Ivar *ivars = class_copyIvarList(metacls, &count);
    testassert(!ivars);
    testassertequal(count, 0);
    free(ivars);
}

TEST(class_copyIvarList_slide) {
    // Make sure the ivars have been slid when we get them back.
    unsigned count;
    class_setSuperclass(cls, [ClassWithAnIvar class]);
    Ivar *ivars = class_copyIvarList(cls, &count);
    testassert(ivars);
    testassertequal(count, 1);
    testassertequalstr(ivar_getName(ivars[0]), "testIvar");
    testassertequal(ivar_getOffset(ivars[0]), 2 * sizeof(void *));
    free(ivars);
}

TEST(class_copyMethodList) {
    unsigned count;
    Method *methods = class_copyMethodList(cls, &count);
    testassert(methods);
    testassertequal(count, 2);
    testassertequalsel(method_getName(methods[0]), @selector(categoryMethod));
    testassertequalsel(method_getName(methods[1]), @selector(testMethod));
    free(methods);
}

TEST(class_copyMethodList_meta) {
    unsigned count;
    Method *methods = class_copyMethodList(metacls, &count);
    testassert(methods);
    testassertequal(count, 2);
    testassertequalsel(method_getName(methods[0]), @selector(categoryMethodClass));
    testassertequalsel(method_getName(methods[1]), @selector(testMethodClass));
    free(methods);
}

TEST(class_copyPropertyList) {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList(cls, &count);
    testassert(properties);
    testassertequal(count, 2);
    testassertequalstr(property_getName(properties[0]), "categoryProperty");
    testassertequalstr(property_getName(properties[1]), "testProperty");
    free(properties);
}

TEST(class_copyPropertyList_meta) {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList(metacls, &count);
    testassert(!properties);
    testassertequal(count, 0);
    free(properties);
}

TEST(class_copyProtocolList) {
    unsigned count;
    Protocol **protocols = class_copyProtocolList(cls, &count);
    testassert(protocols);
    testassertequal(count, 1);
    testassertequal(protocols[0], @protocol(NothingProtocol));
    free(protocols);
}

TEST(class_copyProtocolList_meta) {
    unsigned count;
    Protocol **protocols = class_copyProtocolList(metacls, &count);
    testassert(protocols);
    testassertequal(count, 1);
    testassertequal(protocols[0], @protocol(NothingProtocol));
    free(protocols);
}

TEST(class_createInstance) {
    id instance = class_createInstance(cls, 0);
    testassert(instance);
    testassertequal(object_getClass(instance), cls);
    [instance release];
}

#if TARGET_OS_OSX
TEST(class_createInstanceFromZone) {
    id instance = class_createInstanceFromZone(cls, 0, NULL);
    testassert(instance);
    testassertequal(object_getClass(instance), cls);
    [instance release];
}
#endif

TEST(class_createInstances) {
    id objs[2];
    unsigned count = class_createInstances(cls, 0, objs, 2);
    testassertequal(count, 2);
    testassert(objs[0]);
    testassert(objs[1]);
    testassertequal(object_getClass(objs[0]), cls);
    testassertequal(object_getClass(objs[1]), cls);
    [objs[0] release];
    [objs[1] release];
}

TEST(class_getClassMethod) {
    Method m = class_getClassMethod(cls, @selector(testMethodClass));
    testassert(m);
    testassertequal(method_getName(m), @selector(testMethodClass));
}

TEST(class_getClassMethod_DNE) {
    Method m = class_getClassMethod(cls, @selector(doesNotExist));
    testassert(!m);
}

TEST(class_getClassMethod_meta) {
    Method m = class_getClassMethod(metacls, @selector(testMethodClass));
    testassert(m);
    testassertequal(method_getName(m), @selector(testMethodClass));
}

TEST(class_getClassMethod_meta_DNE) {
    Method m = class_getClassMethod(metacls, @selector(doesNotExist));
    testassert(!m);
}

TEST(class_getClassVariable) {
    testassertequal(class_getClassVariable(cls, "whatever"), NULL);
}

TEST(class_getClassVariable_meta) {
    testassertequal(class_getClassVariable(metacls, "whatever"), NULL);
}

TEST(class_getImageName) {
    const char *name = class_getImageName(cls);
    testassert(name);
    testassert(strstr(name, "unrealizedClassSafety"));
}

TEST(class_getImageName_meta) {
    const char *name = class_getImageName(metacls);
    testassert(name);
    testassert(strstr(name, "unrealizedClassSafety"));
}

TEST(class_getInstanceMethod) {
    Method m = class_getInstanceMethod(cls, @selector(testMethod));
    testassert(m);
    testassertequalsel(method_getName(m), @selector(testMethod));
}

TEST(class_getInstanceMethod_DNE) {
    Method m = class_getInstanceMethod(cls, @selector(doesNotExist));
    testassert(!m);
}

TEST(class_getInstanceMethod_meta) {
    Method m = class_getInstanceMethod(metacls, @selector(testMethodClass));
    testassert(m);
    testassertequalsel(method_getName(m), @selector(testMethodClass));
}

TEST(class_getInstanceMethod_meta_DNE) {
    Method m = class_getInstanceMethod(metacls, @selector(doesNotExist));
    testassert(!m);
}

TEST(class_getInstanceSize) {
    testassertequal(class_getInstanceSize(cls), 2 * sizeof(id));
}

TEST(class_getInstanceSize_meta) {
    testassertequal(class_getInstanceSize(metacls), 5 * sizeof(void *));
}

TEST(class_getInstanceVariable) {
    Ivar ivar = class_getInstanceVariable(cls, "testIvar");
    testassert(ivar);
    testassertequalstr(ivar_getName(ivar), "testIvar");
}

TEST(class_getInstanceVariable_meta) {
    Ivar ivar = class_getInstanceVariable(metacls, "testIvar");
    testassert(!ivar);
}

TEST(class_getIvarLayout) {
    testassertequal(class_getIvarLayout(cls), NULL);
}

TEST(class_getIvarLayout_meta) {
    testassertequal(class_getIvarLayout(metacls), NULL);
}

TEST(class_getMethodImplementation) {
    testassert(class_getMethodImplementation(cls, @selector(testMethod)));
}

TEST(class_getMethodImplementation_DNE) {
    testassert(class_getMethodImplementation(cls, @selector(doesNotExist)));
}

TEST(class_getMethodImplementation_meta) {
    testassert(class_getMethodImplementation(metacls, @selector(testMethodClass)));
}

TEST(class_getMethodImplementation_meta_DNE) {
    testassert(class_getMethodImplementation(metacls, @selector(doesNotExist)));
}

#if __x86_64__
TEST(class_getMethodImplementation_stret) {
    testassert(class_getMethodImplementation_stret(cls, @selector(testMethod)));
}

TEST(class_getMethodImplementation_stret_DNE) {
    testassert(class_getMethodImplementation_stret(cls, @selector(doesNotExist)));
}

TEST(class_getMethodImplementation_stret_meta) {
    testassert(class_getMethodImplementation_stret(metacls, @selector(testMethodClass)));
}

TEST(class_getMethodImplementation_stret_meta_DNE) {
    testassert(class_getMethodImplementation_stret(metacls, @selector(doesNotExist)));
}
#endif

TEST(class_getName) {
    testassertequalstr(class_getName(cls), "TestClass_class_getName");
}

TEST(class_getName_meta) {
    testassertequalstr(class_getName(metacls), "TestClass_class_getName_meta");
}

TEST(class_getProperty) {
    objc_property_t property = class_getProperty(cls, "testProperty");
    testassert(property);
    testassertequalstr(property_getName(property), "testProperty");
}

TEST(class_getProperty_meta) {
    objc_property_t property = class_getProperty(metacls, "testProperty");
    testassert(!property);
}

TEST(class_getSuperclass) {
    testassertequal(class_getSuperclass(cls), [NSObject class]);
}

TEST(class_getSuperclass_meta) {
    testassertequal(class_getSuperclass(metacls), object_getClass([NSObject class]));
}

TEST(class_getVersion) {
    int version = class_getVersion(cls);
    testassertequal(version, 0);
}

TEST(class_getVersion_meta) {
    int version = class_getVersion(metacls);
    // Default metaclass version is 7.
    testassertequal(version, 7);
}

TEST(class_getWeakIvarLayout) {
    testassertequal(class_getWeakIvarLayout(cls), NULL);
}

TEST(class_getWeakIvarLayout_meta) {
    testassertequal(class_getWeakIvarLayout(metacls), NULL);
}

TEST(class_isMetaClass) {
    testassert(!class_isMetaClass(cls));
}

TEST(class_isMetaClass_meta) {
    testassert(class_isMetaClass(metacls));
}

TEST(class_lookupMethod) {
    testassert(class_lookupMethod(cls, @selector(testMethod)));
}

TEST(class_lookupMethod_DNE) {
    testassert(class_lookupMethod(cls, @selector(doesNotExist)));
}

TEST(class_lookupMethod_meta) {
    testassert(class_lookupMethod(metacls, @selector(testMethodClass)));
}

TEST(class_lookupMethod_meta_DNE) {
    testassert(class_lookupMethod(metacls, @selector(doesNotExist)));
}

TEST(class_replaceMethod) {
    testassert(class_replaceMethod(cls, @selector(testMethod), (IMP)nothingMethod, ""));
}

TEST(class_replaceMethod_DNE) {
    testassert(!class_replaceMethod(cls, @selector(doesNotExist), (IMP)nothingMethod, ""));
}

TEST(class_replaceMethod_meta) {
    testassert(class_replaceMethod(metacls, @selector(testMethodClass), (IMP)nothingMethod, ""));
}

TEST(class_replaceMethod_meta_DNE) {
    testassert(!class_replaceMethod(metacls, @selector(doesNotExist), (IMP)nothingMethod, ""));
}

TEST(class_replaceMethodsBulk) {
    SEL sel = @selector(testMethod);
    IMP imp = (IMP)nothingMethod;
    const char *types = "";
    class_replaceMethodsBulk(cls, &sel, &imp, &types, 1);
    testassertequal(class_getMethodImplementation(cls, sel), imp);
}

TEST(class_replaceMethodsBulk_meta) {
    SEL sel = @selector(testMethod);
    IMP imp = (IMP)nothingMethod;
    const char *types = "";
    class_replaceMethodsBulk(metacls, &sel, &imp, &types, 1);
    testassertequal(class_getMethodImplementation(metacls, sel), imp);
}

TEST(class_replaceProperty) {
    class_replaceProperty(cls, "testProperty", NULL, 0);
}

TEST(class_replaceProperty_meta) {
    class_replaceProperty(metacls, "testProperty", NULL, 0);
}

TEST(class_respondsToMethod) {
    testassert(class_respondsToMethod(cls, @selector(testMethod)));
}

TEST(class_respondsToMethod_DNE) {
    testassert(!class_respondsToMethod(cls, @selector(doesNotExist)));
}

TEST(class_respondsToMethod_meta) {
    testassert(class_respondsToMethod(metacls, @selector(testMethodClass)));
}

TEST(class_respondsToMethod_meta_DNE) {
    testassert(!class_respondsToMethod(metacls, @selector(doesNotExist)));
}

TEST(class_respondsToSelector) {
    testassert(class_respondsToSelector(cls, @selector(testMethod)));
}

TEST(class_respondsToSelector_DNE) {
    testassert(!class_respondsToSelector(cls, @selector(doesNotExist)));
}

TEST(class_respondsToSelector_meta) {
    testassert(class_respondsToSelector(object_getClass(cls), @selector(testMethodClass)));
}

TEST(class_respondsToSelector_meta_DNE) {
    testassert(!class_respondsToSelector(object_getClass(cls), @selector(doesNotExist)));
}

TEST(class_setIvarLayout) {
    class_setIvarLayout(cls, NULL);
}

TEST(class_setSuperclass_unrealized_to_realized) {
    class_setSuperclass(cls, [NSObject class]);
    testassertequal(class_getSuperclass(cls), [NSObject class]);
}

@interface TestClass_setSuperclass_realized_to_unrealized2: ClassWithAnIvar @end
@implementation TestClass_setSuperclass_realized_to_unrealized2 @end
TEST(class_setSuperclass_realized_to_unrealized) {
    class_setSuperclass([TestClass_setSuperclass_realized_to_unrealized2 class], cls);
    testassertequal([TestClass_setSuperclass_realized_to_unrealized2 superclass], cls);
}

@interface TestClass_class_setSuperclass_unrealized_to_unrealized2: ClassWithAnIvar @end
@implementation TestClass_class_setSuperclass_unrealized_to_unrealized2 @end
TEST(class_setSuperclass_unrealized_to_unrealized) {
    extern char OBJC_CLASS_$_TestClass_class_setSuperclass_unrealized_to_unrealized2;
    Class cls2 = (Class)&OBJC_CLASS_$_TestClass_class_setSuperclass_unrealized_to_unrealized2;
    class_setSuperclass(cls, cls2);
    testassertequal(class_getSuperclass(cls), cls2);
}

TEST(class_setVersion) {
    class_setVersion(cls, 1);
    testassertequal(class_getVersion(cls), 1);
}

TEST(class_setVersion_meta) {
    class_setVersion(metacls, 1);
    testassertequal(class_getVersion(metacls), 1);
}

TEST(class_setWeakIvarLayout) {
    class_setWeakIvarLayout(cls, NULL);
}

TEST(class_setWeakIvarLayout_meta) {
    class_setWeakIvarLayout(metacls, NULL);
}

TEST(objc_alloc) {
    id instance = objc_alloc(cls);
    testassert(instance);
    [instance release];
}

TEST(objc_alloc_meta) {
    id instance = objc_alloc(metacls);
    testassert(instance);
}

TEST(objc_allocWithZone) {
    id instance = objc_allocWithZone(cls);
    testassert(instance);
    [instance release];
}

TEST(objc_allocWithZone_meta) {
    id instance = objc_allocWithZone(metacls);
    testassert(instance);
}

TEST(objc_alloc_init) {
    id instance = objc_alloc_init(cls);
    testassert(instance);
    [instance release];
}

TEST(objc_allocateClassPair) {
    Class subclass = objc_allocateClassPair(cls, "TestSubclass_objc_allocateClassPair", 0);
    testassert(subclass);
    objc_registerClassPair(subclass);
    id instance = [[subclass alloc] init];
    testassertequal([instance superclass], cls);
    [instance release];
}

TEST(objc_autorelease_class) {
    objc_autorelease(cls);
}

TEST(objc_autorelease_class_meta) {
    objc_autorelease(metacls);
}

TEST(objc_autorelease) {
    @autoreleasepool {
        objc_autorelease([obj retain]);
    }
}

TEST(objc_autoreleaseReturnValue_class) {
    objc_autoreleaseReturnValue(cls);
}

TEST(objc_autoreleaseReturnValue_class_meta) {
    objc_autoreleaseReturnValue(metacls);
}

TEST(objc_autoreleaseReturnValue) {
    @autoreleasepool {
        objc_autoreleaseReturnValue([obj retain]);
    }
}

TEST(objc_claimAutoreleasedReturnValue_class) {
    objc_claimAutoreleasedReturnValue(cls);
}

TEST(objc_claimAutoreleasedReturnValue_class_meta) {
    objc_claimAutoreleasedReturnValue(metacls);
}

TEST(objc_claimAutoreleasedReturnValue) {
    objc_claimAutoreleasedReturnValue(obj);
}

TEST(objc_clear_deallocating_class) {
    objc_clear_deallocating(cls);
}

TEST(objc_clear_deallocating_class_meta) {
    objc_clear_deallocating(metacls);
}

TEST(objc_clear_deallocating) {
    objc_clear_deallocating(obj);
}

TEST(objc_constructInstance) {
    void *bytes = malloc(2 * sizeof(id));
    id instance = objc_constructInstance(cls, bytes);
    testassertequal(object_getClass(instance), cls);
    [instance release];
}

TEST(objc_constructInstance_meta) {
    void *bytes = malloc(5 * sizeof(id));
    id instance = objc_constructInstance(metacls, bytes);
    testassertequal(object_getClass(instance), metacls);
}

TEST(objc_copyWeak_class) {
    id weak1 = nil;
    id weak2 = nil;
    objc_initWeak(&weak1, cls);
    objc_copyWeak(&weak2, &weak1);
    testassertequal(objc_loadWeakRetained(&weak1), cls);
    testassertequal(objc_loadWeakRetained(&weak2), cls);
    objc_destroyWeak(&weak1);
    objc_destroyWeak(&weak2);
}

TEST(objc_copyWeak_class_meta) {
    id weak1 = nil;
    id weak2 = nil;
    objc_initWeak(&weak1, metacls);
    objc_copyWeak(&weak2, &weak1);
    testassertequal(objc_loadWeakRetained(&weak1), metacls);
    testassertequal(objc_loadWeakRetained(&weak2), metacls);
    objc_destroyWeak(&weak1);
    objc_destroyWeak(&weak2);
}

TEST(objc_copyWeak) {
    id weak1 = nil;
    id weak2 = nil;
    objc_initWeak(&weak1, obj);
    objc_copyWeak(&weak2, &weak1);
    testassertequal(objc_loadWeakRetained(&weak1), obj);
    testassertequal(objc_loadWeakRetained(&weak2), obj);
    objc_destroyWeak(&weak1);
    objc_destroyWeak(&weak2);
}

TEST(objc_destroyWeak) {
    id weak1 = nil;
    objc_initWeak(&weak1, obj);
    objc_destroyWeak(&weak1);
}

TEST(objc_destroyWeak_class) {
    id weak1 = nil;
    objc_initWeak(&weak1, cls);
    objc_destroyWeak(&weak1);
}

TEST(objc_destroyWeak_class_meta) {
    id weak1 = nil;
    objc_initWeak(&weak1, metacls);
    objc_destroyWeak(&weak1);
}

TEST(objc_destructInstance) {
    objc_destructInstance(obj);
}

TEST(objc_duplicateClass) {
    Class newClass = objc_duplicateClass(cls, "TestDuplicate_objc_duplicateClass", 0);
    testassertequal(class_getSuperclass(newClass), class_getSuperclass(cls));
}

TEST(objc_getAssociatedObject) {
    char keyTarget;
    id value = objc_getAssociatedObject(obj, &keyTarget);
    testassertequal(value, NULL);
}

TEST(objc_getAssociatedObject2) {
    char keyTarget;
    objc_setAssociatedObject(obj, &keyTarget, obj, OBJC_ASSOCIATION_RETAIN);
    id value = objc_getAssociatedObject(obj, &keyTarget);
    testassertequal(value, obj);
}

TEST(objc_initWeak_class) {
    id weakVar = nil;
    objc_initWeak(&weakVar, cls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_initWeak_class_meta) {
    id weakVar = nil;
    objc_initWeak(&weakVar, metacls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_initWeak) {
    id weakVar = nil;
    objc_initWeak(&weakVar, obj);
    objc_destroyWeak(&weakVar);
}

TEST(objc_initWeakOrNil_class) {
    id weakVar = nil;
    objc_initWeakOrNil(&weakVar, cls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_initWeakOrNil_class_meta) {
    id weakVar = nil;
    objc_initWeakOrNil(&weakVar, metacls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_initWeakOrNil) {
    id weakVar = nil;
    objc_initWeakOrNil(&weakVar, obj);
    objc_destroyWeak(&weakVar);
}

TEST(objc_isUniquelyReferenced_class) {
    objc_isUniquelyReferenced(cls);
}

TEST(objc_isUniquelyReferenced_class_meta) {
    objc_isUniquelyReferenced(metacls);
}

TEST(objc_isUniquelyReferenced) {
    objc_isUniquelyReferenced(obj);
}

TEST(objc_loadWeak_class) {
    @autoreleasepool {
        id weakVar = nil;
        objc_initWeak(&weakVar, cls);
        testassertequal(objc_loadWeak(&weakVar), cls);
    }
}

TEST(objc_loadWeak_class_meta) {
    @autoreleasepool {
        id weakVar = nil;
        objc_initWeak(&weakVar, metacls);
        testassertequal(objc_loadWeak(&weakVar), metacls);
    }
}

TEST(objc_loadWeak) {
    @autoreleasepool {
        id weakVar = nil;
        objc_initWeak(&weakVar, obj);
        testassertequal(objc_loadWeak(&weakVar), obj);
    }
}

TEST(objc_loadWeakRetained_class) {
    id weakVar = nil;
    objc_initWeak(&weakVar, cls);
    testassertequal(objc_loadWeakRetained(&weakVar), cls);
}

TEST(objc_loadWeakRetained_class_meta) {
    id weakVar = nil;
    objc_initWeak(&weakVar, metacls);
    testassertequal(objc_loadWeakRetained(&weakVar), metacls);
}

TEST(objc_loadWeakRetained) {
    id weakVar = nil;
    objc_initWeak(&weakVar, obj);
    testassertequal(objc_loadWeakRetained(&weakVar), obj);
}

TEST(objc_moveWeak_class) {
    id weak1 = nil;
    id weak2 = nil;
    objc_initWeak(&weak1, cls);
    objc_moveWeak(&weak2, &weak1);
    testassertequal(objc_loadWeakRetained(&weak2), cls);
}

TEST(objc_moveWeak_class_meta) {
    id weak1 = nil;
    id weak2 = nil;
    objc_initWeak(&weak1, metacls);
    objc_moveWeak(&weak2, &weak1);
    testassertequal(objc_loadWeakRetained(&weak2), metacls);
}

TEST(objc_moveWeak) {
    id weak1 = nil;
    id weak2 = nil;
    objc_initWeak(&weak1, obj);
    objc_moveWeak(&weak2, &weak1);
    testassertequal(objc_loadWeakRetained(&weak2), obj);
}

TEST(objc_opt_class_class) {
    testassertequal(objc_opt_class(cls), cls);
}

TEST(objc_opt_class_class_meta) {
    testassertequal(objc_opt_class(metacls), metacls);
}

TEST(objc_opt_class) {
    testassertequal(objc_opt_class(obj), cls);
}

TEST(objc_opt_isKindOfClass_class) {
    testassert(objc_opt_isKindOfClass(cls, [NSObject class]));
}

TEST(objc_opt_isKindOfClass_class_meta) {
    testassert(objc_opt_isKindOfClass(metacls, [NSObject class]));
}

TEST(objc_opt_isKindOfClass_class2) {
    testassert(!objc_opt_isKindOfClass([NSObject class], cls));
}

TEST(objc_opt_isKindOfClass_class2_meta) {
    testassert(!objc_opt_isKindOfClass([NSObject class], metacls));
}

TEST(objc_opt_isKindOfClass) {
    testassert(objc_opt_isKindOfClass(obj, [NSObject class]));
}

TEST(objc_opt_new_class) {
    id instance = objc_opt_new(cls);
    testassertequal(object_getClass(instance), cls);
    [instance release];
}

TEST(objc_opt_respondsToSelector_class) {
    testassert(objc_opt_respondsToSelector(cls, @selector(testMethodClass)));
}

TEST(objc_opt_respondsToSelector_class_DNE) {
    testassert(!objc_opt_respondsToSelector(cls, @selector(doesNotExist)));
}

TEST(objc_opt_respondsToSelector_class_meta) {
    testassert(objc_opt_respondsToSelector(metacls, @selector(self)));
}

TEST(objc_opt_respondsToSelector_class_meta_DNE) {
    testassert(!objc_opt_respondsToSelector(metacls, @selector(doesNotExist)));
}

TEST(objc_opt_respondsToSelector) {
    testassert(objc_opt_respondsToSelector(obj, @selector(testMethod)));
}

TEST(objc_opt_respondsToSelector_DNE) {
    testassert(!objc_opt_respondsToSelector(obj, @selector(doesNotExist)));
}

TEST(objc_opt_self_class) {
    testassertequal(objc_opt_self(cls), cls);
}

TEST(objc_opt_self_class_meta) {
    testassertequal(objc_opt_self(metacls), metacls);
}

TEST(objc_opt_self) {
    testassertequal(objc_opt_self(obj), obj);
}

TEST(objc_release_class) {
    objc_release(cls);
}

TEST(objc_release_class_meta) {
    objc_release(metacls);
}

TEST(objc_removeAssociatedObjects_class) {
    objc_removeAssociatedObjects(cls);
}

TEST(objc_removeAssociatedObjects_class_meta) {
    objc_removeAssociatedObjects(metacls);
}

TEST(objc_removeAssociatedObjects) {
    objc_removeAssociatedObjects(obj);
}

TEST(objc_retain_class) {
    objc_retain(cls);
}

TEST(objc_retain_class_meta) {
    objc_retain(metacls);
}

TEST(objc_retain) {
    [objc_retain(obj) release];
}

TEST(objc_retainAutorelease_class) {
    @autoreleasepool {
        objc_retainAutorelease(cls);
    }
}

TEST(objc_retainAutorelease_class_meta) {
    @autoreleasepool {
        objc_retainAutorelease(metacls);
    }
}

TEST(objc_retainAutorelease) {
    @autoreleasepool {
        objc_retainAutorelease(obj);
    }
}

TEST(objc_retainAutoreleaseReturnValue_class) {
    @autoreleasepool {
        objc_retainAutoreleaseReturnValue(cls);
    }
}

TEST(objc_retainAutoreleaseReturnValue_class_meta) {
    @autoreleasepool {
        objc_retainAutoreleaseReturnValue(metacls);
    }
}

TEST(objc_retainAutoreleaseReturnValue) {
    @autoreleasepool {
        objc_retainAutoreleaseReturnValue(obj);
    }
}

TEST(objc_retainAutoreleasedReturnValue_class) {
    objc_retainAutorelease(cls);
}

TEST(objc_retainAutoreleasedReturnValue_class_meta) {
    objc_retainAutorelease(metacls);
}

TEST(objc_retainAutoreleasedReturnValue) {
    objc_retainAutoreleasedReturnValue(obj);
}

TEST(objc_retain_autorelease_class) {
    @autoreleasepool {
        objc_retain_autorelease(cls);
    }
}

TEST(objc_retain_autorelease_class_meta) {
    @autoreleasepool {
        objc_retain_autorelease(metacls);
    }
}

TEST(objc_retain_autorelease) {
    @autoreleasepool {
        objc_retain_autorelease(obj);
    }
}

TEST(objc_setAssociatedObject_class) {
    char keyTarget;
    objc_setAssociatedObject(cls, &keyTarget, nil, OBJC_ASSOCIATION_RETAIN);
}

TEST(objc_setAssociatedObject_class_meta) {
    char keyTarget;
    objc_setAssociatedObject(metacls, &keyTarget, nil, OBJC_ASSOCIATION_RETAIN);
}

TEST(objc_setAssociatedObject) {
    char keyTarget;
    objc_setAssociatedObject(obj, &keyTarget, nil, OBJC_ASSOCIATION_RETAIN);
}

TEST(objc_setAssociatedObject2_class) {
    char keyTarget;
    objc_setAssociatedObject([NSObject class], &keyTarget, cls, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject([NSObject class], &keyTarget, nil, OBJC_ASSOCIATION_RETAIN);
}

TEST(objc_setAssociatedObject2_class_meta) {
    char keyTarget;
    objc_setAssociatedObject([NSObject class], &keyTarget, metacls, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject([NSObject class], &keyTarget, nil, OBJC_ASSOCIATION_RETAIN);
}

TEST(objc_setAssociatedObject2) {
    char keyTarget;
    objc_setAssociatedObject([NSObject class], &keyTarget, obj, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject([NSObject class], &keyTarget, nil, OBJC_ASSOCIATION_RETAIN);
}

TEST(objc_setProperty) {
    id value = [NSObject new];
    objc_setProperty(obj, @selector(setThing:), sizeof(id), value, false, false);
    testassertequal(obj->testIvar, value);
    obj->testIvar = nil;
    [value release];
}

TEST(objc_setProperty2) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty(target, @selector(setThing:), sizeof(id), obj, false, false);
    testassertequal(target->testIvar, obj);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty2_class) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty(target, @selector(setThing:), sizeof(id), cls, false, false);
    testassertequal(target->testIvar, cls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty2_class_meta) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty(target, @selector(setThing:), sizeof(id), metacls, false, false);
    testassertequal(target->testIvar, metacls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_atomic) {
    id value = [NSObject new];
    objc_setProperty_atomic(obj, @selector(setThing:), value, sizeof(id));
    testassertequal(obj->testIvar, value);
    obj->testIvar = nil;
    [value release];
}

TEST(objc_setProperty_atomic2) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_atomic(target, @selector(setThing:), obj, sizeof(id));
    testassertequal(target->testIvar, obj);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_atomic2_class) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_atomic(target, @selector(setThing:), cls, sizeof(id));
    testassertequal(target->testIvar, cls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_atomic2_class_meta) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_atomic(target, @selector(setThing:), metacls, sizeof(id));
    testassertequal(target->testIvar, metacls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_atomic_copy) {
    id value = @"copy me";
    objc_setProperty_atomic_copy(obj, @selector(setThing:), value, sizeof(id));
    testassertequal(obj->testIvar, value);
    obj->testIvar = nil;
    [value release];
}

TEST(objc_setProperty_atomic_copy_class) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_atomic_copy(target, @selector(setThing:), cls, sizeof(id));
    testassertequal(target->testIvar, cls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_atomic_copy_class_meta) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_atomic_copy(target, @selector(setThing:), metacls, sizeof(id));
    testassertequal(target->testIvar, metacls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_nonatomic) {
    id value = [NSObject new];
    objc_setProperty_nonatomic(obj, @selector(setThing:), value, sizeof(id));
    testassertequal(obj->testIvar, value);
    obj->testIvar = nil;
    [value release];
}

TEST(objc_setProperty_nonatomic2) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_nonatomic(target, @selector(setThing:), obj, sizeof(id));
    testassertequal(target->testIvar, obj);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_nonatomic2_class) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_nonatomic(target, @selector(setThing:), cls, sizeof(id));
    testassertequal(target->testIvar, cls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_nonatomic2_class_meta) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_nonatomic(target, @selector(setThing:), metacls, sizeof(id));
    testassertequal(target->testIvar, metacls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_nonatomic_copy) {
    id value = @"copy me";
    objc_setProperty_nonatomic_copy(obj, @selector(setThing:), value, sizeof(id));
    testassertequal(obj->testIvar, value);
    obj->testIvar = nil;
    [value release];
}

TEST(objc_setProperty_nonatomic_copy_class) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_nonatomic_copy(target, @selector(setThing:), cls, sizeof(id));
    testassertequal(target->testIvar, cls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_setProperty_nonatomic_copy_class_meta) {
    ClassWithAnIvar *target = [ClassWithAnIvar new];
    objc_setProperty_nonatomic_copy(target, @selector(setThing:), metacls, sizeof(id));
    testassertequal(target->testIvar, metacls);
    target->testIvar = nil;
    [target release];
}

TEST(objc_storeStrong_class) {
    id var = nil;
    objc_storeStrong(&var, cls);
    testassertequal(var, cls);
    [var release];
}

TEST(objc_storeStrong_class_meta) {
    id var = nil;
    objc_storeStrong(&var, metacls);
    testassertequal(var, metacls);
    [var release];
}

TEST(objc_storeStrong) {
    id var = nil;
    objc_storeStrong(&var, obj);
    testassertequal(var, obj);
    [var release];
}

TEST(objc_storeWeak_class) {
    id weakVar = nil;
    objc_storeWeak(&weakVar, cls);
    testassertequal(objc_loadWeakRetained(&weakVar), cls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_storeWeak_class_meta) {
    id weakVar = nil;
    objc_storeWeak(&weakVar, metacls);
    testassertequal(objc_loadWeakRetained(&weakVar), metacls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_storeWeak) {
    id weakVar = nil;
    objc_storeWeak(&weakVar, obj);
    testassertequal(objc_loadWeakRetained(&weakVar), obj);
    objc_destroyWeak(&weakVar);
}

TEST(objc_storeWeakOrNil_class) {
    id weakVar = nil;
    objc_storeWeakOrNil(&weakVar, cls);
    testassertequal(objc_loadWeakRetained(&weakVar), cls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_storeWeakOrNil_class_meta) {
    id weakVar = nil;
    objc_storeWeakOrNil(&weakVar, metacls);
    testassertequal(objc_loadWeakRetained(&weakVar), metacls);
    objc_destroyWeak(&weakVar);
}

TEST(objc_storeWeakOrNil) {
    id weakVar = nil;
    objc_storeWeakOrNil(&weakVar, obj);
    testassertequal(objc_loadWeakRetained(&weakVar), obj);
    objc_destroyWeak(&weakVar);
}

TEST(objc_sync_enter_class) {
    objc_sync_enter(cls);
    objc_sync_exit(cls);
}

TEST(objc_sync_enter_class_meta) {
    objc_sync_enter(metacls);
    objc_sync_exit(metacls);
}

TEST(objc_sync_enter) {
    objc_sync_enter(obj);
    objc_sync_exit(obj);
}

TEST(objc_sync_exit_class) {
    objc_sync_exit(cls);
}

TEST(objc_sync_exit_class_meta) {
    objc_sync_exit(metacls);
}

TEST(objc_sync_exit) {
    objc_sync_exit(obj);
}

TEST(objc_sync_try_enter_class) {
    testassert(objc_sync_try_enter(cls));
    objc_sync_exit(cls);
}

TEST(objc_sync_try_enter_class_meta) {
    testassert(objc_sync_try_enter(metacls));
    objc_sync_exit(cls);
}

TEST(objc_sync_try_enter) {
    testassert(objc_sync_try_enter(obj));
    objc_sync_exit(obj);
}

TEST(objc_unsafeClaimAutoreleasedReturnValue_class) {
    objc_unsafeClaimAutoreleasedReturnValue(cls);
}

TEST(objc_unsafeClaimAutoreleasedReturnValue_class_meta) {
    objc_unsafeClaimAutoreleasedReturnValue(metacls);
}

TEST(objc_unsafeClaimAutoreleasedReturnValue) {
    objc_unsafeClaimAutoreleasedReturnValue(obj);
}

TEST(object_copy) {
    id value = [NSObject new];
    obj->testIvar = value;
    TestClass_object_copy *copy = object_copy(obj, 0);
    testassertequal(copy->testIvar, value);
    [copy release];
}

#if TARGET_OS_OSX
TEST(object_copyFromZone) {
    id value = [NSObject new];
    obj->testIvar = value;
    TestClass_object_copy *copy = object_copyFromZone(obj, 0, NULL);
    testassertequal(copy->testIvar, value);
    [copy release];
}
#endif

TEST(object_dispose) {
    struct Object {
        Class __ptrauth_objc_isa_pointer isa;
        id testIvar;
    };
    struct Object *instance = calloc(2, sizeof(id));
    instance->isa = cls;
    object_dispose((id)instance);
}

TEST(object_getClass_class) {
    testassert(object_getClass(cls));
}

TEST(object_getClass_class_meta) {
    testassert(object_getClass(metacls));
}

TEST(object_getClass) {
    testassertequal(object_getClass(obj), cls);
}

TEST(object_getClassName_class) {
    testassertequalstr(object_getClassName(cls), "TestClass_object_getClassName_class");
}

TEST(object_getClassName_class_meta) {
    testassertequalstr(object_getClassName(metacls), "NSObject");
}

TEST(object_getClassName) {
    testassertequalstr(object_getClassName(obj), "TestClass_object_getClassName");
}

TEST(object_getIndexedIvars_class) {
    void *ptr = object_getIndexedIvars(cls);
    testassertequal((char *)cls + 5 * sizeof(id), (char *)ptr);
}

TEST(object_getIndexedIvars_class_meta) {
    void *ptr = object_getIndexedIvars(metacls);
    testassertequal((char *)metacls + 5 * sizeof(id), (char *)ptr);
}

TEST(object_getIndexedIvars) {
    void *ptr = object_getIndexedIvars(obj);
    testassertequal((char *)obj + 2 * sizeof(id), (char *)ptr);
}

TEST(object_getInstanceVariable_class) {
    testassertequal(object_getInstanceVariable(cls, "whatever", NULL), NULL);
}

TEST(object_getInstanceVariable_class_meta) {
    testassertequal(object_getInstanceVariable(metacls, "whatever", NULL), NULL);
}

TEST(object_getInstanceVariable) {
    id target = [NSObject new];
    obj->testIvar = target;
    void *value;
    object_getInstanceVariable(obj, "testIvar", &value);
    testassertequal((id)value, target);
    [target release];
}

TEST(object_getIvar) {
    id target = [NSObject new];
    obj->testIvar = target;
    Ivar ivar = object_getInstanceVariable(obj, "testIvar", NULL);
    id value = object_getIvar(obj, ivar);
    testassertequal(value, target);
    [target release];
}

TEST(object_getMethodImplementation_class) {
    testassert(object_getMethodImplementation(cls, @selector(testMethodClass)));
}

TEST(object_getMethodImplementation_class_DNE) {
    testassert(object_getMethodImplementation(cls, @selector(doesNotExist)));
}

TEST(object_getMethodImplementation_class_meta) {
    testassert(object_getMethodImplementation(metacls, @selector(testMethodClass)));
}

TEST(object_getMethodImplementation_class_meta_DNE) {
    testassert(object_getMethodImplementation(metacls, @selector(doesNotExist)));
}

TEST(object_getMethodImplementation) {
    testassert(object_getMethodImplementation(cls, @selector(testMethod)));
}

TEST(object_getMethodImplementation_DNE) {
    testassert(object_getMethodImplementation(cls, @selector(doesNotExist)));
}

TEST(object_isClass_class) {
    testassert(object_isClass(cls));
}

TEST(object_isClass_class_meta) {
    testassert(object_isClass(metacls));
}

TEST(object_isClass) {
    testassert(!object_isClass(obj));
}

TEST(object_setClass_unrealized_to_realized) {
    object_setClass(obj, [ClassWithAnIvar class]);
    testassertequal(object_getClass(obj), [ClassWithAnIvar class]);
}

TEST(object_setClass_realized_to_unrealized) {
    id instance = [ClassWithAnIvar new];
    object_setClass(instance, cls);
    testassertequal(object_getClass(instance), cls);
}

@interface TestClass_object_setClass_unrealized_to_unrealized2: ClassWithAnIvar @end
@implementation TestClass_object_setClass_unrealized_to_unrealized2 @end
TEST(object_setClass_unrealized_to_unrealized) {
    extern char OBJC_CLASS_$_TestClass_object_setClass_unrealized_to_unrealized2;
    Class cls2 = (Class)&OBJC_CLASS_$_TestClass_object_setClass_unrealized_to_unrealized2;
    object_setClass(obj, cls2);
    testassertequal(object_getClass(obj), cls2);
}

TEST(object_setInstanceVariable) {
    id value = [NSObject new];
    object_setInstanceVariable(obj, "testIvar", value);
    testassertequal(obj->testIvar, value);
    [value release];
}

TEST(object_setInstanceVariableWithStrongDefault) {
    id value = [NSObject new];
    object_setInstanceVariableWithStrongDefault(obj, "testIvar", value);
    testassertequal(obj->testIvar, value);
    [obj->testIvar release];
    [value release];
}

TEST(object_setIvar) {
    id value = [NSObject new];
    Ivar ivar = object_getInstanceVariable(obj, "testIvar", NULL);
    object_setIvar(obj, ivar, value);
    testassertequal(obj->testIvar, value);
    [value release];
}

TEST(object_setIvarWithStrongDefault) {
    id value = [NSObject new];
    Ivar ivar = object_getInstanceVariable(obj, "testIvar", NULL);
    object_setIvarWithStrongDefault(obj, ivar, value);
    testassertequal(obj->testIvar, value);
    [obj->testIvar release];
    [value release];
}

// ***** MAIN FUNCTION AND HELPERS *****

void callTestFunction(long i) {
    if (i < 0 || (size_t)i >= testRecordsCount)
        fail("Invalid test index %ld.", i);

    testassert(!isRealized(testRecords[i].cls));

    struct TestRecord record = testRecords[i];
    struct {
        Class __ptrauth_objc_isa_pointer isa;
        id testIvar;
    } object;
    object.isa = record.cls;
    object.testIvar = nil;
    id objPtr = (id)&object;

#if TEST_REALIZE_CLASSES
    [record.cls self];
    testwarn("Performing test %s with a realized class.", record.name);
#endif

    record.testFn(record.cls, record.metacls, objPtr);
}

// Run with no arguments to run all tests. Run with one argument to run a single
// test, indicated by name or test index. When TEST_OUT_OF_PROCESS is set, the
// no-arguments case spawns a subprocess for each test, providing the test index
// as an argument. The test name support is provided for debugging convenience.
int main(int argc, const char **argv) {
    if (argc > 2)
        fail("Run with one argument to run one test, or no arguments to run all tests.");

    if (argc == 2) {
        char *end;
        long i = strtol(argv[1], &end, 0);
        if (*end == 0) {
            callTestFunction(i);
            exit(0);
        } else {
            for (size_t i = 0; i < testRecordsCount; i++) {
                if (strcmp(argv[1], testRecords[i].name) == 0) {
                    callTestFunction(i);
                    exit(0);
                }
            }
            fail("Unknown test %s.", argv[1]);
        }
    }

    for (size_t i = 0; i < testRecordsCount; i++) {
        testprintf("Testing %s\n", testRecords[i].name);
#if TEST_OUT_OF_PROCESS
        char *testNumberStr;
        asprintf(&testNumberStr, "%zu", i);
        testassert(testNumberStr);

        extern char **environ;
        char *argv0 = strdup(argv[0]);
        char *args[] = { argv0, testNumberStr, NULL };
        pid_t pid;
        int result = posix_spawn(&pid, argv[0], NULL, NULL, args, environ);
        if (result) {
            perror("posix_spawn");
            exit(1);
        }
        int status;
        result = wait4(pid, &status, 0, NULL);
        if (result == -1) {
            perror("wait4");
            exit(1);
        }
        if (!WIFEXITED(status)) {
            fprintf(stderr, "BAD: test %s did not exit normally.\n", testRecords[i].name);
        } else {
            int exitCode = WEXITSTATUS(status);
            if (exitCode != 0)
                fprintf(stderr, "BAD: test %s exited with code %d.\n", testRecords[i].name, exitCode);
            else
                testprintf("Test %s exited normally.\n", testRecords[i].name);
        }
        free(argv0);
        free(testNumberStr);
#else
        callTestFunction(i);
#endif
    }
    succeed(__FILE__);
}
