(define /= (lambda (x y) (not (= x y))))
(define atom (lambda (x) (not (consp x))))
(define identity (lambda (x) x))
(define lognand  (lambda (x y) (lognot (logand x y))))
(define lognor   (lambda (x y) (lognot (logor x y))))
(define logandc1 (lambda (x y) (logand (lognot x) y)))
(define logandc2 (lambda (x y) (logand x (lognot y))))
(define logorc1  (lambda (x y) (logor (lognot x) y)))
(define logorc2  (lambda (x y) (logor x (lognot y))))
(define logtest  (lambda (x y) (not (zero? (logand x y)))))

(define 1+ (lambda (x) (+ x 1)))
(define 1- (lambda (x) (- x 1)))
