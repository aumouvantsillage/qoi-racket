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
    (raise-argument-error 'image-read-qoi (bytes->string/utf-8 qoi-magic) m))
  (define img (make-image
                ; Image width and height, unsigned 32-bit, big-endian.
                (integer-bytes->integer (read-bytes 4 in) #f #t)
                (integer-bytes->integer (read-bytes 4 in) #f #t)
                ; Channels and colorspace.
                (read-byte in)
                (read-byte in)))

  ; Get the ARGB pixel data buffer of the image.
  (define pixels (image-pixels img))
  ; Allocate the index of previous pixel values.
  (define pixel-index (make-vector 64 (make-bytes 4)))

  ; Decode the QOI data chunks.
  (for/fold ([pixel-prev qoi-pixel-init]
             [n 0])
            ([_ (in-naturals)])
            #:break (>= n (bytes-length pixels))
    (define b (read-byte in))
    (when (equal? eof b)
      (error (format "Unexpected end of file at: ~a/~a" n (bytes-length pixels))))
    (define b2 (bitwise-and b qoi-op-mask))
    (define b6 (- b b2))
    ; Identify the current chunk type.
    (define-values (pixel incr)
      (cond
        [(= b  qoi-op-rgb)   (read-qoi-op-rgb   pixels n pixel-prev (read-bytes 3 in))]
        [(= b  qoi-op-rgba)  (read-qoi-op-rgba  pixels n            (read-bytes 4 in))]
        [(= b2 qoi-op-index) (read-qoi-op-index pixels n pixel-index b6)]
        [(= b2 qoi-op-diff)  (read-qoi-op-diff  pixels n pixel-prev  b6)]
        [(= b2 qoi-op-luma)  (read-qoi-op-luma  pixels n pixel-prev  b6 (read-byte in))]
        [(= b2 qoi-op-run)   (read-qoi-op-run   pixels n pixel-prev  b6)]))
    (vector-set! pixel-index (qoi-index-position pixel) pixel)
    (values pixel (+ n incr)))
  img)

(define (read-qoi-op-index pixels n pixel-index pos)
  (update pixels n (vector-ref pixel-index pos)))

(define (read-qoi-op-diff pixels n pixel-prev b)
  (define-values (dr dgb) (quotient/remainder b   16))
  (define-values (dg db)  (quotient/remainder dgb 4))
  (update pixels n
          (list->bytes (map qoi+ (bytes->list pixel-prev)
                                 (list dr dg db 0)
                                 (list -2 -2 -2 0)))))

(define (read-qoi-op-luma pixels n pixel-prev dg b1)
  (define-values (dr-dg db-dg) (quotient/remainder b1 16))
  (update pixels n
          (list->bytes (map qoi+ (bytes->list pixel-prev)
                                 (list dr-dg  dg db-dg 0)
                                 (list    dg   0    dg 0)
                                 (list   -40 -32   -40 0)))))

(define (read-qoi-op-run pixels n pixel-prev b)
  (define run (- b qoi-op-run-bias))
  (update pixels n pixel-prev (apply bytes-append (make-list run pixel-prev))))

(define (read-qoi-op-rgb pixels n pixel-prev rgb)
  (update pixels n (bytes-append rgb (subbytes pixel-prev 3 4))))

(define (read-qoi-op-rgba pixels n rgba)
  (update pixels n rgba))

(define (update pixels n pix [bs pix])
  (bytes-copy! pixels n bs)
  (values pix (bytes-length bs)))

; 95 95 F0 B9
; 7C = 01 11 11 00
; dr = 1 dg = 1 db = -2
;
;
; diff = #x40 + 16(dr + 2) + 4(dg + 2) + (db + 2)
;      = #x40 + 16dr + 4dg + db + 42
; diff - #x40 - 42 = 16dr + 4dg + db
