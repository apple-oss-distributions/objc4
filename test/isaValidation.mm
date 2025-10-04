// TEST_CONFIG MEM=mrc

#define TEST_CALLS_OPERATOR_NEW

#include "test.h"
#include "testroot.i"
#include <ptrauth.h>
#include <spawn.h>
#include <sstream>
#include <string>
#include <vector>

@protocol P
@end

extern char **environ;

id dummyIMP(id self, SEL _cmd) { (void)_cmd; return self; }

char *dupeName(Class cls) {
    char *name;
    asprintf(&name, "%sDuplicate", class_getName(cls));
    return name;
}

typedef void (^TestBlock)(Class);
struct TestCase {
    const char *name;
    TestBlock block;
};

#define NAMED_TESTCASE(name, ...) { name, ^(Class cls) { __VA_ARGS__; } }
#define TESTCASE(...) NAMED_TESTCASE(#__VA_ARGS__, __VA_ARGS__)
#define TESTCASE_NOMETA(...) \
    NAMED_TESTCASE( #__VA_ARGS__, if(class_isMetaClass(cls)) return; __VA_ARGS__; )
#define TESTCASE_OBJ(...) NAMED_TESTCASE( \
    #__VA_ARGS__, \
    if(class_isMetaClass(cls)) return;          \
    id obj = [TestRoot alloc]; \
    *(Class __ptrauth_objc_isa_pointer *)obj = cls; \
    __VA_ARGS__; \
)

struct TestCase TestCases[] = {
    TESTCASE_OBJ(object_getMethodImplementation(obj, @selector(init))),

    TESTCASE(class_getInstanceMethod(cls, @selector(init))),
    TESTCASE(class_getMethodImplementation(cls, @selector(init))),
    TESTCASE(class_respondsToSelector(cls, @selector(init))),
    TESTCASE(class_conformsToProtocol(cls, @protocol(P))),
    TESTCASE(free(class_copyProtocolList(cls, NULL))),
    TESTCASE(class_getProperty(cls, "x")),
    TESTCASE(free(class_copyPropertyList(cls, NULL))),
    TESTCASE(class_addMethod(cls, @selector(nop), (IMP)dummyIMP, "v@:")),
    TESTCASE(class_replaceMethod(cls, @selector(nop), (IMP)dummyIMP, "v@:")),
    TESTCASE(class_addIvar(cls, "x", sizeof(int), sizeof(int), @encode(int))),
    TESTCASE(class_addProtocol(cls, @protocol(P))),
    TESTCASE(class_addProperty(cls, "x", NULL, 0)),
    TESTCASE(class_replaceProperty(cls, "x", NULL, 0)),
    TESTCASE_NOMETA(class_setIvarLayout(cls, NULL)),
    TESTCASE(class_setWeakIvarLayout(cls, NULL)),
    TESTCASE_NOMETA(objc_registerClassPair(cls)),
    TESTCASE_NOMETA(objc_duplicateClass(cls, dupeName(cls), 0)),
    TESTCASE_NOMETA(objc_disposeClassPair(cls)),
};

