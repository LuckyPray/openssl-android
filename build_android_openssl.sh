#!/bin/bash

VERSION='openssl-1.1.1t'
ANDROID_API=24

function build_openssl()
{
    arch=$1
    if [ ! -f $VERSION.tar.gz ]; then
        curl -O https://www.openssl.org/source/$VERSION.tar.gz
    fi
    if [ ! -d $VERSION ]; then
        tar -xf $VERSION.tar.gz
    fi
    if [ -z $ANDROID_NDK_HOME ]; then
        echo "missing ANDROID_NDK_HOME"
        exit 1
    fi
    if [ ! -d $arch ]; then
        mkdir $arch
    fi
    pushd $VERSION

    if [ "$(uname)" == "Darwin" ]; then
        export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
        export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/windows-x86_64/bin:$PATH
    fi

    ./Configure --prefix="`pwd`/$arch" android-$arch -Wno-macro-redefined -D__ANDROID_API__=$ANDROID_API
    make clean
    make
    make install
    popd
}

android_archs="arm64 arm x86 x86_64"
for arch in $android_archs
do
    build_openssl $arch
done

mkdir -p openssl/include
cp -r $VERSION/arm64/include/* openssl/include

build_apis="armeabi-v7a arm64-v8a x86 x86_64"
for api in $build_apis
do
    if [ ! -d openssl/lib/$api ]; then
        mkdir -p openssl/lib/$api
    fi
done

cp $VERSION/arm64/lib/*.a openssl/lib/arm64-v8a
cp $VERSION/arm/lib/*.a openssl/lib/armeabi-v7a
cp $VERSION/x86/lib/*.a openssl/lib/x86
cp $VERSION/x86_64/lib/*.a openssl/lib/x86_64
