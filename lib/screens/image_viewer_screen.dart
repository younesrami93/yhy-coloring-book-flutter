import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/generation_model.dart';

class ImageViewerScreen extends StatefulWidget {
  final Generation generation;

  const ImageViewerScreen({super.key, required this.generation});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  bool _isProcessing = false; // To show loading spinner during actions
  late AnimationController _controlsController;

  @override
  void initState() {
    super.initState();
    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

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

  /// ----------------------------------------------------------------
  /// ACTION LOGIC
  /// ----------------------------------------------------------------

  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint("Download Error: $e");
    }
    return null;
  }

  Future<void> _handleShare(String imageUrl) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _downloadImageBytes(imageUrl);
      if (bytes == null) throw Exception("Failed to download image");

      final temp = await getTemporaryDirectory();
      final path = '${temp.path}/coloring_page_${widget.generation.id}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        // Share the image file specifically (better for Instagram/WhatsApp)
        await Share.shareXFiles(
          [XFile(path)],
          text: 'Check out my coloring page! 🎨',
        );
      }
    } catch (e) {
      _showError("Failed to share image");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePdf(String imageUrl, {bool isPrinting = false}) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await _downloadImageBytes(imageUrl);
      if (bytes == null) throw Exception("Failed to download image");

      final image = pw.MemoryImage(bytes);

      // Create PDF Document
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      if (isPrinting) {
        // Open Print Dialog
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Coloring Page #${widget.generation.id}',
        );
      } else {
        // Share/Save the PDF file
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'coloring_page_${widget.generation.id}.pdf',
        );
      }
    } catch (e) {
      _showError("Failed to process PDF");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// ----------------------------------------------------------------
  /// UI BUILD
  /// ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final g = widget.generation;
    final bool hasResult = g.processedImageUrl != null;
    final String? highResUrl = hasResult ? g.processedImageUrl : g.originalImageUrl;
    final String? thumbUrl = hasResult
        ? (g.processed_thumb_md ?? g.processedImageUrl)
        : (g.original_thumb_md ?? g.originalImageUrl);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // A. ZOOMABLE IMAGE AREA
          GestureDetector(
            onTap: _toggleControls,
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbUrl != null)
                    Image.network(thumbUrl, fit: BoxFit.contain),
                  if (highResUrl != null)
                    Image.network(
                      highResUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const Center(); // Clean loading, we have thumb
                      },
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54)),
                    ),
                ],
              ),
            ),
          ),

          // B. TOP NAV BAR
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
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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

          // C. BOTTOM ACTION BAR
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _controlsController,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                child: _isProcessing
                // Show Loader inside the pill when working
                    ? const SizedBox(
                  height: 50,
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                )
                // Show Buttons
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      FontAwesomeIcons.shareNodes,
                      "Share",
                          () => highResUrl != null ? _handleShare(highResUrl) : null,
                    ),
                    Container(width: 1, height: 24, color: Colors.white12),
                    _buildActionButton(
                      FontAwesomeIcons.filePdf,
                      "PDF",
                          () => highResUrl != null ? _handlePdf(highResUrl, isPrinting: false) : null,
                    ),
                    Container(width: 1, height: 24, color: Colors.white12),
                    _buildActionButton(
                      FontAwesomeIcons.print,
                      "Print",
                          () => highResUrl != null ? _handlePdf(highResUrl, isPrinting: true) : null,
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap != null
          ? () {
        HapticFeedback.lightImpact();
        onTap();
      }
          : null,
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