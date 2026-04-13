// TEST_CONFIG MEM=mrc

#include <objc/objc-internal.h>
#include <objc/objc-gdb.h>
#include "test.h"

@interface TestClass: NSObject @end
@implementation TestClass
- (void)method1 {}
- (void)method2 {}
- (void)method3 {}
- (void)method4 {}
- (void)method5 {}
@end

static void replacement1(id self __unused, SEL _cmd __unused) {}
static void replacement2(id self __unused, SEL _cmd __unused) {}
static void replacement3(id self __unused, SEL _cmd __unused) {}
static void replacement4(id self __unused, SEL _cmd __unused) {}
static void replacement5(id self __unused, SEL _cmd __unused) {}

static void (^hook1Block)(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source);
static void (^hook2Block)(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source);

static ptrauth_objc_hook_methodSetImplementation _objc_hook_methodSetImplementation hook1Old;

static void hook1(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
    if (hook1Block)
        hook1Block(cls, m, count, sels, imps, source);

    if (hook1Old)
        hook1Old(cls, m, count, sels, imps, source);
}

static ptrauth_objc_hook_methodSetImplementation _objc_hook_methodSetImplementation hook2Old;

static void hook2(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
    if (hook2Block)
        hook2Block(cls, m, count, sels, imps, source);

    if (hook2Old)
        hook2Old(cls, m, count, sels, imps, source);
}

