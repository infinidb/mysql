#!/bin/bash

prefix=/usr/local/Calpont
objdir=../mysql-obj
comment="InfiniDB 5.0 Alpha"
WITH_DEBUG=

for arg in "$@"; do
	if [ $(expr -- "$arg" : '--prefix=') -eq 9 ]; then
		prefix="$(echo $arg | awk -F= '{print $2}')"
	elif [ $(expr -- "$arg" : '--with-debug') -eq 12 ]; then
		WITH_DEBUG="-DWITH_DEBUG=1"
	elif [ $(expr -- "$arg" : '--objdir=') -eq 9 ]; then
		objdir="$(echo $arg | awk -F= '{print $2}')"
	elif [ $(expr -- "$arg" : '--comment=') -eq 10 ]; then
		comment="$(echo $arg | awk -F= '{print $2}')"
	else
		echo "ignoring unknown argument: $arg" 1>&2
	fi
done

#extra_ld_flags="-Wl,-rpath -Wl,$prefix/mysql/lib/mysql -Wl,-rpath -Wl,$prefix/lib"
#
#./configure --prefix=$prefix/mysql $WITH_DEBUG --without-libedit --with-readline \
#        --with-plugins=csv,heap,myisam,myisammrg,partition --with-mysqld-ldflags="$extra_ld_flags" \
#        --with-client-ldflags="$extra_ld_flags" --with-extra-charsets=all --with-ssl
#
#make
#

cmake --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Your cmake setup doesn't seem to work!" 1>&2
	exit 1
fi

srcdir=$(pwd)

if [ -d $objdir ]; then
	cd $objdir
	if [ -f Makefile ]; then
		make clean
	fi
else
	mkdir -p $objdir
	cd $objdir
fi

cmakeopts="$WITH_DEBUG \
	-DCMAKE_INSTALL_PREFIX=$prefix \
	-DWITH_EXTRA_CHARSETS=all \
	-DENABLED_LOCAL_INFILE=1 \
	-DWITH_EMBEDDED_SERVER=0 \
	-DWITH_PERFSCHEMA_STORAGE_ENGINE=0"

commentopt="-DCOMPILATION_COMMENT=$comment"

cmake $cmakeopts "$commentopt" $srcdir
rc=$?
if [ $rc -ne 0 ]; then
	exit $rc
fi

make

