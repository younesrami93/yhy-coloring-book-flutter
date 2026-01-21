import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/generations_provider.dart';
import '../../widgets/before_after_card.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationsProvider);

    // --- 1. Empty State / Initial Load ---
    if (state.generations.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.generations.isEmpty && state.error != null) {
      return _buildErrorState(ref, state.error!);
    }

    if (state.generations.isEmpty && !state.isLoading) {
      return const Center(child: Text("No magic yet. Create one!"));
    }

    // --- 2. Grid Content ---
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Infinite Scroll Logic
        if (!state.isLoading &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          ref.read(generationsProvider.notifier).loadNextPage();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(generationsProvider.notifier).refresh();
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,          // 2 items per line
            childAspectRatio: 0.75,     // Taller cards (Portrait)
            crossAxisSpacing: 16,       // Horizontal space
            mainAxisSpacing: 16,        // Vertical space
          ),
          // Add +1 for the loading spinner at the bottom if needed
          itemCount: state.generations.length + (state.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading Spinner Tile
            if (index == state.generations.length) {
              return const Center(
                  child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
              );
            }

            final generation = state.generations[index];
            return BeforeAfterCard(generation: generation);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Oops! $error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: () => ref.read(generationsProvider.notifier).refresh(),
            child: const Text("Try Again"),
          )
        ],
      ),
    );
  }
}