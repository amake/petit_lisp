/// A quoted datum.
class Quote {
  /// Constructs as a quote.
  Quote(this.datum);

  /// The quoted datum.
  dynamic datum;

  @override
  bool operator ==(Object other) => other is Quote && other.datum == datum;

  @override
  int get hashCode => 17 * datum.hashCode;

  @override
  String toString() => "'$datum";
}
