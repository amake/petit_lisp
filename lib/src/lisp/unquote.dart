/// An unquoted datum.
class Unquote {
  /// Constructs as an unquote.
  Unquote(this.datum);

  /// The unquoted datum.
  dynamic datum;

  @override
  bool operator ==(Object other) => other is Unquote && other.datum == datum;

  @override
  int get hashCode => 41 * datum.hashCode;

  @override
  String toString() => ",$datum";
}
