#!/usr/bin/env bash

SCRIPT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
IMG_DIR=$SCRIPT_DIR/qoi_test_images

for f in $IMG_DIR/*.{qoi,rgba} ; do
    NAME=$(basename $f)
    REF=$(sha256sum $f                  | head -c 64)
    OUT=$(sha256sum $IMG_DIR.out/$NAME  | head -c 64)
    if [ "$REF" != "$OUT" ]; then
        echo "$NAME: Checksum mismatch. $REF != $OUT"
    else
        echo "$NAME: OK"
    fi
done
