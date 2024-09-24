// Test OBJC_DEBUG_POOL_ALLOCATION (which is also enabled by MallocStackLogging)

// TEST_ENV OBJC_DEBUG_POOL_ALLOCATION=YES OBJC_DEBUG_POOL_DEPTH=-1
// TEST_CFLAGS -framework Foundation
// TEST_CONFIG MEM=mrc OS=!exclavekit

#include "test.h"

#define FOUNDATION 0
#define NAME "rr-autorelease-stacklogging"
#define DEBUG_POOL_ALLOCATION 1

#include "rr-autorelease2.m"
