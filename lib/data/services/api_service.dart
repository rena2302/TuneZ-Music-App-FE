import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  late PersistCookieJar _cookieJar;
  final Completer<void> _initCompleter = Completer<void>();

  factory ApiService() => _instance; // Singleton instance

  ApiService._internal() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _initCookieJar(); // Đảm bảo _cookieJar khởi tạo hoàn tất

      _dio = Dio(BaseOptions(
        receiveTimeout: Duration(minutes: 5), // Tăng thời gian nhận phản hồi
        connectTimeout: Duration(minutes: 5), // Thời gian kết nối tối đa
        baseUrl: dotenv.env['FLUTTER_PUBLIC_API_ENDPOINT'] ?? '',
        validateStatus: (status) => status != null && status <= 500,
      ));

      _dio.interceptors.add(CookieManager(_cookieJar)); // Thêm CookieManager

      _initCompleter.complete(); // Hoàn thành khởi tạo
    } catch (e) {
      _initCompleter.completeError(e); // Báo lỗi nếu có vấn đề
    }
  }

  Future<void> ensureInitialized() async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
  }

  /// Khởi tạo CookieJar và đảm bảo lưu cookie vĩnh viễn
  Future<void> _initCookieJar() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _cookieJar =
          PersistCookieJar(storage: FileStorage('${appDocDir.path}/cookies'));
    } catch (e) {
      throw Exception('Lỗi khởi tạo CookieJar: $e');
    }
  }

  /// Phương thức GET
  Future<dynamic> get(String endpoint) async {
    await ensureInitialized();
    try {
      final response = await _dio.get(endpoint);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error GET: $e');
    }
  }

  Future<ResponseBody?> getStream(String endpoint) async {
    await ensureInitialized();
    try {
      final response = await _dio.get<ResponseBody>(
        endpoint,
        options: Options(
            responseType: ResponseType.stream,
            headers: {
            'Content-Type': 'application/json',
          },), // ⚡ Nhận dữ liệu dạng stream
      );
      return response.data;
    } catch (e) {
      throw Exception('Error streaming music: $e');
    }
  }

  /// Phương thức POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    await ensureInitialized();
    try {
      final response = await _dio.post(endpoint, data: jsonEncode(body),
      options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error POST: $e');
    }
  }

  /// Phương thức POST login (lưu cookie)
  Future<dynamic> postWithCookies(
      String endpoint, Map<String, dynamic> body) async {
    await ensureInitialized();
    try {
      final response = await _dio.post(endpoint, data: jsonEncode(body),
      options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),);
      final uri = Uri.parse(_dio.options.baseUrl);
      final cookies = await _cookieJar.loadForRequest(uri);
      await _cookieJar.saveFromResponse(uri, cookies);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error POST: $e');
    }
  }

  /// Kiểm tra cookie đã lưu
  Future<List<Cookie>> getCookies(String url) async {
    await ensureInitialized();
    return _cookieJar.loadForRequest(Uri.parse(url));
  }

  /// Xử lý phản hồi HTTP
  dynamic _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data;
    } else {
      throw Exception(
          'HTTP Error: ${response.statusCode}, Body: ${response.data}');
    }
  }

  Future<void> clearCookies() async {
    await ensureInitialized();
    await _cookieJar.deleteAll(); // Xóa tất cả cookie
  }

  Future<dynamic> delete(String endpoint) async {
     await ensureInitialized();
    try {
      final response = await _dio.delete(endpoint);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error DELETE: $e');
    }
  }

Future<dynamic> postFormData(
  FormData formData, 
  String endpoint, {
  Options? options,
}) async {
  await ensureInitialized();
  try {
    // Cấu hình Dio cho upload file lớn
    _dio.options.connectTimeout = const Duration(minutes: 10);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
    _dio.options.sendTimeout = const Duration(minutes: 10);
    _dio.options.validateStatus = (status) => status != null && status < 600;

    final defaultOptions = Options(
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 10),
      validateStatus: (status) => status != null && status < 600,
    );

    final response = await _dio.post(
      endpoint,
      data: formData,
      options: options ?? defaultOptions,
      onSendProgress: (sent, total) {
        if (total != -1) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%');
        }
      },
    );
    return _handleResponse(response);
  } catch (e) {
    print('General error: $e');
    throw Exception('Error uploading: $e');
  }
}
}