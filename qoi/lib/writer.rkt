; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require
  "qoi-defs.rkt"
  "image.rkt")

(provide image-write-qoi)

(define (image-write-qoi img [out (current-output-port)])
  ; Write the QOI header.
  (write-bytes
    (bytes-append
      qoi-magic
      ; Image width and height, unsigned 32-bit, big-endian.
      (integer->integer-bytes (image-width  img) 4 #f #t)
      (integer->integer-bytes (image-height img) 4 #f #t)
      (bytes
        (image-channels   img)
        (image-colorspace img)))
    out)

  ; Get the ARGB pixel data from the image.
  (define pixels (image-pixels img))
  ; Allocate the index of previous pixel values.
  (define pixel-index (make-vector 64 (make-bytes 4)))

  (define last-run-length
    ; Process pixels in raster-scan order.
    ; The loop will return the length of the last run.
    (for/fold ([pixel-prev qoi-pixel-init]
               [run-length 0]
               #:result run-length)
              ([n (in-range 0 (bytes-length pixels) 4)])
      (define pixel (subbytes pixels n (+ 4 n)))
      ; Check whether we are continuing a run.
      (if (equal? pixel pixel-prev)
        ; If the pixel value has not changed, increment the current run length.
        (values pixel (add1 run-length))
        ; If the pixel value has changed, locate it in the index.
        (let ([pos (qoi-index-position pixel)])
          (apply eprintf "~x ~x ~x ~x\n" (bytes->list pixel))
          ; Write the previous runs if applicable.
          (write-qoi-op-runs run-length out)
          ; Check whether the current pixel is present in the index.
          (if (equal? pixel (vector-ref pixel-index pos))
            ; If the current pixel is present in the index, write a QOI_OP_INDEX chunk.
            (write-qoi-op-index pos out)
            ; Otherwise, compute the difference from the previous to the current pixel.
            (let-values ([(da dr dg db dr-dg db-dg) (pixel-diff pixel pixel-prev)])
              ; Add the current pixel to the index.
              (vector-set! pixel-index pos pixel)
              ; Check whether differential or luma encoding can be applied.
              (cond [(not (zero? da))
                     ; If the alpha value has changed, write the new ARGB pixel data (QOI_OP_RGBA).
                     (write-qoi-op-rgba pixel out)]
                    [(and (<= -2 dr 1) (<= -2 dg 1) (<= -2 db 1))
                     ; If the RGB deltas are small enough, encode the differences (QOI_OP_DIFF).
                     (write-qoi-op-diff dr dg db out)]
                    [(and (<= -32 dg 31) (<= -8 dr-dg 7) (<= -8 db-dg 7))
                     ; Use the green delta as a reference to encode the relative
                     ; red and blue deltas (QOI_OP_LUMA).)
                     (write-qoi-op-luma dg dr-dg db-dg out)]
                    [else
                     ; As a fallback, write the RGB data (QOI_OP_RGB).
                     (write-qoi-op-rgb pixel out)])))
          ; Reset the current run length.
          (values pixel 0)))))
  ; Write the last run if applicable.
  (write-qoi-op-runs last-run-length out)
  ; Write the QOI end marker.
  (write-bytes qoi-end-marker out))

(define (pixel-diff pixel pixel-prev)
  (match-define (list da dr dg db)
    (map qoi- (bytes->list pixel) (bytes->list pixel-prev)))
  (values da dr dg db (qoi- dr dg) (qoi- db dg)))

(define (write-qoi-op-index pos out)
  (write-byte (+ qoi-op-index pos) out))

(define (write-qoi-op-runs len out)
  (define-values (full-runs last-len) (quotient/remainder len qoi-op-run-maxlen))
  (for ([n (in-range full-runs)])
    (write-byte qoi-op-run-full))
  (unless (zero? last-len)
    (write-byte (+ qoi-op-run last-len qoi-op-run-bias))))

(define (write-qoi-op-rgb pixel out)
  (write-byte qoi-op-rgb)
  ; Write the RGB part of the ARGB data.
  (write-bytes (subbytes pixel 1 4)))

(define (write-qoi-op-rgba pixel out)
  (write-byte qoi-op-rgba)
  ; Write the RGB part of the ARGB data, and then the alpha value.
  (write-bytes (subbytes pixel 1 4))
  (write-byte (bytes-ref pixel 0)))

(define (write-qoi-op-diff dr dg db out)
  (write-byte (+ qoi-op-diff (* 16 dr) (* 4 dg) db qoi-op-diff-bias) out))

(define (write-qoi-op-luma dg dr-dg db-dg out)
  (write-bytes (bytes (+ qoi-op-luma dg qoi-op-luma-dg-bias)
                      (+ (* 16 dr-dg) db-dg qoi-op-luma-drdb-bias)) out))
