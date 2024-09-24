// See instructions in weak.h

#include <complex.h>

#include "test.h"
#include "weak.h"

// In ObjC++ mode we won't get `complex` and `I`. Fall back to ordinary real
// types in that mode.
#ifndef complex
#define complex
#define I 1.0
#endif

struct BigStruct {
    long a, b, c, d, e, f, g;
};

// Subclass of superclass that isn't there
@interface MyMissingSuper : MissingSuper
+(int) method;
@end
@implementation MyMissingSuper
+(int) method { return 1+[super method]; }
+(void) load { state++; }

+ (struct BigStruct)stret { return (struct BigStruct){ 1, 2, 3, 4, 5, 6, 7 }; }
+ (long double)fpret { return 42.0; }
+ (long double complex)fp2ret { return 42 + 43 * I; }

@end

// Subclass of subclass of superclass that isn't there
@interface MyMissingSub : MyMissingSuper
+(int) method;
@end
@implementation MyMissingSub
+(int) method { return 1+[super method]; }
+(void) load { state++; }
@end

// Another subclass of superclass that isn't there, for additional testing.
@interface MyMissingSub2 : MyMissingSuper
+(int) method;
@end
@implementation MyMissingSub2
+(int) method { return 1+[super method]; }
@end

// Subclass of real superclass
@interface MyNotMissingSuper : NotMissingSuper
+(int) method;
@end
@implementation MyNotMissingSuper
+(int) method { return 1+[super method]; }
+(void) load { state++; }
@end

// Subclass of subclass of superclass that isn't there
@interface MyNotMissingSub : MyNotMissingSuper
+(int) method;
@end
@implementation MyNotMissingSub
+(int) method { return 1+[super method]; }
+(void) load { state++; }
@end

// Categories on all of the above
@interface MissingRoot (MissingRootExtras)
+(void)load;
+(int) cat_method;
@end
@implementation MissingRoot (MissingRootExtras)
+(void)load { state++; }
+(int) cat_method { return 40; }
@end

@interface MissingSuper (MissingSuperExtras)
+(void)load;
+(int) cat_method;
@end
@implementation MissingSuper (MissingSuperExtras)
+(void)load { state++; }
+(int) cat_method { return 1+[super cat_method]; }
@end

@interface MyMissingSuper (MyMissingSuperExtras)
+(void)load;
+(int) cat_method;
@end
@implementation MyMissingSuper (MyMissingSuperExtras)
+(void)load { state++; }
+(int) cat_method { return 1+[super cat_method]; }
@end

@interface MyMissingSub (MyMissingSubExtras)
+(void)load;
+(int) cat_method;
@end
@implementation MyMissingSub (MyMissingSubExtras)
+(void)load { state++; }
+(int) cat_method { return 1+[super cat_method]; }
@end


@interface NotMissingRoot (NotMissingRootExtras)
+(void)load;
+(int) cat_method;
@end
@implementation NotMissingRoot (NotMissingRootExtras)
+(void)load { state++; }
+(int) cat_method { return 30; }
@end

@interface NotMissingSuper (NotMissingSuperExtras)
+(void)load;
+(int) cat_method;
@end
@implementation NotMissingSuper (NotMissingSuperExtras)
+(void)load { state++; }
+(int) cat_method { return 1+[super cat_method]; }
@end

@interface MyNotMissingSuper (MyNotMissingSuperExtras)
+(void)load;
+(int) cat_method;
@end
@implementation MyNotMissingSuper (MyNotMissingSuperExtras)
+(void)load { state++; }
+(int) cat_method { return 1+[super cat_method]; }
@end

@interface MyNotMissingSub (MyNotMissingSubExtras)
+(void)load;
+(int) cat_method;
@end
@implementation MyNotMissingSub (MyNotMissingSubExtras)
+(void)load { state++; }
+(int) cat_method { return 1+[super cat_method]; }
@end


#if WEAK_FRAMEWORK
#   define TESTIVAR(cond) testassert(cond)
#else
#   define TESTIVAR(cond) /* rdar */
#endif

static BOOL classInList(__unsafe_unretained Class classes[], const char *name)
{
    for (int i = 0; classes[i] != nil; i++) {
        if (0 == strcmp(class_getName(classes[i]), name)) return YES;
    }
    return NO;
}

static BOOL classInNameList(const char **names, const char *name)
{
    const char **cp;
    for (cp = names; *cp; cp++) {
        if (0 == strcmp(*cp, name)) return YES;
    }
    return NO;
}

