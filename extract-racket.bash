#!/usr/bin/env bash

opts=(
    racket/bin/racket
        racket/src/expander/bootstrap-run.rkt

    -x -s # extract to s-expr

    # input/output files
    -t racket/src/expander/racket.rkt
    -o racket.rktl

    # cache and checkout path
    -c racket/src/expander/compiled/cache-src
    -k racket/

    # knots
    ++knot read /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/read/api.rkt
    ++knot read /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/read/number.rkt
    ++knot read /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/read/primitive-parameter.rkt
    ++knot read /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/read/readtable-parameter.rkt
    ++knot read /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/read/readtable.rkt
    ++knot read /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/read/special-comment.rkt

    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/api.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/collection.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/dynamic-require.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/load.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/parameter.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/reflect-compiled.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/reflect.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/namespace/api-module.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/namespace/api.rkt
    ++knot main /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/namespace/attach.rkt

    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/common/module-path.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/common/parse-module-path.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/expand/definition-context.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/expand/liberal-def-ctx.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/expand/rename-trans.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/expand/set-bang-trans.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/expand/syntax-local.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/namespace/namespace.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/namespace/variable-reference.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/run/error-knots.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/api-taint.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/api.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/binding.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/error.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/property.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/serialize.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/srcloc.rkt
    ++knot core /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/syntax/syntax.rkt

    ++knot utils /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/eval/collection.rkt

    ++knot place-struct /Users/jsailor/stuff/coding/racket/racket-git.3/racket/src/expander/boot/place-primitive.rkt
)

echo ">>> ${opts[*]}"
"${opts[@]}"
exit $?