int main() {
    // Test that the counter is updated even when no hook is set
    Method testMethod = class_getInstanceMethod([TestClass class], @selector(method1));
    uint64_t countBeforeNoHook = objc_debug_methodSetImplementationCallCount;
    IMP testIMP = method_setImplementation(testMethod, (IMP)replacement1);
    testassertequal(objc_debug_methodSetImplementationCallCount, countBeforeNoHook + 1);
    method_setImplementation(testMethod, testIMP); // restore

    _objc_setHook_methodSetImplementation(hook2, &hook2Old);
    _objc_setHook_methodSetImplementation(hook1, &hook1Old);

    // method_setImplementation
    Method m1 = class_getInstanceMethod([TestClass class], @selector(method1));

    uint64_t callCountBefore = objc_debug_methodSetImplementationCallCount;

    __block BOOL hook1Called = NO;
    hook1Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, Nil);
        testassertequal(m, m1);
        testassertequal(count, 1);
        testassertequal(sels[0], @selector(method1));
        testassertequal(imps[0], (IMP)replacement1);
        testassertequal(source, _objc_hook_methodSetImplementationSourceMethodSetImplementation);
        hook1Called = YES;
    };

    __block BOOL hook2Called = NO;
    hook2Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, Nil);
        testassertequal(m, m1);
        testassertequal(count, 1);
        testassertequal(sels[0], @selector(method1));
        testassertequal(imps[0], (IMP)replacement1);
        testassertequal(source, _objc_hook_methodSetImplementationSourceMethodSetImplementation);
        hook2Called = YES;
    };

    IMP oldIMP1 = method_setImplementation(m1, (IMP)replacement1);

    testassert(hook1Called);
    testassert(hook2Called);
    testassertequal(objc_debug_methodSetImplementationCallCount, callCountBefore + 1);

    hook1Block = nil;
    hook2Block = nil;
    method_setImplementation(m1, oldIMP1);

    // method_exchangeImplementations
    Method m2 = class_getInstanceMethod([TestClass class], @selector(method2));
    IMP m1_imp = method_getImplementation(m1);
    IMP m2_imp = method_getImplementation(m2);

    callCountBefore = objc_debug_methodSetImplementationCallCount;

    __block int hook1CallCount = 0;
    hook1Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, Nil);
        testassertequal(count, 1);
        testassertequal(source, _objc_hook_methodSetImplementationSourceMethodExchangeImplementations);

        if (hook1CallCount == 0) {
            // First call: m1 gets m2's IMP
            testassertequal(m, m1);
            testassertequal(sels[0], @selector(method1));
            testassertequal(imps[0], m2_imp);
        } else if (hook1CallCount == 1) {
            // Second call: m2 gets m1's IMP
            testassertequal(m, m2);
            testassertequal(sels[0], @selector(method2));
            testassertequal(imps[0], m1_imp);
        } else {
            fail("hook1 called too many times");
        }
        hook1CallCount++;
    };

    __block int hook2CallCount = 0;
    hook2Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, Nil);
        testassertequal(count, 1);
        testassertequal(source, _objc_hook_methodSetImplementationSourceMethodExchangeImplementations);

        if (hook2CallCount == 0) {
            // First call: m1 gets m2's IMP
            testassertequal(m, m1);
            testassertequal(sels[0], @selector(method1));
            testassertequal(imps[0], m2_imp);
        } else if (hook2CallCount == 1) {
            // Second call: m2 gets m1's IMP
            testassertequal(m, m2);
            testassertequal(sels[0], @selector(method2));
            testassertequal(imps[0], m1_imp);
        } else {
            fail("hook2 called too many times");
        }
        hook2CallCount++;
    };

    method_exchangeImplementations(m1, m2);

    testassertequal(hook1CallCount, 2);
    testassertequal(hook2CallCount, 2);
    testassertequal(objc_debug_methodSetImplementationCallCount, callCountBefore + 2);

    // class_replaceMethod - replacing existing method
    Method m3 = class_getInstanceMethod([TestClass class], @selector(method3));

    callCountBefore = objc_debug_methodSetImplementationCallCount;

    hook1Called = NO;
    hook1Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, [TestClass class]);
        testassertequal(m, NULL);
        testassertequal(count, 1);
        testassertequal(sels[0], @selector(method2));
        testassertequal(imps[0], (IMP)replacement2);
        testassertequal(source, _objc_hook_methodSetImplementationSourceClassReplaceMethod);
        hook1Called = YES;
    };

    hook2Called = NO;
    hook2Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, [TestClass class]);
        testassertequal(m, NULL);
        testassertequal(count, 1);
        testassertequal(sels[0], @selector(method2));
        testassertequal(imps[0], (IMP)replacement2);
        testassertequal(source, _objc_hook_methodSetImplementationSourceClassReplaceMethod);
        hook2Called = YES;
    };

    class_replaceMethod([TestClass class], @selector(method2), (IMP)replacement2,
                        method_getTypeEncoding(m3));

    testassert(hook1Called);
    testassert(hook2Called);
    testassertequal(objc_debug_methodSetImplementationCallCount, callCountBefore + 1);

    // class_replaceMethod - adding new method (should not call hook)
    callCountBefore = objc_debug_methodSetImplementationCallCount;

    hook1Called = NO;
    hook1Block = ^(Class cls __unused, Method m __unused, uint32_t count __unused, const SEL *sels __unused, const IMP *imps __unused, int source __unused) {
        fail("hook1 should not be called when adding a new method");
    };

    hook2Called = NO;
    hook2Block = ^(Class cls __unused, Method m __unused, uint32_t count __unused, const SEL *sels __unused, const IMP *imps __unused, int source __unused) {
        fail("hook2 should not be called when adding a new method");
    };

    // newMethod doesn't exist, so this should add without calling the hook
    class_replaceMethod([TestClass class], @selector(newMethod), (IMP)replacement3, "v@:");

    testassert(!hook1Called);
    testassert(!hook2Called);
    testassertequal(objc_debug_methodSetImplementationCallCount, callCountBefore);

    // class_replaceMethodsBulk
    SEL bulkSELs[3] = {
        @selector(method3),
        @selector(method4),
        @selector(method5)
    };
    IMP bulkIMPs[3] = {
        (IMP)replacement3,
        (IMP)replacement4,
        (IMP)replacement5
    };
    const char *bulkTypes[3] = {
        method_getTypeEncoding(class_getInstanceMethod([TestClass class], @selector(method3))),
        method_getTypeEncoding(class_getInstanceMethod([TestClass class], @selector(method4))),
        method_getTypeEncoding(class_getInstanceMethod([TestClass class], @selector(method5)))
    };

    callCountBefore = objc_debug_methodSetImplementationCallCount;

    hook1Called = NO;
    hook1Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, [TestClass class]);
        testassertequal(m, NULL);
        testassertequal(count, 3);
        testassertequal(sels[0], @selector(method3));
        testassertequal(sels[1], @selector(method4));
        testassertequal(sels[2], @selector(method5));
        testassertequal(imps[0], (IMP)replacement3);
        testassertequal(imps[1], (IMP)replacement4);
        testassertequal(imps[2], (IMP)replacement5);
        testassertequal(source, _objc_hook_methodSetImplementationSourceClassReplaceMethodsBulk);
        hook1Called = YES;
    };

    hook2Called = NO;
    hook2Block = ^(Class cls, Method m, uint32_t count, const SEL *sels, const IMP *imps, int source) {
        testassertequal(cls, [TestClass class]);
        testassertequal(m, NULL);
        testassertequal(count, 3);
        testassertequal(sels[0], @selector(method3));
        testassertequal(sels[1], @selector(method4));
        testassertequal(sels[2], @selector(method5));
        testassertequal(imps[0], (IMP)replacement3);
        testassertequal(imps[1], (IMP)replacement4);
        testassertequal(imps[2], (IMP)replacement5);
        testassertequal(source, _objc_hook_methodSetImplementationSourceClassReplaceMethodsBulk);
        hook2Called = YES;
    };

    class_replaceMethodsBulk([TestClass class], bulkSELs, bulkIMPs, bulkTypes, 3);

    testassert(hook1Called);
    testassert(hook2Called);
    testassertequal(objc_debug_methodSetImplementationCallCount, callCountBefore + 3);

    callCountBefore = objc_debug_methodSetImplementationCallCount;

    hook1Called = NO;
    hook1Block = ^(Class cls __unused, Method m __unused, uint32_t count __unused, const SEL *sels __unused, const IMP *imps __unused, int source __unused) {
        fail("hook1 should not be called when count is 0");
    };

    hook2Called = NO;
    hook2Block = ^(Class cls __unused, Method m __unused, uint32_t count __unused, const SEL *sels __unused, const IMP *imps __unused, int source __unused) {
        fail("hook2 should not be called when count is 0");
    };

    class_replaceMethodsBulk([TestClass class], bulkSELs, bulkIMPs, bulkTypes, 0);

    testassert(!hook1Called);
    testassert(!hook2Called);
    testassertequal(objc_debug_methodSetImplementationCallCount, callCountBefore);

    succeed(__FILE__);
}
