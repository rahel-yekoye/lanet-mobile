import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fidel_model.dart';
import '../services/dataset_service.dart';

final fidelProvider = ChangeNotifierProvider<FidelProvider>((ref) {
  return FidelProvider(DatasetService());
});

class FidelProvider extends ChangeNotifier {
  final DatasetService _datasetService;
  List<FidelModel> _all = [];
  bool loading = true;
  String? error;

  FidelProvider(this._datasetService);

  List<FidelModel> get all => _all;
  
  List<FidelModel> get leadingFamilies =>
      _all.where((f) => f.order == 1).toList()
        ..sort((a, b) => a.familyOrder.compareTo(b.familyOrder));

  List<FidelModel> family(String family) =>
      _all.where((f) => f.family == family).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  Future<void> load() async {
    try {
      loading = true;
      error = null;
      notifyListeners();
      
      _all = await _datasetService.loadFidel();
    } catch (e) {
      error = 'Failed to load Fidel data: ${e.toString()}';
      debugPrint('Error loading Fidel data: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}