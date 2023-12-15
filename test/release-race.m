// TEST_CONFIG MEM=mrc LANGUAGE=objective-c

#import <dispatch/dispatch.h>
#import <objc/NSObject.h>
#import "test.h"

@interface MyEncoder : NSObject
{
    int x;
}
@end

@implementation MyEncoder

- (id)init
{
    x = 1;
    return self;
}

- (void)close
{
    x = 2;
    [self release];
}

- (void)dealloc
{
    // Make sure that release has the appropriate barriers so that we're
    // guaranteed to see the x=2 above.
    testassertequal(x, 2);
    [super dealloc];
}
@end

int main() {
    for (unsigned long long i = 0; i < 100000000000ULL; i++) {
        if (i % 100000 == 0)
            testprintf("%llu\n", i);

        MyEncoder *enc = [MyEncoder new];
        [enc retain];   // For the first dispatch
        [enc retain];   // For the second one
        MyEncoder __unsafe_unretained *enc_weak = enc;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [enc_weak close];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [enc_weak release];
        });
        [enc release]; // Drop top level reference
    }
    succeed(__FILE__);
}
