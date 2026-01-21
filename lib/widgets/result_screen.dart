import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yhy_coloring_book_flutter/widgets/before_after_slider.dart';
import '../theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // DUMMY DATA FOR NOW
    String originalImage = "https://picsum.photos/id/237/800/800"; // Dog photo
    String resultImage = "https://picsum.photos/id/1/800/800?grayscale&blur=2"; // Simulation of sketch

    //const String originalImage = "https://broken-url-1";
    //const String resultImage = "https://broken-url-2";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Result"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. THE SLIDER
            BeforeAfterSlider(
              beforeImage: originalImage,
              afterImage: resultImage,
              height: 400,
            ),

            const SizedBox(height: 32),

            // 2. INSTRUCTIONS
            Text(
              "Comparison",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              "Drag the slider to compare original vs result",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // 3. ACTIONS ROW
            Row(
              children: [
                // Save / Download Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: Download logic
                    },
                    icon: const Icon(FontAwesomeIcons.download),
                    label: const Text("Save"),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Share Button
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Retry Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Try Another Style"),
            ),
          ],
        ),
      ),
    );
  }
}