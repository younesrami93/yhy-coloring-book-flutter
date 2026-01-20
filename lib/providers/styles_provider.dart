import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/style_model.dart';

// The centralized client provider
final apiClientProvider = Provider((ref) => ApiClient());

// The data provider
final stylesProvider = FutureProvider<List<StyleModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.fetchStyles();
});