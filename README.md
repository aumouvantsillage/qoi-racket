Quite OK Image format encoder and decoder in Racket
===

Installation
------------

Install [Racket](https://racket-lang.org/).

Run these commands to clone this repository and install the `qoi` library:

```
git clone https://github.com/aumouvantsillage/qoi-racket.git
cd qoi-racket/qoi
raco pkg install --auto
```

Examples
--------

Install [ImageMagick](https://imagemagick.org/).

Run this script to get the official test image set and convert the PNG
files to RGBA:

```
cd qoi-racket/qoi-test
./setup.sh
```

### QOI encoding

Run this script to convert all test images `qoi_test_images/*.rgba` to `qoi_test_images.out/*.qoi`:

```
racket writer-tests.rkt
```

### QOI decoding

Run this script to convert all test images `qoi_test_images/*.qoi` to `qoi_test_images.out/*.rgba`:

```
racket reader-tests.rkt
```

API
---

### `(struct image (width height channels colorspace pixels)`

Structure type for images. Use `make-image` to create a new image instance.

* `width`: image width, in pixels.
* `height`: image height, in pixels.
* `channels`: 3=RGB, 4=RGBA.
* `colorspace`: 0=sRGB with linear alpha, 1=all channels linear.
* `pixels`: a mutable [byte string](https://docs.racket-lang.org/reference/bytestrings.html) with RGBA pixel values (one byte per channel).

### `(make-image width height channels colorspace)`

Creates and returns a new instance of the `image` structure type.

### `(image-read-rgba width height channels colorspace [in (current-input-port)])`

Creates and returns a new instance of the `image` structure type.
Its `pixels` field is filled with RGBA data from the input port `in`.

### `(image-write-rgba img [out (current-output-port)])`

Write the RGBA data of the image `img` to the output port `out`.

### `(image-read-qoi [in (current-input-port)])`

Creates and returns a new instance of the `image` structure type.
This function reads and decodes QOI data from the input port `in` and fills the
`pixels` field of the image with the decoded RGBA data.

### `(image-write-qoi img [out (current-output-port)])`

Encode the RGBA data of the image `img` to the QOI format and write the result
to the output port `out`.
