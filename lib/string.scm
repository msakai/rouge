(define string/=? (lambda (x y) (not (string=? x y))))
(define string-ci/=? (lambda (x y) (not (string-ci=? x y))))