#!/bin/bash

VERSION='openssl-1.1.1t'

function buildopenssl()
{
    androidarch=$1
    if [ ! -f $VERSION.tar.gz ]; then
        curl -O https://www.openssl.org/source/$VERSION.tar.gz
    fi
    if [ ! -d $VERSION ]; then
        tar -xf $VERSION.tar.gz
    fi
    if [ -z $ANDROID_NDK_HOME ]; then
        echo "missing ANDROID_NDK_HOME"
        exit
    fi
    if [ ! -d $androidarch ]; then
        mkdir $androidarch
    fi
    pushd $VERSION
    PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
    ./Configure --prefix="`pwd`/$androidarch" android-$androidarch -Wno-macro-redefined -D__ANDROID_API__=24
    make clean
    make
    make install
    popd
}

buildopenssl arm64
buildopenssl arm
buildopenssl x86
buildopenssl x86_64

mkdir -p openssl/include openssl/lib/arm64-v8a openssl/lib/armeabi-v7a openssl/lib/x86 openssl/lib/x86_64

cp -r $VERSION/arm64/include/* openssl/include
cp $VERSION/arm64/lib/*.a openssl/lib/arm64-v8a
cp $VERSION/arm/lib/*.a openssl/lib/armeabi-v7a
cp $VERSION/x86/lib/*.a openssl/lib/x86
cp $VERSION/x86_64/lib/*.a openssl/lib/x86_64
