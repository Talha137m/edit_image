

import 'package:edit_the_image/capture_frames.dart/formats.dart/services.dart';

import 'abstract.dart';

class PngFormat extends ImageFormat {
  const PngFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  PngFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return PngFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "png";
}

class JpgFormat extends ImageFormat {
  const JpgFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  JpgFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return JpgFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "jpg";
}

class BmpFormat extends ImageFormat {
  const BmpFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  BmpFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return BmpFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  FFmpegRenderOperation processor(
      {required String inputPath,
      required String outputPath,
      required double frameRate}) {
    return FFmpegRenderOperation([
      "-y",
      "-i",
      inputPath,
      "-pix_fmt",
      "bgra",
      scalingFilter != null ? "-vf??$scalingFilter" : null,
      "-vframes",
      "1",
      outputPath,
    ]);
  }

  @override
  String get extension => "bmp";
}

class TiffFormat extends ImageFormat {
  const TiffFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  TiffFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return TiffFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "tiff";
}
