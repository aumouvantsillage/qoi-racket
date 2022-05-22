; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  "qoi-defs.rkt")

(provide
  (struct-out image)
  make-image
  image-read-rgba
  image-write-rgba)

(struct image (width height channels colorspace pixels)
  #:constructor-name private-image)

(define (make-image width height channels colorspace)
  (unless (> width 0)
    (raise-argument-error 'make-image "width > 0" width))
  (unless (> height 0)
    (raise-argument-error 'make-image "height > 0" height))
  (define size (* width height))
  (unless (<= size qoi-pixels-max)
    (raise-argument-error 'make-image (format "width * height <= ~a" qoi-pixels-max) size))
  (unless (<= 3 channels 4)
    (raise-argument-error 'make-image "channels = 3|4" channels))
  (unless (<= 0 colorspace 1)
    (raise-argument-error 'make-image "colorspace = 0|1" colorspace))
  (private-image width height channels colorspace (make-bytes (* 4 size))))

(define (image-read-rgba width height channels colorspace [in (current-input-port)])
  (define img (make-image width height channels colorspace))
  (read-bytes! (image-pixels img) in)
  img)

(define (image-write-rgba img [out (current-output-port)])
  (write-bytes (image-pixels img) out))
