import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class KlipyMediaWidget extends StatelessWidget {
  final Widget media;
  final double watermarkXOffset;
  final double watermarkYOffset;
  final double watermarkHeight;

  const KlipyMediaWidget({
    required this.media,
    this.watermarkHeight = 10,
    this.watermarkXOffset = 4,
    this.watermarkYOffset = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        media,
        Positioned(
          bottom: watermarkYOffset,
          left: watermarkXOffset,
          child: Image.asset(
            'assets/media_watermark.png',
            height: watermarkHeight,
            package: 'klipy_flutter',
            semanticLabel: 'KLIPY',
          ),
        ),
      ],
    );
  }
}
