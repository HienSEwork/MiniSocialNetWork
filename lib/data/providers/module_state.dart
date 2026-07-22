enum ModuleStatus { initial, loading, success, error }

class ModuleDataException implements Exception {
  const ModuleDataException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
