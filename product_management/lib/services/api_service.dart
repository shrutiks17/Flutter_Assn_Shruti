import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.29.149:3000';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<http.Response> _requestWithTimeout(Future<http.Response> request) async {
    return request.timeout(_timeout, onTimeout: () {
      throw Exception('Connection timeout');
    });
  }

  static Future<List<Product>> getProducts() async {
    final response = await _requestWithTimeout(
      http.get(Uri.parse('$_baseUrl/products'))
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final data = responseData['data'] as List;
      return data.map((p) => Product.fromJson(p)).toList();
    }
    throw _handleError(response);
  }

  static Future<Product> addProduct(Product product, _) async {
    final response = await _requestWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      )
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return Product.fromJson(responseData['data']);
    }
    throw _handleError(response);
  }

  static Future<Product> updateProduct(Product product, _) async {
    final response = await _requestWithTimeout(
      http.put(
        Uri.parse('$_baseUrl/products/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      )
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      return Product.fromJson(responseData['data']);
    }
    throw _handleError(response);
  }

  static Future<void> deleteProduct(String id) async {
    final response = await _requestWithTimeout(
      http.delete(Uri.parse('$_baseUrl/products/$id'))
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _handleError(response);
    }
  }

  static Exception _handleError(http.Response response) {
    try {
      final error = json.decode(response.body);
      return Exception(error['message'] ?? 'Unknown error');
    } catch (e) {
      return Exception('Failed with status ${response.statusCode}');
    }
  }
}