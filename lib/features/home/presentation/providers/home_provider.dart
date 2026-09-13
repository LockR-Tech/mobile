import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/features/home/data/models/advertisement_model.dart';
import 'package:smart_laundry_locker/features/home/data/models/blog_model.dart';
import 'package:smart_laundry_locker/features/home/data/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository _repository;

  HomeProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AdvertisementModel> _advertisements = [];
  List<AdvertisementModel> get advertisements => _advertisements;

  List<BlogModel> _blogs = [];
  List<BlogModel> get blogs => _blogs;

  Future<void> loadHomeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.getActiveAdvertisements(),
        _repository.getRecentBlogs(),
      ]);

      _advertisements = results[0] as List<AdvertisementModel>;
      _blogs = results[1] as List<BlogModel>;
    } catch (e) {
      print("Error loading home data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
