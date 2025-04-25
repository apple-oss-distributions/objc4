#!/bin/sh

# Create a VFS overlay to virtually install the build products into the SDK.
# The LLVM virtual filesystem is documented here.
# http://llvm.org/doxygen/classllvm_1_1vfs_1_1RedirectingFileSystem.html#details
if [ "$RC_XBS" = "YES" -a "$RC_BUILDIT" != "YES" ]
then
    # The overlay is not needed in an XBS environment where installhdrs merges the
    # build products into the SDK before the other targets run installapi/install.
    roots=" []"
else
    roots="
-
  type: directory
  name: ${SDKROOT}/usr/include
  contents:
  -
    type: file
    name: ObjectiveC.apinotes
    external-contents: ${BASE_DIRECTORY}/usr/include/ObjectiveC.apinotes
  -
    type: file
    name: ObjectiveC.modulemap
    external-contents: ${BASE_DIRECTORY}/usr/include/ObjectiveC.modulemap
  -
    type: directory-remap
    name: objc
    external-contents: ${BASE_DIRECTORY}/usr/include/objc
-
  type: directory
  name: ${SDKROOT}/usr/local/include
  contents:
  -
    type: file
    name: ObjectiveC_Private.apinotes
    external-contents: ${BASE_DIRECTORY}/usr/local/include/ObjectiveC_Private.apinotes
  -
    type: file
    name: ObjectiveC_Private.modulemap
    external-contents: ${BASE_DIRECTORY}/usr/local/include/ObjectiveC_Private.modulemap
  -
    type: directory-remap
    name: objc
    external-contents: ${BASE_DIRECTORY}/usr/local/include/objc"
fi

printf "\
version: 0
roots:%s" \
"$roots" > "$SCRIPT_OUTPUT_FILE_0"
