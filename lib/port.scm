

(define peek-char
  (lambda ((port (current-input-port)))
    (ruby:send port 'peek_char)))

(define read-char
  (lambda ((port (current-input-port)))
    (ruby:send port 'read_char)))


(define write
  (lambda (obj (port (current-output-port)))
    (ruby:send port 'write obj)))

(define newline
  (lambda ((port (current-output-port)))
    (ruby:send port 'write obj)))

(define write-char
  (lambda (c (port (current-output-port)))
    (ruby:send port 'write_char c)))

(define display
  (lambda (obj (port (current-output-port)))
    (ruby:send port 'display obj)))
