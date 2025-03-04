#!/usr/bin/env bash
# prerequisite: /path/to/SMDK/script/dep_pkg_install.sh

readonly BASEDIR=$(readlink -f $(dirname $0))/..
cd $BASEDIR/lib
#set -x
set -e

source "$BASEDIR/script/common.sh"
SMDKMALLOC=smdk_allocator
JEMALLOC=jemalloc-5.2.1
REDIS=redis-6.2.1
MEMCACHED=memcached-1.6.9
MEMTIER=memtier_benchmark-1.3.0
STREAM=stream
NUMACTL=numactl-2.0.14
CXL_KERNEL=linux-5.17-rc5-smdk
CXL_KERNEL_CONFIG=config-linux-5.17-rc5-smdk
QEMU=qemu_cxl2.0v4
MLC=mlc
VOLTDB=$BASEDIR/src/app/voltdb

SMDK_BIN=$BASEDIR/lib/SMDK_bin
SMDK_VERSION=v1.0

function build_voltdb() {
	app=$VOLTDB
	log_normal "[build $app]"

	cd $app/voltdb_src
	if [ ! -f "/bundles/kafkastream10.jar" ]; then
		ant
	fi
	ret=$?
	cd -

	source $app/voltdb_src/bin/voltenv
	cd $app/voltdb_src/examples/voltkv
	javac -classpath $CLIENTCLASSPATH client/voltkv/*.java
	jar cf voltkv-client.jar -C client voltkv
	rm -rf client/voltkv/*.class
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}


function build_numactl() {
	app=$NUMACTL
	log_normal "[build $app]"

	cd $app
	if [ ! -f "numactl" ]; then
		autoreconf -f -i
		./configure && make -j
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi

}

function build_qemu(){
	app=$QEMU
	log_normal "[build $app]"

	mkdir -p qemu/$app/build
	cd qemu/$app/build
	if [ ! -f "qemu-system-x86_64" ]; then
		../configure --target-list=x86_64-softmmu --enable-debug
		make -j
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}

function build_bm(){
	app=$STREAM
	log_normal "[build $app]"

	cd $app
	if [ ! -f "stream_c.exe" ]; then
		make -j
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}

function build_redis(){
	app=$REDIS
	log_normal "[build $app]"
	if [ ! -d "$app" ]; then
		log_normal "extract $app"
		tar -xvf $app.tar.gz 1>/dev/null
		log_normal "extract $app..done"
	fi

	cd $app
	if [ ! -f "src/redis-server" ]; then
		make -j MALLOC=libc 
		make install PREFIX=$SMDK_BIN
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}

function build_memcached(){
	app=$MEMCACHED
	log_normal "[build $app]"

	cd $app
	if [ ! -f "memcached" ]; then
		autoreconf -f -i
		./configure --prefix=$SMDK_BIN --enable-extstore && make -j && make install
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}

function build_memtier(){
	app=$MEMTIER
	log_normal "[build $app]"
	if [ ! -d "$app" ]; then
                log_normal "extract $app"
                tar -xvf $app.tar.gz 1>/dev/null
                log_normal "extract $app..done"
	fi

	cd $app
	if [ ! -f "memtier_benchmark" ]; then
		autoreconf -ivf && ./configure --prefix=$SMDK_BIN && make -j
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}

function build_smdk_kernel(){
	app=$CXL_KERNEL
	log_normal "[build $app]"

	cd $app
	if [ ! -f "arch/x86_64/boot/bzImage" ]; then
		cp ../$CXL_KERNEL_CONFIG .config
		#Note : make -j for building kernel would case a build error
		make oldconfig && make -j 4
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[build $app]..success"
	else
		log_error "[build $app]..error"
	fi
}

function build_smdkmalloc(){
	app=$SMDKMALLOC
	log_normal "[build smdkmalloc]"

	if [ ! -f "$app/lib/libcxlmalloc.a" ]; then
		cd $app/$JEMALLOC
		autoconf
		./configure --with-jemalloc-prefix='je_' --with-private-namespace='' --disable-cxx
		cd - && cd $app
		make
		cd -
	fi
	ret=$?

	if [ $ret = 0 ]; then
		log_normal "[build smdkmalloc]..success"
	else
		log_error "[build smdkmalloc]..error"
	fi
}

function build_all(){
	build_smdkmalloc
	build_redis
	build_memcached
	build_memtier
	build_bm
	build_numactl
	#build_voltdb
	#build_qemu
	#build_smdk_kernel
}

function clean_smdkmalloc(){
	app=$SMDKMALLOC
	log_normal "[clean smdkmalloc]"
	if [ -d "$app" ]; then
		cd $app
		make clean
		cd -
	fi
	log_normal "[clean smdkmalloc]..done"
}

function clean_redis(){
	app=$REDIS
	log_normal "[clean $app]"
	if [ -d "$app" ]; then
		cd $app
		make clean && make distclean
		cd -
	fi
	log_normal "[clean $app]..done"
}

function clean_memcached(){
	app=$MEMCACHED
	log_normal "[clean $app]"
	if [ -d "$app" ]; then
		cd $app
		make clean && make distclean
		cd -
	fi
	log_normal "[clean $app]..done"
}

function clean_memtier(){
	app=$MEMTIER
	log_normal "[clean $app]"
	if [ -d "$app" ]; then
		cd $app
		make clean && make distclean
		cd -
	fi
	log_normal "[clean $app]..done"
}

function clean_bm(){
	app=$STREAM
	log_normal "[clean $app]"
	if [ -d "$app" ]; then
		cd $app
		make clean
		cd -
	fi
	log_normal "[clean $app]..done"
}

function clean_kernel(){
	app=$CXL_KERNEL
	log_normal "[clean $app]"
	if [ -d "$app" ]; then
		cd $app
		make clean && make distclean
		cd -
	fi
	log_normal "[clean $app]..done"
}

function clean_qemu(){
    app=$QEMU
    log_normal "[clean $app]"

    if [ -f qemu/$app/build ]; then
        cd qemu/$app/build
        if [ -f "qemu-system-x86_64" ]; then
            make clean && make distclean
        fi
        ret=$?
        cd -

        if [ $ret = 0 ]; then
            log_normal "[clean $app]..success"
        else
            log_error "[clean $app]..error"
        fi
    fi
}

function clean_numactl(){
	app=$NUMACTL
	log_normal "[clean $app]"

	cd $app
	if [ -f "numactl" ]; then
		make clean && make distclean
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[clean $app]..success"
	else
		log_error "[clean $app]..error"
	fi
}

function clean_voltdb(){
	app=$VOLTDB
	log_normal "[build $app]"

	cd $app/voltdb_src
	if [ -f "/bundles/kafkastream10.jar" ]; then
		ant clean
	fi
	ret=$?
	cd -

	if [ $ret = 0 ]; then
		log_normal "[clean $app]..success"
	else
		log_error "[clean $app]..error"
	fi
}

case "$1" in
	kernel)
		build_smdk_kernel
		;;

	smdkmalloc)
		build_smdkmalloc
		;;

	memcached)
		build_memcached
		;;

	memtier)
		build_memtier
		;;

	redis)
		build_redis
		;;

	bm)
		build_bm
		;;
		
	qemu)
		build_qemu
		;;

	voltdb)
		build_voltdb
		;;

	numactl)
		build_numactl
		;;

	all)
		build_all
		;;

	clean_kernel)
		clean_kernel
		;;

	clean_smdkmalloc)
		clean_smdkmalloc
		;;

	clean_memcached)
		clean_memcached
		;;

	clean_memtier)
		clean_memtier
		;;

	clean_redis)
		clean_redis
		;;

	clean_bm)
		clean_bm
		;;

	clean_qemu)
		clean_qemu
		;;

	clean_voltdb)
		clean_voltdb
		;;

	clean_numactl)
		clean_numactl
		;;

	clean_all)
		clean_smdkmalloc
		clean_redis
		clean_memcached
		clean_memtier
		clean_bm
#		clean_kernel
#		clean_qemu
		clean_numactl
#		clean_voltdb
		;;
	*)
		echo "Usage: build_lib.sh {all|kernel|smdkmalloc|redis|memcached|memtier||qemu|numactl|voltdb|bm}"
		echo "Usage: build_lib.sh {clean_all|clean_kernel|clean_smdkmalloc|clean_redis|clean_memcached|clean_memtier|clean_qemu|clean_numactl|clean_voltdb|clean_bm}"
		exit 1
		;;
esac
