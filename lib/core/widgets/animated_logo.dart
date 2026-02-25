import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    super.key,
    this.fontSize = 32,
    this.color,
  });

  final double fontSize;
  final Color? color;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  static const _words = ['Sweet', 'Sour', 'Salty', 'Bitter', 'Umami'];
  static const _slideDuration = Duration(milliseconds: 450);
  static const _pauseDuration = Duration(milliseconds: 1200);

  late AnimationController _controller;
  late Animation<double> _animation;
  int _index = 0;
  Timer? _pauseTimer;

  int get _nextIndex => (_index + 1) % _words.length;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _slideDuration);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pauseTimer = Timer(_pauseDuration, () {
          if (!mounted) return;
          setState(() => _index = _nextIndex);
          _controller.reset();
          _controller.forward();
        });
      }
    });

    _pauseTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  TextStyle _styleFor(String word, Color color) {
    if (word == 'Salty') {
      return GoogleFonts.raleway(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );
    }
    return GoogleFonts.pacifico(
      fontSize: widget.fontSize * 0.78,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    // Fixed slot dimensions — wide enough for the longest word, tall for one line
    final slotWidth = widget.fontSize * 3.8;
    final slotHeight = widget.fontSize * 1.35;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Fixed-size clipped slot for the cycling word
        SizedBox(
          width: slotWidth,
          height: slotHeight,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final offset = _animation.value * slotHeight;
                return Stack(
                  children: [
                    // Current word — slides up from center to above
                    Positioned(
                      right: 0,
                      bottom: offset,
                      child: SizedBox(
                        height: slotHeight,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _words[_index],
                            style: _styleFor(_words[_index], color),
                          ),
                        ),
                      ),
                    ),
                    // Next word — slides up from below into center
                    Positioned(
                      right: 0,
                      bottom: offset - slotHeight,
                      child: SizedBox(
                        height: slotHeight,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _words[_nextIndex],
                            style: _styleFor(_words[_nextIndex], color),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Static "Bytes"
        SizedBox(
          height: slotHeight,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'Bytes',
              style: GoogleFonts.raleway(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
