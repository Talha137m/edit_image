

import 'package:edit_the_image/capture_frames.dart/formats.dart/services.dart';

import 'abstract.dart';

class MovFormat extends MotionFormat {
  const MovFormat({
    super.audio,
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.video,
          processShare: 0.2,
        );

  @override
  MovFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return MovFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "mov";
}

class GifFormat extends MotionFormat {
  final bool transparency;

  final bool loop;

  const GifFormat({
    this.loop = true,
    this.transparency = false,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.2,
          scale: null,
          audio: null,
          interpolation: Interpolation.bicubic,
        );

  @override
  GifFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
    bool? transparency,
    bool? loop,
  }) {
    return GifFormat(
      loop: loop ?? this.loop,
      transparency: transparency ?? this.transparency,
    );
  }

  @override
  String get extension => "gif";

  @override
  FFmpegRenderOperation processor({
    required String inputPath,
    required String outputPath,
    required double frameRate,
  }) {
    return FFmpegRenderOperation([
      "-y",
      "-i",
      inputPath,
      transparency
          ? "-filter_complex??[0:v] setpts=N/($frameRate*TB),"
              "palettegen=stats_mode=single:max_colors=256 [palette];"
              " [0:v][palette] paletteuse"
          : "-filter:v??setpts=N/($frameRate*TB)",
      loop ? "-loop??0" : "-loop??-1",
      outputPath,
    ]);
  }
}

class Mp4Format extends MotionFormat {
  const Mp4Format({
    super.audio,
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.video,
          processShare: 0.2,
        );

  @override
  Mp4Format copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return Mp4Format(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "mp4";
}
