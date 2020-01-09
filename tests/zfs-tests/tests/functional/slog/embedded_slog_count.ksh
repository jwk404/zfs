#!/bin/ksh -p

#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

. $STF_SUITE/tests/functional/slog/slog.kshlib

#
# DESCRIPTION:
#	Verify the correct number of embedded slogs are in use given the
#	setting of the ZFS_MAX_EMBEDDED_SLOGS tunable.
#
# STRATEGY:
#	1. Create pools after setting the tunable to 0, 1, 3 and 4.
#	2. For each pool, verify that the number of slogs is appropriate
#	   given the tunable setting.
#

verify_runnable "global"

function cleanup_local
{
	log_must set_tunable32 ZFS_MAX_EMBEDDED_SLOGS $zfs_max_embedded_slogs
	cleanup
}
log_onexit cleanup_local

log_must setup

zfs_max_embedded_slogs=$(get_tunable ZFS_MAX_EMBEDDED_SLOGS)
num_pool_devs=$(echo $VDEV | wc -w)
for num_slogs in 0 1 3 4; do
	log_must set_tunable32 ZFS_MAX_EMBEDDED_SLOGS $num_slogs
	log_must zpool create $TESTPOOL $VDEV
	slogs=$(get_embedded_slog_count $TESTPOOL)

	# The tunable can be higher than the number of vdevs in the pool.
	expected_num_slogs=$(get_min $num_pool_devs $num_slogs)

	[[ $expected_num_slogs -eq $slogs ]] || \
	    log_fail "Expected $num_slogs slogs, but got '$slogs'"

	log_must zfs create $TESTPOOL/$TESTFS
	ziltest $TESTPOOL $TESTPOOL/$TESTFS $VDIR

	log_must zpool destroy $TESTPOOL
done

log_pass "Expected number of embedded slogs found."
