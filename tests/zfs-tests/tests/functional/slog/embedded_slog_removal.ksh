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
#	Verify that removing a disk with an embeddeed slog is safe, and that a
#	new embedded slog is created on the next import.
#
# STRATEGY:
#	1. Create a pool with an embedded slog on only one vdev.
#	2. Remove that vdev, verify the pool has no embedded slogs.
#	3. Export and import the pool and verify an embedded slog is creatd.
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
log_must set_tunable32 ZFS_MAX_EMBEDDED_SLOGS 1

log_must zpool create $TESTPOOL $VDEV
slog=$(get_embedded_slog_count $TESTPOOL)
[[ 1 -eq $slog ]] || log_fail "Expected 1 embedded slog, but found $slog"

remove_dev=$(get_embedded_slog_devices $TESTPOOL)
log_must zpool remove $TESTPOOL $remove_dev
slog=$(get_embedded_slog_count $TESTPOOL)
[[ 0 -eq $slog ]] || log_fail "Expected 0 embedded slogs, but got '$slog'"

log_must zpool export $TESTPOOL
log_must zpool import -d $VDIR $TESTPOOL

slog=$(get_embedded_slog_count $TESTPOOL)
[[ 1 -eq $slog ]] || log_fail "Expected 1 embedded slog, but found $slog"

log_pass "Removing disk with embedded slog works."
