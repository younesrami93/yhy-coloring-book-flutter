import 'dart:convert';
import 'package:app/core/ApiException.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/generation_model.dart';
import 'styles_provider.dart'; // To access apiClientProvider

// The State class to hold our list and metadata
class GenerationsState {
  final List<Generation> generations;
  final bool isLoading;
  final int currentPage;
  final int lastPage;
  final String? error;

  GenerationsState({
    this.generations = const [],
    this.isLoading = false,
    this.currentPage = 0, // 0 means nothing loaded yet
    this.lastPage = 1,
    this.error,
  });

  GenerationsState copyWith({
    List<Generation>? generations,
    bool? isLoading,
    int? currentPage,
    int? lastPage,
    String? error,
  }) {
    return GenerationsState(
      generations: generations ?? this.generations,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      error: error,
    );
  }
}

class GenerationsNotifier extends StateNotifier<GenerationsState> {
  final Ref ref;

  GenerationsNotifier(this.ref) : super(GenerationsState()) {
    loadNextPage(); // Load first page on init
  }

  Future<Generation?> fetchGeneration(int id) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('generations/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming your API returns { "data": { ... } } or just { ... }
        // Adjust 'data' access based on your specific API wrapper
        final generationData = data['data'] ?? data;
        final newGeneration = Generation.fromJson(generationData);

        // Optional: Update the list in state if it exists there
        _updateLocalGeneration(newGeneration);

        return newGeneration;
      }
    } catch (e) {
      print("Error fetching generation $id: $e");
    }
    return null;
  }

  void _updateLocalGeneration(Generation newGen) {
    final index = state.generations.indexWhere((g) => g.id == newGen.id);
    if (index != -1) {
      // Replace the old one with the new one
      final updatedList = List<Generation>.from(state.generations);
      updatedList[index] = newGen;
      state = state.copyWith(generations: updatedList);
    } else {
      // Prepend it to the list (since it's new/recent)
      state = state.copyWith(generations: [newGen, ...state.generations]);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.currentPage >= state.lastPage) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final client = ref.read(apiClientProvider);

      // The client will now THROW an exception if status is 400+
      final response = await client.get('generations?page=$nextPage');

      // If we get here, it means success (200 OK)
      final data = jsonDecode(response.body);
      final pageData = GenerationResponse.fromJson(data);

      state = state.copyWith(
        generations: [...state.generations, ...pageData.data],
        currentPage: pageData.currentPage,
        lastPage: pageData.lastPage,
        isLoading: false,
      );
    } on ApiException catch (e) {
      // Catch our custom error
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      // Catch generic errors (no internet, parsing fail)
      state = state.copyWith(
        isLoading: false,
        error: "Connection failed. Please try again.",
      );
    }
  }

  Future<void> refresh() async {
    state = GenerationsState(); // Reset state
    await loadNextPage();
  }
}

final generationsProvider =
    StateNotifierProvider<GenerationsNotifier, GenerationsState>((ref) {
      return GenerationsNotifier(ref);
    });
