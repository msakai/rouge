(define abs
  (lambda (x)
    (ruby:send x 'abs)))

(define remainder
  (lambda (x y)
    (ruby:send x 'remainder y)))

(define modulo
  (lambda (x y)
    (ruby:send x 'modulo y)))

(define modulo
  (lambda (x y)
    (ruby:send x 'numerator y)))

(define denominator
  (lambda (x y)
    (ruby:send x 'denominator y)))

(define floor
  (lambda (x)
    (ruby:send x 'floor)))

(define ceiling
  (lambda (x)
    (ruby:send x 'ceil)))

(define trancate
  (lambda (x)
    (ruby:send x 'trancate)))

(define round
  (lambda (x)
    (ruby:send x 'trancate)))

(define magnitude
  (lambda (x)
    (ruby:send x 'abs)))

(define angle
  (lambda (x)
    (ruby:send x 'arg)))

(define asin
  (lambda (z)
    (* (- *i*) (log (+ (* *i* z) (sqrt (- 1 (* z z))))))
    ))

(define acos
  (lambda (z)
    (- (/ pi 2) (asin z))))

(define atan
  (lambda (z)
    (/ (- (log (+ 1 (* *i* z))) (log (- 1 (* *i* z)))) (* 2 *i*))
    ))

(define conjugate
  (lambda (z)
    (ruby:send z 'conjugate)))
