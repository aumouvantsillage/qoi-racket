; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  racket/draw
  racket/runtime-path
  qoi)

(define-runtime-path png-filename "qoi_test_images/dice.png")
(define-runtime-path qoi-filename "qoi_test_images.out/dice.qoi")

(define dice-img (make-object bitmap% png-filename 'png/alpha))

(with-output-to-file qoi-filename  #:exists 'replace
  (thunk
    (write-qoi dice-img)))
