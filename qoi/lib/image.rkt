; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  racket/draw
  "qoi-defs.rkt")

(provide
  (struct-out image)
  make-image
  image-read-bitmap
  image-read-rgba
  image-write-bitmap)

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

(define (image-read-rgba width height colorspace [in (current-input-port)])
  (define img (make-image width height 4 colorspace))
  (read-bytes! (image-pixels img) in)
  img)

; TODO Reorder ARGB to RGBA
(define (image-read-bitmap in)
  (define bitmap (read-bitmap in))
  (define width  (send bitmap get-width))
  (define height (send bitmap get-height))
  (define img (make-image width
                          height
                          (if (send bitmap has-alpha-channel?) 4 3)
                          qoi-colorspace-linear)) ; read-bitmap always applies gamma correction
  (send bitmap get-argb-pixels 0 0 width height (image-pixels img))
  img)

; TODO Reorder RGBA to ARGB
(define (image-write-bitmap img name)
  (println (image-pixels img))
  (define bitmap (make-object bitmap% (image-pixels img)
                                      (image-width  img)
                                      (image-height img)))
  (send bitmap save-file name 'png))
