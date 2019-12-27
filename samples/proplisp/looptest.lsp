(define forloop
  (lambda (i n body)
    (if (<= i n)
	(begin
	 (body i)
	 (forloop (+ i 1) n body)))))

(forloop 1 10
	 (lambda (i) (print i nl)))

