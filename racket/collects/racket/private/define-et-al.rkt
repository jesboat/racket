
;;----------------------------------------------------------------------
;; -define, when, unless, let/ec, define-struct

(module define-et-al '#%kernel
  (#%require (for-syntax '#%kernel "stx.rkt" "qq-and-or.rkt" 
                         "cond.rkt"))

  (#%provide -define -define-syntax
             ;define define-syntax define-for-syntax
             when unless
             call/ec let/ec)

  ; --------------------------------------------------
  ;
  ;
  ;        ;             ;;;;   ;                                        ;                                    ;                 ;
  ;        ;            ;                                               ;                                     ;                  ;
  ;        ;            ;                                              ;                                      ;                   ;
  ;     ;;;;    ;;;     ;     ;;;     ; ;;;     ;;;                    ;      ; ;;;     ;;    ; ;;;           ;   ;  ;  ;  ;      ;
  ;    ;   ;   ;   ;  ;;;;;;    ;     ;;   ;   ;   ;                  ;       ;;   ;   ;  ;   ;;   ;          ;  ;   ;  ;  ;       ;
  ;   ;    ;  ;    ;    ;       ;     ;    ;  ;    ;                  ;       ;    ;  ;    ;  ;    ;          ; ;    ; ; ; ;       ;
  ;   ;    ;  ;;;;;;    ;       ;     ;    ;  ;;;;;;                  ;       ;    ;  ;    ;  ;    ;          ;;     ; ; ; ;       ;
  ;   ;    ;  ;         ;       ;     ;    ;  ;                       ;       ;    ;  ;    ;  ;    ;          ;;     ; ; ; ;       ;
  ;   ;    ;  ;         ;       ;     ;    ;  ;                        ;      ;    ;  ;    ;  ;    ;          ; ;    ; ; ; ;      ;
  ;   ;   ;;   ;        ;       ;     ;    ;   ;                       ;      ;    ;   ;  ;   ;    ;          ;  ;    ;   ;       ;
  ;    ;;; ;    ;;;;    ;       ;;;   ;    ;    ;;;;                    ;     ;    ;    ;;    ;    ;          ;   ;   ;   ;      ;
  ;                                                  ;;;;;;;             ;                                                      ;
  ;                                                                       ;                                                    ;
  ;
  ;
  ; non-keyword define* forms
  ;


  ; define, define-syntax, and define-values-for-syntax
  ;
  ; These are not directly user-visible, so we put minimal effort into error
  ; reporting.
  (begin-for-syntax
    (define-values (process-function-define)
      (lambda (full-stx prototype-stx body-list)
        (define-values (id-or-nested-prototype) (stx-car prototype-stx))
        (define-values (arg-spec) (stx-cdr prototype-stx))
        (define-values (this-layer-rhs) (datum->syntax #f
                                                       (list* (quote-syntax lambda)
                                                              arg-spec
                                                              body-list)
                                                       full-stx))
        (if (identifier? id-or-nested-prototype)
            (values id-or-nested-prototype this-layer-rhs)
            (if (stx-pair? id-or-nested-prototype)
                (process-function-define full-stx id-or-nested-prototype (list this-layer-rhs))
                (raise-syntax-error #f "bad syntax" full-stx id-or-nested-prototype)))))

    (define-values (process-identifier-define)
      (lambda (full-stx id body-list)
        (raise-syntax-error-if (null? body-list)
                               "bad syntax (missing expression after identifier)"
                               full-stx)
        (raise-syntax-error-if (pair? (cdr body-list))
                               "bad syntax (multiple expressions after identifier)"
                               full-stx)
        (values id (car body-list))))

    (define-values (process-define)
      (lambda (head-for-output-form stx)
        (define-values (lst) (syntax->list stx))
        (raise-syntax-error-unless lst "bad syntax" stx)
        (raise-syntax-error-unless (pair? (cdr lst)) "bad syntax" stx)
        (define-values (id rhs)
          (if (identifier? (cadr lst))
              (process-identifier-define stx (cadr lst) (cddr lst))
              (if (stx-pair? (cadr lst))
                  (process-function-define stx (cadr lst) (cddr lst))
                  (raise-syntax-error #f "bad syntax" stx (cadr lst)))))
        (datum->syntax #f
                       (list head-for-output-form (list id) rhs)
                       stx))))

  (define-syntaxes (define)
    (lambda (stx)
      (process-define (quote-syntax define-values) stx)))

  (define-syntaxes (define-syntax)
    (lambda (stx)
      (process-define (quote-syntax define-syntaxes) stx)))

  (define-syntaxes (define-for-syntax)
    (lambda (stx)
      (datum->syntax #f
                     (list (quote-syntax begin-for-syntax)
                           (process-define (quote-syntax define-values) stx))
                     stx)))

  (define-syntaxes (-define)
    (make-rename-transformer (quote-syntax define)))

  (define-syntaxes (-define-syntax)
    (make-rename-transformer (quote-syntax define-syntax)))

  ; --------------------------------------------------
  ;
  ;
  ;           ;                            ;                  ;;;
  ;           ;                            ;                    ;
  ;           ;                           ;                     ;
  ;  ;  ;  ;  ; ;;;     ;;;   ; ;;;       ;   ;    ;  ; ;;;     ;       ;;;    ;;;;    ;;;;
  ;  ;  ;  ;  ;;   ;   ;   ;  ;;   ;     ;    ;    ;  ;;   ;    ;      ;   ;  ;    ;  ;    ;
  ;  ; ; ; ;  ;    ;  ;    ;  ;    ;    ;     ;    ;  ;    ;    ;     ;    ;  ;       ;
  ;  ; ; ; ;  ;    ;  ;;;;;;  ;    ;    ;     ;    ;  ;    ;    ;     ;;;;;;   ;;      ;;
  ;  ; ; ; ;  ;    ;  ;       ;    ;   ;      ;    ;  ;    ;    ;     ;          ;;      ;;
  ;  ; ; ; ;  ;    ;  ;       ;    ;   ;      ;    ;  ;    ;    ;     ;            ;       ;
  ;   ;   ;   ;    ;   ;      ;    ;  ;       ;   ;;  ;    ;    ;      ;      ;    ;  ;    ;
  ;   ;   ;   ;    ;    ;;;;  ;    ;  ;        ;;; ;  ;    ;    ;;;     ;;;;   ;;;;    ;;;;
  ;
  ;
  ; when and unless
  ;

  (define-syntaxes (when)
    (lambda (stx)
      (define-values (lst) (syntax->list stx))
      (raise-syntax-error-unless (pair? lst) "bad syntax" stx)
      (raise-syntax-error-if (null? (cdr lst)) "bad syntax (missing test expression and body)" stx)
      (raise-syntax-error-if (null? (cddr lst)) "bad syntax (missing body)" stx)
      (datum->syntax (quote-syntax here)
                     (list (quote-syntax if)
                           (cadr lst)
                           (list* (quote-syntax let-values)
                                  (quote-syntax ())
                                  (cddr lst))
                           (quote-syntax (void)))
                     stx)))

  (define-syntaxes (unless)
    (lambda (stx)
      (define-values (lst) (syntax->list stx))
      (raise-syntax-error-unless (pair? lst) "bad syntax" stx)
      (raise-syntax-error-if (null? (cdr lst)) "bad syntax (missing test expression and body)" stx)
      (raise-syntax-error-if (null? (cddr lst)) "bad syntax (missing body)" stx)
      (datum->syntax (quote-syntax here)
                     (list (quote-syntax if)
                           (cadr lst)
                           (quote-syntax (void))
                           (list* (quote-syntax let-values)
                                  (quote-syntax ())
                                  (cddr lst)))
                     stx)))

  ; --------------------------------------------------
  ;
  ;
  ;                   ;;;     ;;;          ;                          ;;;                          ;
  ;                     ;       ;          ;                            ;               ;          ;
  ;                     ;       ;         ;                             ;               ;         ;
  ;     ;;;;    ;;;;    ;       ;         ;     ;;;     ;;;;            ;       ;;;     ;         ;     ;;;     ;;;;
  ;    ;       ;   ;    ;       ;        ;     ;   ;   ;                ;      ;   ;  ;;;;;;     ;     ;   ;   ;
  ;   ;       ;    ;    ;       ;       ;     ;    ;  ;                 ;     ;    ;    ;       ;     ;    ;  ;
  ;   ;       ;    ;    ;       ;       ;     ;;;;;;  ;                 ;     ;;;;;;    ;       ;     ;;;;;;  ;
  ;   ;       ;    ;    ;       ;      ;      ;       ;                 ;     ;         ;      ;      ;       ;
  ;   ;       ;    ;    ;       ;      ;      ;       ;                 ;     ;         ;      ;      ;       ;
  ;    ;      ;   ;;    ;       ;     ;        ;       ;                ;      ;        ;     ;        ;       ;
  ;     ;;;;   ;;; ;    ;;;     ;;;   ;         ;;;;    ;;;;            ;;;     ;;;;     ;;;  ;         ;;;;    ;;;;
  ;
  ;
  ; call/ec and let/ec
  ;

  (define-values (call/ec) call-with-escape-continuation)

  (define-syntaxes (let/ec)
    (lambda (stx)
      (define-values (lst) (syntax->list stx))
      (raise-syntax-error-unless (pair? lst) "bad syntax" stx)
      (define-values (len) (length lst))
      (raise-syntax-error-if (= len 1) "bad syntax (missing identifier and body)" stx)
      (raise-syntax-error-if (= len 2) "bad syntax (missing body)" stx)
      (datum->syntax (quote-syntax here)
                     (list (quote-syntax call-with-escape-continuation)
                           (datum->syntax #f
                                          (list* (quote-syntax lambda)
                                                 (list (cadr lst))
                                                 (stx-cdr (stx-cdr stx)))
                                          stx))
                     stx)))

  ;
  ; --------------------------------------------------
  )
