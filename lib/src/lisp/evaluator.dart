import 'package:petitparser/petitparser.dart';

import 'cons.dart';
import 'environment.dart';
import 'name.dart';
import 'quasiquote.dart';
import 'quote.dart';
import 'splice.dart';
import 'unquote.dart';

/// The evaluation function.
dynamic eval(Environment env, dynamic expr) {
  env.checkInterrupt();
  if (expr is Quote) {
    return expr.datum;
  } else if (expr is Quasiquote) {
    return unquasiquote(env, expr.datum);
  } else if (expr is Cons) {
    final Function function = eval(env, expr.head);
    return function(env, expr.tail);
  } else if (expr is Name) {
    return env[expr];
  } else {
    return expr;
  }
}

/// Evaluate a cons of instructions.
dynamic evalList(Environment env, dynamic expr) {
  dynamic result;
  while (expr is Cons) {
    result = eval(env, expr.head);
    expr = expr.tail;
  }
  return result;
}

/// The arguments evaluation function.
dynamic evalArguments(Environment env, dynamic args) {
  if (args is Cons) {
    return Cons(eval(env, args.head), evalArguments(env, args.tail));
  } else {
    return null;
  }
}

/// Reads and evaluates a [script].
dynamic evalString(Parser parser, Environment env, String script) {
  dynamic result;
  for (final cell in parser.parse(script).value) {
    result = eval(env, cell);
  }
  return result;
}

/// Converts a lisp value to a Dart boolean.
bool truthy(dynamic arg) => arg != false && arg != null;

dynamic unquasiquote(Environment env, dynamic expr) {
  if (expr is Cons) {
    final head = unquasiquote(env, expr.head);
    final tail = unquasiquote(env, expr.tail);
    if (head == null && tail == null) {
      return null;
    } else if (expr.head is Splice && head is Cons) {
      _lastCell(head).cdr = tail;
      return head;
    } else if (expr.tail?.head is Splice && head is Cons) {
      return head..cdr = tail;
    } else {
      return Cons(head, tail);
    }
  } else if (expr is Quote) {
    return Quote(unquasiquote(env, expr.datum));
  } else if (expr is Splice) {
    return eval(env, expr.datum);
  } else if (expr is Unquote) {
    return eval(env, expr.datum);
  } else {
    return expr;
  }
}

Cons _lastCell(Cons head) {
  while (head.tail != null) {
    head = head.tail!;
  }
  return head;
}
