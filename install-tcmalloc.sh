#!/bin/bash

# A script to setup tcmalloc on RHEL flavor servers.

# We need libunwind first, as it is a dependency of tcmalloc
install_libunwind() {
	UNWIND_VERSION="libunwind-1.1"
	UNWIND_DLURL="http://savannah.spinellicreations.com/libunwind/"
	wget --quiet "${UNWIND_DLURL}/${UNWIND_VERSION}.tar.gz"
	[[ ! -f "${UNWIND_VERSION}.tar.gz" ]] && { echo "Could not retrieve libunwind.  This is a needed dependency."; exit 1; }
	tar xzf ${UNWIND_VERSION}.tar.gz
	cd ${UNWIND_VERSION} && ./configure && make && make install && cd -
}

# Install gperftools
install_gperftools() {
	PERF_VERSION="gperftools-2.2.1"
	PERF_DLURL="https://googledrive.com/host/0B6NtGsLhIcf7MWxMMF9JdTN3UVk/gperftools-2.2.1.tar.gz"
	wget --no-check-certificate "${PERF_DLURL}"
	[[ ! -f "${PERF_VERSION}.tar.gz" ]] && { echo "Could not retrieve gperftools tar archive."; exit 1; }
	tar xzf ${PERF_VERSION}.tar.gz
	cd ${PERF_VERSION}
	if [[ ${1} == 'minimal' ]]; then
		./configure --disable-cpu-profiler --disable-heap-profiler --disable-heap-checker --disable-debugalloc --enable-minimal && make && make install
	else
		./configure && make && make install
	fi

	echo -e "\n\nInstallation complete.  You should now add the following lines accordingly."
	echo -e "\nLine 2 of /etc/init.d/httpd & /etc/init.d/mysql:"
	echo -e "export LD_PRELOAD=\"/usr/local/lib/libtcmalloc_minimal.so\"\n"
	echo -e "/etc/my.cnf:"
	echo -e "[mysqld_safe]\nmalloc-lib=/usr/local/lib/libtcmalloc_minimal.so\n"
}

# Let's install everything
install_all() {
	install_libunwind
	install_gperftools ${1}
}

if [[ ${1} == 'full' ]]; then
	install_all
elif [[ ${1} == 'minimal' ]]; then
	install_all minimal
else
	echo "Run this script again as '${0} full' or '${0} minimal' to install tcmalloc."
fi
