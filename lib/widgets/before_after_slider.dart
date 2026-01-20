import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  final String beforeImage;
  final String afterImage;
  final double height;

  const BeforeAfterSlider({
    super.key,
    required this.beforeImage, // We keep these for later
    required this.afterImage,
    this.height = 400,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _splitValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // FIXED SHADOW SYNTAX
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Explicit color
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              // 1. BOTTOM LAYER (The "Result")
              // Using a BLUE container to test
              Positioned.fill(
                child: Image.network(
                  widget.afterImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.blue), // Fallback to Blue
                ),
              ),

              // 2. TOP LAYER (The "Original")
              // Using a RED container to test
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _splitValue, // This controls the reveal
                  child: SizedBox(
                    width: width, // FORCE full width
                    height: height,
                    child: Image.network(
                      widget.beforeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.red), // Fallback to Red
                    ),
                  ),
                ),
              ),

              // 3. THE SLIDER LINE
              Positioned(
                left: (width * _splitValue) - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),

              // 4. THE HANDLE ICON
              Positioned(
                left: (width * _splitValue) - 16,
                top: (height / 2) - 16,
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
                      )
                    ],
                  ),
                  child: const Icon(Icons.compare_arrows, size: 20, color: Colors.black),
                ),
              ),

              // 5. TOUCH DETECTOR
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      _splitValue += details.delta.dx / width;
                      if (_splitValue < 0.0) _splitValue = 0.0;
                      if (_splitValue > 1.0) _splitValue = 1.0;
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}