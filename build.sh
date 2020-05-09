#! /bin/bash

cd libsodium
./autogen.sh
dist-build/ios.sh
cd libsodium-ios

lipo lib/libsodium.a -thin i386 -output libsodium-sim.a
lipo lib/libsodium.a -thin x86_64 -output libsodium-catalyst.a
lipo -remove i386 lib/libsodium.a -o libsodium-ios.a
lipo -remove x86_64 libsodium-ios.a -o libsodium-ios.a

function create_framework () {
    PRODUCT_NAME="Clibsodium"
    FRAMEWORK_PATH="Clibsodium.framework"

    # Create the path to the real Headers die
    mkdir -p "$1/${FRAMEWORK_PATH}/Versions/A/Headers"
    mkdir -p "$1/${FRAMEWORK_PATH}/Versions/A/Modules"
    
    cp ../../module.modulemap "$1/${FRAMEWORK_PATH}/Versions/A/Modules"
    cp -a ${PWD}/$2 "$1/${FRAMEWORK_PATH}/Versions/A/${PRODUCT_NAME}"
    # Create the required symlinks
    ln -sfh A "$1/${FRAMEWORK_PATH}/Versions/Current"
    ln -sfh Versions/Current/Headers "$1/${FRAMEWORK_PATH}/Headers"
    ln -sfh Versions/Current/Modules "$1/${FRAMEWORK_PATH}/Modules"
    ln -sfh "Versions/Current/${PRODUCT_NAME}" \
                 "$1/${FRAMEWORK_PATH}/${PRODUCT_NAME}"

    # Copy the public headers into the framework
    cp -r "include/" \
               "$1/${FRAMEWORK_PATH}/Versions/A/Headers"

    mv "$1/${FRAMEWORK_PATH}/Versions/A/Headers/sodium.h" "$1/${FRAMEWORK_PATH}/Versions/A/Headers/${PRODUCT_NAME}.h"
}

for binary in `ls *.a`
do
    input=${binary%%.*}
    IFS='-' && read -ra ADDR <<< "$input"
    dir_name=${ADDR[1]}
    IFS=' '
    
    create_framework ${dir_name} "${binary}"
done
xcodebuild -create-xcframework \
    -framework ios/${FRAMEWORK_PATH} \
    -framework sim/${FRAMEWORK_PATH} \
    -framework catalyst/${FRAMEWORK_PATH} \
    -output ../../${PRODUCT_NAME}.xcframework
    
rm -rf lib

echo "DONE!"

