import 'package:flutter/material.dart';
import 'package:lanet_mobile/models/fidel_model.dart';
import 'package:lanet_mobile/services/dataset_service.dart';

class FidelProvider extends ChangeNotifier {
  final DatasetService _datasetService;

  FidelProvider(this._datasetService);

  List<FidelModel> _all = [];

  List<FidelModel> get leadingFamilies =>
      _all.where((f) => f.order == 1).toList()
        ..sort((a, b) => a.familyOrder.compareTo(b.familyOrder));

  List<FidelModel> family(String family) =>
      _all.where((f) => f.family == family).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  Future<void> load() async {
    _all = await _datasetService.loadFidel();
    notifyListeners();
  }
}
