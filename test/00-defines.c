/*
TEST_CONFIG MEM=mrc LANGUAGE=c

TEST_BUILD
$DIR/defines.sh '$C{TESTINCLUDEDIR}' '$C{TESTLOCALINCLUDEDIR}' '$C{COMPILE_C}' '$C{COMPILE_CXX}' '$C{COMPILE_M}' '$C{COMPILE_MM}' '$VERBOSE'
$C{COMPILE_C} $DIR/00-defines.c -o 00-defines.exe
END
 */


#include "test.h"

int main()
{
    succeed(__FILE__);
}
