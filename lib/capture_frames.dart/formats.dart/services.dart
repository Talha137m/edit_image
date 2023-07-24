import 'dart:io';

class FFmpegRenderOperation {
  final List<String> arguments;

  FFmpegRenderOperation(List<String?> arguments)
      : arguments = arguments
            .whereType<String>()
            .expand((element) => element.split("??"))
            .toList();
}

enum FormatHandling {
  image,

  video,

  unknown;

  bool get isVideo => this == FormatHandling.video;

  bool get isImage => this == FormatHandling.image;

  bool get isUnknown => this == FormatHandling.unknown;
}

class RenderScale {
  final int w;
  final int h;

  const RenderScale(this.w, this.h);

  static RenderScale get fullHD => const RenderScale(1920, 1080);

  static RenderScale get hd => const RenderScale(1280, 720);

  static RenderScale get fourK => const RenderScale(3840, 2160);

  static RenderScale get lowRes => const RenderScale(640, 360);

  static RenderScale get veryLowRes => const RenderScale(320, 180);

  static RenderScale get qhd => const RenderScale(2560, 1440);

  static RenderScale get svga => const RenderScale(800, 600);

  static RenderScale get xga => const RenderScale(1024, 768);

  static RenderScale get hdPlus => const RenderScale(1366, 768);

  static RenderScale get wqxga => const RenderScale(2560, 1600);
}

enum Interpolation {
  nearest,

  bilinear,

  bicubic,

  lanczos,

  spline,

  gauss,

  sinc,
}

class RenderAudio {
  final String path;

  final double startTime;

  final double endTime;

  RenderAudio.url(Uri url, {this.startTime = 0, this.endTime = 1000})
      : path = url.toString();

  RenderAudio.file(File file, {this.startTime = 0, this.endTime = 1000})
      : path = file.path;

  Duration? get duration =>
      Duration(milliseconds: (endTime / 1000 - startTime / 1000).toInt());
}
