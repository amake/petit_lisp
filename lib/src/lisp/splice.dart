/// A spliced datum.
class Splice {
  /// Constructs as a splice.
  Splice(this.datum);

  /// The spliced datum.
  dynamic datum;

  @override
  bool operator ==(Object other) => other is Splice && other.datum == datum;

  @override
  int get hashCode => 23 * datum.hashCode;

  @override
  String toString() => ",@$datum";
}
