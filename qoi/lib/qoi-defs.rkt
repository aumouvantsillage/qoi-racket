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
(define qoi-op-run-bias -1)
(define qoi-op-diff-bias 2)
(define qoi-op-luma-dg-bias 32)
(define qoi-op-luma-drb-bias 8)

(define qoi-op-run-maxlen 62)

; Initial value of the previous pixel in the encoder/decoder (RGBA).
(define qoi-pixel-init (bytes 0 0 0 255))

; Hash function for the pixel index.
(define (qoi-index-position pixel)
  (match-define (list r g b a) (bytes->list pixel))
  (remainder (+ (* 3 r) (* 5 g) (* 7 b) (* 11 a)) 64))

(define (can-use-op-diff? dr dg db)
  (define lo (- qoi-op-diff-bias))
  (define hi (sub1 qoi-op-diff-bias))
  (and (<= lo dr hi) (<= lo dg hi) (<= lo db hi)))

(define (can-use-op-luma? dg dr-dg db-dg)
  (define dg-lo (- qoi-op-luma-dg-bias))
  (define dg-hi (sub1 qoi-op-luma-dg-bias))
  (define drb-lo (- qoi-op-luma-drb-bias))
  (define drb-hi (sub1 qoi-op-luma-drb-bias))
  (and (<= dg-lo dg dg-hi) (<= drb-lo dr-dg drb-hi) (<= drb-lo db-dg drb-hi)))

(define (qoi- a b)
  (define a-b (- a b))
  (cond [(> a-b  127) (- a-b 256)]
        [(< a-b -128) (+ a-b 256)]
        [else            a-b]))

(define (qoi+ . args)
  (bitwise-and #xFF (apply + args)))
