/*
TEST_RUN_OUTPUT
objc\[[0-9]+\]: Class of category TestCategory at 0x[a-fA-f0-9]+ in .*rootMissingCategoryClass.exe is set to 0xbad4007, indicating it is missing from an installed root
END
*/

#include "class-structures.h"
#include "test.h"

#include <objc/objc-abi.h>

#define BAD_ROOT_ADDRESS 0xbad4007

static struct ObjCCategory testCategory = {
    "TestCategory",
    (struct ObjCClass *)BAD_ROOT_ADDRESS
};

static struct ObjCCategory *testCategoryListEntry __attribute__((used)) __attribute__((section("__DATA, __objc_catlist"))) = &testCategory;


int main() {
    fail("This test is supposed to crash before main()");
}
