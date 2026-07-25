import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoMarkerEditor extends StatelessWidget {
  const PhotoMarkerEditor({
    super.key,
    required this.photo,
    required this.markerX,
    required this.markerY,
    required this.onMarkerChanged,
  });

  final XFile photo;
  final double? markerX;
  final double? markerY;
  final void Function(double x, double y) onMarkerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.router_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tap the exact place where the Internet box should be mounted',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return AspectRatio(
              aspectRatio: 16 / 10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final x = (details.localPosition.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0)
                      .toDouble();
                  final height = constraints.maxWidth / (16 / 10);
                  final y = (details.localPosition.dy / height)
                      .clamp(0.0, 1.0)
                      .toDouble();
                  onMarkerChanged(x, y);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE8ECEA),
                          child: Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      if (markerX != null && markerY != null)
                        Positioned(
                          left: markerX! * constraints.maxWidth - 22,
                          top:
                              markerY! * (constraints.maxWidth / (16 / 10)) -
                              54,
                          child: const _MountMarker(),
                        ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              markerX == null
                                  ? 'No mounting point marked yet'
                                  : 'Mounting point marked • Tap to move it',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MountMarker extends StatelessWidget {
  const _MountMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF39A44),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.router_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        Container(width: 3, height: 10, color: Colors.white),
      ],
    );
  }
}
