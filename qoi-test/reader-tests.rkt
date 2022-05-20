; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  racket/runtime-path
  qoi)

(define-runtime-path qoi-filename  "qoi_test_images/dice.qoi")
(define-runtime-path rgba-filename "qoi_test_images.out/dice.rgba")

(define dice-img (with-input-from-file qoi-filename
                    (thunk
                      (image-read-qoi))))

(with-output-to-file rgba-filename #:exists 'replace
  (thunk
    (image-write-rgba dice-img)))
