import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio dio;
  final Function(String)? onAuthFailure;
  final Function(String)? onError;
  final Future Function() getToken;
  final bool enableLogError;

  ApiService({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    this.onAuthFailure,
    this.onError,
    required this.getToken,
    bool isAuth = false,
    this.enableLogError = false,
  }) : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !isAuth) {
          onAuthFailure?.call('Authentication failed');
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> postRequest(String path, Map<String, dynamic> data) async {
    try {
      return await dio.post(path, data: data);
    } catch (e) {
      logError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Response> getRequest(String path,
      {Map<String, dynamic>? query}) async {
    try {
      return await dio.get(path, queryParameters: query);
    } catch (e) {
      logError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Response> patchRequest(
      String endpoint, Map<String, dynamic> data) async {
    try {
      return await dio.patch(endpoint, data: data);
    } catch (e) {
      logError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Response> putRequest(
      String endpoint, Map<String, dynamic> data) async {
    try {
      return await dio.put(endpoint, data: data);
    } catch (e) {
      logError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<Response> deleteRequest(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      return await dio.delete(endpoint, queryParameters: data);
    } catch (e) {
      logError(e, StackTrace.current);
      rethrow;
    }
  }

  void logError(dynamic error, StackTrace stackTrace) {
    if (!enableLogError) return;

    if (kDebugMode) {
      debugPrint('Error: $error');
      debugPrint('Stack Trace: $stackTrace');
      if (error is DioException && error.response != null) {
        debugPrint('Error Data: ${error.response!.data}');
      }
    }

    if (error is DioException && error.response != null) {
      onError?.call(error.response!.data.toString());
    } else {
      onError?.call(error.toString());
    }
  }

  Future<void> setToken(String token) async {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
