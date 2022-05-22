; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  racket/runtime-path
  qoi)

(define-runtime-path in-dir  "qoi_test_images")
(define-runtime-path out-dir "qoi_test_images.out")

(define (check name expected actual)
  (unless (equal? expected actual)
    (error (format "~a mismatch: expected ~a, actual ~a" name expected actual))))

(with-input-from-file (build-path in-dir "images.lst")
  (thunk
    (for ([l (in-lines)])
      (match-define (list name width height cc) (string-split l ","))
      (unless (regexp-match #rx"s?rgba?" cc)
        (error "Unsupported colorspace/channel" cc))
      (printf "Converting: ~a.qoi to RGBA\n" name)
      (define in-file  (build-path in-dir  (format "~a.qoi"  name)))
      (define out-file (build-path out-dir (format "~a.rgba" name)))
      (define img (with-input-from-file in-file image-read-qoi))
      (check "Width"      (string->number width)           (image-width      img))
      (check "Height"     (string->number height)          (image-height     img))
      (check "Channels"   (if (string-suffix? cc "a") 4 3) (image-channels   img))
      (check "Colorspace" (if (string-prefix? cc "s") 0 1) (image-colorspace img))
      (with-output-to-file out-file #:exists 'replace
        (thunk (image-write-rgba img))))))