#define CHECK(expr) \
    do { \
        if ((expr) < 0) { \
            perror(#expr); \
            exit(1); \
        } \
    } while(0)

void parent(char *argv0)
{
    int testCount = sizeof(TestCases) / sizeof(*TestCases);
    for (int i = 0; i < testCount; i++) {
        char *testIndex;
        asprintf(&testIndex, "%d", i);
        char *argvSpawn[] = {
            argv0,
            testIndex,
            NULL
        };

        int outputPipe[2];
        CHECK(pipe(outputPipe));
        int pipeRead = outputPipe[0];
        int pipeWrite = outputPipe[1];

        posix_spawn_file_actions_t fileActions;
        posix_spawn_file_actions_init(&fileActions);
        posix_spawn_file_actions_adddup2(&fileActions, pipeWrite, STDOUT_FILENO);
        posix_spawn_file_actions_adddup2(&fileActions, pipeWrite, STDERR_FILENO);

        pid_t pid;
        CHECK(posix_spawn(&pid, argv0, &fileActions, NULL, argvSpawn, environ));

        free(testIndex);
        CHECK(posix_spawn_file_actions_destroy(&fileActions));
        close(pipeWrite);

        std::string output;
        while (true) {
            // This could be more efficient, but the output isn't big enough to
            // matter.
            constexpr size_t readSize = 42;
            char buffer[readSize];

            ssize_t readResult = read(pipeRead, buffer, readSize);
            if (readResult < 0) {
                if (errno == EINTR || errno == EAGAIN)
                    continue;
                CHECK(readResult); // Always fails, we just want the error reporting.
            }

            if (readResult == 0)
                break;

            output.append(buffer, readResult);
        }
        close(pipeRead);

        // Gather lines as separate strings.
        std::vector<std::string> outputLines;
        std::stringstream outputStream{output};
        std::string line;
        while (std::getline(outputStream, line))
            outputLines.push_back(line);

        bool isGood = false;

        // See if the last line is what we expect.
        if (outputLines.size() > 0) {
            for (size_t lastLineIndex = outputLines.size() - 1; lastLineIndex > 0; lastLineIndex--) {
                auto &line = outputLines[lastLineIndex];

                // Skip empty lines and "unknown class" errors.
                if (line.size() == 0)
                    continue;
                if (line.find("Attempt to use unknown class") != std::string::npos)
                    continue;

                std::string expected = "Completed test on good classes.";
                if (line == expected)
                    isGood = true;
                break;
            }
        }

        if (!isGood) {
            fprintf(stderr, "BAD: unexpected output from child process:\n%s\n", output.c_str());
        }

        CHECK(waitpid(pid, NULL, 0));
    }
    succeed(__FILE__);
}

void child(char *argv1)
{
    long index = strtol(argv1, NULL, 10);
    struct TestCase testCase = TestCases[index];
    TestBlock block = testCase.block;

    const char *name = testCase.name;
    if (strncmp(name, "free(", 5) == 0)
        name += 5;
    const char *paren = strchr(name, '(');
    long len = paren != NULL ? paren - name : strlen(name);
    fprintf(stderr, "Testing %.*s\n", (int)len, name);

    // Make sure plain classes work.
    block([TestRoot class]);
    block(object_getClass([TestRoot class]));

    // And framework classes.
    block([NSObject class]);
    block(object_getClass([NSObject class]));

    // Test a constructed, unregistered class.
    Class allocatedClass = objc_allocateClassPair([TestRoot class],
                                                  "AllocatedTestClass",
                                                  0);
    class_getMethodImplementation(allocatedClass, @selector(self));
    block(object_getClass(allocatedClass));
    block(allocatedClass);

    // Test a constructed, registered class. (Do this separately so
    // test cases can dispose of the class if needed.)
    allocatedClass = objc_allocateClassPair([TestRoot class],
                                            "AllocatedTestClass2",
                                            0);
    objc_registerClassPair(allocatedClass);
    block(object_getClass(allocatedClass));
    block(allocatedClass);

    // Test a duplicated class.

    Class duplicatedClass = objc_duplicateClass([TestRoot class],
                                                "DuplicateClass",
                                                0);
    block(object_getClass(duplicatedClass));
    block(duplicatedClass);

    fprintf(stderr, "Completed test on good classes.\n");

    // Test a fake class.
    Class templateClass = objc_allocateClassPair([TestRoot class],
                                                 "TemplateClass",
                                                 0);
    void *fakeClass = malloc(malloc_size(templateClass));
    memcpy(fakeClass, templateClass, malloc_size(templateClass));
    *(Class __ptrauth_objc_isa_pointer *)fakeClass = object_getClass(templateClass);
    block((Class)fakeClass);
    fail("Should have died on the fake class");
}

int main(int argc, char **argv)
{
    // We want to run a bunch of tests, all of which end in _objc_fatal
    // (at least if they succeed). Spawn one subprocess per test and
    // have the parent process manage it all. The test will begin by
    // running parent(), which will repeatedly re-spawn this program to
    // call child() with the index of the test to run.
    if (argc == 1) {
        parent(argv[0]);
    } else {
        child(argv[1]);
    }
}
