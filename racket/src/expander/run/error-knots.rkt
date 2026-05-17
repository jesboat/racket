#lang racket/base

(require (prefix-in base: "../syntax/error.rkt"))
(require (prefix-in base: "../expand/missing-module.rkt"))

(define exn:fail:syntax base:exn:fail:syntax)
(define exn:fail:syntax:unbound base:exn:fail:syntax:unbound)
(define exn:fail:filesystem:missing-module base:exn:fail:filesystem:missing-module)
(define exn:fail:syntax:missing-module base:exn:fail:syntax:missing-module)

(begin
  ; During extration, the simplifier removes unused definitions before tying
  ; knots, which means that uses of the above to tie knots would fail unless
  ; they are used in a way the simplifier can see.
  (void exn:fail:syntax
        exn:fail:syntax:unbound
        exn:fail:filesystem:missing-module
        exn:fail:syntax:missing-module))

