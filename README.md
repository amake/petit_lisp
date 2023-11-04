Petit Lisp
==========

This project is a simple grammar and evaluator for LISP. The code is reasonably
complete to run and evaluate complex programs. Binaries for a Read–Eval–Print
Loop (REPL) are provided for the console and the web browser.

```bash
dart run bin/lisp/lisp.dart
```

It is a fork of the [PetitParser Lisp
example](https://github.com/petitparser/dart-petitparser-examples#lisp).

## Web

To run the web example execute the following commands from the command line and
navigate to http://localhost:8080/:

```bash
dart pub global activate webdev
webdev serve --release
```
