#!/bin/bash
set -e

HOME=$(pwd)
TOOLS=$(pwd)/tools
PATCH=$(pwd)/patch
KERNEL=$(pwd)/kernel

# Auto-detect NDK path or use environment variable
if [ -z "$NDK_HOME" ]; then
    if [ -d "/opt/android-ndk" ]; then
        export NDK_HOME="/opt/android-ndk"
    elif [ -d "/root/.android/sdk/ndk/28.0.13004108" ]; then
        export NDK_HOME="/root/.android/sdk/ndk/28.0.13004108"
    fi
fi

if [ -z "$NDK_HOME" ] || [ ! -d "$NDK_HOME" ]; then
    echo "Warning: Android NDK not found. Set NDK_HOME environment variable."
    echo "Android build will be skipped."
    BUILD_ANDROID=false
else
    BUILD_ANDROID=true
fi
# Build tools
cd $TOOLS
rm -rf build
mkdir -p build

if [ "$BUILD_ANDROID" = true ]; then
    # Build Android version
    mkdir -p build/android
    cd build/android
    cmake \
      -DCMAKE_TOOLCHAIN_FILE="$NDK_HOME/build/cmake/android.toolchain.cmake" \
      -DCMAKE_BUILD_TYPE=Release \
      -DANDROID_PLATFORM=android-33 \
      -DANDROID_ABI=arm64-v8a ../..
    cmake --build .
    mv kptools kptools-android
    cd $TOOLS
fi

# Build Linux version
cd build
cmake ..
make
mv kptools kptools-linux

cd $KERNEL

make clean
make

cd $HOME

# Set ANDROID_NDK for patch build
if [ "$BUILD_ANDROID" = true ]; then
    export ANDROID_NDK="$NDK_HOME"
fi

rm -rf $PATCH/res/kpimg.enc
rm -rf $PATCH/res/kpimg

if [ "$BUILD_ANDROID" = true ]; then
    cp -r $TOOLS/build/android/kptools-android $PATCH/res
fi
cp -r $TOOLS/build/kptools-linux $PATCH/res
cp -r $KERNEL/kpimg $PATCH/res

cd $PATCH

g++ -o encrypt encrypt.cpp -O3 -std=c++17
chmod 755 ./encrypt
./encrypt res/kpimg res/kpimg.enc

# Generate headers with clean variable names by running xxd from the res directory
cd res
xxd -i kpimg.enc > ../include/kpimg_enc.h
xxd -i kptools-linux > ../include/kptools_linux.h

if [ "$BUILD_ANDROID" = true ]; then
    xxd -i kptools-android > ../include/kptools_android.h

    cd $PATCH
    # Build Android patch
    rm -rf build-android
    mkdir -p build-android
    cd build-android

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake" \
        -DCMAKE_BUILD_TYPE=Release \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM=android-33 \
        -DANDROID_STL=c++_static

    cmake --build .
    cp -r patch_android $HOME
    
    cd $PATCH
else
    # Create dummy Android header for Linux-only build
    cd $PATCH
    echo "// Dummy Android header for Linux build" > include/kptools_android.h
    echo "unsigned char kptools_android[] = {};" >> include/kptools_android.h
    echo "unsigned int kptools_android_len = 0;" >> include/kptools_android.h
fi

# Build Linux patch
rm -rf build-linux
mkdir -p build-linux
cd build-linux
cmake .. && make
mv patch patch_linux
cp -r patch_linux $HOME
