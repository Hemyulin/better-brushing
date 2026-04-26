import 'package:flutter/material.dart';

class PlaqueBubble extends StatelessWidget {
  const PlaqueBubble({
    super.key,
    required this.alignment,
    required this.size,
    required this.visible,
  });

  final Alignment alignment;
  final double size;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: visible ? 1 : 0,
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4C1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD166), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22C98400),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '•',
            style: TextStyle(
              fontSize: 24,
              color: Color(0xFFC98400),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
