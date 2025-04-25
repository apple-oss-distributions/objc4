// TEST_CONFIG MEM=mrc

#include "test.h"

#include <complex.h>

#include <objc/runtime.h>
#include <objc/message.h>

const id ID_RESULT = (id)0x12345678;
const long long LL_RESULT = __LONG_LONG_MAX__ - 2LL*__INT_MAX__;
const double FP_RESULT = __DBL_MIN__ + __DBL_EPSILON__;
const long double LD_RESULT = __LDBL_MIN__ + __LDBL_EPSILON__;
const long double complex LDC_RESULT = LD_RESULT + LD_RESULT * I;
// STRET_RESULT in test.h


static int state = 0;
static id receiver;

OBJC_ROOT_CLASS
@interface Super { id isa; } @end

@interface Super (Forwarded)
+(id)idret:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(id)idre2:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(id)idre3:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long long)llret:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long long)llre2:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long long)llre3:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(struct stret)stret:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(struct stret)stre2:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(struct stret)stre3:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(double)fpret:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(double)fpre2:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(double)fpre3:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long double)ldret:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long double)ldre2:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long double)ldre3:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long double complex)ldcret:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long double complex)ldcre2:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

+(long double complex)ldcre3:
   (long)i1 :(long)i2 :(long)i3 :(long)i4 :(long)i5 :(long)i6 :(long)i7 :(long)i8 :(long)i9 :(long)i10 :(long)i11 :(long)i12 :(long)i13  :(double)f1 :(double)f2 :(double)f3 :(double)f4 :(double)f5 :(double)f6 :(double)f7 :(double)f8 :(double)f9 :(double)f10 :(double)f11 :(double)f12 :(double)f13 :(double)f14 :(double)f15;

@end


long long forward_handler(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15)
{
#if __arm64__
# if __LP64__
#   define p "x"  // true arm64
# else
#   define p "w"  // arm64_32
# endif
    void *struct_addr;
    __asm__ volatile("mov %" p "0, " p "8" : "=r" (struct_addr) : : p "8");
#endif

    testassertequal(self, receiver);

    testassertequal(i1, 1);
    testassertequal(i2, 2);
    testassertequal(i3, 3);
    testassertequal(i4, 4);
    testassertequal(i5, 5);
    testassertequal(i6, 6);
    testassertequal(i7, 7);
    testassertequal(i8, 8);
    testassertequal(i9, 9);
    testassertequal(i10, 10);
    testassertequal(i11, 11);
    testassertequal(i12, 12);
    testassertequal(i13, 13);

    testassertequal(f1, 1.0);
    testassertequal(f2, 2.0);
    testassertequal(f3, 3.0);
    testassertequal(f4, 4.0);
    testassertequal(f5, 5.0);
    testassertequal(f6, 6.0);
    testassertequal(f7, 7.0);
    testassertequal(f8, 8.0);
    testassertequal(f9, 9.0);
    testassertequal(f10, 10.0);
    testassertequal(f11, 11.0);
    testassertequal(f12, 12.0);
    testassertequal(f13, 13.0);
    testassertequal(f14, 14.0);
    testassertequal(f15, 15.0);

    if (_cmd == @selector(idret::::::::::::::::::::::::::::)  ||
        _cmd == @selector(idre2::::::::::::::::::::::::::::)  ||
        _cmd == @selector(idre3::::::::::::::::::::::::::::))
    {
        union {
            id idval;
            long long llval;
        } result;
        testassertequal(state, 11);
        state = 12;
        result.idval = ID_RESULT;
        return result.llval;
    }
    else if (_cmd == @selector(llret::::::::::::::::::::::::::::)  ||
             _cmd == @selector(llre2::::::::::::::::::::::::::::)  ||
             _cmd == @selector(llre3::::::::::::::::::::::::::::))
    {
        testassertequal(state, 13);
        state = 14;
        return LL_RESULT;
    }
    else if (_cmd == @selector(fpret::::::::::::::::::::::::::::)  ||
             _cmd == @selector(fpre2::::::::::::::::::::::::::::)  ||
             _cmd == @selector(fpre3::::::::::::::::::::::::::::))
    {
        testassertequal(state, 15);
        state = 16;
#if defined(__i386__)
        __asm__ volatile("fldl %0" : : "m" (FP_RESULT));
#elif defined(__x86_64__)
        __asm__ volatile("movsd %0, %%xmm0" : : "m" (FP_RESULT));
#elif defined(__arm64__)
        __asm__ volatile("ldr d0, %0" : : "m" (FP_RESULT));
#elif defined(__arm__)  &&  __ARM_ARCH_7K__
        __asm__ volatile("vld1.64 {d0}, %0" : : "m" (FP_RESULT));
#elif defined(__arm__)
        union {
            double fpval;
            long long llval;
        } result;
        result.fpval = FP_RESULT;
        return result.llval;
#else
#       error unknown architecture
#endif
        return 0;
    }
    else if (_cmd == @selector(stret::::::::::::::::::::::::::::)  ||
             _cmd == @selector(stre2::::::::::::::::::::::::::::)  ||
             _cmd == @selector(stre3::::::::::::::::::::::::::::))
    {
#if __i386__  ||  __x86_64__  ||  __arm__
        fail("stret message sent to non-stret forward_handler");
#elif __arm64_32__ || __arm64__
        testassertequal(state, 17);
        state = 18;
        memcpy(struct_addr, &STRET_RESULT, sizeof(STRET_RESULT));
        return 0;
#else
#       error unknown architecture
#endif
    }
    else if (_cmd == @selector(ldret::::::::::::::::::::::::::::)  ||
             _cmd == @selector(ldre2::::::::::::::::::::::::::::)  ||
             _cmd == @selector(ldre3::::::::::::::::::::::::::::))
    {
        testassertequal(state, 19);
        state = 20;
#if defined(__x86_64__)
        __asm__ volatile("fldt %0" : : "m" (LD_RESULT));
#elif defined(__arm64__)
        __asm__ volatile("ldr d0, %0" : : "m" (FP_RESULT));
#else
#       error unknown architecture
#endif
        return 0;
    }
    else if (_cmd == @selector(ldcret::::::::::::::::::::::::::::)  ||
             _cmd == @selector(ldcre2::::::::::::::::::::::::::::)  ||
             _cmd == @selector(ldcre3::::::::::::::::::::::::::::))
    {
        testassertequal(state, 21);
        state = 22;
#if defined(__x86_64__)
        long double realPart = creall(LDC_RESULT);
        long double imagPart = cimagl(LDC_RESULT);
        __asm__ volatile("fldt %0" : : "m" (realPart));
        __asm__ volatile("fldt %0" : : "m" (imagPart));
#elif defined(__arm64__)
        long double realPart = creall(LDC_RESULT);
        long double imagPart = cimagl(LDC_RESULT);
        __asm__ volatile("ldr d0, %0" : : "m" (realPart));
        __asm__ volatile("ldr d1, %0" : : "m" (imagPart));
#else
#       error unknown architecture
#endif
        return 0;
    }
    else {
        fail("unknown selector %s in forward_handler", sel_getName(_cmd));
    }
}


