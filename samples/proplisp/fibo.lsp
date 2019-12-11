(define fibo
  (lambda (n)
    (if (< n 2)
	n
      (+ (fibo (- n 1)) (fibo (- n 2))))))

(define calcms
  (lambda (cycles)
    (/ (+ 40000 cycles) 80000)))

(define n 0)
(define r 0)
(define elapsed 0)
(while (<= n 10)
  (begin
   (set! elapsed (getcnt))
   (set! r (fibo n))
   (set! elapsed (- (getcnt) elapsed))
   (print "fibo(" n ") = " r (calcms elapsed) "ms (" elapsed " cycles)" nl)
   (set! n (+ n 1))))

(print "done fibo test" nl)
