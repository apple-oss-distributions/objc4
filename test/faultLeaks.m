// TEST_CONFIG MEM=mrc, LANGUAGE=objective-c
// TEST_ENV OBJC_DEBUG_SYNC_ERRORS=Fault
/* TEST_RUN_OUTPUT
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
objc\[\d+\]: objc_sync_exit\(0x[a-fA-F0-9]+\) returned error -1
[\S\s]*0 leaks for 0 total leaked bytes[\S\s]*
OK: faultLeaks.m
END
*/

#include <objc/objc-sync.h>

#include <spawn.h>
#include <stdio.h>

#include "test.h"
#include "testroot.i"

int main() {
    id obj = [TestRoot alloc];

    // objc_sync_exit on an object that isn't locked will provoke a fault from
    // OBJC_DEBUG_SYNC_ERRORS=Fault. Do this several times to ensure any leak is
    // detected.
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);
    objc_sync_exit(obj);

    char *pidstr;
    int result = asprintf(&pidstr, "%u", getpid());
    testassert(result);

    extern char **environ;
    char *argv[] = { "/usr/bin/leaks", pidstr, NULL };
    pid_t pid;
    result = posix_spawn(&pid, "/usr/bin/leaks", NULL, NULL, argv, environ);
    if (result) {
        perror("posix_spawn");
        exit(1);
    }
    wait4(pid, NULL, 0, NULL);

    free(pidstr);
    [obj release];

    succeed(__FILE__);
}
