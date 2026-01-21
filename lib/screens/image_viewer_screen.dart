import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/generation_model.dart';
// import '../theme.dart'; // Uncomment if you need AppTheme colors

class ImageViewerScreen extends StatefulWidget {
  final Generation generation;

  const ImageViewerScreen({super.key, required this.generation});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  late AnimationController _controlsController;

  @override
  void initState() {
    super.initState();
    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
        _controlsController.reverse();
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsController.forward();
    } else {
      _controlsController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.generation;
    final bool hasResult = g.processedImageUrl != null;

    // 1. Resolve URLs
    // High Res: The final result (or original if no result)
    final String? highResUrl = hasResult ? g.processedImageUrl : g.originalImageUrl;

    // Thumbnail: The smaller version (or fallback to High Res if missing)
    // NOTE: We assume your model has these fields based on your 'before_after_card.dart'
    // If 'processed_thumb_md' is not in your model, remove that part or ensure model is updated.
    final String? thumbUrl = hasResult
        ? (g.processed_thumb_md ?? g.processedImageUrl)
        : (g.original_thumb_md ?? g.originalImageUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- A. ZOOMABLE IMAGE AREA ---
          GestureDetector(
            onTap: _toggleControls,
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.0 ,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // LAYER 1: Low-Res Thumbnail (Placeholder)
                  // This is displayed immediately at the back
                  if (thumbUrl != null)
                    Image.network(
                      thumbUrl,
                      fit: BoxFit.contain,
                    ),

                  // LAYER 2: High-Res Image (Loads on top)
                  if (highResUrl != null)
                    Image.network(
                      highResUrl,
                      fit: BoxFit.contain,

                      // Custom Loader: Shows while fetching chunks
                      loadingBuilder: (context, child, loadingProgress) {
                        // If fully loaded (progress is null), show the image
                        if (loadingProgress == null) return child;

                        // If loading, show the UI on top of Layer 1
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Loading high quality...",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },

                      // Smooth Fade-In when loaded
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },

                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16)),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image,
                                    color: Colors.white54, size: 32),
                                SizedBox(height: 8),
                                Text("Failed to load HD",
                                    style: TextStyle(color: Colors.white54)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // --- B. TOP NAV BAR ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _controlsController,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 52, 8, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- C. BOTTOM ACTION BAR ---
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _controlsController,
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF202020).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(FontAwesomeIcons.shareNodes, "Share"),
                    Container(width: 1, height: 24, color: Colors.white12),
                    _buildActionButton(FontAwesomeIcons.filePdf, "PDF"),
                    Container(width: 1, height: 24, color: Colors.white12),
                    _buildActionButton(FontAwesomeIcons.print, "Print"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label feature coming soon!")),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}