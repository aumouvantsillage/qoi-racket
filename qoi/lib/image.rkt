; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  "qoi-defs.rkt")

(provide
  (struct-out image)
  (contract-out
    [make-image (->i ([width      (and/c integer? (>/c 0))]
                      [height     (and/c integer? (>/c 0))]
                      [channels   (between/c 3 4)]
                      [colorspace (between/c 0 1)])
                     #:pre (width height) (<= (* width height) qoi-pixels-max)
                     [result image?])])
  image-read-rgba
  image-write-rgba)

(struct image (width height channels colorspace pixels)
  #:constructor-name private-image)

(define (make-image width height channels colorspace)
  (private-image width height channels colorspace (make-bytes (* 4 width height))))

(define (image-read-rgba width height channels colorspace [in (current-input-port)])
  (define img (make-image width height channels colorspace))
  (read-bytes! (image-pixels img) in)
  img)

(define (image-write-rgba img [out (current-output-port)])
  (write-bytes (image-pixels img) out))
