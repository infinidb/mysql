#!/bin/bash

prefix=/usr/local/Calpont
WITH_DEBUG=

for arg in "$@"; do
	if [ `expr -- "$arg" : '--prefix='` -eq 9 ]; then
		prefix="`echo $arg | awk -F= '{print $2}'`"
	elif [ `expr -- "$arg" : '--with-debug'` -eq 12 ]; then
		WITH_DEBUG=--with-debug
	else
		echo "ignoring unknown argument: $arg" 1>&2
	fi
done

extra_ld_flags="-Wl,-rpath -Wl,$prefix/mysql/lib/mysql -Wl,-rpath -Wl,$prefix/lib"

autoreconf
./configure --prefix=$prefix/mysql $WITH_DEBUG --without-libedit --with-readline \
        --with-plugins=csv,heap,myisam,myisammrg,partition --with-mysqld-ldflags="$extra_ld_flags" \
        --with-client-ldflags="$extra_ld_flags" --with-extra-charsets=all --with-ssl

# Hmm... libtool script is jacked on newer CentOS?
grep -Eqs 'CentOS release 6' /etc/redhat-release
if [ $? -eq 0 ]; then
	grep -Eqs 'VERSION=1.5.22' libtool
	if [ $? -eq 0 ]; then
		/bin/cp -f /usr/bin/libtool .
	fi
fi

make

