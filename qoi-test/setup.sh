#!/usr/bin/env bash

SCRIPT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
IMG_DIR=$SCRIPT_DIR/qoi_test_images

# Download and extract the official test images.
echo "Downloading test images"
curl -o $SCRIPT_DIR/qoi_test_images.zip https://qoiformat.org/qoi_test_images.zip
unzip -d $SCRIPT_DIR $SCRIPT_DIR/qoi_test_images.zip

# Convert all PNG images to RGBA.
echo "Converting test images to RGBA"
rm $IMG_DIR/images.lst
for f in $IMG_DIR/*.png; do
    IMG_NAME=$(basename $f .png)
    IMG_BASE=$IMG_DIR/$IMG_NAME
    convert $f -print "$IMG_NAME,%[width],%[height],%[channels]\n" $IMG_BASE.rgba >> $IMG_DIR/images.lst
done
