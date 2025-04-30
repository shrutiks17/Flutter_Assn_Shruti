import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    if (_isLoading) return;
    
    _startLoading();
    try {
      final products = await ApiService.getProducts();
      _products = products;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(Product product, param1) async {
    _startLoading();
    try {
      final newProduct = await ApiService.addProduct(product, null);
      _products.add(newProduct);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  Future<void> updateProduct(Product product, param1) async {
    _startLoading();
    try {
      final updatedProduct = await ApiService.updateProduct(product, null);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  Future<void> deleteProduct(String id) async {
    if (id.isEmpty) {
      _error = "Product ID is invalid.";
      notifyListeners();
      return;
    }

    _startLoading();
    try {
      await ApiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  void _startLoading() {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
  }

  void _stopLoading() {
    if (!_isLoading) return;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}