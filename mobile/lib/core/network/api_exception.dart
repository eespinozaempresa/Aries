class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(dynamic error) {
    if (error?.response != null) {
      final data = error.response.data;
      final msg = data is Map ? (data['message'] ?? 'Error del servidor') : 'Error del servidor';
      return ApiException(
        msg is List ? (msg).join(', ') : msg.toString(),
        statusCode: error.response.statusCode,
      );
    }
    return const ApiException('Sin conexión al servidor');
  }

  @override
  String toString() => message;
}
