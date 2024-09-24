// TEST_CONFIG
// TEST_ENV OBJC_DEBUG_POOL_DEPTH=-1

#include "test.h"
#include <objc/objc-exception.h>
#include <objc/NSObject.h>

static int state;

@interface Foo : NSObject @end
@interface Bar : NSObject @end

@interface Foo (Unimplemented)
+(void)method;
@end

@implementation Bar @end

@implementation Foo

-(void)check { state++; }
+(void)check { testassert(!"caught class object, not instance"); }

static id exc;

static void handler(id unused, void *ctx) __attribute__((used));
static void handler(id unused __unused, void *ctx __unused)
{
    testassert(state == 3); state++;
}

+(BOOL) resolveClassMethod:(SEL)__unused name
{
    testassertequal(state, 1); state++;
#if TARGET_OS_EXCLAVEKIT
    state++;  // handler would have done this
#elif TARGET_OS_OSX
    objc_addExceptionHandler(&handler, 0);
    testassertequal(state, 2); 
#else
    state++;  // handler would have done this
#endif
    state++;
    exc = [Foo new];
    @throw exc;
}


@end

int main()
{
    // unwind exception and alt handler through objc_msgSend()

    PUSH_POOL {

#if TARGET_OS_EXCLAVEKIT
        const int count = 256;
#else
        const int count = is_guardmalloc() ? 1000 : 100000;
#endif
        state = 0;
        for (int i = 0; i < count; i++) {
            @try {
                testassertequal(state, 0); state++;
                [Foo method];
                testunreachable();
            } @catch (Bar *e) {
                testunreachable();
            } @catch (Foo *e) {
                testassertequal(e, exc);
                testassertequal(state, 4); state++;
                testassertequal(state, 5); [e check];  // state++
                RELEASE_VAR(exc);
            } @catch (id e) {
                testunreachable();
            } @catch (...) {
                testunreachable();
            } @finally {
                testassertequal(state, 6); state++;
            }
            testassertequal(state, 7); state = 0;
        }

    } POP_POOL;

    succeed(__FILE__);
}
