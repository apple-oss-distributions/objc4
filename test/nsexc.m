/* 
need exception-safe ARC for exception deallocation tests 
TEST_CONFIG  MEM=mrc,arc LANGUAGE=objc,objc++
TEST_CFLAGS -fobjc-arc-exceptions -framework Foundation
*/

#define USE_FOUNDATION 1
#include "exc.m"
