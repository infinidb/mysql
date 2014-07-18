#!/bin/bash

prefix=/usr/local/Calpont/mysql
objdir=../mysql-obj
comment="InfiniDB 5.0 Alpha"
WITH_DEBUG=
ncpus=1

usage()
{
cat <<EOD
usage: idbbuild.sh [--prefix=PFX] [--with-debug] [--objdir=DIR]
                   [--comment="COM"] [--ncpus=N] [--help]
   --prefix     set install prefix (currently $prefix)
   --with-debug enable debug symbols (requires matching settings in connector)
   --objdir     set build dir (currently $objdir)
   --comment    set server comment (currently "$comment")
   --ncpus      set build concurrency (autodeteced at $ncpus)
   --help       display this help
EOD
}

ncpus=$(lscpu 2>/dev/null | awk '/^CPU.s.:/ {print $2}')
if [ -z "$ncpus" ]; then
	ncpus=1
fi

for arg in "$@"; do
	if [ $(expr -- "$arg" : '--prefix=') -eq 9 ]; then
		prefix="$(echo $arg | awk -F= '{print $2}')"
	elif [ $(expr -- "$arg" : '--with-debug') -eq 12 ]; then
		WITH_DEBUG="-DWITH_DEBUG=1"
	elif [ $(expr -- "$arg" : '--objdir=') -eq 9 ]; then
		objdir="$(echo $arg | awk -F= '{print $2}')"
	elif [ $(expr -- "$arg" : '--comment=') -eq 10 ]; then
		comment="$(echo $arg | awk -F= '{print $2}')"
	elif [ $(expr -- "$arg" : '--ncpus=') -eq 8 ]; then
		ncpus="$(echo $arg | awk -F= '{print $2}')"
        elif [ $(expr -- "$arg" : '--help') -eq 6 ]; then
                usage
                exit 0
	else
		echo "ignoring unknown argument: $arg" 1>&2
	fi
done

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

jobs=
if [ $ncpus -gt 1 ]; then
	jobs="-j$ncpus"
fi

make $jobs && make install