struct stret forward_stret_handler(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15)
{
    testassertequal(self, receiver);

    testassertequal(i1, 1);
    testassertequal(i2, 2);
    testassertequal(i3, 3);
    testassertequal(i4, 4);
    testassertequal(i5, 5);
    testassertequal(i6, 6);
    testassertequal(i7, 7);
    testassertequal(i8, 8);
    testassertequal(i9, 9);
    testassertequal(i10, 10);
    testassertequal(i11, 11);
    testassertequal(i12, 12);
    testassertequal(i13, 13);

    testassertequal(f1, 1.0);
    testassertequal(f2, 2.0);
    testassertequal(f3, 3.0);
    testassertequal(f4, 4.0);
    testassertequal(f5, 5.0);
    testassertequal(f6, 6.0);
    testassertequal(f7, 7.0);
    testassertequal(f8, 8.0);
    testassertequal(f9, 9.0);
    testassertequal(f10, 10.0);
    testassertequal(f11, 11.0);
    testassertequal(f12, 12.0);
    testassertequal(f13, 13.0);
    testassertequal(f14, 14.0);
    testassertequal(f15, 15.0);

    if (_cmd == @selector(idret::::::::::::::::::::::::::::)  ||
        _cmd == @selector(idre2::::::::::::::::::::::::::::)  ||
        _cmd == @selector(idre3::::::::::::::::::::::::::::)  ||
        _cmd == @selector(llret::::::::::::::::::::::::::::)  ||
        _cmd == @selector(llre2::::::::::::::::::::::::::::)  ||
        _cmd == @selector(llre3::::::::::::::::::::::::::::)  ||
        _cmd == @selector(fpret::::::::::::::::::::::::::::)  ||
        _cmd == @selector(fpre2::::::::::::::::::::::::::::)  ||
        _cmd == @selector(fpre3::::::::::::::::::::::::::::))
    {
        fail("non-stret selector %s sent to forward_stret_handler", sel_getName(_cmd));
    }
    else if (_cmd == @selector(stret::::::::::::::::::::::::::::)  ||
             _cmd == @selector(stre2::::::::::::::::::::::::::::)  ||
             _cmd == @selector(stre3::::::::::::::::::::::::::::))
    {
        testassertequal(state, 17);
        state = 18;
        return STRET_RESULT;
    }
    else {
        fail("unknown selector %s in forward_stret_handler", sel_getName(_cmd));
    }

}


