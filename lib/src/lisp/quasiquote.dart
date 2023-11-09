/// A quasi-quoted datum.
class Quasiquote {
  /// Constructs as a quasiquote.
  Quasiquote(this.datum);

  /// The quasiquoted datum.
  dynamic datum;

  @override
  bool operator ==(Object other) => other is Quasiquote && other.datum == datum;

  @override
  int get hashCode => 19 * datum.hashCode;

  @override
  String toString() => "`$datum";
}
