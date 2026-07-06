import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/order_model.dart';

class OrderRepository {
  final Dio _dio;

  OrderRepository(this._dio);

  Future<PaginatedOrders> getOrders({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page},
      );

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        return PaginatedOrders.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<OrderDetail> getOrderDetail(int orderId) async {
    try {
      final response = await _dio.get(ApiEndpoints.orderDetail(orderId.toString()));

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return OrderDetail.fromJson(data);
        }
        return OrderDetail.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
