import './name.dart';

/// The basic data structure of LISP.
class Cons {
  factory Cons.quote(dynamic datum) => Cons(Name('quote'), Cons(datum));
  factory Cons.quasiquote(dynamic datum) =>
      Cons(Name('quasiquote'), Cons(datum));
  factory Cons.unquote(dynamic datum) => Cons(Name('unquote'), Cons(datum));
  factory Cons.unquoteSplicing(dynamic datum) =>
      Cons(Name('unquote-splicing'), Cons(datum));

  /// Constructs a cons.
  Cons([this.car, this.cdr]);

  /// The first object.
  dynamic car;

  /// The second object.
  dynamic cdr;

  /// The head of the cons.
  dynamic get head => car;

  /// The tail of the cons, if applicable.
  Cons? get tail {
    if (cdr is Cons) {
      return cdr;
    } else if (cdr == null) {
      return null;
    } else {
      throw StateError('${toString()} does not have a tail.');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Cons && car == other.car && cdr == other.cdr;

  @override
  int get hashCode => 31 * car.hashCode + cdr.hashCode;

  @override
  String toString() {
    if (_isQuote) return _specialToString("'");
    if (_isQuasiquote) return _specialToString("`");
    if (_isUnquote) return _specialToString(",");
    if (_isUnquoteSplicing) return _specialToString(",@");

    final buffer = StringBuffer();
    buffer.write('(');
    var current = this;
    for (;;) {
      buffer.write(current.car);
      if (current.cdr is Cons) {
        current = current.cdr;
        buffer.write(' ');
      } else if (current.cdr == null) {
        buffer.write(')');
        return buffer.toString();
      } else {
        buffer.write(' . ');
        buffer.write(current.cdr);
        buffer.write(')');
        return buffer.toString();
      }
    }
  }

  bool _isSpecialForm(Name name) =>
      car == name && cdr is Cons && cdr.tail == null;
  bool get _isQuote => _isSpecialForm(Name('quote'));
  bool get _isQuasiquote => _isSpecialForm(Name('quasiquote'));
  bool get _isUnquote => _isSpecialForm(Name('unquote'));
  bool get _isUnquoteSplicing => _isSpecialForm(Name('unquote-splicing'));

  String _specialToString(String prefix) => '$prefix${cdr.head}';
}
