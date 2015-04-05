#lang racket/base

(require rackunit)
(require "prelude.rkt")

(require "ch17.rkt")

(define toppings void)

(define (deepB m)
  (cond
    [(zero? m)
     (let/cc jump
       (set! toppings jump)
       'pizza)]
    [else (cons (deepB (sub1 m)) '())]))

; let/cc was messing up the test-case & check-equal? :/
(deepB 6) ; '((((((pizza))))))
(toppings 'mozzeralla) ; '((((((mozzeralla))))))
(toppings 'cake) ; '((((((cake))))))
(toppings '(pizza)) ; '(((((((pizza)))))))
(cons (toppings 'cake) '()) ; '(((((((cake)))))))
(cons (cons (cons (toppings 'mozzarella) '()))) ; '(((((((mozzarella)))))))

(deepB 4) ; '((((pizza))))
(cons (cons (cons (toppings 'mozzarella) '()))) ; '((((mozzarella))))
; as well as...
(toppings 'mozzarella) ; '((((mozzarella))))

(cons (toppings 'cake) (toppings 'cake)) ; '((((cake))))

(define (deep&coB m k)
  (cond
    [(zero? m)
     (begin
       (set! toppings k)
       (k 'pizza))]
    [else
      (deep&coB (sub1 m)
         (lambda (x)
           (k (cons x '()))))]))

(test-case "deep&coB"
  (check-equal? (deep&coB 6 (lambda (x) x)) '((((((pizza)))))))
  (check-equal? (deep&coB 2 (lambda (x) x)) '((pizza)))
  (check-equal? (deep&coB 4 (lambda (x) x)) '((((pizza)))))
  (check-equal? (cons (toppings 'cake) (toppings 'cake)) '(((((cake)))) (((cake)))))
  (check-equal? (cons (toppings 'cake)
                  (cons (toppings 'mozzarella)
                    (cons (toppings 'pizza) '())))
                '(((((cake)))) ((((mozzarella)))) ((((pizza)))))))
; Yay! deepB without the crazy letccing

(define leave (lambda (x) x)) ; provide a default implementation for testing

(define (walk l)
  (cond
    [(null? l) '()]
    [(atom? (car l)) (leave (car l))]
    [else
      (begin
        (walk (car l))
        (walk (cdr l)))]))

(test-case "walk"
  (check-equal? (walk '((potato) (chips (chips (with))) fish)) 'fish))

(define (start-it l)
  (let/cc here
    (set! leave here)
    (walk l)))

(test-case "start-it"
  (check-equal? (start-it '((potato) (chips (chips (with))) fish)) 'potato))

(define fill void)

(define (waddle l)
  (cond
    [(null? l) '()]
    [(atom? (car l))
     (begin
       (let/cc rest
         (set! fill rest)
         (leave (car l)))
       (waddle (cdr l)))]
    [else
      (begin
        (waddle (car l))
        (waddle (cdr l)))]))

(define (start-it2 l)
  (let/cc here
    (set! leave here)
    (waddle l)))

(define (get-next x)
  (let/cc here-again
    (set! leave here-again)
    (fill 'go)))

(test-case "waddle"
  (check-equal? (start-it2 '((donuts)
                             (cheerios (cheerios (spaghettios)))
                             donuts))
                'donuts)
  (check-equal? (get-next 'go) 'cheerios)
  (check-equal? (get-next 'go) 'cheerios)
  (check-equal? (get-next 'go) 'spaghettios)
  (check-equal? (get-next 'go) 'donuts))
  ; (check-equal? (get-next 'go) '())) ; can't run because then start-it2 gets called again :/

(define (get-first l)
  (let/cc here
    (set! leave here)
    (waddle l)
    (leave '())))

(test-case "waddling some more"
  (check-equal? (get-first '(donut)) 'donut)
  (check-equal? (get-next 'go) '())
  (check-equal? (get-first '(fish (chips))) 'fish)
  (check-equal? (get-next 'go) 'chips)
  (check-equal? (get-next 'go) '()))

(define two-in-a-row*?
  (letrec
    ([T? (lambda (a)
           (let ([n (get-next 0)])
             (if (atom? n)
               (or (eq? n a)
                   (T? n))
               #f)))]
     [get-next
       (lambda (x)
         (let/cc here-again
                 (set! leave here-again)
                 (fill 'go)))]
     [fill (lambda (x) x)]
     [waddle
       (lambda (l)
         (cond
           [(null? l) '()]
           [(atom? (car l))
            (begin
              (let/cc rest
                      (set! fill rest)
                      (leave (car l)))
              (waddle (cdr l)))]
           [else (begin
                   (waddle (car l))
                   (waddle (cdr l)))]))])
    (lambda (l)
      (let ([fst (let/cc here
                         (set! leave here)
                         (waddle l)
                         (leave '()))])
        (if (atom? fst) (T? fst) #f)))))

; yikes!

(test-case "two-in-a-row*?"
  (check-false (two-in-a-row*? '((mozzarella) (cake) mozzarella)))
  (check-true (two-in-a-row*? '((potato) (chips ((with) fish) fish)))))