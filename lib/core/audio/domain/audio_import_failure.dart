enum AudioImportFailureType {
  cancelled,
  invalidFormat,
  unsupportedFormat,
  corruptFile,
  readFailed,
}

class AudioImportFailure {
  const AudioImportFailure({
    required this.type,
    required this.message,
  });

  final AudioImportFailureType type;
  final String message;
}

class AudioImportException implements Exception {
  const AudioImportException(this.failure);

  final AudioImportFailure failure;

  @override
  String toString() => failure.message;
}
