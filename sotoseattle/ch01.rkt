#lang racket

(require "lib/shared.rkt")
(require rackunit)
(require (only-in racket/function thunk))

; ______________ATOMS______________
'atom
'turkey
'1942
'u
'*abc$

; ______________LISTS______________
'(atom)
'(atom turkey or)
'((atom turkey) or)
'(how are you doing so far)

; ______________S Expression______________
'xyz
'(x y z)
'((x y) z)

; a list is a collection of S-expressions inside parenthesis (level 1)
'(how are you doing so far)            ; # S-exp = 6 atoms
'(((how) are) ((you) (doing so)) far)  ; # S-exp = 1 atom and 2 lists
'()            ; is a list with no S-exp inside. This S-exp is called the null or empty list
'(() () () ()) ; is a list with 4 S-exp (lists) inside

; ______________CAR______________
; first element of a list, returns an element of the list (list or atom)

(check-equal? (car '(a b c)) 'a)
(check-equal? (car '((a b c) x y)) '(a b c))
(check-exn exn:fail? (thunk (car 'atom))) ; error, only works on lists
(check-exn exn:fail? (thunk (car '())))   ; error THE PRIMITIVE LAW OF CAR!!!
(check-equal? (car '(((hotdogs)) (and) (pickle) relish)) '((hotdogs))) ; the list of the list of hotdogs
(check-equal? (car (car '(((hotdogs)) (and) (pickle) relish))) '(hotdogs))
(check-equal? (car (car (car '(((hotdogs)) (and) (pickle) relish)))) 'hotdogs)

; ______________CDR______________
; could'er => the list without car (the list!), returns a list

(check-equal? (cdr '(a b c)) '(b c))
(check-equal? (cdr '((a b c) x y)) '(x y))
(check-equal? (cdr '(hamburger)) '())
(check-equal? (cdr '((x) t r)) '(t r))

(check-exn exn:fail? (thunk (cdr 'atom))) ; error, only works on lists
(check-exn exn:fail? (thunk (cdr '())))   ; error THE PRIMITIVE LAW OF CDR!!!

(check-equal? (car (cdr '((b) (x y) ((c))))) '(x y))    ; from the inside out, 1sr cdr => ((x y) ((c))), 2nd car => (x y)
(check-equal? (cdr (cdr '((b) (x y) ((c))))) '(((c))))    ; from the inside out, 1sr cdr => ((x y) ((c))), 2nd cdr => (((c))) <== list of (( c ))
;(check-exn exn:fail (thunk (cdr (car '(a (b (c)) d))))) ; error because cdr of atom is not allowed

; both car and cdr take as argument a non-empty list
; car returns an S-exp, cdr returns a list

; ______________CONS______________
; takes 2 arguments and adds an S-exp to the front of a list
(cons 'peanut '(butter and jelly))
(cons '(banana and) '(peanut butter and jelly))
(cons '((help) this) '(is very ((hard) to learn)))
(cons '(a b (c)) '()) ; interesting, works too
(cons 's '())
(cons '((a b c)) 'b) ; => should be error because 2nd arg is not a list ############# CHEK
(cons 'a 'b)         ; => should be error because 2nd arg is not a list ############# CHEK
; LAW OF CONS: takes 2 args, the second must be a list, returns a list

(cons 'a (car '((b) c d)))
(cons 'a (cdr '((b) c d)))

; ______________NULL?______________
(check-true (null? '()))
(check-false (null? '(a b c)))
(check-false (null? 'a))  ; should be no answer, but gives false because it is always #f except for the empty list
; LAW OF NULL?: is defined only for a list

; ______________ATOM?______________
; atom? takes a single argument, a S-exp
(check-true (atom? 'Harry))
(check-false (atom? '(Harry had a heap of apples)))
(check-true (atom? (car '(Harry had a heap of apples))))
(check-false (atom? (cdr '(Harry had a heap of apples))))
(check-false (atom? (cdr '(Harry))))
(check-true (atom? (car (cdr '(swing low sweet cherry oat)))))
(check-false (atom? (car (cdr '(swing (low sweet) cheery oat)))))

; ______________EQ?______________
(check-true  (eq? 'Harry 'Harry))
(check-false (eq? 'margarine 'butter))
(check-false (eq? '() '(strawberry)))
(check-true  (eq? '() '()))
(check-false (eq? '(pepe) '(pepe)))
(check-false (eq? '6 '7))
(check-true  (eq? '6 '6))
; LAW OF EQ?: takes two non-numeric atoms as arguments

; works with empty lists and gives #t (for anything else gives #f)
; works with numbers as strings

(check-true (eq? (car '(Mary had a litle lamb chop)) 'Mary))
(check-false (eq? (cdr '(soured milk)) 'milk))
(check-false (eq? (cdr '(soured milk)) '(milk)))
(check-true (eq? (car '(beans beans we need jelly beans)) (car (cdr '(beans beans we need jelly beans)))))