@implementation Super
+(void)initialize { }
+(id)class { return self; }
@end

typedef id (*id_fn_t)(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);

typedef long long (*ll_fn_t)(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);

typedef double (*fp_fn_t)(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);

typedef long double (*ld_fn_t)(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);

typedef long double complex (*ldc_fn_t)(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);

typedef struct stret (*st_fn_t)(id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);

#if __x86_64__
typedef struct stret * (*fake_st_fn_t)(struct stret *, id self, SEL _cmd, long i1, long i2, long i3, long i4, long i5, long i6, long i7, long i8, long i9, long i10, long i11, long i12, long i13, double f1, double f2, double f3, double f4, double f5, double f6, double f7, double f8, double f9, double f10, double f11, double f12, double f13, double f14, double f15);
#endif

__BEGIN_DECLS
extern void *getSP(void);
__END_DECLS

#if defined(__x86_64__)
    asm(".text \n _getSP: movq %rsp, %rax \n retq \n");
#elif defined(__i386__)
    asm(".text \n _getSP: movl %esp, %eax \n ret \n");
#elif defined(__arm__)
    asm(".text \n .thumb \n .thumb_func _getSP \n "
        "_getSP: mov r0, sp \n bx lr \n");
#elif defined(__arm64__)
    asm(".text \n _getSP: mov x0, sp \n ret \n");
#else
#   error unknown architecture
#endif

int main()
{
    id idval;
    long long llval;
    struct stret stval;
#if __x86_64__
    struct stret *stptr;
#endif
    double fpval;
    long double ldval;
    long double complex ldcval;
    void *sp1 = (void*)1;
    void *sp2 = (void*)2;

    st_fn_t stret_fwd;
#if __arm64__
    stret_fwd = (st_fn_t)_objc_msgForward;
#else
    stret_fwd = (st_fn_t)_objc_msgForward_stret;
#endif

    receiver = [Super class];

    // Test user-defined forward handler

    objc_setForwardHandler((void*)&forward_handler, (void*)&forward_stret_handler);

    state = 11;
    sp1 = getSP();
    idval = [Super idre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 12);
    testassertequal(idval, ID_RESULT);

    state = 13;
    sp1 = getSP();
    llval = [Super llre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 14);
    testassertequal(llval, LL_RESULT);

    state = 15;
    sp1 = getSP();
    fpval = [Super fpre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 16);
    testassertequal(fpval, FP_RESULT);

    state = 17;
    sp1 = getSP();
    stval = [Super stre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));

#if __x86_64__
    // check stret return register
    state = 17;
    sp1 = getSP();
    stptr = ((fake_st_fn_t)objc_msgSend_stret)(&stval, [Super class], @selector(stre3::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));
    testassertequal(stptr, &stval);
#endif

    state = 19;
    sp1 = getSP();
    ldval = [Super ldre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 20);
    testassertequal(ldval, LD_RESULT);

    state = 21;
    sp1 = getSP();
    ldcval = [Super ldcre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 22);
    testassertequal(ldcval, LDC_RESULT);


    // Test user-defined forward handler, cached

    state = 11;
    sp1 = getSP();
    idval = [Super idre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 12);
    testassertequal(idval, ID_RESULT);

    state = 13;
    sp1 = getSP();
    llval = [Super llre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 14);
    testassertequal(llval, LL_RESULT);

    state = 15;
    sp1 = getSP();
    fpval = [Super fpre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 16);
    testassertequal(fpval, FP_RESULT);

    state = 17;
    sp1 = getSP();
    stval = [Super stre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));

#if __x86_64__
    // check stret return register
    state = 17;
    sp1 = getSP();
    stptr = ((fake_st_fn_t)objc_msgSend_stret)(&stval, [Super class], @selector(stre3::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));
    testassertequal(stptr, &stval);
#endif

    state = 19;
    sp1 = getSP();
    ldval = [Super ldre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 20);
    testassertequal(ldval, LD_RESULT);

    state = 21;
    sp1 = getSP();
    ldcval = [Super ldcre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 22);
    testassertequal(ldcval, LDC_RESULT);


    // Test user-defined forward handler, uncached but fixed-up

    _objc_flush_caches(nil);

    state = 11;
    sp1 = getSP();
    idval = [Super idre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 12);
    testassertequal(idval, ID_RESULT);

    state = 13;
    sp1 = getSP();
    llval = [Super llre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 14);
    testassertequal(llval, LL_RESULT);

    state = 15;
    sp1 = getSP();
    fpval = [Super fpre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 16);
    testassertequal(fpval, FP_RESULT);

    state = 17;
    sp1 = getSP();
    stval = [Super stre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));

