(define char-alphabetic?
  (lambda (char)
    (ruby:send char 'alphabetic?)))

(define char-numeric?
  (lambda (char)
    (ruby:send char 'numeric?)))

(define char-whitespace?
  (lambda (char)
    (ruby:send char 'whitespace?)))

(define char-upper-case?
  (lambda (char)
    (ruby:send char 'upper_case?)))

(define char-lower-case?
  (lambda (char)
    (ruby:send char 'lower_case?)))


(define char-upcase
  (lambda (char)
    (ruby:send char 'upcase)))

(define char-downcase
  (lambda (char)
    (ruby:send char 'downcase)))

(define char=?
  (lambda (char1 char2)
    (ruby:send char1 '== char2)))

(define char<?
  (lambda (char1 char2)
    (ruby:send char1 '< char2)))

(define char>?
  (lambda (char1 char2)
    (ruby:send char1 '> char2)))

(define char<=?
  (lambda (char1 char2)
    (ruby:send char1 '<= char2)))

(define char>=?
  (lambda (char1 char2)
    (ruby:send char1 '>= char2)))

(define char-ci=?
  (lambda (char1 char2)
    (ruby:send (char-downcase char1) '== (char-downcase char2))))

(define char-ci<?
  (lambda (char1 char2)
    (ruby:send (char-downcase char1) '< (char-downcase char2))))

(define char-ci>?
  (lambda (char1 char2)
    (ruby:send (char-downcase char1) '> (char-downcase char2))))

(define char-ci<=?
  (lambda (char1 char2)
    (ruby:send (char-downcase char1) '<= (char-downcase char2))))

(define char-ci>=?
  (lambda (char1 char2)
    (ruby:send (char-downcase char1) '>= (char-downcase char2))))

(define char->integer
  (lambda (char)
    (ruby:send char 'to_i)))
