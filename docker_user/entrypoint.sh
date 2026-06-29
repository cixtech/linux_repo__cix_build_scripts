#!/bin/sh

# Copyright (c) 2023, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

set -eu

uid=$(id -u)
gid=$(id -g)
if test "$uid" = "0" -o "$gid" = "0" ; then
    echo "ERROR: refusing to run as root UID==0 or GID==0" >&2
    id
    exit 1
fi

#echo "$USER:x:$uid:$gid::$HOME:/bin/bash"
echo "$USER::$uid:$gid::$HOME:/bin/bash" > /etc/passwd
#echo "$USER:x:$gid:"
echo "$USER::$gid:" > /etc/group

if test "$#" -ne 0 ; then
    exec "$@"
    exit 1
fi

if ! test -t 0 ; then
    echo "ERROR: no arguments given and STDIN is not a terminal." >&2
    exit 1
fi

cat <<EOF
STDIN is connected to a terminal but no arguments given so we will give you a
interactive bash shell.

EOF
exec /bin/bash
exit 1
