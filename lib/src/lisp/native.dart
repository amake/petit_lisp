import 'cons.dart';
import 'environment.dart';
import 'evaluator.dart';
import 'name.dart';
import 'types.dart';

class NativeEnvironment extends Environment {
  NativeEnvironment([super.owner]) {
    // basic functions
    define(Name('define'), _define);
    define(Name('lambda'), _lambda);
    define(Name('quote'), _quote);
    define(Name('eval'), _eval);
    define(Name('apply'), _apply);
    define(Name('let'), _let);
    define(Name('set!'), _set);
    define(Name('print'), _print);
    define(Name('progn'), _progn);
    define(Name('macro'), _macro);

    // control structures
    define(Name('if'), _if);
    define(Name('while'), _while);
    define(Name('and'), _and);
    define(Name('or'), _or);
    define(Name('not'), _not);

    // arithmetic operators
    define(Name('+'), _plus);
    define(Name('-'), _minus);
    define(Name('*'), _multiply);
    define(Name('/'), _divide);
    define(Name('%'), _modulo);

    // arithmetic comparators
    define(Name('<'), _smaller);
    define(Name('<='), _smallerOrEqual);
    define(Name('='), _equal);
    define(Name('!='), _notEqual);
    define(Name('>'), _larger);
    define(Name('>='), _largerOrEqual);

    // list operators
    define(Name('cons'), _cons);
    define(Name('car'), _car);
    define(Name('car!'), _carSet);
    define(Name('cdr'), _cdr);
    define(Name('cdr!'), _cdrSet);
  }

  static dynamic _define(Environment env, dynamic args) {
    if (args.head is Name) {
      return env.define(args.head, evalList(env, args.tail));
    } else if (args.head is Cons) {
      final Cons head = args.head;
      if (head.head is Name) {
        return env.define(head.head, _lambda(env, Cons(head.tail, args.tail)));
      }
    }
    throw ArgumentError('Invalid define: $args');
  }

  static Lambda _lambda(
    Environment lambdaEnv,
    dynamic lambdaArgs, {
    bool shouldEvalArgs = true,
  }) =>
      (evalEnv, evalArgs) {
        final inner = lambdaEnv.create();
        var names = lambdaArgs.head;
        var values =
            shouldEvalArgs ? evalArguments(evalEnv, evalArgs) : evalArgs;
        var optional = false;
        while (names != null) {
          if (!optional && names.head == Name('&optional')) {
            optional = true;
            names = names.tail;
            continue;
          }
          if (optional && names.head == Name('&optional')) {
            throw ArgumentError('Invalid lambda: $lambdaArgs');
          }
          if (optional && values == null) {
            inner.define(names.head, null);
            names = names.tail;
            continue;
          }
          if (names.head == Name('&rest')) {
            final restArg = names.tail?.head;
            if (restArg is! Name) {
              throw ArgumentError('Invalid lambda: $lambdaArgs');
            }
            inner.define(restArg, values);
            break;
          }
          inner.define(names.head, values.head);
          names = names.tail;
          values = values.tail;
        }
        return evalList(inner, lambdaArgs.tail);
      };

  static dynamic _macro(Environment env, dynamic args) {
    if (args.head is Cons) {
      final Cons head = args.head;
      if (head.head is Name) {
        return env.define(
          head.head,
          _macroImpl(env, Cons(head.tail, args.tail)),
        );
      }
    }
    throw ArgumentError('Invalid macro: $args');
  }

  static Lambda _macroImpl(Environment lambdaEnv, dynamic lambdaArgs) {
    final generator = _lambda(lambdaEnv, lambdaArgs, shouldEvalArgs: false);
    return (evalEnv, evalArgs) => eval(evalEnv, generator(evalEnv, evalArgs));
  }

  static dynamic _quote(Environment env, dynamic args) => args.head;

  static dynamic _eval(Environment env, dynamic args) =>
      eval(env.create(), eval(env, args.head));

  static dynamic _apply(Environment env, dynamic args) {
    final Function function = eval(env, args.head);
    return function(env.create(), args.tail);
  }

  static dynamic _let(Environment env, dynamic args) {
    final inner = env.create();
    var binding = args.head;
    while (binding is Cons) {
      final definition = binding.head;
      if (definition is Cons) {
        inner.define(definition.head, eval(env, definition.tail?.head));
      } else {
        throw ArgumentError('Invalid let: $args');
      }
      binding = binding.tail;
    }
    return evalList(inner, args.tail);
  }

  static dynamic _set(Environment env, dynamic args) =>
      env[args.head] = eval(env, args.tail.head);

