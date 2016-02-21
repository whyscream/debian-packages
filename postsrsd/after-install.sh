#!/bin/sh
file=/etc/postsrsd.secret

if ! test -f $file; then
    echo "Generating secrets file: $file"
    touch $file
    chmod 600 $file
    dd if=/dev/urandom bs=18 count=1 2> /dev/null | base64 > $file
fi
