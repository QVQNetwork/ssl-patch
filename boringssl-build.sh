#!/bin/sh
export WORKDIRECTORY=$PWD
export ARCH=`uname -m`
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

if [ -z $GOROOT ];then
if [ "$ARCH" = "x86_64" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1`
fi
if [ "$ARCH" = "i386" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-386\.tar\.gz' | head -n 1`
fi
if [ "$ARCH" = "armv6l" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-armv6l\.tar\.gz' | head -n 1`
fi
echo "Downloading golang"
curl -so $WORKDIRECTORY/go.tar.gz $GOURL
tar -xzf $WORKDIRECTORY/go.tar.gz
rm -rf $WORKDIRECTORY/go.tar.gz
export PATH=$WORKDIRECTORY/go/bin:$PATH
export GOROOT=$WORKDIRECTORY/go
fi

NETWORK_CHECK=`curl -I -s --connect-timeout 5 https://github.com -w %{http_code} | tail -n1`

if [ "$NETWORK_CHECK" = "200" ]; then
  git clone https://github.com/google/boringssl.git $WORKDIRECTORY/boringssl
else
  echo "Unable to connect to GitHub, please check your Internet availability"
  exit 1
fi

cd $WORKDIRECTORY/boringssl
git am $WORKDIRECTORY/0001-max-version-upgrade-to-tls1.3.patch
git am $WORKDIRECTORY/0002-DO-NOT-MERGE-Version-Upgrade-to-OpenSSL-1.1.1-to-sup.patch
mkdir $WORKDIRECTORY/boringssl/build
cd $WORKDIRECTORY/boringssl/build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j`nproc`
mkdir $WORKDIRECTORY/boringssl/.openssl
mkdir $WORKDIRECTORY/boringssl/.openssl/include
mkdir $WORKDIRECTORY/boringssl/.openssl/include/openssl
cd $WORKDIRECTORY/boringssl/.openssl/include/openssl
ln $WORKDIRECTORY/boringssl/include/openssl/* .
mkdir $WORKDIRECTORY/boringssl/.openssl/lib
cp $WORKDIRECTORY/boringssl/build/crypto/libcrypto.a $WORKDIRECTORY/boringssl/.openssl/lib/libcrypto.a
cp $WORKDIRECTORY/boringssl/build/ssl/libssl.a $WORKDIRECTORY/boringssl/.openssl/lib/libssl.a
echo "Configure nginx with \"--with-openssl=$WORKDIRECTORY/boringssl\""
echo "Run \"touch /root/ssl-patch/boringssl/.openssl/include/openssl/ssl.h\" AFTER you encountered a build error"
