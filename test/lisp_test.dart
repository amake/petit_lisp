import 'package:petit_lisp/lisp.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

const Matcher isName = TypeMatcher<Name>();
const Matcher isString = TypeMatcher<String>();
const Matcher isCons = TypeMatcher<Cons>();

void main() {
  final grammarDefinition = LispGrammarDefinition();
  final parserDefinition = LispParserDefinition();

  final native = NativeEnvironment();
  final standard = StandardEnvironment(native);

  dynamic exec(String value, [Environment? env]) =>
      evalString(lispParser, env ?? standard.create(), value);

  group('Cell', () {
    test('Name', () {
      final cell1 = Name('foo');
      final cell2 = Name('foo');
      final cell3 = Name('bar');
      expect(cell1, cell2);
      expect(cell1, same(cell2));
      expect(cell1, isNot(cell3));
      expect(cell1, isNot(same(cell3)));
    });
    test('Cons', () {
      final cell = Cons(1, 2);
      expect(cell.car, 1);
      expect(cell.head, 1);
      expect(cell.cdr, 2);
      expect(() => cell.tail, throwsStateError);
      cell.car = 3;
      expect(cell.car, 3);
      expect(cell.head, 3);
      expect(cell.cdr, 2);
      expect(() => cell.tail, throwsStateError);
      cell.cdr = Cons(4, 5);
      expect(cell.car, 3);
      expect(cell.head, 3);
      expect(cell.tail?.car, 4);
      expect(cell.tail?.head, 4);
      expect(cell.tail?.cdr, 5);
      expect(cell == cell, isTrue);
      expect(cell.hashCode, isNonZero);
      expect(cell.toString(), '(3 4 . 5)');
    });
    test('Cons (special forms)', () {
      expect(Cons.quote(1), Cons(Name('quote'), Cons(1)));
      expect(Cons.quasiquote(1), Cons(Name('quasiquote'), Cons(1)));
      expect(Cons.unquote(1), Cons(Name('unquote'), Cons(1)));
      expect(Cons.unquoteSplicing(1), Cons(Name('unquote-splicing'), Cons(1)));
      expect(Cons.quote(1).toString(), "'1");
      expect(Cons.quasiquote(1).toString(), '`1');
      expect(Cons.unquote(1).toString(), ',1');
      expect(Cons.unquoteSplicing(1).toString(), ',@1');
    });
  });
  group('Environment', () {
    final env = standard.create();
    test('Standard', () {
      expect(env.owner, isNotNull);
      expect(env.keys, isEmpty);
      expect(env.owner?.keys, isNot(isEmpty));
    });
    test('Create', () {
      final sub = env.create();
      expect(sub.owner, same(env));
      expect(sub.keys, isEmpty);
    });
  });
  group('Grammar', () {
    final grammar = grammarDefinition.build();
    test('Linter', () {
      expect(linter(grammar), isEmpty);
    });
    test('Name', () {
      final result = grammar.parse('foo').value;
      expect(result, ['foo']);
    });
    test('Name for operator', () {
      final result = grammar.parse('+').value;
      expect(result, ['+']);
    });
    test('Name for special', () {
      final result = grammar.parse('set!').value;
      expect(result, ['set!']);
    });
    test('String', () {
      final result = grammar.parse('"foo"').value;
      expect(result, [
        [
          '"',
          ['f', 'o', 'o'],
          '"'
        ]
      ]);
    });
    test('String with escape', () {
      final result = grammar.parse('"\\""').value;
      expect(result, [
        [
          '"',
          [
            ['\\', '"']
          ],
          '"'
        ]
      ]);
    });
    test('Number integer', () {
      final result = grammar.parse('123').value;
      expect(result, ['123']);
    });
    test('Number negative integer', () {
      final result = grammar.parse('-123').value;
      expect(result, ['-123']);
    });
    test('Number positive integer', () {
      final result = grammar.parse('+123').value;
      expect(result, ['+123']);
    });
    test('Number floating', () {
      final result = grammar.parse('123.45').value;
      expect(result, ['123.45']);
    });
    test('Number floating exponential', () {
      final result = grammar.parse('1.23e4').value;
      expect(result, ['1.23e4']);
    });
    test('List empty', () {
      final result = grammar.parse('()').value;
      expect(result, [
        ['(', [], ')']
      ]);
    });
    test('List empty []', () {
      final result = grammar.parse('[]').value;
      expect(result, [
        ['[', [], ']']
      ]);
    });
    test('List empty {}', () {
      final result = grammar.parse('{}').value;
      expect(result, [
        ['{', [], '}']
      ]);
    });
    test('List one element', () {
      final result = grammar.parse('(1)').value;
      expect(result, [
        [
          '(',
          ['1', []],
          ')'
        ]
      ]);
    });
    test('List two elements', () {
      final result = grammar.parse('(1 2)').value;
      expect(result, [
        [
          '(',
          [
            '1',
            ['2', []]
          ],
          ')'
        ]
      ]);
    });
    test('List three elements', () {
      final result = grammar.parse('(+ 1 2)').value;
      expect(result, [
        [
          '(',
          [
            '+',
            [
              '1',
              ['2', []]
            ]
          ],
          ')'
        ]
      ]);
    });
    test('Quote', () {
      expect(grammar.parse("'a").value, [
        ["'", 'a']
      ]);
      expect(grammar.parse("'1").value, [
        ["'", '1']
      ]);
      expect(grammar.parse(''''"foo"''').value, [
        [
          "'",
          [
            '"',
            ['f', 'o', 'o'],
            '"'
          ]
        ]
      ]);
      expect(grammar.parse("'()").value, [
        [
          "'",
          ['(', [], ')']
        ]
      ]);
    });
    test('Quasiquote', () {
      expect(grammar.parse('`a').value, [
        ['`', 'a']
      ]);
      expect(grammar.parse('`1').value, [
        ['`', '1']
      ]);
      expect(grammar.parse('`"foo"').value, [
        [
          '`',
          [
            '"',
            ['f', 'o', 'o'],
            '"'
          ]
        ]
      ]);
      expect(grammar.parse('`()').value, [
        [
          '`',
          ['(', [], ')']
        ]
      ]);
      expect(grammar.parse('`(,1)').value, [
        [
          '`',
          [
            '(',
            [
              [',', '1'],
              []
            ],
            ')'
          ]
        ]
      ]);
    });
    test('Cons', () {
      expect(grammar.parse('(1 . 2)').value, [
        [
          '(',
          ['1', '.', '2'],
          ')'
        ]
      ]);
      expect(grammar.parse('(1 2 . 3)').value, [
        [
          '(',
          [
            '1',
            ['2', '.', '3']
          ],
          ')'
        ]
      ]);
      expect(grammar.parse('(1 . (2 . 3))').value, [
        [
          '(',
          [
            '1',
            '.',
            [
              '(',
              ['2', '.', '3'],
              ')'
            ]
          ],
          ')'
        ]
      ]);
      expect(grammar.parse('1 . 2'), isA<Failure>());
      expect(grammar.parse('(1 . )'), isA<Failure>());
      expect(grammar.parse('( . 2)'), isA<Failure>());
      expect(grammar.parse('(1 . 2 . 3)'), isA<Failure>());
      expect(grammar.parse('(1 . 2 3 . 4)'), isA<Failure>());
    });
  });
  group('Parser', () {
    final atom = parserDefinition.buildFrom(parserDefinition.atom());
    test('Linter', () {
      expect(linter(atom, excludedTypes: {LinterType.info}), isEmpty);
    });
    test('Name', () {
      final cell = atom.parse('foo').value;
      expect(cell, isName);
      expect(cell.toString(), 'foo');
    });
    test('Name for operator', () {
      final cell = atom.parse('+').value;
      expect(cell, isName);
      expect(cell.toString(), '+');
    });
    test('Name for special', () {
      final cell = atom.parse('set!').value;
      expect(cell, isName);
      expect(cell.toString(), 'set!');
    });
    test('String', () {
      final cell = atom.parse('"foo"').value;
      expect(cell, isString);
      expect(cell, 'foo');
    });
    test('String with escape', () {
      final cell = atom.parse('"\\""').value;
      expect(cell, '"');
    });
    test('Number integer', () {
      final cell = atom.parse('123').value;
      expect(cell, 123);
    });
    test('Number negative integer', () {
      final cell = atom.parse('-123').value;
      expect(cell, -123);
    });
    test('Number positive integer', () {
      final cell = atom.parse('+123').value;
      expect(cell, 123);
    });
    test('Number floating', () {
      final cell = atom.parse('123.45').value;
      expect(cell, 123.45);
    });
    test('Number floating exponential', () {
      final cell = atom.parse('1.23e4').value;
      expect(cell, 1.23e4);
    });
    test('List empty', () {
      final cell = atom.parse('()').value;
      expect(cell, isNull);
    });
    test('List empty []', () {
      final cell = atom.parse('[ ]').value;
      expect(cell, isNull);
    });
    test('List empty {}', () {
      final cell = atom.parse('{   }').value;
      expect(cell, isNull);
    });
    test('List one element', () {
      final cell = atom.parse('(1)').value;
      expect(cell, isCons);
      expect(cell.head, 1);
      expect(cell.tail, isNull);
    });
    test('List two elements', () {
      final cell = atom.parse('(1 2)').value;
      expect(cell, isCons);
      expect(cell.head, 1);
      expect(cell.tail, isCons);
      expect(cell.tail.head, 2);
      expect(cell.tail.tail, isNull);
    });
    test('List three elements', () {
      final cell = atom.parse('(+ 1 2)').value;
      expect(cell, isCons);
      expect(cell.head, isName);
      expect(cell.head.toString(), '+');
      expect(cell.tail, isCons);
      expect(cell.tail.head, 1);
      expect(cell.tail.tail, isCons);
      expect(cell.tail.tail.head, 2);
      expect(cell.tail.tail.tail, isNull);
    });
    test('Quote', () {
      final cell = atom.parse("'(1 2)").value;
      expect(cell, isCons);
      expect(cell.head, isName);
      expect(cell.head.toString(), 'quote');
      expect(cell.tail, isCons);
      expect(cell.tail.head, isCons);
      expect(cell.tail.head.head, 1);
      expect(cell.tail.head.tail, isCons);
      expect(cell.tail.head.tail.head, 2);
      expect(cell.tail.head.tail.tail, isNull);
    });
    test('Quasiquote', () {
      final cell = atom.parse('`(1 ,2)').value;
      expect(cell, isCons);
      expect(cell.head, isName);
      expect(cell.head.toString(), 'quasiquote');
      expect(cell.tail, isCons);
      expect(cell.tail.head, isCons);
      expect(cell.tail.head.head, 1);
      expect(cell.tail.head.tail, isCons);
      expect(cell.tail.head.tail.head, isCons);
      expect(cell.tail.head.tail.head.head, isName);
      expect(cell.tail.head.tail.head.head.toString(), 'unquote');
      expect(cell.tail.head.tail.head.tail, isCons);
      expect(cell.tail.head.tail.head.tail.head, 2);
      expect(cell.tail.head.tail.head.tail.tail, isNull);
    });
    test('Splice', () {
      final cell = atom.parse('`(1 ,@2)').value;
      expect(cell, isCons);
      expect(cell.head, isName);
      expect(cell.head.toString(), 'quasiquote');
      expect(cell.tail, isCons);
      expect(cell.tail.head, isCons);
      expect(cell.tail.head.head, 1);
      expect(cell.tail.head.tail, isCons);
      expect(cell.tail.head.tail.head, isCons);
      expect(cell.tail.head.tail.head.head, isName);
      expect(cell.tail.head.tail.head.head.toString(), 'unquote-splicing');
      expect(cell.tail.head.tail.head.tail, isCons);
      expect(cell.tail.head.tail.head.tail.head, 2);
      expect(cell.tail.head.tail.head.tail.tail, isNull);
    });
    test('Cons', () {
      final cell = atom.parse('(1 . 2)').value;
      expect(cell, isCons);
      expect(cell.car, 1);
      expect(cell.cdr, 2);
    });
    test('Null', () {
      final cell = atom.parse('null').value;
      expect(cell, isNull);
    });
  });
  group('Natives', () {
    test('Define', () {
      expect(exec('(define a 1)'), 1);
      expect(exec('(define a 2) a'), 2);
      expect(exec('((define (a) 3))'), 3);
      expect(exec('(define (a) 4) (a)'), 4);
      expect(exec('((define (a x) x) 5)'), 5);
      expect(exec('(define (a x) x) (a 6)'), 6);
      expect(() => exec('(define 12)'), throwsArgumentError);
    });
    test('Lambda', () {
      expect(exec('((lambda () 1) 2)'), 1);
      expect(exec('((lambda (x) x) 2)'), 2);
      expect(exec('((lambda (x) (+ x x)) 2)'), 4);
      expect(exec('((lambda (x y) (+ x y)) 2 4)'), 6);
      expect(exec('((lambda (x y z) (+ x y z)) 2 4 6)'), 12);
    });
    test('Lambda (&optional)', () {
      expect(exec('((lambda (x y &optional z) (+ x y)) 2 4)'), 6);
      expect(exec('((lambda (x y &optional z) (+ x y z)) 2 4 6)'), 12);
      expect(exec('((lambda (x y &optional z) z) 2 4)'), null);
      expect(
        () => exec('((lambda (x y &optional z) (+ x y z)) 2 4)'),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => exec('((lambda (x y &optional &optional) (+ x y)) 2 4)'),
        throwsArgumentError,
      );
    });
    test('Lambda (&rest)', () {
      expect(exec('((lambda (x y &rest args) (length args)) 2 4)'), 0);
      expect(exec('((lambda (x y &rest args) (length args)) 2 4 6)'), 1);
      expect(exec('((lambda (x y &rest args) (length args)) 2 4 6 8)'), 2);
      expect(
        () => exec('((lambda (x y &rest) (+ x y)) 2 4)'),
        throwsArgumentError,
      );
    });
    test('Macro', () {
      final env = standard.create();
      env.define(Name('x'), 0);
      exec(
          '(define-macro (inc var)'
          "  (cons 'set! (cons var (cons (cons '+ (cons 1 (cons var '()))) '()))))"
          '(inc x)'
          '(inc x)',
          env);
      expect(env[Name('x')], 2);
    });
    test('Make-symbol', () {
      final symbols = List.generate(10, (_) => exec('(make-symbol "foo")'));
      for (final sym in symbols) {
        expect(sym, isName);
      }
      expect(symbols.map((sym) => sym.toString()).toSet().length, 1);
      expect(Name(symbols[0].toString()), isNot(symbols[0]));
    });
    test('Gensym', () {
      final symbols = List.generate(10, (_) => exec('(gensym)'));
      for (final sym in symbols) {
        expect(sym, isName);
      }
      expect(symbols.map((sym) => sym.toString()).toSet().length, 10);
      expect(Name(symbols[0].toString()), symbols[0]);
    });
    test('Quote', () {
      expect(exec('(quote 1)'), 1);
      expect(exec('(quote a)'), Name('a'));
      expect(exec('(quote (+ 1))'), Cons(Name('+'), Cons(1)));
      expect(exec('(quote null)'), isNull);
    });
    test('Quote (syntax)', () {
      expect(exec("'()"), null);
      expect(exec("'null"), isNull);
      expect(exec("'a"), Name('a'));
      expect(exec("'`a"), Cons.quasiquote(Name('a')));
      expect(exec("'(1)"), Cons(1));
      expect(exec("'(+ 1)"), Cons(Name('+'), Cons(1)));
      expect(
        exec("'(a `(b ,c))"),
        Cons(
          Name('a'),
          Cons(Cons.quasiquote(
            Cons(Name('b'), Cons(Cons.unquote(Name('c')))),
          )),
        ),
      );
    });
    test('Quasiquote', () {
      expect(exec('`()'), isNull);
      expect(exec('`null'), isNull);
      expect(exec('`,null'), isNull);
      expect(exec('`a'), Name('a'));
      expect(exec("`'a"), Cons.quote(Name('a')));
      expect(exec('`(1)'), Cons(1));
      expect(exec('`(+ 1)'), Cons(Name('+'), Cons(1)));
      expect(exec('`(,(+ 1 1))'), Cons(2));
      expect(
        exec('`((+ 1 ,(+ 1 1)))'),
        Cons(Cons(Name('+'), Cons(1, Cons(2)))),
      );
      expect(exec("`('(,(+ 1 1)))"), Cons(Cons.quote(Cons(2))));
      expect(
        exec("`(`(,(+ 1 1)))"),
        Cons(
          Cons.quasiquote(
            Cons(Cons.unquote(Cons(Name('+'), Cons(1, Cons(1))))),
          ),
        ),
      );
    });
    test('Splice', () {
      expect(exec('`,@1'), 1);
      expect(exec('`(,@1)'), 1);
      expect(() => exec('`(,@1 2)'), throwsArgumentError);
      expect(exec("`(,@'(1) 2)"), Cons(1, Cons(2)));
      expect(exec("`(,@() 2)"), Cons(2));
      expect(exec("`(,@'() 2)"), Cons(2));
      expect(exec("`(,@())"), isNull);
      expect(exec("`(,@null)"), isNull);
      expect(exec("`(,@'(1))"), Cons(1));
      expect(exec("`(1 ,@2)"), Cons(1, 2));
      expect(exec("`(1 ,@'(2) 3)"), Cons(1, Cons(2, Cons(3))));
      expect(exec("`(1 ,@'(2 3) 4)"), Cons(1, Cons(2, Cons(3, Cons(4)))));
      expect(
        exec("`(1 (2 3) ,@4)"),
        Cons(1, Cons(Cons(2, Cons(3)), 4)),
      );
      expect(
        exec("`(1 (2 3) ,@'(4))"),
        Cons(1, Cons(Cons(2, Cons(3)), Cons(4))),
      );
      expect(
        exec("`(1 () ,@'(4))"),
        Cons(1, Cons(null, Cons(4))),
      );
      expect(
        exec("`(1 ,@'(4) ())"),
        Cons(1, Cons(4, null)),
      );
      expect(
        exec("`(',@())"),
        Cons(Cons(Name('quote'))), // guile: error; sbcl: ((QUOTE))
      );
      expect(
        exec("`(',@'(1))"),
        Cons(Cons.quote(1)), // guile: ((quote 1)) sbcl: ('1)
      );
      expect(
        exec("`(',@'(1 2))"),
        Cons(Cons(Name('quote'),
            Cons(1, Cons(2)))), // guile: ((quote 1 2)) sbcl: ((QUOTE 1 2))
      );
    });
    test('Eval', () {
      expect(exec('(eval (quote (+ 1 2)))'), 3);
    });
    test('Apply', () {
      expect(exec('(apply + 1 2 3)'), 6);
      expect(exec('(apply + 1 2 3 (+ 2 2))'), 10);
    });
    test('Let', () {
      expect(exec('(let ((a 1)) a)'), 1);
      expect(exec('(let ((a 1) (b 2)) a)'), 1);
      expect(exec('(let ((a 1) (b 2)) b)'), 2);
      expect(exec('(let ((a 1) (b 2)) (+ a b))'), 3);
      expect(exec('(let ((a 1) (b 2)) (+ a b) 4)'), 4);
      expect(exec('(let (a) a)'), isNull);
      expect(exec('(let (a) (set! a 1) a)'), 1);
      expect(() => exec('(let (1))'), throwsArgumentError);
    });
    test('Progn', () {
      final env = standard.create();
      env.define(Name('x'), 0);
      expect(exec('(progn 1 2)'), 2);
      expect(exec('(progn 1 (+ 1 1))'), 2);
      expect(exec('(progn (set! x (+ x 1)) (set! x (+ x 1)) x)', env), 2);
    });
    group('Print', () {
      final buffer = StringBuffer();
      setUp(() {
        printer = buffer.write;
      });
      tearDown(() {
        printer = print;
        buffer.clear();
      });
      test('empty', () {
        expect(exec('(print)'), isNull);
        expect(buffer.toString(), isEmpty);
      });
      test('elements', () {
        expect(exec('(print 1 2 3)'), isNull);
        expect(buffer.toString(), '123');
      });
      test('expression', () {
        expect(exec('(print (+ 1 2) " " (+ 3 4))'), isNull);
        expect(buffer.toString(), '3 7');
      });
    });
    test('Set!', () {
      final env = standard.create();
      env.define(Name('a'), null);
      expect(exec('(set! a 1)', env), 1);
      expect(exec('(set! a (+ 1 2))', env), 3);
      expect(exec('(set! a (+ 1 2)) (+ a 1)', env), 4);
    });
    test('Set! (undefined)', () {
      expect(() => exec('(set! a 1)'), throwsArgumentError);
      expect(() => standard[Name('a')], throwsArgumentError);
    });
    test('If', () {
      expect(exec('(if true)'), isNull);
      expect(exec('(if false)'), isNull);
      expect(exec('(if true 1)'), 1);
      expect(exec('(if false 1)'), isNull);
      expect(exec('(if true 1 2)'), 1);
      expect(exec('(if false 1 2)'), 2);
    });
    test('If (truthiness)', () {
      expect(exec('(if (and 1) 3 4)'), 3);
      expect(exec('(if (and 1 false) 3 4)'), 4);
      expect(exec('(if (or 1) 3 4)'), 3);
      expect(exec('(if (or 1 false) 3 4)'), 3);
      expect(exec('(if (or false) 3 4)'), 4);
    });
    test('If (laziness)', () {
      expect(exec('(if (= 1 1) 3 4)'), 3);
      expect(exec('(if (= 1 2) 3 4)'), 4);
    });
    test('While', () {
      final env = standard.create();
      env.define(Name('a'), 0);
      exec('(while (< a 3) (set! a (+ a 1)))', env);
      expect(env[Name('a')], 3);
    });
    test('While (truthiness)', () {
      final env = standard.create();
      env.define(
        Name('a'),
        Cons(Name('foo'), Cons(Name('bar'), Cons(Name('baz')))),
      );
      exec('(while (cdr a) (set! a (cdr a)))', env);
      expect(env[Name('a')], Cons(Name('baz')));
    });
    test('True', () {
      expect(exec('true'), isTrue);
    });
    test('False', () {
      expect(exec('false'), isFalse);
    });
    test('And', () {
      expect(exec('(and)'), isTrue);
      expect(exec('(and true)'), isTrue);
      expect(exec('(and false)'), isFalse);
      expect(exec('(and true true)'), isTrue);
      expect(exec('(and true false)'), isFalse);
      expect(exec('(and false true)'), isFalse);
      expect(exec('(and false false)'), isFalse);
      expect(exec('(and true true true)'), isTrue);
      expect(exec('(and true true false)'), isFalse);
      expect(exec('(and true false true)'), isFalse);
      expect(exec('(and true false false)'), isFalse);
      expect(exec('(and false true true)'), isFalse);
      expect(exec('(and false true false)'), isFalse);
      expect(exec('(and false false true)'), isFalse);
      expect(exec('(and false false false)'), isFalse);
    });
    test('And (truthiness)', () {
      expect(exec('(and 1)'), 1);
      expect(exec('(and 1 false)'), isFalse);
      expect(exec('(and "foo")'), "foo");
      expect(exec("(and '(a))"), Cons(Name('a')));
      expect(exec("(and '())"), isFalse);
      expect(exec('(and 1 2 3)'), 3);
      expect(exec('(and false 2 3)'), isFalse);
    });
    test('And (laziness)', () {
      final env = standard.create();
      env.define(Name('a'), null);
      exec('(and false (set! a true))', env);
      expect(env[Name('a')], isNull);
      exec('(and true (set! a true))', env);
      expect(env[Name('a')], isTrue);
    });
    test('Or', () {
      expect(exec('(or)'), isFalse);
      expect(exec('(or true)'), isTrue);
      expect(exec('(or false)'), isFalse);
      expect(exec('(or true true)'), isTrue);
      expect(exec('(or true false)'), isTrue);
      expect(exec('(or false true)'), isTrue);
      expect(exec('(or false false)'), isFalse);
      expect(exec('(or true true true)'), isTrue);
      expect(exec('(or true true false)'), isTrue);
      expect(exec('(or true false true)'), isTrue);
      expect(exec('(or true false false)'), isTrue);
      expect(exec('(or false true true)'), isTrue);
      expect(exec('(or false true false)'), isTrue);
      expect(exec('(or false false true)'), isTrue);
      expect(exec('(or false false false)'), isFalse);
    });
    test('Or (truthiness)', () {
      expect(exec('(or 1)'), 1);
      expect(exec('(or 1 false)'), 1);
      expect(exec('(or false 1)'), 1);
      expect(exec('(or "foo")'), "foo");
      expect(exec("(or '(a))"), Cons(Name('a')));
      expect(exec("(or '())"), isFalse);
      expect(exec('(or 1 2 3)'), 1);
      expect(exec('(or false 2 3)'), 2);
    });
    test('Or (laziness)', () {
      final env = standard.create();
      env.define(Name('a'), null);
      exec('(or true (set! a true))', env);
      expect(env[Name('a')], isNull);
      exec('(or false (set! a true))', env);
      expect(env[Name('a')], isTrue);
    });
    test('Not', () {
      expect(exec('(not true)'), isFalse);
      expect(exec('(not false)'), isTrue);
    });
    test('Not (truthy)', () {
      expect(exec('(not 1)'), isFalse);
      expect(exec('(not "foo")'), isFalse);
      expect(exec("(not '(a))"), isFalse);
      expect(exec("(not '())"), isTrue);
      expect(exec("(not null)"), isTrue);
    });
    test('Add', () {
      expect(exec('(+ 1)'), 1);
      expect(exec('(+ 1 2)'), 3);
      expect(exec('(+ 1 2 3)'), 6);
      expect(exec('(+ 1 2 3 4)'), 10);
    });
    test('Sub', () {
      expect(exec('(- 1)'), -1);
      expect(exec('(- 1 2)'), -1);
      expect(exec('(- 1 2 3)'), -4);
      expect(exec('(- 1 2 3 4)'), -8);
    });
    test('Mul', () {
      expect(exec('(* 2)'), 2);
      expect(exec('(* 2 3)'), 6);
      expect(exec('(* 2 3 4)'), 24);
    });
    test('Div', () {
      expect(exec('(/ 24)'), 24);
      expect(exec('(/ 24 3)'), 8);
      expect(exec('(/ 24 3 2)'), 4);
    });
    test('Mod', () {
      expect(exec('(% 24)'), 24);
      expect(exec('(% 24 5)'), 4);
      expect(exec('(% 24 5 3)'), 1);
    });
    test('Less', () {
      expect(exec('(< 1 2)'), isTrue);
      expect(exec('(< 1 1)'), isFalse);
      expect(exec('(< 2 1)'), isFalse);
      expect(exec('(< "a" "b")'), isTrue);
      expect(exec('(< "a" "a")'), isFalse);
      expect(exec('(< "b" "a")'), isFalse);
    });
    test('Less equal', () {
      expect(exec('(<= 1 2)'), isTrue);
      expect(exec('(<= 1 1)'), isTrue);
      expect(exec('(<= 2 1)'), isFalse);
      expect(exec('(<= "a" "b")'), isTrue);
      expect(exec('(<= "a" "a")'), isTrue);
      expect(exec('(<= "b" "a")'), isFalse);
    });
    test('Equal', () {
      expect(exec('(= 1 1)'), isTrue);
      expect(exec('(= 1 2)'), isFalse);
      expect(exec('(= 2 1)'), isFalse);
      expect(exec('(= "a" "a")'), isTrue);
      expect(exec('(= "a" "b")'), isFalse);
      expect(exec('(= "b" "a")'), isFalse);
    });
    test('Not equal', () {
      expect(exec('(!= 1 1)'), isFalse);
      expect(exec('(!= 1 2)'), isTrue);
      expect(exec('(!= 2 1)'), isTrue);
      expect(exec('(!= "a" "a")'), isFalse);
      expect(exec('(!= "a" "b")'), isTrue);
      expect(exec('(!= "b" "a")'), isTrue);
    });
    test('Larger', () {
      expect(exec('(> 1 1)'), isFalse);
      expect(exec('(> 1 2)'), isFalse);
      expect(exec('(> 2 1)'), isTrue);
      expect(exec('(> "a" "a")'), isFalse);
      expect(exec('(> "a" "b")'), isFalse);
      expect(exec('(> "b" "a")'), isTrue);
    });
    test('Larger equal', () {
      expect(exec('(>= 1 1)'), isTrue);
      expect(exec('(>= 1 2)'), isFalse);
      expect(exec('(>= 2 1)'), isTrue);
      expect(exec('(>= "a" "a")'), isTrue);
      expect(exec('(>= "a" "b")'), isFalse);
      expect(exec('(>= "b" "a")'), isTrue);
    });
    test('eq?', () {
      expect(exec('(eq? 1 1)'), true);
      expect(exec('(eq? 1 2)'), false);
      expect(exec('(eq? 1 1.0)'), false);
      expect(exec('(eq? 1.0 1.0)'), true);
      expect(exec('(eq? "foo" "foo")'), false);
      expect(exec('(eq? "foo" "bar")'), false);
      expect(exec("(eq? 'foo 'foo)"), true);
    });
    test('Cons', () {
      expect(exec('(cons 1 2)'), Cons(1, 2));
      expect(exec('(cons 1 null)'), Cons(1));
      expect(exec('(cons null 2)'), Cons(null, 2));
      expect(exec('(cons null null)'), Cons());
      expect(
          exec('(cons 1 (cons 2 (cons 3 null)))'), Cons(1, Cons(2, Cons(3))));
    });
    test('Cons (syntax)', () {
      expect(exec("'(1 . 2)"), Cons(1, 2));
      expect(exec("`(1 . 2)"), Cons(1, 2));
      expect(exec("`(1 . ,(+ 1 1))"), Cons(1, 2));
      expect(exec("'(1 . (2 . 3))"), Cons(1, Cons(2, 3)));
      expect(exec("'(1 . ())"), Cons(1));
      expect(exec("'(1 . null)"), Cons(1));
      expect(exec("(car '(1 . 2))"), 1);
      expect(exec("(cdr '(1 . 2))"), 2);
    });

    test('Car', () {
      expect(exec('(car null)'), isNull);
      expect(exec('(car (cons 1 2))'), 1);
    });
    test('Car!', () {
      expect(exec('(car! null 3)'), isNull);
      expect(exec('(car! (cons 1 2) 3)'), Cons(3, 2));
    });
    test('Cdr', () {
      expect(exec('(cdr null)'), isNull);
      expect(exec('(cdr (cons 1 2))'), 2);
    });
    test('Cdr!', () {
      expect(exec('(cdr! null 3)'), isNull);
      expect(exec('(cdr! (cons 1 2) 3)'), Cons(1, 3));
    });
  });
  group('Library', () {
    test('Null', () {
      expect(exec('null'), isNull);
    });
    test('Null? (true)', () {
      expect(exec("(null? '())"), isTrue);
      expect(exec('(null? null)'), isTrue);
    });
    test('Null? (false)', () {
      expect(exec('(null? 1)'), isFalse);
      expect(exec('(null? "a")'), isFalse);
      expect(exec('(null? (quote a))'), isFalse);
      expect(exec('(null? true)'), isFalse);
      expect(exec('(null? false)'), isFalse);
    });
    test('When', () {
      expect(exec('(when true 1)'), 1);
      expect(exec('(when true 1 (+ 1 1))'), 2);
      expect(exec('(when false 1)'), isNull);
      expect(exec('(when null 1)'), isNull);
      expect(exec('(when "foo" 1)'), 1);
    });
    test('Unless', () {
      expect(exec('(unless true 1)'), isNull);
      expect(exec('(unless true 1 (+ 1 1))'), isNull);
      expect(exec('(unless false 1)'), 1);
      expect(exec('(unless null 1)'), 1);
      expect(exec('(unless "foo" 1)'), isNull);
    });
    test('Length', () {
      expect(exec("(length '())"), 0);
      expect(exec("(length '(1))"), 1);
      expect(exec("(length '(1 1))"), 2);
      expect(exec("(length '(1 1 1))"), 3);
      expect(exec("(length '(1 1 1 1))"), 4);
      expect(exec("(length '(1 1 1 1 1))"), 5);
    });
    test('Append', () {
      expect(exec("(append '() '())"), isNull);
      expect(exec("(append '(1) '())"), exec("'(1)"));
      expect(exec("(append '() '(1))"), exec("'(1)"));
      expect(exec("(append '(1) '(2))"), exec("'(1 2)"));
      expect(exec("(append '(1 2) '(3))"), exec("'(1 2 3)"));
      expect(exec("(append '(1) '(2 3))"), exec("'(1 2 3)"));
    });
    test('List', () {
      expect(exec('(list)'), isNull);
      expect(exec('(list 1 (+ 1 1))'), Cons(1, Cons(2)));
      expect(exec('(list 1 (+ 1 1) "foo")'), Cons(1, Cons(2, Cons('foo'))));
    });
    test('List Head', () {
      expect(exec("(list-head '(5 6 7) 0)"), 5);
      expect(exec("(list-head '(5 6 7) 1)"), 6);
      expect(exec("(list-head '(5 6 7) 2)"), 7);
      expect(exec("(list-head '(5 6 7) 3)"), isNull);
    });
    test('List Tail', () {
      expect(exec("(list-tail '(5 6 7) 0)"), exec("'(6 7)"));
      expect(exec("(list-tail '(5 6 7) 1)"), exec("'(7)"));
      expect(exec("(list-tail '(5 6 7) 2)"), isNull);
    });
    test('Map', () {
      expect(exec("(map '() (lambda (x) (* 2 x)))"), isNull);
      expect(exec("(map '(2) (lambda (x) (* 2 x)))"), exec("'(4)"));
      expect(exec("(map '(2 3) (lambda (x) (* 2 x)))"), exec("'(4 6)"));
      expect(exec("(map '(2 3 4) (lambda (x) (* 2 x)))"), exec("'(4 6 8)"));
    });
    test('Inject', () {
      expect(exec("(inject '() 5 (lambda (s e) (+ s e 1)))"), 5);
      expect(exec("(inject '(2) 5 (lambda (s e) (+ s e 1)))"), 8);
      expect(exec("(inject '(2 3) 5 (lambda (s e) (+ s e 1)))"), 12);
    });
    test('member', () {
      expect(exec("(member 1 '(1 2 3))"), true);
      expect(exec("(member 2 '(1 2 3))"), true);
      expect(exec("(member 3 '(1 2 3))"), true);
      expect(exec("(member 4 '(1 2 3))"), false);
      expect(exec('''(member "foo" '("bar" "foo" "baz"))'''), true);
      expect(exec('''(member "foo" '("bar" "foo" "baz") eq?)'''), false);
    });
    test('memq', () {
      expect(exec("(memq 1 '(1 2 3))"), true);
      expect(exec("(memq 2 '(1 2 3))"), true);
      expect(exec("(memq 3 '(1 2 3))"), true);
      expect(exec("(memq 4 '(1 2 3))"), false);
      expect(exec('''(memq "foo" '("bar" "foo" "baz"))'''), false);
    });
  });
  group('Examples', () {
    test('Fibonacci', () {
      final env = standard.create();
      exec(
          '(define (fib n)'
          '  (if (<= n 1)'
          '    1'
          '    (+ (fib (- n 1)) (fib (- n 2)))))',
          env);
      expect(exec('(fib 0)', env), 1);
      expect(exec('(fib 1)', env), 1);
      expect(exec('(fib 2)', env), 2);
      expect(exec('(fib 3)', env), 3);
      expect(exec('(fib 4)', env), 5);
      expect(exec('(fib 5)', env), 8);
    });
    test('Closure', () {
      final env = standard.create();
      exec(
          '(define (mul n)'
          '  (lambda (x) (* n x)))',
          env);
      expect(exec('((mul 2) 3)', env), 6);
      expect(exec('((mul 3) 4)', env), 12);
      expect(exec('((mul 4) 5)', env), 20);
    });
    test('Object', () {
      final env = standard.create();
      exec(
          '(define (counter start)'
          '  (let ((count start))'
          '    (lambda ()'
          '      (set! count (+ count 1)))))',
          env);
      exec('(define a (counter 10))', env);
      exec('(define b (counter 20))', env);
      expect(exec('(a)', env), 11);
      expect(exec('(b)', env), 21);
      expect(exec('(a)', env), 12);
      expect(exec('(b)', env), 22);
      expect(exec('(a)', env), 13);
      expect(exec('(b)', env), 23);
    });
    test('Macro (advanced)', () {
      final env = standard.create()
        ..define(Name('x'), null)
        ..define(Name('y'), null);
      exec(
          '(define-macro (set2! a b val)'
          "  (list 'progn (list 'set! a val) (list 'set! b val)))"
          '(set2! x y 1)',
          env);
      expect(env[Name('x')], 1);
      expect(env[Name('y')], 1);
    });
    test('Macro (make-symbol)', () {
      final env = standard.create()..define(Name('foo'), 0);
      exec(
          '(define-macro (for var from init to final do &rest body)'
          '  (let ((tempvar (make-symbol "max")))'
          '    `(let ((,var ,init)'
          '           (,tempvar ,final))'
          '       (while (<= ,var ,tempvar)'
          '         ,@body'
          '         (set! ,var (+ 1 ,var))))))'
          '(for x from 1 to 10 do'
          '  (set! foo (+ 1 foo)))',
          env);
      expect(env[Name('foo')], 10);
    });
    test('Exit infinite loop', () {
      final start = DateTime.timestamp().millisecondsSinceEpoch;
      final env = standard.create()
        ..interrupt = () {
          final end = DateTime.timestamp().millisecondsSinceEpoch;
          if (end - start > 200) throw StateError('interrupted');
        };
      expect(() => exec('(while true)', env), throwsStateError);
    });
  });
}
