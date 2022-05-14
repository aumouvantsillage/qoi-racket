; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(require threading)

(provide write-qoi)

(define (write-qoi img [out (current-output-port)])
  (write-qoi-header     img out)
  (write-qoi-chunks     img out)
  (write-qoi-end-marker img out))

(define (write-qoi-header img out)
  (~>
    (list
      ; Magic bytes.
      #"qoif"
      ; Image width and height, unsigned 32-bit, big-endian.
      (integer->integer-bytes (send img get-width)  4 #f #t)
      (integer->integer-bytes (send img get-height) 4 #f #t)
      (bytes
        ; Channels: 4 for RGBA, 3 for RGB.
        (if (send img has-alpha-channel?) 4 3)
        ; Colorspace: 0 for sRGB with linear alpha, 1 for all channels linear.
        ; TODO This information cannot be retrieved from a bitmap% instance.
        0))
    (bytes-join #"")
    (write-bytes out)))

(define (write-qoi-chunks img out)
  ; Allocate a byte string for ARGB data.
  (define width  (send img get-width))
  (define height (send img get-height))
  (define blen   (* 4 width height))
  (define argb   (make-bytes blen))
  ; Fill the byte string with image data.
  ; We could decide to read it a few rows at a time.
  (send img get-argb-pixels 0 0 width height argb)
  ; Initialize the previous ARGB pixel value.
  (define pixel-prev (bytes 255 0 0 0))
  ; Allocate the index of previous pixel values.
  (define pixel-index (make-vector 64 (make-bytes 4)))
  ; Initialize the current run length.
  (define run-length 0)

  (for ([n (in-range 0 blen 4)])
    (define pixel (subbytes argb n (+ 4 n)))
    (if (equal? pixel pixel-prev)
      ; If the pixel value has not changed, increment the current run length.
      (set! run-length (add1 run-length))
      ; If the pixel value has changed, locate it in the index.
      (let ([pos (vector-member pixel pixel-index)])
        ; Write the pending runs if applicable.
        (write-qoi-op-runs run-length out)
        (set! run-length 0)
        (if pos
          ; If the current pixel is present in the index, write a QOI_OP_INDEX chunk.
          (write-qoi-op-index pos out)
          ; Otherwise, compute the difference between the current and previous pixels.
          (match-let ([(list da dr dg db dr-dg db-dg) (pixel-diff pixel pixel-prev)])
            ; If the current pixel has the same alpha as the previous pixel,
            ; write the current RGB pixel data.
            (if (zero? da)
              (cond [(and (<= -2 dr 1) (<= -2 dg 1) (<= -2 db 1))
                     (write-qoi-op-diff dr dg db out)]
                    [(and (<= -32 dg 31) (<= -8 dr-dg 7) (<= -8 db-dg 7))
                     (write-qoi-op-luma dg dr-dg db-dg out)]
                    [else
                     (write-qoi-op-rgb pixel out)])
              ; If the alpha value has changed, write the current ARGB pixel data.
              (write-qoi-op-rgba pixel out))))))
    ; Update the previous pixel value.
    (set! pixel-prev pixel)
    ; Add the current pixel to the index.
    (vector-set! pixel-index (index-position pixel) pixel))

  ; Finalize last runs.
  (write-qoi-op-runs run-length out))

(define (index-position pixel)
  (match-define (list a r g b) (bytes->list pixel))
  (remainder (+ (* 3 r) (* 5 g) (* 7 b) (* 11 a)) 64))

(define (pixel-diff pixel pixel-prev)
  (match-define (list da dr dg db)
    (map - (bytes->list pixel) (bytes->list pixel-prev)))
  (list da dr dg db (- dr dg) (- db dg)))

(define (write-qoi-op-index pos out)
  (write-byte pos out))

(define (write-qoi-op-runs len out)
  (define-values (full-runs last-len) (quotient/remainder len 62))
  (for ([n (in-range full-runs)])
    (write-byte #xFD))
  (unless (zero? last-len)
    (write-byte (+ #xC0 (sub1 last-len)))))

(define (write-qoi-op-rgb pixel out)
  (write-byte #xFE)
  (write-bytes (subbytes pixel 1 4)))

(define (write-qoi-op-rgba pixel out)
  (write-byte #xFF)
  (write-bytes (subbytes pixel 1 4))
  (write-byte (bytes-ref pixel 0)))

(define (write-qoi-op-diff dr dg db out)
  (write-byte (+ #x40 (* 16 (+ 2 dr))
                      (* 4 (+ 2 dg))
                      (+ 2 db))
              out))

(define (write-qoi-op-luma dg dr-dg db-dg out)
  (write-bytes (bytes (+ #x80 (+ 32 dg))
                      (+ (* 16 (+ 8 dr-dg))
                         (+ 8 db-dg)))
               out))

(define (write-qoi-end-marker img out)
  (write-bytes (bytes 0 0 0 0 0 0 0 1) out))