#if __x86_64__
    // check stret return register
    state = 17;
    sp1 = getSP();
    stptr = ((fake_st_fn_t)objc_msgSend_stret)(&stval, [Super class], @selector(stre3::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));
    testassertequal(stptr, &stval);
#endif

    state = 19;
    sp1 = getSP();
    ldval = [Super ldre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 20);
    testassertequal(ldval, LD_RESULT);

    state = 21;
    sp1 = getSP();
    ldcval = [Super ldcre3:1:2:3:4:5:6:7:8:9:10:11:12:13:1.0:2.0:3.0:4.0:5.0:6.0:7.0:8.0:9.0:10.0:11.0:12.0:13.0:14.0:15.0];
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 22);
    testassertequal(ldcval, LDC_RESULT);



    // Test user-defined forward handler, manual forwarding

    state = 11;
    sp1 = getSP();
    idval = ((id_fn_t)_objc_msgForward)(receiver, @selector(idre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 12);
    testassertequal(idval, ID_RESULT);

    state = 13;
    sp1 = getSP();
    llval = ((ll_fn_t)_objc_msgForward)(receiver, @selector(llre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 14);
    testassertequal(llval, LL_RESULT);

    state = 15;
    sp1 = getSP();
    fpval = ((fp_fn_t)_objc_msgForward)(receiver, @selector(fpre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 16);
    testassertequal(fpval, FP_RESULT);

    state = 17;
    sp1 = getSP();
    stval = stret_fwd(receiver, @selector(stre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));

    state = 19;
    sp1 = getSP();
    ldval = ((ld_fn_t)_objc_msgForward)(receiver, @selector(ldre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 20);
    testassertequal(ldval, LD_RESULT);

    state = 21;
    sp1 = getSP();
    ldcval = ((ldc_fn_t)_objc_msgForward)(receiver, @selector(ldcre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 22);
    testassertequal(ldcval, LDC_RESULT);


    // Test user-defined forward handler, manual forwarding, cached

    state = 11;
    sp1 = getSP();
    idval = ((id_fn_t)_objc_msgForward)(receiver, @selector(idre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 12);
    testassertequal(idval, ID_RESULT);

    state = 13;
    sp1 = getSP();
    llval = ((ll_fn_t)_objc_msgForward)(receiver, @selector(llre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 14);
    testassertequal(llval, LL_RESULT);

    state = 15;
    sp1 = getSP();
    fpval = ((fp_fn_t)_objc_msgForward)(receiver, @selector(fpre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 16);
    testassertequal(fpval, FP_RESULT);

    state = 17;
    sp1 = getSP();
    stval = stret_fwd(receiver, @selector(stre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));

    state = 19;
    sp1 = getSP();
    ldval = ((ld_fn_t)_objc_msgForward)(receiver, @selector(ldre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 20);
    testassertequal(ldval, LD_RESULT);

    state = 21;
    sp1 = getSP();
    ldcval = ((ldc_fn_t)_objc_msgForward)(receiver, @selector(ldcre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 22);
    testassertequal(ldcval, LDC_RESULT);


    // Test user-defined forward handler, manual forwarding, uncached but fixed-up

    _objc_flush_caches(nil);

    state = 11;
    sp1 = getSP();
    idval = ((id_fn_t)_objc_msgForward)(receiver, @selector(idre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 12);
    testassertequal(idval, ID_RESULT);

    state = 13;
    sp1 = getSP();
    llval = ((ll_fn_t)_objc_msgForward)(receiver, @selector(llre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 14);
    testassertequal(llval, LL_RESULT);

    state = 15;
    sp1 = getSP();
    fpval = ((fp_fn_t)_objc_msgForward)(receiver, @selector(fpre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 16);
    testassertequal(fpval, FP_RESULT);

    state = 17;
    sp1 = getSP();
    stval = stret_fwd(receiver, @selector(stre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 18);
    testassert(stret_equal(stval, STRET_RESULT));

    state = 19;
    sp1 = getSP();
    ldval = ((ld_fn_t)_objc_msgForward)(receiver, @selector(ldre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 20);
    testassertequal(ldval, LD_RESULT);

    state = 21;
    sp1 = getSP();
    ldcval = ((ldc_fn_t)_objc_msgForward)(receiver, @selector(ldcre2::::::::::::::::::::::::::::), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0);
    sp2 = getSP();
    testassertequal(sp1, sp2);
    testassertequal(state, 22);
    testassertequal(ldcval, LDC_RESULT);


    succeed(__FILE__);
}
