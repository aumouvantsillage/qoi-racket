; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  racket/runtime-path
  qoi)

(define-runtime-path in-dir  "qoi_test_images")
(define-runtime-path out-dir "qoi_test_images.out")

(with-input-from-file (build-path in-dir "images.lst")
  (thunk
    (for ([l (in-lines)])
      (match-define (list name width height cc) (string-split l ","))
      (unless (regexp-match #rx"s?rgba?" cc)
        (error "Unsupported colorspace/channel" cc))
      (printf "Converting: ~a.rgba to QOI\n" name)
      (define in-file  (build-path in-dir  (format "~a.rgba" name)))
      (define out-file (build-path out-dir (format "~a.qoi"  name)))
      (define img (with-input-from-file in-file
                    (thunk
                      (image-read-rgba (string->number width)
                                       (string->number height)
                                       (if (string-suffix? cc "a") 4 3)
                                       (if (string-prefix? cc "s") 0 1)))))
      (with-output-to-file out-file #:exists 'replace
        (thunk (image-write-qoi img))))))
