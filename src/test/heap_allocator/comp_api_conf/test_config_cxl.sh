#!/usr/bin/env bash
###################################################################
# TC : test allocator configurations for CXL work well
# prerequisite : install cxlmalloc
###################################################################
readonly BASEDIR=$(readlink -f $(dirname $0))/../../../../
source "$BASEDIR/script/common.sh"
export PATH=$PATH:.

CXLMALLOCDIR=$BASEDIR/lib/smdk_allocator/lib
export LD_PRELOAD=$CXLMALLOCDIR/libcxlmalloc.so

testcase=( t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 t13 t14 t15)

function t1(){
	CXLMALLOC_CONF=use_exmem:true,:
	run_test $CXLMALLOC_CONF
}

function t2(){
	CXLMALLOC_CONF=use_exmem:false,:
	run_test $CXLMALLOC_CONF
}

function t3(){
	CXLMALLOC_CONF=use_exmem:true,exmem_zone_size:131072,:
	run_test $CXLMALLOC_CONF
}

function t4(){
	CXLMALLOC_CONF=use_exmem:true,normal_zone_size:2048,:
	run_test $CXLMALLOC_CONF
}

function t5(){
	CXLMALLOC_CONF=use_exmem:false,exmem_zone_size:512,normal_zone_size:4096,:
	run_test $CXLMALLOC_CONF
}

function t6(){
	CXLMALLOC_CONF=priority:exmem,:
	run_test $CXLMALLOC_CONF
}

function t7(){
	CXLMALLOC_CONF=use_exmem:true,exmem_zone_size:512,normal_zone_size:4096,priority:exmem,:
	run_test $CXLMALLOC_CONF
}

function t8(){
	CXLMALLOC_CONF=narenas:10,use_exmem:true,exmem_zone_size:10240,normal_zone_size:20480,priority:exmem,:
	run_test $CXLMALLOC_CONF
}

function t9(){
	CXLMALLOC_CONF=use_exmem:true,nr_normal_arena:10,nr_exmem_arena:5,:
	run_test $CXLMALLOC_CONF
}

function t10(){
	CXLMALLOC_CONF=use_exmem:true,nr_normal_arena:1,nr_exmem_arena:1,priority:exmem,:
	run_test $CXLMALLOC_CONF
}

function t11(){
	# the number of cxl/normal arena = # cpu * auto arena scale
	CXLMALLOC_CONF=use_exmem:true,use_auto_arena_scaling:true,:
	run_test $CXLMALLOC_CONF
}

function t12(){
	# override nr_cxl_Arena / nr_normal_arena as use_auto_arena_scaling is enabled
	CXLMALLOC_CONF=use_exmem:true,use_auto_arena_scaling:true,nr_exmem_arena:1,nr_normal_arena:2,:
	run_test $CXLMALLOC_CONF
}

function t13(){
	# maxmemory_policy = oom
	CXLMALLOC_CONF=use_exmem:true,maxmemory_policy:oom,:
	run_test $CXLMALLOC_CONF
}

function t14(){
	# maxmemory_policy = interleave
	CXLMALLOC_CONF=use_exmem:true,maxmemory_policy:interleave,:
	run_test $CXLMALLOC_CONF
}

function t15(){
	# maxmemory_policy = remain
	CXLMALLOC_CONF=use_exmem:true,maxmemory_policy:remain,:
	run_test $CXLMALLOC_CONF
}

function run_test(){
	unset CXLMALLOC_CONF
	CXLMALLOC_CONF=$1
	echo $CXLMALLOC_CONF 
	echo "--------------------------------"
	export CXLMALLOC_CONF
	ls
}


for i in "${testcase[@]}"
do
	log_normal "run test - $i"
	$i
done
