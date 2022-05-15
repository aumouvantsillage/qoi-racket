; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require racket/draw)

(provide
  (struct-out image)
  image-read-bitmap)

(struct image (width height channels colorspace pixels))

(define (image-read-bitmap in)
  (define bitmap (read-bitmap in))
  (define width  (send bitmap get-width))
  (define height (send bitmap get-height))
  (define pixels (make-bytes (* 4 width height)))
  (send bitmap get-argb-pixels 0 0 width height pixels)
  (image width
         height
         (if (send bitmap has-alpha-channel?) 4 3)
         1 ; read-bitmap always applies gamma correction
         pixels))
