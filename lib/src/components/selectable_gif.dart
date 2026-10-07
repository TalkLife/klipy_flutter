import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:klipy_flutter/klipy_flutter.dart';

class KlipySelectableGif extends StatelessWidget {
  final Color backgroundColor;
  final Function(KlipyResultObject)? onTap;
  final KlipyResultObject result;

  /// Position in the results grid. When set, the result is exposed to
  /// accessibility services as a button with the identifier
  /// `klipyResult_<index>`, so it can be found by screen readers and UI tests.
  final int? index;

  const KlipySelectableGif({
    required this.result,
    this.backgroundColor = Colors.transparent,
    this.onTap,
    this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mediaObject = result.media.tinyGifTransparent ?? result.media.tinyGif;

    // If no media object is found, early out
    if (mediaObject == null) return const SizedBox.shrink();

    // Each result was a bare image with no semantics: a screen reader announced
    // nothing and a UI test could only tap it by screen position. A container
    // node with a stable id per position (and the GIF's title as its label)
    // fixes both without changing how it looks.
    return Semantics(
      identifier: index == null ? null : 'klipyResult_$index',
      label: result.title,
      button: true,
      container: true,
      child: GestureDetector(
      onTap: () => onTap?.call(result),
      child: ExtendedImage.network(
        mediaObject.url,
        cache: true,
        gaplessPlayback: true,
        fit: BoxFit.fill,
        headers: const {'accept': 'image/*'},
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return AspectRatio(
                aspectRatio: mediaObject.dimensions.aspectRatio,
                child: Container(color: backgroundColor),
              );
            case LoadState.completed:
              return AspectRatio(
                aspectRatio: mediaObject.dimensions.aspectRatio,
                child: ExtendedRawImage(
                  fit: BoxFit.fill,
                  image: state.extendedImageInfo?.image,
                ),
              );
            case LoadState.failed:
              return AspectRatio(
                aspectRatio: mediaObject.dimensions.aspectRatio,
                child: Container(color: backgroundColor),
              );
          }
        },
      ),
    ),
    );
  }
}
