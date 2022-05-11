; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(provide write-qoi)

(define (write-qoi img [out (current-output-port)])
  (write-qoi-header     img out)
  (write-qoi-chunks     img out)
  (write-qoi-end-marker img out))

(define (write-qoi-header img out)
  (write-bytes #"qoif" out)
  (write-uint32 (send img get-width) out)
  (write-uint32 (send img get-height) out)
  (write-byte (if (send img has-alpha-channel?) 4 3) out)
  (write-byte 0 out)) ; Assume sRGB with linear Alpha

(define (write-qoi-chunks img out)
  (void))

(define (write-qoi-end-marker img out)
  (write-bytes (bytes 0 0 0 0 0 0 0 1) out))

(define (write-uint32 v out)
  (write-bytes (integer->integer-bytes v 4 #f #t)))
