#!/bin/bash

VERSION='openssl-3.4.0'
ANDROID_API=24

if [ ! -f $VERSION.tar.gz ]; then
    curl -L -O https://www.openssl.org/source/$VERSION.tar.gz
fi

if [ ! -d $VERSION ]; then
    tar -xf $VERSION.tar.gz
fi

if [ -z $ANDROID_NDK_HOME ]; then
    echo "missing ANDROID_NDK_HOME"
    exit 1
fi

if [ "$(uname)" == "Darwin" ]; then
    proc="$(sysctl -n hw.logicalcpu)"
    export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    proc="$(nproc)"
    export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    proc="$(nproc)"
    export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/windows-x86_64/bin:$PATH
fi

export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME

function build_openssl()
{
    arch=$1
    toolchain_prefix=$2

    if [ ! -d $arch ]; then
        mkdir $arch
    fi

	export CC="$toolchain_prefix$ANDROID_API-clang"
	export CXX="$toolchain_prefix$ANDROID_API-clang++"
	export CXXFLAGS="-fPIC"
	export CPPFLAGS="-DANDROID -fPIC"
    echo "Building OpenSSL for $arch with $CC"

    pushd $VERSION
    ./Configure --prefix="`pwd`/$arch" android-$arch -Wno-macro-redefined -D__ANDROID_API__=$ANDROID_API \
    && make clean \
    && make -j$proc \
    && make install
    popd
}

targets=(
  "arm64   aarch64-linux-android      arm64-v8a"
  "arm     armv7a-linux-androideabi   armeabi-v7a"
  "x86     i686-linux-android         x86"
  "x86_64  x86_64-linux-android       x86_64"
)

for entry in "${targets[@]}"; do
  set -- $entry
  arch=$1; triple=$2; abi=$3
  build_openssl $arch $triple
done

rm -rf openssl/include
mkdir -p openssl/include
cp -r $VERSION/arm64/include/* openssl/include/

rm -rf openssl/lib
for entry in "${targets[@]}"; do
  set -- $entry
  arch=$1; abi=$3
  mkdir -p openssl/lib/$abi
  cp $VERSION/$arch/lib/*.a openssl/lib/$abi/
done
