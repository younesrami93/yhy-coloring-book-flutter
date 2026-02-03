import 'package:app/api/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/style_model.dart';

// The centralized client provider
final apiClientProvider = Provider((ref) => ApiClient());

// The data provider
final stylesProvider = FutureProvider<List<StyleModel>>((ref) async {
  return ApiService().fetchStyles();
});
