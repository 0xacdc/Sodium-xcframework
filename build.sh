#! /bin/bash

# delete previous version af xcframework
rm -rf *.xcframework
# read Module Name from Modulemap
parsed=$(sed -n -e 's/framework module\(.*\){/\1/p' module.modulemap)
# trimm Module Name
MODULE_NAME=$(echo ${parsed} | xargs)

cd libsodium
./autogen.sh
dist-build/ios.sh
cd libsodium-ios

lipo lib/libsodium.a -thin i386 -output libsodium-sim.a
lipo lib/libsodium.a -thin x86_64 -output libsodium-catalyst.a
lipo -remove i386 lib/libsodium.a -o libsodium-ios.a
lipo -remove x86_64 libsodium-ios.a -o libsodium-ios.a

function create_framework () {
    FRAMEWORK_NAME="${MODULE_NAME}.framework"

    # Create the path to the real Headers die
    mkdir -p "$1/${FRAMEWORK_NAME}/Versions/A/Headers"
    mkdir -p "$1/${FRAMEWORK_NAME}/Versions/A/Modules"
    # Copy the moduleMap and binary itself
    cp ../../module.modulemap "$1/${FRAMEWORK_NAME}/Versions/A/Modules"
    cp -a ${PWD}/$2 "$1/${FRAMEWORK_NAME}/Versions/A/${MODULE_NAME}"
    
    # Create the required symlinks
    ln -sfh A "$1/${FRAMEWORK_NAME}/Versions/Current"
    ln -sfh Versions/Current/Headers "$1/${FRAMEWORK_NAME}/Headers"
    ln -sfh Versions/Current/Modules "$1/${FRAMEWORK_NAME}/Modules"
    ln -sfh "Versions/Current/${MODULE_NAME}" \
                 "$1/${FRAMEWORK_NAME}/${MODULE_NAME}"

    # Copy the public headers into the framework
    cp -r "include/" \
               "$1/${FRAMEWORK_NAME}/Versions/A/Headers"

    mv "$1/${FRAMEWORK_NAME}/Versions/A/Headers/sodium.h" "$1/${FRAMEWORK_NAME}/Versions/A/Headers/${MODULE_NAME}.h"
}

for binary in `ls *.a`
do
    input=${binary%%.*}
    IFS='-' && read -ra ADDR <<< "$input"
    dir_name=${ADDR[1]}
    IFS=' '
    
    create_framework ${dir_name} ${binary}
done
xcodebuild -create-xcframework \
    -framework ios/${FRAMEWORK_NAME} \
    -framework sim/${FRAMEWORK_NAME} \
    -framework catalyst/${FRAMEWORK_NAME} \
    -output ../../${MODULE_NAME}.xcframework
    
rm -rf ../libsodium-ios

echo "DONE!"

