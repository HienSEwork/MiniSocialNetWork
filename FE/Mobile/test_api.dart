import 'dart:io';
// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void main() async {
  print('Starting API test...');
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://localhost:5001/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Bypass SSL just in case
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );

  try {
    print('Sending POST /Auth/login...');
    final response = await dio.post(
      '/Auth/login',
      data: {'email': 'admin@TechNet.local', 'password': 'Admin!123'},
    );
    print('Login Success: ${response.statusCode}');
    print('Data: ${response.data}');
  } on DioException catch (e) {
    print('DioException occurred:');
    print('Type: ${e.type}');
    print('Message: ${e.message}');
    if (e.response != null) {
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
    } else {
      print('Error without response. Error: ${e.error}');
      print('Stack trace: ${e.stackTrace}');
    }
  } catch (e) {
    print('General exception: $e');
  }
}
