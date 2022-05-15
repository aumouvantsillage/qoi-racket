#!/bin/env bash

SCRIPT_DIR=$(realpath $(dirname "${BASH_SOURCE[0]}"))
curl -o $SCRIPT_DIR/qoi_test_images.zip https://qoiformat.org/qoi_test_images.zip
unzip -d $SCRIPT_DIR $SCRIPT_DIR/qoi_test_images.zip
