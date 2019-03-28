#!/usr/bin/env bash
#
# MIT License
#
# Copyright (c) 2018 Jianshen Liu
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


set -eu -o pipefail

if [ "$#" -ne 1 ]; then
	cat <<-ENDOFMESSAGE
Usage: $0 BLOCK_DEVICE

Discard all the sectors on a block device with "hdparm --trim-sector-ranges".

Note that this script is EXCEPTIONALLY DANGEROUS.
See the option --trim-sector-ranges of hdparm.

For the differences between trim and secure erase operation, see
https://www.thomas-krenn.com/en/wiki/SSD_Secure_Erase
https://storage.toshiba.com/docs/services-support-documents/ssd_application_note.pdf
ENDOFMESSAGE
	exit
fi

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

device="$1"
if [ ! -b "$device" ]; then
	echo "$device is not a block device"
    exit 2
fi

total_sectors="$(blockdev --getsz "$device")"
echo "total $total_sectors 512-byte sectors on device $device"

MAXSECT=65535

sectors="$total_sectors"
pos=0

while [ "$sectors" -gt 0 ]; do
    if [ "$sectors" -gt "$MAXSECT" ]; then
	    size="$MAXSECT"
    else
        size="$sectors"
    fi

    hdparm --please-destroy-my-drive --trim-sector-ranges "$pos":"$size" "$device" > /dev/null

    sectors=$(( sectors - size ))
    pos=$(( pos + size ))
done

echo "successfully trimmed all $total_sectors sectors"

printf "\\ndone!\\n"
