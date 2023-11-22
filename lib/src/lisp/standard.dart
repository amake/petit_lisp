import 'environment.dart';
import 'evaluator.dart';
import 'parser.dart';

/// The standard library.
class StandardEnvironment extends Environment {
  /// Imports the standard library into the [Environment].
  StandardEnvironment(super.owner) {
    evalString(lispParser, this, _standardLibrary);
  }

  /// A simple standard library, should be moved to external file.
  static const String _standardLibrary = """
; null functions
(define (null? x) (= null x))

; booleans
(define true (and))
(define false (or))

; control flow
(define-macro (when test #:rest body)
  `(if ,test (progn ,@body)))

(define-macro (unless test #:rest body)
  `(if (not ,test) (progn ,@body)))

(define-macro (let* bindings #:rest body)
  (if (null? bindings)
    `(progn ,@body)
    `(let (,(car bindings))
       (let* ,(cdr bindings)
         ,@body))))

; accessors
(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))
(define (caaar x) (car (car (car x))))
(define (cdaar x) (cdr (car (car x))))
(define (cadar x) (car (cdr (car x))))
(define (caadr x) (car (car (cdr x))))
(define (cddar x) (cdr (cdr (car x))))
(define (caddr x) (car (cdr (cdr x))))
(define (cdadr x) (cdr (car (cdr x))))
(define (cdddr x) (cdr (cdr (cdr x))))

; list functions
(define* (list #:rest args) args)

(define (list? x)
  (or (null? x)
      (and (pair? x)
           (or (null? (cdr x)) (list? (cdr x))))))

(define (length list)
  (if (null? list)
      0
      (+ 1 (length (cdr list)))))

(define (append list1 list2)
  (if (null? list1)
    list2
    (cons (car list1) (append (cdr list1) list2))))

(define (list-head list index)
  (if (= index 0)
    (car list)
    (list-head
      (cdr list)
      (- index 1))))

(define (list-tail list index)
  (if (= index 0)
    (cdr list)
    (list-tail
      (cdr list)
      (- index 1))))

(define (for-each list proc)
  (while (not (null? list))
    (proc (car list))
    (set! list (cdr list))))

(define (map list proc)
  (if (null? list)
    '()
    (cons (proc (car list))
          (map (cdr list) proc))))

(define (inject list value proc)
  (if (null? list)
    value
    (inject
      (cdr list)
      (proc value (car list))
      proc)))

(define* (member element list #:optional compare-fn)
  (if list
    (or ((or compare-fn =) element (car list))
        (member element (cdr list) compare-fn))))

(define (memq element list)
  (member element list eq?))

(define-macro (cond &rest clauses)
  (when clauses
    (let* ((clause (car clauses))
           (tempcond (make-symbol " cond"))
           (body (cdr clause))
           (rest (cdr clauses)))
      `(let ((,tempcond ,(car clause)))
         (if ,tempcond
           ,(if body `(progn ,@body) tempcond)
           (cond ,@rest))))))
""";
}
