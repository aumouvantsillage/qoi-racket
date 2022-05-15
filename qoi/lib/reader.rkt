; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  "qoi-defs.rkt"
  "image.rkt")

(provide image-read-qoi)

(define (image-read-qoi [in (current-input-port)])
  ; Read the QOI header.
  (define m (read-bytes 4 in))
  (unless (equal? qoi-magic m)
    (raise-argument-error 'image-read-qoi (bytes->string/utf-8 qoi-magic) m)))
