(module mzscheme-utils (lib "mzscheme-core.ss" "frtime") 
  
  (require (all-except mzscheme
                       module
                       #%app
                       #%top
                       #%datum
                       #%plain-module-begin
                       #%module-begin
                       if
                       lambda
                       case-lambda
                       ;apply
                       reverse
                       list-ref
                       require
                       provide
                       letrec
                       match
                       cons car cdr pair? null?
                       caar cdar cadr cddr caddr cdddr cadddr cddddr
                       make-struct-type
                       make-struct-field-accessor
                       make-struct-field-mutator
                       vector
                       vector-ref
		       quasiquote
                       ;qq-append
                       define-struct
                       list
		       list*
		       list?
		       append
                       and
                       or
                       cond when unless ;case
                       map ormap andmap assoc member)
           (rename mzscheme mzscheme:if if)
           (rename (lib "lang-ext.ss" "frtime") lift lift)
           (rename (lib "frp-core.ss" "frtime") super-lift super-lift)
           (rename (lib "frp-core.ss" "frtime") behavior? behavior?)
           (rename (lib "lang-ext.ss" "frtime") undefined undefined)
           (rename (lib "lang-ext.ss" "frtime") undefined? undefined?)
	   (lib "class.ss"))
  
  
  (define-syntax (lifted-send stx)
    (syntax-case stx ()
      [(_ obj meth arg ...)
       (with-syntax ([(obj-tmp) (generate-temporaries '(obj))]
                     [(arg-tmp ...) (generate-temporaries (syntax->list
#'(arg ...)))])
         #'(lift #t 
                 (lambda (obj-tmp arg-tmp ...)
                   (send obj-tmp meth arg-tmp ...))
                 obj arg ...))]))
    
  
  (define (list-ref lst idx)
    (if (lift #t positive? idx)
        (list-ref (cdr lst) (lift #t sub1 idx))
        (car lst)))
  
  ;(define (frp:eq? itm1 itm2)
  ;  (lift #t eq? itm1 itm2))

  
  (define-syntax cond
    (syntax-rules (else =>)
      [(_ [else result1 result2 ...])
       (begin result1 result2 ...)]
      [(_ [test => result])
       (let ([temp test])
         (if temp (result temp)))]
      [(_ [test => result] clause1 clause2 ...)
       (let ([temp test])
         (if temp
             (result temp)
             (cond clause1 clause2 ...)
             (cond clause1 clause2 ...)))]
      [(_ [test]) test]
      [(_ [test] clause1 clause2 ...)
       (let ((temp test))
         (if temp
             temp
             (cond clause1 clause2 ...)
             (cond clause1 clause2 ...)))]
      [(_ [test result1 result2 ...])
       (if test (begin result1 result2 ...))]
      [(_ [test result1 result2 ...]
          clause1 clause2 ...)
       (if test
           (begin result1 result2 ...)
           (cond clause1 clause2 ...)
           (cond clause1 clause2 ...))]))
  
  (define-syntax and
    (syntax-rules ()
      [(_) #t]
      [(_ exp) exp]
      [(_ exp exps ...) (if exp
                            (and exps ...)
                            #f)]))
  
  (define-syntax or
    (syntax-rules ()
      [(_) #f]
      [(_ exp) exp]
      [(_ exp exps ...) (let ([v exp])
                          (if v
                              v
                              (or exps ...)
                              (or-undef exps ...)))]))
  
  
    (define-syntax or-undef
    (syntax-rules ()
      [(_) undefined]
      [(_ exp) (let ([v exp]) (if v v undefined))]
      [(_ exp exps ...) (let ([v exp])
                          (if v
                              v
                              (or-undef exps ...)
                              (or-undef exps ...)))]))
  

  
  (define-syntax when
    (syntax-rules ()
      [(_ test body ...) (if test (begin body ...))]))
  
  (define-syntax unless
    (syntax-rules ()
      [(_ test body ...) (if (not test) (begin body ...))]))
  
  (define (ormap proc lst)
    (and (pair? lst)
         (or (proc (car lst)) (ormap proc (cdr lst)))))
  
  (define (andmap proc lst)
    (or (null? lst)
        (and (proc (car lst)) (andmap proc (cdr lst)))))
  
  (define (caar v)
    (car (car v)))
  
  (define (cdar v)
    (cdr (car v)))
  
  (define (cadr v)
    (car (cdr v)))
  
  (define (cddr v)
    (cdr (cdr v)))
  
  (define (caddr v)
    (car (cddr v)))
  
  (define (cdddr v)
    (cdr (cddr v)))
  
  (define (cadddr v)
    (car (cdddr v)))
  
  (define (cddddr v)
    (cdr (cdddr v)))
 
  #|
  (define-syntax frp:case
    (syntax-rules ()
      [(_ expr clause ...)
       (super-lift (lambda (v) (case v clause ...)) expr)]))
  |#
  (define (split-list acc lst)
    (if (null? (cdr lst))
        (values acc (car lst))
        (split-list (append acc (list (car lst))) (cdr lst))))
  
  (define frp:apply
    (lambda (fn . args)
      (if (behavior? args)
          (super-lift
           (lambda (args)
             (apply apply fn args))
           args)
          (apply apply fn args))))
  #|
  ;; taken from startup.ss
  (define-syntax frp:case
    (lambda (x)
      (syntax-case x (else)
	((_ v)
	 (syntax (begin v (cond))))
	((_ v (else e1 e2 ...))
	 (syntax/loc x (begin v e1 e2 ...)))
	((_ v ((k ...) e1 e2 ...))
	 (syntax/loc x (if (memv v '(k ...)) (begin e1 e2 ...))))
	((_ v ((k ...) e1 e2 ...) c1 c2 ...)
	 (syntax/loc x (let ((x v))
			 (if (memv x '(k ...))
			     (begin e1 e2 ...)
			     (frp:case x c1 c2 ...)))))
	((_ v (bad e1 e2 ...) . rest)
	 (raise-syntax-error 
	  #f
	  "bad syntax (not a datum sequence)"
	  x
	  (syntax bad)))
	((_ v clause . rest)
	 (raise-syntax-error 
	  #f
	  "bad syntax (missing expression after datum sequence)"
	  x
	  (syntax clause)))
	((_ . v)
	 (not (null? (syntax-e (syntax v))))
	 (raise-syntax-error 
	  #f
	  "bad syntax (illegal use of `.')"
	  x)))))
  
  
|#
  
  (define-syntax frp:case
    (syntax-rules ()
      [(_ exp clause ...)
       (let ([v exp])
         (vcase v clause ...))]))
  
  (define-syntax vcase
    (syntax-rules (else)
      [(_ v [else exp ...])
       (begin exp ...)]
      [(_ v [dl exp ...])
       (if (lift #t memv v (quote dl))
           (begin exp ...))]
      [(_ v [dl exp ...] clause ...)
       (if (lift #t memv v (quote dl))
           (begin exp ...)
           (vcase v clause ...))]))
  
  (define map
    (case-lambda
      [(f l) (if (pair? l)
                 (cons (f (car l)) (map f (cdr l)))
                 null)]
      [(f l1 l2) (if (and (pair? l1) (pair? l2))
                     (cons (f (car l1) (car l2)) (map f (cdr l1) (cdr l2)))
                     null)]
      [(f l . ls) (if (and (pair? l) (andmap pair? ls))
                      (cons (apply f (car l) (map car ls)) (apply map f (cdr l) (map cdr ls)))
                      null)]))
  

  (define (frp:length lst)
    (cond
     [(pair? lst) (lift #t add1 (frp:length (cdr lst)))]
     [(null? lst) 0]
     [else (error 'length (format "expects list, given ~a" lst))]))
  
  (define (reverse lst)
    (let loop ([lst lst] [acc ()])
      (if (pair? lst)
          (loop (cdr lst) (cons (car lst) acc))
          acc)))
  
  (provide cond 
           and 
           or 
           or-undef 
           when 
           unless
           map
           ormap 
           andmap
           caar
           cadr
           cddr
           caddr
           cdddr
           cadddr
           cddddr
           ;case
           build-path
           collection-path
           
           list-ref
           (rename frp:case case)
           (rename frp:apply apply)
           (rename frp:length length)
           reverse
           
           (lifted + - * / = 
                   eq? 
                   equal? eqv? < > <= >= 
                   add1 cos sin tan symbol->string symbol?
                   number->string string->symbol eof-object? exp expt even? odd? string-append eval ; list-ref
                   sub1 sqrt not number? string? zero? min max modulo
                   string->number void? rational? char? char-upcase char-ci>=? char-ci<=?
                   string>=? char-upper-case? char-alphabetic?
                   string<? string-ci=? string-locale-ci>?
                   string-locale-ci<? string-locale-ci=? atan asin acos exact? magnitude imag-part
                   real-part numerator abs log lcm gcd arithmetic-shift integer-sqrt make-rectangular
                   complex? char>? char<? char=?
                   char-numeric? date-time-zone-offset list->string substring string->list
                   string-ci<? string-ci>=? string<=? string-ci<=? string>? string-locale<? string=?
                   string-length string-ref
                   floor angle round
                   ceiling real? date-hour procedure? procedure-arity
                   rationalize date-year-day date-week-day date? date-dst? date-year date-month date-day
                   date-minute date-second make-date char-downcase char>=? char<=? char->integer integer->char boolean?
                   integer? quotient remainder positive? negative? inexact->exact exact->inexact
                   make-polar denominator truncate bitwise-not bitwise-xor bitwise-and bitwise-ior inexact?
                   char-whitespace? assq assv memq memv list-tail ;reverse
                   ;length
                   seconds->date
                   expand syntax-object->datum exn-message continuation-mark-set->list exn-continuation-marks
                   exn:fail? regexp-match
                   list->vector make-vector)
            
           (rename eq? mzscheme:eq?)
           make-exn:fail  current-inspector make-inspector
           make-namespace namespace? namespace-symbol->identifier namespace-variable-value
           namespace-set-variable-value! namespace-undefine-variable! namespace-mapped-symbols
           parameterize current-seconds current-milliseconds current-inexact-milliseconds
           call-with-values make-parameter
           null
           gensym collect-garbage
           error set! printf fprintf current-error-port for-each void
           procedure-arity-includes? raise-type-error raise thread
           current-continuation-marks
           raise-mismatch-error require-for-syntax define-syntax syntax-rules syntax-case
          ; set-eventspace
	   ;install-errortrace-key
           (lifted:nonstrict format)
           print-struct
           ;lambda
           ;case-lambda
           define
           let
           let*
           values
           let*-values           
           let-values
           define-values
           begin
           begin0
           quote
           unquote
           unquote-splicing

           syntax
           let/ec
           with-handlers
           unsyntax
           current-security-guard
           make-security-guard
           dynamic-require
           path->complete-path
           string->path
           split-path
           current-directory
           exit
           system-type 
           lifted-send
           unsyntax-splicing 

           delay
           force
           random
           sleep
           read-case-sensitive
           file-exists?
           with-input-from-file
           read
         
           
          ; null
        ;   make-struct-field-mutator
           )
  
  ; from core
  (provide (all-from (lib "mzscheme-core.ss" "frtime")))
           
  )