(module norm-define '#%kernel
  (#%require "stx.rkt")

  (#%provide normalize-definition normalize-definition/mk-rhs)

  
  (define-values (check-arg-is-id)
    (lambda (full-stx arg)
      (raise-syntax-error-unless (identifier? arg)
                                 "not an identifier for procedure argument"
                                 full-stx
                                 arg)))

  ; (try-parse-id/id+dfl id-or-id+dfl)
  ;   id-or-id+dfl : syntax?   ; expected shape #'id or #'[id dfl-expr]
  ;  -> (values (or/c identifier? #f) boolean?)
  ; Attempts to parse the specified syntax as an identifier-or-identifier+default,
  ; as might appear in a function argument list (potentially preceded by a keyword.)
  ; If successful, returns `(values id had-default?)`; else returns `(values #f #f)`.
  (define-values (try-parse-id/id+dfl)
    (lambda (id-or-id+dfl)
      (if (identifier? id-or-id+dfl)
          (values id-or-id+dfl #f)
          (let-values ([(id+dfl) (syntax->list id-or-id+dfl)])
            (if id+dfl
                (if (= 2 (length id+dfl))
                    (if (identifier? (car id+dfl))
                        (values (car id+dfl) #t)
                        (values #f #f))
                    (values #f #f))
                (values #f #f))))))

  ; (arg-spec->argname-list/kw+opt full-stx full-arg-spec)
  ; full-stx is the full definition form.
  ; full-arg-spec is the argument spec, i.e. the stx-cdr of a prototype,
  ; and has the shape
  ;    arg-spec := ()
  ;              | rest-id
  ;              | id . arg-spec
  ;              | [id dfl] . arg-spec
  ;              | #:kw id . arg-spec
  ;              | #:kw [id dfl] . arg-spec
  ; Validates the arg-spec, raising the leftmost error if any. If no errors,
  ; returns the list of all `id`s and `rest-id`s in the arg-spec.
  (define-values (arg-spec->argname-list/kw+opt)
    (lambda (full-stx full-arg-spec)
      (define-values (check-kw!)
        (let-values ([(h) (make-hasheq)])
          (lambda (kw-stx)
            (define-values (prev) (hash-ref h (syntax-e kw-stx) #f))
            (if prev
                (raise-syntax-error #f
                                    "duplicate keyword for argument"
                                    full-stx
                                    kw-stx
                                    (list prev))
                (hash-set! h (syntax-e kw-stx) kw-stx)))))

      (define-values (loop)
        (lambda (arg-spec seen-optional?)
          (if (stx-pair? arg-spec)
              ; Valid:
              ;   arg-spec = (id . rest)
              ;   arg-spec = ([id dfl] . rest)
              ;   arg-spec = (#:kw id . rest)
              ;   arg-spec = (#:kw [id dfl] . rest)
              (if (keyword? (syntax-e (stx-car arg-spec)))
                  (let-values ([(kw-stx) (stx-car arg-spec)]
                               [(after-kw) (stx-cdr arg-spec)])
                    (check-kw! kw-stx)
                    (raise-syntax-error-unless (stx-pair? after-kw)
                                               ; We use the traditional error message; better would be
                                               ; "missing argument identifier (or identifier with default value) after keyword"
                                               "missing argument identifier after keyword"
                                               full-stx
                                               kw-stx)
                    (define-values (id _has-default?) (try-parse-id/id+dfl (stx-car after-kw)))
                    (raise-syntax-error-unless id
                                               ; We use the traditional error message; better would be
                                               ; "expected an argument identifier (or identifier with default value) after keyword"
                                               ; raised with sub-expr `(stx-car after-kw)`
                                               "missing argument identifier after keyword"
                                               full-stx
                                               kw-stx)
                    (cons id
                          (loop (stx-cdr after-kw) seen-optional?)))
                  (let-values ([(id has-default?) (try-parse-id/id+dfl (stx-car arg-spec))])
                    (raise-syntax-error-unless id
                                               "not an identifier, identifier with default, or keyword for procedure argument"
                                               full-stx
                                               (stx-car arg-spec))
                    (if seen-optional?
                        (raise-syntax-error-unless has-default?
                                                   "default-value expression missing"
                                                   full-stx
                                                   (stx-car arg-spec))
                        (void))
                    (cons id
                          (loop (stx-cdr arg-spec) has-default?))))
              ; Valid:
              ;   id
              ;   ()
              (if (stx-null? arg-spec)
                  null
                  (begin (check-arg-is-id full-stx arg-spec)
                         (list arg-spec))))))

      (loop full-arg-spec #f)))

  ; (arg-spec->argname-list/plain full-stx full-arg-spec)
  ; full-stx is the full definition form.
  ; full-arg-spec is the argument spec, i.e. the stx-cdr of a prototype,
  ; and has the shape
  ;    arg-spec := ()
  ;              | rest-id
  ;              | id . arg-spec
  ; Validates the arg-spec, raising the leftmost error if any. If no errors,
  ; returns the list of all `id`s and `rest-id`s in the arg-spec.
  (define-values (arg-spec->argname-list/plain)
    (lambda (full-stx arg-spec)
      (if (stx-pair? arg-spec)
          (begin (check-arg-is-id full-stx (stx-car arg-spec))
                 (cons (stx-car arg-spec)
                       (arg-spec->argname-list/plain full-stx (stx-cdr arg-spec))))
          (if (stx-null? arg-spec)
              null
              (begin (check-arg-is-id full-stx arg-spec)
                     (list arg-spec))))))

  (define-values (do-simple-prototype)
    (lambda (full-stx proto lambda-stx allow-key+opt?)
      (define-values (_head) (stx-car proto))
      (define-values (arg-spec) (stx-cdr proto))
      (define-values (all-args)
        (if allow-key+opt?
            (arg-spec->argname-list/kw+opt full-stx arg-spec)
            (arg-spec->argname-list/plain full-stx arg-spec)))
      ; TODO dup ID check on all-args goes here
      (lambda (body)
        (datum->syntax #f
                       (list* lambda-stx arg-spec body)
                       full-stx))))

  (define-values (do-general-prototype)
    (lambda (full-stx proto lambda-stx allow-key+opt?)
      (define-values (id-or-nested) (stx-car proto))
      (if (identifier? id-or-nested)
          (values id-or-nested
                  (do-simple-prototype full-stx proto lambda-stx allow-key+opt?))
          (if (stx-pair? id-or-nested)
              (let-values ([(id mk-rhs) (do-general-prototype full-stx
                                                              id-or-nested
                                                              lambda-stx
                                                              allow-key+opt?)])
                (let-values ([(mk-inner) (do-simple-prototype full-stx
                                                              proto
                                                              lambda-stx
                                                              allow-key+opt?)])
                  (values id
                          (lambda (body)
                            (mk-rhs (list (mk-inner body)))))))
              (raise-syntax-error #f
                                  "bad syntax (not an identifier for procedure name, and not a nested procedure form)"
                                  full-stx
                                  id-or-nested)))))

  (define-values (do-fn-define)
    (lambda (full-stx proto body-stxl lambda-stx allow-key+opt? err-no-body?)
      (define-values (id mk-rhs)
        (do-general-prototype full-stx proto lambda-stx allow-key+opt?))
      (raise-syntax-error-unless (stx-list? body-stxl)
                                 "bad syntax (illegal use of `.' for procedure body)"
                                 full-stx)
      (if err-no-body?
          (raise-syntax-error-if (stx-null? body-stxl)
                                 "bad syntax (no expressions for procedure body)"
                                 full-stx)
          (void))
      (values id
              mk-rhs
              (datum->syntax (quote-syntax here)  ; here??
                             body-stxl))))

  (define-values (do-id-define)
    (lambda (full-stx id body-stxl)
      (raise-syntax-error-unless (stx-list? body-stxl)
                                 "bad syntax (illegal use of `.')"
                                 full-stx)
      (raise-syntax-error-unless (stx-pair? body-stxl)
                                 "bad syntax (missing expression after identifier)"
                                 full-stx)
      (raise-syntax-error-unless (stx-null? (stx-cdr body-stxl))
                                 "bad syntax (multiple expressions after identifier)"
                                 full-stx)
      (values id values (stx-car body-stxl))))

  (define-values (normalize-definition/mk-rhs)
    (lambda (stx lambda-stx check-context? allow-key+opt? err-no-body?)
      (if check-context?
          (raise-syntax-error-if (eq? (syntax-local-context) 'expression)
                                 "not allowed in an expression context"
                                 stx)
          (void))
      (raise-syntax-error-unless (stx-pair? stx) "bad syntax" stx)
      (raise-syntax-error-unless (stx-pair? (stx-cdr stx)) "bad syntax" stx)
      (define-values (id-or-proto) (stx-car (stx-cdr stx)))
      (define-values (body-stxl) (stx-cdr (stx-cdr stx)))
      (if (identifier? id-or-proto)
          (do-id-define stx id-or-proto body-stxl)
          (if (stx-pair? id-or-proto)
              (do-fn-define stx id-or-proto body-stxl lambda-stx allow-key+opt? err-no-body?)
              (raise-syntax-error #f "bad syntax" stx id-or-proto)))))

  (define-values (normalize-definition)
    (case-lambda 
     [(stx lambda-stx check-context? allow-key+opt?)
      (let-values ([(id mk-rhs body)
                    (normalize-definition/mk-rhs stx lambda-stx check-context? allow-key+opt? #t)])
        (values id (mk-rhs body)))]
     [(stx lambda-stx check-context?) (normalize-definition stx lambda-stx check-context? #f)]
     [(stx lambda-stx) (normalize-definition stx lambda-stx #t #f)])))