int main(int argc __unused, char **argv)
{
    BOOL weakMissing;
    if (strstr(argv[0], "-not-missing.exe")) {
        weakMissing = NO;
    } else if (strstr(argv[0], "-missing.exe")) {
        weakMissing = YES;
    } else {
        fail("executable name must be weak*-missing.exe or weak*-not-missing.exe");
    }

    // class and category +load methods
    if (weakMissing) testassert(state == 8);
    else testassert(state == 16);

    // Loop to check both the uncached and cached cases. Do it more than twice
    // just in case we somehow managed to clear caches at just the wrong time,
    // and out of general paranoia.
    for (int i = 0; i < 10; i++) {
        state = 0;

        // classes
        testassert([NotMissingRoot class]);
        testassert([NotMissingSuper class]);
        testassert([MyNotMissingSuper class]);
        testassert([MyNotMissingSub class]);
        if (weakMissing) {
            // Test MyMissingSub2 first, to ensure that we correctly handle the case
            // where a subclass is messaged before we've noticed that the superclass
            // should be disabled.
            testassertnil([MyMissingSub2 class]);
            testassertnil([MissingRoot class]);
            testassertnil([MissingSuper class]);
            testassertnil([MyMissingSuper class]);
            testassertnil([MyMissingSub class]);
        } else {
            testassert([MissingRoot class]);
            testassert([MissingSuper class]);
            testassert([MyMissingSuper class]);
            testassert([MyMissingSub class]);
        }

        // objc_getClass
        testassert(objc_getClass("NotMissingRoot"));
        testassert(objc_getClass("NotMissingSuper"));
        testassert(objc_getClass("MyNotMissingSuper"));
        testassert(objc_getClass("MyNotMissingSub"));
        if (weakMissing) {
            testassert(objc_getClass("MissingRoot") == nil);
            testassert(objc_getClass("MissingSuper") == nil);
            testassert(objc_getClass("MyMissingSuper") == nil);
            testassert(objc_getClass("MyMissingSub") == nil);
        } else {
            testassert(objc_getClass("MissingRoot"));
            testassert(objc_getClass("MissingSuper"));
            testassert(objc_getClass("MyMissingSuper"));
            testassert(objc_getClass("MyMissingSub"));
        }

        // class list
        union {
            Class *c;
            void *v;
        } classes;
        classes.c = objc_copyClassList(NULL);
        testassert(classInList(classes.c, "NotMissingRoot"));
        testassert(classInList(classes.c, "NotMissingSuper"));
        testassert(classInList(classes.c, "MyNotMissingSuper"));
        testassert(classInList(classes.c, "MyNotMissingSub"));
        if (weakMissing) {
            testassert(! classInList(classes.c, "MissingRoot"));
            testassert(! classInList(classes.c, "MissingSuper"));
            testassert(! classInList(classes.c, "MyMissingSuper"));
            testassert(! classInList(classes.c, "MyMissingSub"));
        } else {
            testassert(classInList(classes.c, "MissingRoot"));
            testassert(classInList(classes.c, "MissingSuper"));
            testassert(classInList(classes.c, "MyMissingSuper"));
            testassert(classInList(classes.c, "MyMissingSub"));
        }
        free(classes.v);

        // class name list
        const char *image = class_getImageName(objc_getClass("NotMissingRoot"));
        testassert(image);
        const char **names = objc_copyClassNamesForImage(image, NULL);
        testassert(names);
        testassert(classInNameList(names, "NotMissingRoot"));
        testassert(classInNameList(names, "NotMissingSuper"));
        if (weakMissing) {
            testassert(! classInNameList(names, "MissingRoot"));
            testassert(! classInNameList(names, "MissingSuper"));
        } else {
            testassert(classInNameList(names, "MissingRoot"));
            testassert(classInNameList(names, "MissingSuper"));
        }
        free(names);

        image = class_getImageName(objc_getClass("MyNotMissingSub"));
        testassert(image);
        names = objc_copyClassNamesForImage(image, NULL);
        testassert(names);
        testassert(classInNameList(names, "MyNotMissingSuper"));
        testassert(classInNameList(names, "MyNotMissingSub"));
        if (weakMissing) {
            testassert(! classInNameList(names, "MyMissingSuper"));
            testassert(! classInNameList(names, "MyMissingSub"));
        } else {
            testassert(classInNameList(names, "MyMissingSuper"));
            testassert(classInNameList(names, "MyMissingSub"));
        }
        free(names);

        // methods
        testassert(20 == [NotMissingRoot method]);
        testassert(21 == [NotMissingSuper method]);
        testassert(22 == [MyNotMissingSuper method]);
        testassert(23 == [MyNotMissingSub method]);
        if (weakMissing) {
            testassert(0 == [MissingRoot method]);
            testassert(0 == [MissingSuper method]);
            testassert(0 == [MyMissingSuper method]);
            testassert(0 == [MyMissingSub method]);
        } else {
            testassert(10 == [MissingRoot method]);
            testassert(11 == [MissingSuper method]);
            testassert(12 == [MyMissingSuper method]);
            testassert(13 == [MyMissingSub method]);
        }

        // category methods
        testassert(30 == [NotMissingRoot cat_method]);
        testassert(31 == [NotMissingSuper cat_method]);
        testassert(32 == [MyNotMissingSuper cat_method]);
        testassert(33 == [MyNotMissingSub cat_method]);
        if (weakMissing) {
            testassert(0 == [MissingRoot cat_method]);
            testassert(0 == [MissingSuper cat_method]);
            testassert(0 == [MyMissingSuper cat_method]);
            testassert(0 == [MyMissingSub cat_method]);
        } else {
            testassert(40 == [MissingRoot cat_method]);
            testassert(41 == [MissingSuper cat_method]);
            testassert(42 == [MyMissingSuper cat_method]);
            testassert(43 == [MyMissingSub cat_method]);
        }

        // allocations and ivars
        id obj;
        NotMissingSuper *obj2;
        MissingSuper *obj3;
        testassert((obj = [[NotMissingRoot alloc] init]));
        RELEASE_VAR(obj);
        testassert((obj2 = [[NotMissingSuper alloc] init]));
        TESTIVAR(obj2->ivar == 200);
        RELEASE_VAR(obj2);
        testassert((obj2 = [[MyNotMissingSuper alloc] init]));
        TESTIVAR(obj2->ivar == 200);
        RELEASE_VAR(obj2);
        testassert((obj2 = [[MyNotMissingSub alloc] init]));
        TESTIVAR(obj2->ivar == 200);
        RELEASE_VAR(obj2);
        if (weakMissing) {
            testassert([[MissingRoot alloc] init] == nil);
            testassert([[MissingSuper alloc] init] == nil);
            testassert([[MyMissingSuper alloc] init] == nil);
            testassert([[MyMissingSub alloc] init] == nil);
        } else {
            testassert((obj = [[MissingRoot alloc] init]));
            RELEASE_VAR(obj);
            testassert((obj3 = [[MissingSuper alloc] init]));
            TESTIVAR(obj3->ivar == 100);
            RELEASE_VAR(obj3);
            testassert((obj3 = [[MyMissingSuper alloc] init]));
            TESTIVAR(obj3->ivar == 100);
            RELEASE_VAR(obj3);
            testassert((obj3 = [[MyMissingSub alloc] init]));
            TESTIVAR(obj3->ivar == 100);
            RELEASE_VAR(obj3);
        }

        // msgSend variants
        if (weakMissing) {
            // Disable these until the compiler starts zeroing structs when
            // messaging non-nil classes. rdar://120010990
            // struct BigStruct big = [MyMissingSuper stret];
            // testassertequal(big.a, 0);
            // testassertequal(big.b, 0);
            // testassertequal(big.c, 0);
            // testassertequal(big.d, 0);
            // testassertequal(big.e, 0);
            // testassertequal(big.f, 0);
            // testassertequal(big.g, 0);

            testassertequal([MyMissingSuper fpret], 0.0);
            testassertequal([MyMissingSub fpret], 0.0);

            testassertequal([MyMissingSuper fp2ret], 0.0);
            testassertequal([MyMissingSub fp2ret], 0.0);
        } else {
            struct BigStruct big = [MyMissingSuper stret];
            testassertequal(big.a, 1);
            testassertequal(big.b, 2);
            testassertequal(big.c, 3);
            testassertequal(big.d, 4);
            testassertequal(big.e, 5);
            testassertequal(big.f, 6);
            testassertequal(big.g, 7);

            testassertequal([MyMissingSuper fpret], 42.0);
            testassertequal([MyMissingSub fpret], 42.0);

            testassertequal([MyMissingSuper fp2ret], 42 + 43 * I);
            testassertequal([MyMissingSub fp2ret], 42 + 43 * I);
        }
    }

    *strrchr(argv[0], '.') = 0;
    succeed(basename(argv[0]));
    return 0;
}

