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
      final status = data['status']?.toString().toLowerCase();
      if (status == 'failure' ||
          status == 'error' ||
          data['errors'] != null ||
          data['error'] != null ||
          data['message'] != null ||
          data['msg'] != null) {
        final errors = data['errors'] ?? data['error'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
        if (errors is String && errors.isNotEmpty) {
          return errors;
        }
        if (data['message'] != null) {
          if (data['message'] is String && (data['message'] as String).isNotEmpty) {
            return data['message'] as String;
          }
          if (data['message'] is List && (data['message'] as List).isNotEmpty) {
            return (data['message'] as List).first.toString();
          }
          return data['message'].toString();
        }
        if (data['msg'] != null && data['msg'].toString().isNotEmpty) {
          return data['msg'].toString();
        }
        if (data['detail'] != null && data['detail'].toString().isNotEmpty) {
          return data['detail'].toString();
        }
        if (status == 'failure' || status == 'error') {
          return 'Something went wrong';
        }
      }
    }
    return null;
  }

  @override
  String toString() => message;
}
