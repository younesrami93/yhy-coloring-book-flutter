import 'package:flutter/material.dart';
import '../models/generation_model.dart';
import '../theme.dart';
import '../screens/image_viewer_screen.dart';

class BeforeAfterCard extends StatefulWidget {
  final Generation generation;

  const BeforeAfterCard({super.key, required this.generation});

  @override
  State<BeforeAfterCard> createState() => _BeforeAfterCardState();
}

class _BeforeAfterCardState extends State<BeforeAfterCard> {
  double _splitPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = widget.generation;
    final bool isCompleted = g.status == 'completed';

    // 1. SAFE URL RESOLUTION
    // We try to use the fields from your model.
    // If your model uses 'originalImageUrl', these lines work.
    // If it uses 'original_thumb_md', you might need to swap them.
    // I will use the standard accessors assuming your Generation model is consistent.
    final baseImage = g.originalImageUrl;
    final resultImage = g.processedImageUrl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- A. INTERACTIVE IMAGE AREA ---
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(generation: g),
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Base Image
                _buildImage(baseImage),

                // 2. Result Image (Clipped)
                if (isCompleted && resultImage != null)
                  ClipRect(
                    clipper: _SplitClipper(_splitPosition),
                    child: Hero(
                      tag: 'gen_img_${g.id}', // Hero animation tag
                      child: _buildImage(resultImage),
                    ),
                  ),
              ],
            ),
          ),

          // --- B. STATUS OVERLAY ---
          if (!isCompleted)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (g.status == 'failed')
                    const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 32)
                  else
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      g.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // --- C. SLIDER HANDLE ---
          if (isCompleted)
            LayoutBuilder(
              builder: (context, constraints) {
                // We handle the drag separately so it doesn't conflict with the Tap
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _splitPosition = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                    });
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        left: constraints.maxWidth * _splitPosition,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 2, color: Colors.white),
                      ),
                      Positioned(
                        left: (constraints.maxWidth * _splitPosition) - 16,
                        top: constraints.maxHeight / 2 - 16,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.compare_arrows, size: 18, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // --- D. BOTTOM GRADIENT & TEXT ---
          // FIX: Positioned must be directly inside Stack.
          // IgnorePointer goes inside Positioned.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: true, // Let clicks pass through to the image
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g.styleName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(g.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Uses Standard Image.network (No CachedNetworkImage dependency needed)
  Widget _buildImage(String? url) {
    if (url == null) {
      return Container(color: const Color(0xFFE0E0E0));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(color: const Color(0xFFF5F5F5));
      },
      errorBuilder: (ctx, err, stack) => const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[date.month - 1]} ${date.day}";
    } catch (_) {
      return "";
    }
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double splitPercent;
  _SplitClipper(this.splitPercent);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(size.width * splitPercent, 0, size.width, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}