  static dynamic _print(Environment env, dynamic args) {
    final buffer = StringBuffer();
    while (args != null) {
      buffer.write(eval(env, args.head));
      args = args.tail;
    }
    printer(buffer.toString());
    return null;
  }

  static dynamic _progn(Environment env, dynamic args) {
    dynamic result;
    while (args != null) {
      result = eval(env, args.head);
      args = args.tail;
    }
    return result;
  }

  static dynamic _if(Environment env, dynamic args) {
    final condition = eval(env, args.head);
    if (truthy(condition)) {
      if (args.tail != null) {
        return eval(env, args.tail.head);
      }
    } else {
      if (args.tail != null && args.tail.tail != null) {
        return eval(env, args.tail.tail.head);
      }
    }
    return null;
  }

  static dynamic _while(Environment env, dynamic args) {
    dynamic result;
    while (truthy(eval(env, args.head))) {
      result = evalList(env, args.tail);
    }
    return result;
  }

  static dynamic _and(Environment env, dynamic args) {
    dynamic arg = true;
    while (args != null) {
      arg = eval(env, args.head);
      if (!truthy(arg)) {
        return false;
      }
      args = args.tail;
    }
    return arg;
  }

  static dynamic _or(Environment env, dynamic args) {
    while (args != null) {
      final arg = eval(env, args.head);
      if (truthy(arg)) {
        return arg;
      }
      args = args.tail;
    }
    return false;
  }

  static dynamic _not(Environment env, dynamic args) =>
      !truthy(eval(env, args.head));

  static dynamic _plus(Environment env, dynamic args) {
    num value = eval(env, args.head);
    for (args = args.tail; args != null; args = args.tail) {
      value += eval(env, args.head);
    }
    return value;
  }

  static dynamic _minus(Environment env, dynamic args) {
    num value = eval(env, args.head);
    if (args.tail == null) {
      return -value;
    }
    for (args = args.tail; args != null; args = args.tail) {
      value -= eval(env, args.head);
    }
    return value;
  }

  static dynamic _multiply(Environment env, dynamic args) {
    num value = eval(env, args.head);
    for (args = args.tail; args != null; args = args.tail) {
      value *= eval(env, args.head);
    }
    return value;
  }

  static dynamic _divide(Environment env, dynamic args) {
    num value = eval(env, args.head);
    for (args = args.tail; args != null; args = args.tail) {
      value /= eval(env, args.head);
    }
    return value;
  }

  static dynamic _modulo(Environment env, dynamic args) {
    num value = eval(env, args.head);
    for (args = args.tail; args != null; args = args.tail) {
      value %= eval(env, args.head);
    }
    return value;
  }

  static dynamic _smaller(Environment env, dynamic args) {
    final Comparable a = eval(env, args.head);
    final Comparable b = eval(env, args.tail.head);
    return a.compareTo(b) < 0;
  }

  static dynamic _smallerOrEqual(Environment env, dynamic args) {
    final Comparable a = eval(env, args.head);
    final Comparable b = eval(env, args.tail.head);
    return a.compareTo(b) <= 0;
  }

  static dynamic _equal(Environment env, dynamic args) {
    final a = eval(env, args.head);
    final b = eval(env, args.tail.head);
    return a == b;
  }

  static dynamic _notEqual(Environment env, dynamic args) {
    final a = eval(env, args.head);
    final b = eval(env, args.tail.head);
    return a != b;
  }

  static dynamic _larger(Environment env, dynamic args) {
    final Comparable a = eval(env, args.head);
    final Comparable b = eval(env, args.tail.head);
    return a.compareTo(b) > 0;
  }

  static dynamic _largerOrEqual(Environment env, dynamic args) {
    final Comparable a = eval(env, args.head);
    final Comparable b = eval(env, args.tail.head);
    return a.compareTo(b) >= 0;
  }

  static dynamic _cons(Environment env, dynamic args) {
    final head = eval(env, args.head);
    final tail = eval(env, args.tail.head);
    return Cons(head, tail);
  }

  static dynamic _car(Environment env, dynamic args) {
    final cons = eval(env, args.head);
    return cons is Cons ? cons.head : null;
  }

  static dynamic _carSet(Environment env, dynamic args) {
    final cons = eval(env, args.head);
    if (cons is Cons) {
      cons.car = eval(env, args.tail.head);
    }
    return cons;
  }

  static dynamic _cdr(Environment env, dynamic args) {
    final cons = eval(env, args.head);
    return cons is Cons ? cons.cdr : null;
  }

  static dynamic _cdrSet(Environment env, dynamic args) {
    final cons = eval(env, args.head);
    if (cons is Cons) {
      cons.cdr = eval(env, args.tail.head);
    }
    return cons;
  }
}
