import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingCard extends StatelessWidget {
  final Color primaryColor;

  const LoadingCard({
    super.key,
    required this.primaryColor,
  });

  Color _getComplementaryColor() {
    final HSLColor hsl = HSLColor.fromColor(primaryColor);

    // Create harmonious colors using 60° and 120° shifts
    final color1 = HSLColor.fromAHSL(
      hsl.alpha,
      (hsl.hue + 60) % 360,
      hsl.saturation,
      math.max(0.2, hsl.lightness * 0.7), // Ensure darker than primary
    ).toColor();

    final color2 = HSLColor.fromAHSL(
      hsl.alpha,
      (hsl.hue + 120) % 360,
      math.min(1.0, hsl.saturation * 1.2), // Slightly more saturated
      math.max(0.15, hsl.lightness * 0.6), // Even darker
    ).toColor();

    // Choose the color that provides better contrast
    final primaryLuminance = primaryColor.computeLuminance();
    final color1Contrast = (primaryLuminance - color1.computeLuminance()).abs();
    final color2Contrast = (primaryLuminance - color2.computeLuminance()).abs();

    return color1Contrast > color2Contrast ? color1 : color2;
  }

  @override
  Widget build(BuildContext context) {
    final complementaryColor = _getComplementaryColor();

    // List of witty quotes
    final List<String> wittyQuotes = [
      "Compiling creativity... Hold tight!",
      "Great code takes time... and so does this progress bar.",
      "Optimizing bugs... or just renaming them as features?",
      "Searching for the semicolon you forgot...",
      "Magic takes a moment... coding takes a bit longer.",
      "Loading... because copy-pasting takes time!"
    ];

    // Pick a random quote
    final String randomQuote = wittyQuotes[math.Random().nextInt(wittyQuotes.length)];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 550,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred Background
                    Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated coding person icon
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 2 * math.pi),
                            duration: const Duration(seconds: 2),
                            builder: (context, double value, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Person Icon
                                  Icon(
                                    Icons.person,
                                    size: 110,
                                    color: primaryColor,
                                  ),
                                  // Animated Laptop
                                  Transform.translate(
                                    offset: Offset(
                                        32 * math.cos(value),
                                        32 * math.sin(value)
                                    ),
                                    child: Icon(
                                      Icons.laptop_mac,
                                      size: 70,
                                      color: complementaryColor,
                                    ),
                                  ),
                                  // Animated Code Symbol
                                  Transform.translate(
                                    offset: Offset(
                                        -32 * math.sin(value),
                                        -32 * math.cos(value)
                                    ),
                                    child: Icon(
                                      Icons.code,
                                      size: 55,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 35),
                          // Fun loading text with complementary gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, complementaryColor],
                            ).createShader(bounds),
                            child: Text(
                              randomQuote,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Progress indicator with percentage
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(seconds: 2),
                            builder: (context, double value, child) {
                              return Column(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [primaryColor, complementaryColor],
                                    ).createShader(bounds),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: primaryColor.withOpacity(0.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Colors.white, // Use white as base color for shader
                                      ),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Percentage text with gradient too
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [primaryColor, complementaryColor],
                                    ).createShader(bounds),
                                    child: Text(
                                      "${(value * 100).toInt()}%",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Use white as base color for shader
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Decorative Elements
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Transform.rotate(
                        angle: math.pi / 6,
                        child: Icon(
                          Icons.terminal_rounded,
                          size: 120,
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: Icon(
                          Icons.keyboard_rounded,
                          size: 120,
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
