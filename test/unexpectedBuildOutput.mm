// TEST_CONFIG MEM=arc
// TEST_CFLAGS -framework Foundation

#include "test.h"
#include <Foundation/Foundation.h>

int main()
{
    NSString *unexpectedBuildOutputFile = @"../../unexpected-build-output";
    if ([[NSFileManager defaultManager] fileExistsAtPath: unexpectedBuildOutputFile]) {
        NSData *data = [NSData dataWithContentsOfFile: unexpectedBuildOutputFile];
        if (!data)
            data = [@"<unable to read unexpected-build-output>" dataUsingEncoding: NSUTF8StringEncoding];

        [[NSFileHandle fileHandleWithStandardOutput] writeData: data];

        fail(__FILE__);
    } else {
        succeed(__FILE__);
    }
}
