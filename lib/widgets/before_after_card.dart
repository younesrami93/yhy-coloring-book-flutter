import 'package:flutter/material.dart';
import '../models/generation_model.dart';
import '../theme.dart';

class BeforeAfterCard extends StatefulWidget {
  final Generation generation;

  const BeforeAfterCard({super.key, required this.generation});

  @override
  State<BeforeAfterCard> createState() => _BeforeAfterCardState();
}

class _BeforeAfterCardState extends State<BeforeAfterCard> {
  // Start split at 50%
  double _splitPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = widget.generation;
    final bool isCompleted = g.status == 'completed';

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
      // Clip everything to the rounded corners
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND LAYERS (The Images)
          _buildBaseImage(g.original_thumb_md),

          if (isCompleted && g.processed_thumb_md != null)
            ClipRect(
              clipper: _SplitClipper(_splitPosition),
              child: _buildBaseImage(g.processedImageUrl),
            ),

          // 2. STATUS OVERLAY (If not ready)
          if (!isCompleted)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (g.status == 'failed')
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorRed,
                      size: 32,
                    )
                  else
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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

          // 3. INTERACTIVE SLIDER (Only if completed)
          if (isCompleted)
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      final newSplit =
                          details.localPosition.dx / constraints.maxWidth;
                      _splitPosition = newSplit.clamp(0.0, 1.0);
                    });
                  },
                  child: Stack(
                    children: [
                      // The Vertical Line
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: constraints.maxWidth * _splitPosition,
                        child: Container(width: 2, color: Colors.white),
                      ),
                      // The Handle Icon
                      Positioned(
                        top: constraints.maxHeight / 2 - 16,
                        left: (constraints.maxWidth * _splitPosition) - 16,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 4. BOTTOM INFO GRADIENT
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
        ],
      ),
    );
  }

  Widget _buildBaseImage(String? url) {
    if (url == null) {
      return Container(color: const Color(0xFFE0E0E0));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: const Color(0xFFF5F5F5));
      },
      errorBuilder: (ctx, err, stack) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      // Simple format: Jan 19
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
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
  Rect getClip(Size size) {
    // Reveal from right to left (Processed image is on top layer)
    // If splitPercent is 0.5, we clip the left half of the top image
    // effectively showing the 'Processed' image on the RIGHT side.
    return Rect.fromLTRB(size.width * splitPercent, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
