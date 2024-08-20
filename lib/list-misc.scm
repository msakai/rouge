(define endp (lambda (x) (null? x)))

(define first   (lambda (x) (nth 0 x)))
(define second  (lambda (x) (nth 1 x)))
(define third   (lambda (x) (nth 2 x)))
(define fourth  (lambda (x) (nth 3 x)))
(define fifth   (lambda (x) (nth 4 x)))
(define sixth   (lambda (x) (nth 5 x)))
(define seventh (lambda (x) (nth 6 x)))
(define eighth  (lambda (x) (nth 7 x)))
(define ninth   (lambda (x) (nth 8 x)))
(define tenth   (lambda (x) (nth 9 x)))
(define rest    (lambda (x) (cdr x)))

(define last
  (lambda (x)
    (if (or (null? x) (null? (cdr x))) x
        (last (cdr x)))))
