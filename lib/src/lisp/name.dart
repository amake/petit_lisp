/// An unique symbolic name.
///
/// This provides essentially the behavior of the built-in [Symbol], but
/// allows access and printing of the underlying string.
class Name {
  /// Factory for new symbol cells.
  factory Name(String name) =>
      _interned.putIfAbsent(name, () => Name._internal(name));

  /// Factory for new, uninterned symbol cells.
  factory Name.uninterned(String name) => Name._internal(name);

  /// Internal constructor for symbol.
  Name._internal(this._name);

  /// The interned symbols.
  static final Map<String, Name> _interned = {};

  /// Determine whether a symbol is interned.
  static bool isInterned(String name) => _interned.containsKey(name);

  /// The name of the symbol.
  final String _name;

  /// Returns the string representation of the symbolic name.
  @override
  String toString() => _name;
}
