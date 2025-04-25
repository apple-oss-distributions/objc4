//
//  ObjectiveCRPathInstallName.h
//  ObjectiveC
//
//  Copyright © 2024 Apple Inc. All rights reserved.
//

#include <mach-o/loader.h>
#include <TargetConditionals.h>

// Swift was supported as an embedded library in macOS (née OS X) 10.9, iOS 7.0, watchOS 2.0, tvOS 9.0.
// It became part of the OS in macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2. Projects can continue
// to embed Swift, but the linker will see the OS version and try to link on that by default. In order
// to support back deployment, add a magic symbol to the OS library so that back deployment will link
// on the embedded library instead. When running on a newer OS, the OS version of the library will be
// used due to Xcode inserting a runpath search path of /usr/lib/swift based on the deployment target
// being less than SupportedTargets[target][SwiftOSRuntimeMinimumDeploymentTarget] in SDKSettings.plist.

// The linker uses a specially formatted symbol to do the back deployment:
// $ld$previous$<install-name>$<compatibility-version>$<platform>$<start-version>$<end-version>$<symbol-name>$
// compatibility-version and symbol-name are left off to apply to all library versions and symbols.
// This symbol isn't a legal C identifier, so it needs to be specified with __asm.
#define LD_PREVIOUS_OBJECTIVEC_RPATH(platform, startVersion, endVersion) \
__asm("$ld$previous$@rpath/libswiftObjectiveC.dylib$$" __STRING(platform) "$" __STRING(startVersion) "$" __STRING(endVersion) "$$")
// Using the __STRING macro is important so that platform gets expanded before being stringified.
// The versions could just be #version, __STRING is only used for consistency.

#if TARGET_OS_OSX || TARGET_OS_MACCATALYST
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_MACOS, 10.9, 10.14.4);
#elif TARGET_OS_IOS && !TARGET_OS_VISION
#if TARGET_OS_SIMULATOR
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_IOSSIMULATOR, 7.0, 12.2);
#else
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_IOS, 7.0, 12.2);
#endif
#elif TARGET_OS_WATCH
#if TARGET_OS_SIMULATOR
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_WATCHOSSIMULATOR, 2.0, 5.2);
#else
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_WATCHOS, 2.0, 5.2);
#endif
#elif TARGET_OS_TV
#if TARGET_OS_SIMULATOR
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_TVOSSIMULATOR, 9.0, 12.2);
#else
extern const char ld_previous_objectivec_rpath LD_PREVIOUS_OBJECTIVEC_RPATH(PLATFORM_TVOS, 9.0, 12.2);
#endif
#endif
// Swift wasn't supported as an embedded library in any other OS, so no need to create back deployment
// symbols for any of the other ones.
