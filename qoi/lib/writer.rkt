; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  "qoi-defs.rkt"
  "image.rkt")

(provide image-write-qoi)

(define (image-write-qoi img [out (current-output-port)])
  (write-qoi-header img out)
  (write-qoi-data img out)
  (write-bytes qoi-end-marker out))

(define (write-qoi-header img out)
  (write-bytes
    (bytes-append
      qoi-magic
      ; Image width and height, unsigned 32-bit, big-endian.
      (integer->integer-bytes (image-width  img) 4 #f #t)
      (integer->integer-bytes (image-height img) 4 #f #t)
      (bytes
        (image-channels   img)
        (image-colorspace img)))
    out))

(define (write-qoi-data img out)
  ; Get the ARGB pixel data from the image.
  (define pixels (image-pixels img))
  ; Allocate the index of previous pixel values.
  (define pixel-index (make-vector 64 (make-bytes 4)))
  ; Process pixels in raster-scan order and write QOI chunks to the output
  ; port, except for a possible last run.
  (define last-run-length
    (for/fold ([pixel-prev qoi-pixel-init]
               [run-length 0]
               #:result run-length)
              ([n (in-range 0 (bytes-length pixels) 4)])
      (define pixel (subbytes pixels n (+ 4 n)))
      (cond
        [(equal? pixel pixel-prev)
         (values pixel (add1 run-length))]
        [else
         (write-qoi-op-runs run-length out)
         (write-qoi-chunk pixel pixel-prev pixel-index out)
         (values pixel 0)])))
  ; Write the last runs if applicable.
  (write-qoi-op-runs last-run-length out))

(define (write-qoi-chunk pixel pixel-prev pixel-index out)
  (define pos (qoi-index-position pixel))
  (cond
    [(equal? pixel (vector-ref pixel-index pos))
     (write-qoi-op-index pos out)]
    [else
     (vector-set! pixel-index pos pixel)
     (define-values (dr dg db da dr-dg db-dg) (pixel-diff pixel pixel-prev))
     (cond
       [(not (zero? da))
        (write-qoi-op-rgba pixel out)]
       [(can-use-op-diff? dr dg db)
        (write-qoi-op-diff dr dg db out)]
       [(can-use-op-luma? dg dr-dg db-dg)
        (write-qoi-op-luma dg dr-dg db-dg out)]
       [else
        (write-qoi-op-rgb pixel out)])]))

(define (pixel-diff pixel pixel-prev)
  (match-define (list dr dg db da)
    (map qoi- (bytes->list pixel) (bytes->list pixel-prev)))
  (values dr dg db da (qoi- dr dg) (qoi- db dg)))

(define (write-qoi-op-index pos out)
  (write-byte (+ qoi-op-index pos) out))

(define qoi-op-run-full (+ qoi-op-run qoi-op-run-maxlen qoi-op-run-bias))

(define (write-qoi-op-runs len out)
  (define-values (full-runs last-len) (quotient/remainder len qoi-op-run-maxlen))
  (for ([n (in-range full-runs)])
    (write-byte qoi-op-run-full))
  (unless (zero? last-len)
    (write-byte (+ qoi-op-run last-len qoi-op-run-bias))))

(define (write-qoi-op-rgb pixel out)
  (write-byte qoi-op-rgb)
  ; Write the RGB part of the RGBA data.
  (write-bytes (subbytes pixel 0 3)))

(define (write-qoi-op-rgba pixel out)
  (write-byte qoi-op-rgba)
  (write-bytes pixel))

(define qoi-op-diff-bias/w (* qoi-op-diff-bias (+ 16 4 1)))

(define (write-qoi-op-diff dr dg db out)
  (write-byte (+ qoi-op-diff (* 16 dr) (* 4 dg) db qoi-op-diff-bias/w) out))

(define qoi-op-luma-drb-bias/w (* qoi-op-luma-drb-bias (+ 16 1)))

(define (write-qoi-op-luma dg dr-dg db-dg out)
  (write-bytes (bytes (+ qoi-op-luma dg qoi-op-luma-dg-bias)
                      (+ (* 16 dr-dg) db-dg qoi-op-luma-drb-bias/w)) out))
