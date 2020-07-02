#! /bin/bash

# delete previous version af xcframework
rm -rf *.xcframework
# read Module Name from Modulemap
parsed=$(sed -n -e 's/framework module\(.*\){/\1/p' module.modulemap)
# trimm Module Name
MODULE_NAME=$(echo ${parsed} | xargs)

cp simulator.sh libsodium/dist-build
chmod +x libsodium/dist-build/simulator.sh

cd libsodium
./autogen.sh

# Run Build Scripts
dist-build/simulator.sh
dist-build/ios.sh
dist-build/osx.sh
dist-build/watchos.sh

# Create temorary dirrectory
rm -rf tmp_xcframework
mkdir tmp_xcframework

# Separate iOS platforms
lipo libsodium-ios/lib/libsodium.a -thin x86_64 -output tmp_xcframework/libsodium-catalyst.a
lipo -remove i386 libsodium-ios/lib/libsodium.a -o tmp_xcframework/libsodium-ios.a
lipo -remove x86_64 tmp_xcframework/libsodium-ios.a -o tmp_xcframework/libsodium-ios.a

# Separate WatchOS Platform
#Both watchos-x86_64-simulator and watchos-i386-simulator represent two equivalent library definitions.
lipo libsodium-watchos/lib/libsodium.a -thin i386 -output tmp_xcframework/libsodium-watchosSim.a
lipo -remove i386 libsodium-watchos/lib/libsodium.a -o tmp_xcframework/libsodium-watchos.a
lipo -remove x86_64 tmp_xcframework/libsodium-watchos.a -o tmp_xcframework/libsodium-watchos.a

#Copy OSX Platform
cp libsodium-osx/lib/libsodium.a tmp_xcframework/libsodium-osx.a

#Copy Simulator Platform
cp libsodium-simulator/lib/libsodium.a tmp_xcframework/libsodium-sim.a

cd tmp_xcframework

function create_framework () {
    FRAMEWORK_NAME="${MODULE_NAME}.framework"

    # Create the path to the real Headers
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

    # Copy the headers into the framework
    case $1 in
         osx)
              cp -r ../libsodium-osx/include/* "$1/${FRAMEWORK_NAME}/Versions/A/Headers"
              ;;
         watchos)
              cp -r ../libsodium-watchos/include/* "$1/${FRAMEWORK_NAME}/Versions/A/Headers"
              ;;
         sim)
              cp -r ../libsodium-ios/include/* "$1/${FRAMEWORK_NAME}/Versions/A/Headers"
              ;;
         *)
              cp -r ../libsodium-ios/include/* "$1/${FRAMEWORK_NAME}/Versions/A/Headers"
              ;;
    esac

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
    -framework osx/${FRAMEWORK_NAME} \
    -framework watchos/${FRAMEWORK_NAME} \
    -framework watchosSim/${FRAMEWORK_NAME} \
    -output ../../${MODULE_NAME}.xcframework
    
rm -rf ../libsodium-ios
rm -rf ../libsodium-simulator
rm -rf ../libsodium-osx
rm -rf ../libsodium-watchos
rm -rf ../tmp_xcframework

echo "DONE!"

