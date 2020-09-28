#!/bin/sh
WORKDIRECTORY=$PWD
ARCH=$(uname -m)
if command -v git > /dev/null 2>&1; then
  echo "Checking git: OK"
else
  echo "Checking git: FAILED, please install git"
  exit 1
fi

if command -v cmake > /dev/null 2>&1; then
  echo "Checking cmake: OK"
else
  echo "Checking cmake: FAILED, please install cmake"
  exit 1
fi

if command -v curl > /dev/null 2>&1; then
  echo "Checking curl: OK"
else
  echo "Checking curl: FAILED, please install curl"
  exit 1
fi

if [ -d $WORKDIRECTORY/go ]; then
PATH=$WORKDIRECTORY/go/bin:$PATH
GOROOT=$WORKDIRECTORY/go
if [ -z $GOROOT ];then
NO_GOROOT_SYSTEM=true
fi
else
if [ -z $GOROOT ];then
if [ "$ARCH" = "x86_64" ]; then
GOURL="https://dl.google.com/go/$(curl https://golang.org/VERSION?m=text).linux-amd64.tar.gz"
fi
if [ "$ARCH" = "i386" ]; then
GOURL="https://dl.google.com/go/$(curl https://golang.org/VERSION?m=text).linux-386.tar.gz"
fi
if [ "$ARCH" = "armv6l" ]; then
GOURL="https://dl.google.com/go/$(curl https://golang.org/VERSION?m=text).linux-armv6l.tar.gz"
fi
if [ "$ARCH" = "armv7l" ]; then
GOURL="https://dl.google.com/go/$(curl https://golang.org/VERSION?m=text).linux-armv6l.tar.gz"
fi
if [ "$ARCH" = "" ]; then
echo "Your architecture is not supported"
fi
echo "Downloading golang"
curl -so $WORKDIRECTORY/go.tar.gz $GOURL
tar -xzf $WORKDIRECTORY/go.tar.gz
rm -rf $WORKDIRECTORY/go.tar.gz
PATH=$WORKDIRECTORY/go/bin:$PATH
GOROOT=$WORKDIRECTORY/go
NO_GOROOT_SYSTEM=true
fi
fi

NETWORK_CHECK=$(curl -I -s --connect-timeout 5 https://github.com -w %{http_code} | tail -n1)

if [ -d $WORKDIRECTORY/boringssl ]; then
cd $WORKDIRECTORY/boringssl
git pull
git reset --hard origin/master
git am $WORKDIRECTORY/*.patch
rm -rf $WORKDIRECTORY/boringssl/build
rm -rf $WORKDIRECTORY/boringssl/build2
rm -rf $WORKDIRECTORY/boringssl/.openssl
else
if [ "$NETWORK_CHECK" = "200" ]; then
  git clone --depth 1 https://github.com/google/boringssl.git $WORKDIRECTORY/boringssl
  cd $WORKDIRECTORY/boringssl
  git am $WORKDIRECTORY/*.patch
else
  echo "Unable to connect to GitHub, please check your Internet availability"
  exit 1
fi
fi

mkdir $WORKDIRECTORY/boringssl/build
cd $WORKDIRECTORY/boringssl/build
echo "Building Static libraries"
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j`nproc`
mkdir $WORKDIRECTORY/boringssl/build2
cd $WORKDIRECTORY/boringssl/build2
echo "Building Shared objects"
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=1
make -j`nproc`
mkdir $WORKDIRECTORY/boringssl/.openssl
mkdir $WORKDIRECTORY/boringssl/.openssl/include
mkdir $WORKDIRECTORY/boringssl/.openssl/include/openssl
cd $WORKDIRECTORY/boringssl/.openssl/include/openssl
ln $WORKDIRECTORY/boringssl/include/openssl/* .
mkdir $WORKDIRECTORY/boringssl/.openssl/lib
mkdir $WORKDIRECTORY/boringssl/lib
cp $WORKDIRECTORY/boringssl/build/crypto/libcrypto.a $WORKDIRECTORY/boringssl/.openssl/lib/libcrypto.a
cp $WORKDIRECTORY/boringssl/build/ssl/libssl.a $WORKDIRECTORY/boringssl/.openssl/lib/libssl.a
cp $WORKDIRECTORY/boringssl/build2/crypto/libcrypto.so $WORKDIRECTORY/boringssl/.openssl/lib/libcrypto.so
cp $WORKDIRECTORY/boringssl/build2/ssl/libssl.so $WORKDIRECTORY/boringssl/.openssl/lib/libssl.so

echo "If you want to compile nginx"
echo "git am nginx-boringssl/*.patch in nginx source directory"
echo "and"
echo "Configure nginx with \"--with-openssl=$WORKDIRECTORY/boringssl\". Use nginx version >= 1.15 for best result."
echo ""
#if [ "$NO_GOROOT_SYSTEM" = "true" ]; then
#echo "Runing"
#echo "export PATH=$WORKDIRECTORY/go/bin:\$PATH"
#echo "export GOROOT=$WORKDIRECTORY/go"
#echo "If you want to compile nginx"
#fi
