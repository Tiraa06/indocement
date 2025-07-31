import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final Dio _dio = Dio();

  /// Ambil token dari SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// GET request dengan token
  static Future<Response> get(
    String url, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
  }) async {
    final token = await getToken();
    return _dio.get(
      url,
      queryParameters: params,
      options: Options(
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
      ),
    );
  }

  /// POST request dengan token
  static Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    final token = await getToken();
    return _dio.post(
      url,
      data: data,
      options: Options(
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
      ),
    );
  }

  /// PUT request dengan token
  static Future<Response> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    final token = await getToken();
    return _dio.put(
      url,
      data: data,
      options: Options(
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
      ),
    );
  }

  /// DELETE request dengan token
  static Future<Response> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    final token = await getToken();
    return _dio.delete(
      url,
      data: data,
      options: Options(
        headers: {
          'accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          ...?headers,
        },
      ),
    );
  }
}