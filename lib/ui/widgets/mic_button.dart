import 'package:flutter/material.dart';

/// Animated mic button that pulses when recording.
class MicButton extends StatefulWidget {
  final bool isListening;
  final double soundLevel; // 0.0 – 1.0
  final VoidCallback onTap;

  const MicButton({
    super.key,
    required this.isListening,
    required this.soundLevel,
    required this.onTap,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulse1;
  late Animation<double> _pulse2;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _pulse1 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulse2 = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(MicButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _pulseController.repeat();
    } else if (!widget.isListening && old.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic radius grows with sound level
    final extraRadius = widget.isListening ? widget.soundLevel * 24 : 0.0;
    final primaryColor = widget.isListening
        ? const Color(0xFFE53935)
        : const Color(0xFF6C63FF);

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _buttonScale,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController]),
          builder: (context, child) {
            return SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring 2
                  if (widget.isListening)
                    Opacity(
                      opacity: (1.0 - _pulseController.value).clamp(0, 1),
                      child: Transform.scale(
                        scale: _pulse2.value + extraRadius / 50,
                        child: _PulseRing(color: primaryColor, radius: 35),
                      ),
                    ),
                  // Inner pulse ring 1
                  if (widget.isListening)
                    Opacity(
                      opacity: (1.0 - _pulseController.value * 0.7).clamp(0, 1),
                      child: Transform.scale(
                        scale: _pulse1.value + extraRadius / 80,
                        child: _PulseRing(color: primaryColor, radius: 35),
                      ),
                    ),
                  // The button itself
                  child!,
                ],
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.isListening
                    ? [const Color(0xFFE53935), const Color(0xFFFF6B6B)]
                    : [const Color(0xFF6C63FF), const Color(0xFF9C5FF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.45),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final Color color;
  final double radius;

  const _PulseRing({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.6), width: 2),
      ),
    );
  }
}
