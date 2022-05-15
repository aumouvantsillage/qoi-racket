; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  racket/runtime-path
  qoi)

(define-runtime-path qoi-filename "qoi_test_images/dice.qoi")
(define-runtime-path png-filename "qoi_test_images.out/dice.png")

(with-input-from-file qoi-filename
  (thunk
    (image-read-qoi)))
