import 'dart:convert';
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

  Future<void> loadNextPage() async {
    // Prevent duplicate calls or calls after last page
    if (state.isLoading || state.currentPage >= state.lastPage) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final nextPage = state.currentPage + 1;
      final client = ref.read(apiClientProvider);

      final response = await client.get('generations?page=$nextPage');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pageData = GenerationResponse.fromJson(data);

        state = state.copyWith(
          // Append new data to existing list
          generations: [...state.generations, ...pageData.data],
          currentPage: pageData.currentPage,
          lastPage: pageData.lastPage,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Failed to load history",
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
