#lang racket

(require "lib/shared.rkt")
(require rackunit)

; Definition
; Arithmetic Expression: An atom (incl numbers) or two arithm_expr combined with + x ^

(define numbered_raw?
  (lambda (aexp)
    (cond
      ((atom? aexp) (number? aexp)) ; if it is atom, it return the result of is_this_atom_a_number? (not the list!)
      (else
       (cond
        ((eq? (car (cdr aexp)) '+) (and (numbered_raw? (car aexp)) (numbered_raw? (car (cdr (cdr aexp))))))
        ((eq? (car (cdr aexp)) 'x) (and (numbered_raw? (car aexp)) (numbered_raw? (car (cdr (cdr aexp))))))
        ((eq? (car (cdr aexp)) '^) (and (numbered_raw? (car aexp)) (numbered_raw? (car (cdr (cdr aexp)))))))))))

(module+ test
  (check-false (numbered_raw? '(pepe + juan)))
  (check-true  (numbered_raw? '(1 + 2)))
  (check-true  (numbered_raw? '(1 + (2 + 1))))
  (check-true  (numbered_raw? '((1 x 2) ^ (2 + (1 + 1))))))

; If we assume that the aexp will always be well formed
; we can ignore the + x ^, and only look at the numbers themselves

(define numbered?
  (lambda (aexp)
    (cond
      ((atom? aexp) (number? aexp))
      (else (and (numbered? (car aexp)) 
                 (numbered? (car (cdr (cdr aexp)))))))))

(module+ test
  (check-false (numbered? '(pepe + juan)))
  (check-true  (numbered? '(1 + 2)))
  (check-true  (numbered? '(1 + (2 + 1))))
  (check-true  (numbered? '((1 x 2) ^ (2 + (1 + 1))))))

;;;;;;;;;;;; FROM CHAPTER 4
(define ✢ ; <-------------------------------- ADD
  (lambda (n m)
    (cond
      ((zero? m) n)
      (else (add1 (✢ n (sub1 m)))))))

(define x ; <-------------------------------- MUTIPLY
  (lambda (n m)
    (cond
      ((zero? m) 0)
      (else (✢ n (x n (sub1 m)))))))

(define ^ ; <-------------------------------- EXPONENTIATION
  (lambda (n m)
    (cond
      ((zero? m) 1)
      (else (x n (^ n (sub1 m)))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define value
  (lambda (nexp)
    (cond
      ((atom? nexp) nexp)
      (else
       (cond
         ((eq? (car (cdr nexp)) '+) (✢ (value (car nexp)) (value (car (cdr (cdr nexp))))))
         ((eq? (car (cdr nexp)) 'x) (x (value (car nexp)) (value (car (cdr (cdr nexp))))))
         ((eq? (car (cdr nexp)) '^) (^ (value (car nexp)) (value (car (cdr (cdr nexp)))))))))))

(module+ test
  (check-equal? (value '(2 + 3)) 5)
  (check-equal? (value '(2 x 3)) 6)
  (check-equal? (value '(2 ^ 3)) 8)
  (check-equal? (value '(2 + (1 + 2))) 5))

; SEVENTH COMMANDMENT
; Recur on the subparts of the same nature
;   - on sublists of lists
;   - on subexpr of expressions

(define value_my_prn
  (lambda (nexp)
    (cond
      ((atom? nexp) nexp)
      (else
       (cond
         ((eq? (car nexp) '+) (✢ (value_my_prn (car (cdr nexp))) (value_my_prn (car (cdr (cdr nexp))))))
         ((eq? (car nexp) 'x) (x (value_my_prn (car (cdr nexp))) (value_my_prn (car (cdr (cdr nexp))))))
         ((eq? (car nexp) '^) (^ (value_my_prn (car (cdr nexp))) (value_my_prn (car (cdr (cdr nexp)))))))))))

(module+ test
  (check-equal? (value_my_prn '(+ 2 3)) 5)
  (check-equal? (value_my_prn '(x 2 3)) 6)
  (check-equal? (value_my_prn '(^ 2 3)) 8)
  (check-equal? (value_my_prn '(+ 2 (+ 1 (+ 1 1)))) 5))

; We can clarify and simplify by extracting sub methods

(define 1st-sub-exp
  (lambda (nexp)
    (car (cdr nexp))))

(define 2nd-sub-exp
  (lambda (nexp)
    (car (cdr (cdr nexp)))))

(define operator
  (lambda (nexp)
    (car nexp)))

(define value_2
  (lambda (nexp)
    (cond
      ((atom? nexp) nexp)
      (else
       (cond
         ((eq? (operator nexp) '+) (✢ (value_2 (1st-sub-exp nexp)) (value_2 (2nd-sub-exp nexp))))
         ((eq? (operator nexp) 'x) (x (value_2 (1st-sub-exp nexp)) (value_2 (2nd-sub-exp nexp))))
         ((eq? (operator nexp) '^) (^ (value_2 (1st-sub-exp nexp)) (value_2 (2nd-sub-exp nexp)))))))))

(module+ test
  (check-equal? (value_2 '(+ 2 3)) 5)
  (check-equal? (value_2 '(x 2 3)) 6)
  (check-equal? (value_2 '(^ 2 3)) 8)
  (check-equal? (value_2 '(+ 2 (+ 1 2))) 5))

; EIGHTH COMMANDMENT
; after tests pass, and simplifying, apply DRY by extracting helper methods 
;
; similar to 4 pr of simple design: 1) test pass 2) expressive/simplify 3) DRY 4) minimize

; fun with weirdness

(define sero?
  (lambda (n)
    (null? n)))

(define edd1
  (lambda (n)
    (cons '() n))) ; aint the same (cons '() n) than (cons n '())

(define zub1
  (lambda (n)
    (cond
      ((sero? n) n) ; I rather check
      (else (cdr n)))))

(module+ test
  (check-true  (sero? '()))
  (check-false (sero? '(())))
  (check-equal? (edd1 '()) '(()))
  (check-equal? (edd1 '(() ())) '(() () ()))
  (check-equal? (zub1 '(() ())) '(()))
  (check-equal? (zub1 '()) '())
  )

(define w+
  (lambda (n m)
    (cond
      ((sero? m) n)
      (else (w+ (edd1 n) (zub1 m))))))  ; my version
      ;(else (edd1 (w+ n (zub1 m))))))) ; the book's version

(module+ test
  (check-equal? (w+ '(() ()) '(())) '(() () ()))
  (check-equal? (w+ '() '(())) '(()))
  (check-equal? (w+ '(()) '(())) '(() ()))
  (check-equal? (w+ '() '()) '())
  )

(define lat?
  (lambda (lat)
    (cond
      ((null? lat) #t)
      ((atom? (car lat)) (lat? (cdr lat)))
      (else #f)))) ; dont get the point of the shadows joke

(module+ test
  (check-false (lat? '(() () ()))))