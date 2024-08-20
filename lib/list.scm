(define caar   (lambda (x) (car (car x))))
(define cadr   (lambda (x) (car (cdr x))))
(define cdar   (lambda (x) (cdr (car x))))
(define cddr   (lambda (x) (cdr (cdr x))))
(define caaar  (lambda (x) (caar (car x))))
(define caadr  (lambda (x) (caar (cdr x))))
(define cadar  (lambda (x) (cadr (car x))))
(define caddr  (lambda (x) (cadr (cdr x))))
(define cdaar  (lambda (x) (cdar (car x))))
(define cdadr  (lambda (x) (cdar (cdr x))))
(define cddar  (lambda (x) (cddr (car x))))
(define cdddr  (lambda (x) (cddr (cdr x))))
(define caaaar (lambda (x) (caaar (car x))))
(define caaadr (lambda (x) (caaar (cdr x))))
(define caadar (lambda (x) (caadr (car x))))
(define caaddr (lambda (x) (caadr (cdr x))))
(define cadaar (lambda (x) (cadar (car x))))
(define cadadr (lambda (x) (cadar (cdr x))))
(define caddar (lambda (x) (caddr (car x))))
(define cadddr (lambda (x) (caddr (cdr x))))
(define cdaaar (lambda (x) (cdaar (car x))))
(define cdaadr (lambda (x) (cdaar (cdr x))))
(define cdadar (lambda (x) (cdadr (car x))))
(define cdaddr (lambda (x) (cdadr (cdr x))))
(define cddaar (lambda (x) (cddar (car x))))
(define cddadr (lambda (x) (cddar (cdr x))))
(define cdddar (lambda (x) (cdddr (car x))))
(define cddddr (lambda (x) (cdddr (cdr x))))

(define listp (lambda (x) (or (consp x) (null? x))))

(define length
  (lambda (x)
    (if (null? x)
        0
        (+ 1 (length (cdr x))))))

(define list (lambda x x))

(define copy-list
  (lambda (x)
    (if (null? x)
        '()
        (cons (car x) (copy-list (cdr x))))))

(define append
  (lambda (x y)
    (if (null? x) (copy-list y)
        (cons (car x) (append (cdr x) y)))))

(define reverse
  (lambda (src &optional dest)
    (if (null? src) dest
      (reverse (cdr src) (cons (car src) dest)))))

(define list-tail
  (lambda (x k)
    (if (zero? k)
        x 
        (list-tail (cdr x) (- k 1)))))

(define list-ref
  (lambda (list k)
    (car (list-tail list k))))

(define member-if
  (lambda (x list func)
    (if (null? list)
        #f
        (if (func x (car list)) list
            (member-if x (cdr list) func)))))

(define memq (lambda (x list) (member-if x list eq?)))
(define memv (lambda (x list) (member-if x list eqv?)))
(define member (lambda (x list) (member-if x list equal?)))

(define assoc-if
  (lambda (obj alist func)
    (if (null? alist)
        #f
        (if (func obj (car (car alist)))
            (car alist)
            (assoc-if obj (cdr alist) func)))))

(define assq (lambda (obj alist) (assoc-if obj alist eq?)))
(define assv (lambda (obj alist) (assoc-if obj alist eqv?)))
(define assoc (lambda (obj alist) (assoc-if obj alist equal?)))
