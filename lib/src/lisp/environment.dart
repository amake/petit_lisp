import 'name.dart';

typedef InterruptCallback = void Function();

/// Environment of bindings.
class Environment {
  /// Constructor for the nested environment.
  Environment([this._owner]) : _bindings = {};

  /// The owning environment.
  final Environment? _owner;

  /// A callback to check if execution should continue. Consumers should set
  /// this to a function that throws an exception if execution should stop.
  InterruptCallback? interrupt;

  /// The internal environment bindings.
  final Map<Name, dynamic> _bindings;

  /// Constructor for a nested environment.
  Environment create() => Environment(this);

  /// Return the binding for [key].
  dynamic operator [](Name key) {
    if (_bindings.containsKey(key)) {
      return _bindings[key];
    } else if (_owner != null) {
      return _owner![key];
    } else {
      _invalidBinding(key);
      return null;
    }
  }

  /// Updates the binding for [key] with a [value].
  void operator []=(Name key, dynamic value) {
    if (_bindings.containsKey(key)) {
      _bindings[key] = value;
    } else if (_owner != null) {
      _owner![key] = value;
    } else {
      _invalidBinding(key);
    }
  }

  /// Defines a new binding from [key] to [value].
  dynamic define(Name key, dynamic value) => _bindings[key] = value;

  /// Returns the keys of the bindings.
  Iterable<Name> get keys => _bindings.keys;

  /// Returns the parent of the bindings.
  Environment? get owner => _owner;

  /// Check if execution should continue. See [interrupt].
  void checkInterrupt() {
    Environment? env = this;
    while (env != null) {
      env.interrupt?.call();
      env = env.owner;
    }
  }

  /// Called when a missing binding is accessed.
  void _invalidBinding(Name key) =>
      throw ArgumentError('Unknown binding for $key');
}
