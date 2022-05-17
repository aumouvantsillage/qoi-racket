; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

#lang racket

(provide (all-defined-out))

(define qoi-pixels-max 400000000)

(define qoi-colorspace-srgb   0)
(define qoi-colorspace-linear 1)

; Magic bytes at the beginning of the QOI header.
(define qoi-magic #"qoif")

; Chunk identification bits
(define qoi-op-index #x00)
(define qoi-op-diff  #x40)
(define qoi-op-luma  #x80)
(define qoi-op-run   #xC0)
(define qoi-op-rgb   #xFE)
(define qoi-op-rgba  #xFF)
(define qoi-end-marker (bytes 0 0 0 0 0 0 0 1))

(define qoi-op-mask  #xC0)

; Biases. diff and luma are cumulated for all fields.
(define qoi-op-run-bias  -1)
(define qoi-op-diff-bias 42)
(define qoi-op-luma-dg-bias 32)
(define qoi-op-luma-drdb-bias 136)

(define qoi-op-run-maxlen 62)
(define qoi-op-run-full (+ qoi-op-run qoi-op-run-maxlen qoi-op-run-bias))

; Initial value of the previous pixel in the encoder/decoder (ARGB).
(define qoi-pixel-init (bytes 255 0 0 0))

; Hash function for the pixel index.
(define (qoi-index-position pixel)
  (match-define (list a r g b) (bytes->list pixel))
  (remainder (+ (* 3 r) (* 5 g) (* 7 b) (* 11 a)) 64))

(define (qoi- a b)
  (define a-b (- a b))
  (cond [(> a-b  127) (- a-b 256)]
        [(< a-b -128) (+ a-b 256)]
        [else            a-b]))

(define (qoi+ a b)
  (bitwise-and #xFF (+ a b)))
