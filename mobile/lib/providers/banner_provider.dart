import 'package:flutter/foundation.dart';
import '../models/banner.dart';
import '../services/api_service.dart';

class BannerProvider with ChangeNotifier {
  List<Banner> _banners = [];
  bool _isLoading = false;
  String? _error;

  List<Banner> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadBanners() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await ApiService.getBanners();
      
      if (response['success']) {
        final bannersData = response['data']['banners'] as List;
        _banners = bannersData.map((banner) => Banner.fromJson(banner)).toList();
      } else {
        _setError(response['message'] ?? 'Error al cargar banners');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}
