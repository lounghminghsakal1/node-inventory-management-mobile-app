import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  factory ApiException.fromDioException(DioException error) {
    final extracted = extractErrorMessage(error.response?.data);
    if (extracted != null && extracted.isNotEmpty) {
      return ApiException(extracted, error.response?.statusCode);
    }
    if (error.message != null && error.message!.isNotEmpty) {
      // Remove generic Dio prefixes if any
      final cleanMsg = error.message!
          .replaceFirst(RegExp(r'^DioException \[.*?\]: '), '')
          .replaceFirst('Exception: ', '');
      return ApiException(cleanMsg, error.response?.statusCode);
    }
    return ApiException('Something went wrong', error.response?.statusCode);
  }

  factory ApiException.fromResponseData(dynamic data, [int? statusCode]) {
    final extracted = extractErrorMessage(data);
    return ApiException(extracted ?? 'Something went wrong', statusCode);
  }

  /// Always check if status is failure or errors array is present,
  /// returning the 1st element of the errors array if available.
  static String? extractErrorMessage(dynamic data) {
    if (data is Map) {
      if (data['status'] == 'failure' ||
          data['status'] == 'error' ||
          data['errors'] != null ||
          data['error'] != null) {
        final errors = data['errors'] ?? data['error'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
        if (errors is String && errors.isNotEmpty) {
          return errors;
        }
        if (data['message'] is String && (data['message'] as String).isNotEmpty) {
          return data['message'] as String;
        }
        if (data['status'] == 'failure') {
          return 'Something went wrong';
        }
      }
    }
    return null;
  }

  @override
  String toString() => message;
}
