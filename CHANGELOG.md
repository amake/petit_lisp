# Changelog

## 6.5.0

* Update petitparser to 7.0.1

## 6.4.0

* Optional and rest args keywords are now preferably `#:optional` and `#:rest`
  * They are recognized by `lambda*`, `define*`, and `define-macro*`, but not
    `lambda`, `define`, or `define-macro`
  * `&optional` and `&rest` are recognized as synonyms
* Dotted rest args are supported everywhere
* Add built-in functions: `pair?`, `list?`, `let*`, `cond`

## 6.3.0

* "Truthy" logic: `false` and `null` are falsy; others are truthy
* Support `&rest` arguments in lambdas
* Add macros
* Add quasiquoting, unquoting, splicing, dotted pairs
* Add built-in functions: `list`, `progn`, `make-symbol`, `gensym`, `eq?`,
  `member`, `memq`, `when`, `unless`, and all `c[ad]{2,3}r` functions

## 6.2.0

* Add `Environment.interrupt` callback to allow interrupting execution

## 6.1.0

* Support `&optional` arguments in lambdas

## 6.0.2

* Initial version extracted from https://github.com/petitparser/dart-petitparser-examples.
