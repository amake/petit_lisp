library petitparser.example.lisp.evaluator;

import 'package:petitparser/petitparser.dart';

import 'cons.dart';
import 'environment.dart';
import 'name.dart';

/// The evaluation function.
Object eval(Environment env, Object expr) {
  if (expr is Cons) {
    Function function = eval(env, expr.head);
    return function(env, expr.tail);
  } else if (expr is Name) {
    return env[expr];
  } else {
    return expr;
  }
}

/// Evaluate a cons of instructions.
Object evalList(Environment env, Cons expr) {
  var result;
  while (expr is Cons) {
    result = eval(env, expr.head);
    expr = expr.tail;
  }
  return result;
}

/// The arguments evaluation function.
Object evalArguments(Environment env, Cons args) {
  if (args is Cons) {
    return new Cons(eval(env, args.head), evalArguments(env, args.tail));
  } else {
    return null;
  }
}

/// Reads and evaluates a [script].
Object evalString(Parser parser, Environment env, String script) {
  var result;
  for (var cell in parser.parse(script).value) {
    result = eval(env, cell);
  }
  return result;
}
