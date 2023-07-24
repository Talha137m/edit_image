import 'package:edit_the_image/capture_frames.dart/formats.dart/services.dart';


import 'image.dart';
import 'motion.dart';

abstract class RenderFormat {
  final FormatHandling handling;

  final double processShare;

  final Interpolation interpolation;

  final RenderScale? scale;

  const RenderFormat({
    required this.scale,
    required this.handling,
    required this.processShare,
    required this.interpolation,
  });

  String get extension;

  FFmpegRenderOperation processor({
    required String inputPath,
    required String outputPath,
    required double frameRate,
  });

  String? get scalingFilter =>
      scale != null ? "scale=w=${scale!.w}:-1:${interpolation.name}" : null;

  bool get isMotion => this is MotionFormat;

  bool get isImage => this is ImageFormat;

  MotionFormat? get asMotion => isMotion ? this as MotionFormat : null;

  ImageFormat? get asImage => isImage ? this as ImageFormat : null;
}

abstract class MotionFormat extends RenderFormat {
  final List<RenderAudio>? audio;

  const MotionFormat({
    required this.audio,
    required super.scale,
    required super.interpolation,
    required super.handling,
    required super.processShare,
  });

  MotionFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  });

  @override
  FFmpegRenderOperation processor(
      {required String inputPath,
      required String outputPath,
      required double frameRate}) {
    final audioInput = audio != null && audio!.isNotEmpty
        ? audio!.map((e) => "-i??${e.path}").join('??')
        : null;
    final mergeAudiosList = audio != null && audio!.isNotEmpty
        ? ";${List.generate(audio!.length, (index) => "[${index + 1}:a]"
                "atrim=start=${audio![index].startTime}"
                ":${"end=${audio![index].endTime}"}[a${index + 1}];").join()}"
            "${List.generate(audio!.length, (index) => "[a${index + 1}]").join()}"
            "amix=inputs=${audio!.length}[a]"
        : "";
    final overwriteAudioExecution = audio != null && audio!.isNotEmpty
        ? "-map??[v]??-map??[a]??-c:v??libx264??-c:a??"
            "aac??-shortest??-pix_fmt??yuv420p??-vsync??2"
        : "-map??[v]??-pix_fmt??yuv420p";
    return FFmpegRenderOperation([
      "-i",
      inputPath,
      audioInput,
      "-filter_complex",
      "[0:v]${scalingFilter != null ? "$scalingFilter," : ""}"
          "setpts=N/($frameRate*TB)[v]$mergeAudiosList",
      overwriteAudioExecution,
      "-y",
      outputPath,
    ]);
  }

  static MovFormat get mov => const MovFormat();

  static Mp4Format get mp4 =>const Mp4Format();

  static GifFormat get gif => const GifFormat();
}

abstract class ImageFormat extends RenderFormat {
  const ImageFormat({
    required super.scale,
    required super.interpolation,
    required super.handling,
    required super.processShare,
  });

  ImageFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  });

  @override
  FFmpegRenderOperation processor(
      {required String inputPath,
      required String outputPath,
      required double frameRate}) {
    return FFmpegRenderOperation([
      "-y",
      "-i",
      inputPath,
      scalingFilter != null ? "-vf??$scalingFilter" : null,
      "-vframes",
      "1",
      outputPath,
    ]);
  }

  static ImageFormat get png => const PngFormat();

  static ImageFormat get jpg => const JpgFormat();

  static ImageFormat get bmp => const BmpFormat();

  static ImageFormat get tiff => const TiffFormat();
}
