abstract class RenderSettings {
  final double pixelRatio;

  final Duration processTimeout;

  const RenderSettings({
    this.pixelRatio = 1,
    this.processTimeout = const Duration(minutes: 3),
  });

  bool get isImage => this is ImageSettings;

  bool get isMotion => this is MotionSettings;

  MotionSettings? get asMotion => isMotion ? this as MotionSettings : null;

  ImageSettings? get asImage => isImage ? this as ImageSettings : null;
}

class ImageSettings extends RenderSettings {
  const ImageSettings({
    super.pixelRatio,
    super.processTimeout,
  });
}

class MotionSettings extends RenderSettings {
  final int frameRate;

  final int simultaneousCaptureHandlers;

  const MotionSettings({
    this.simultaneousCaptureHandlers = 10,
    this.frameRate = 20,
    super.pixelRatio,
    super.processTimeout,
  }) : assert(frameRate < 100, "Frame rate unrealistic high.");
}

class RealRenderSettings extends RenderSettings {
  final Duration capturingDuration;

  final int frameAmount;

  const RealRenderSettings({
    required super.pixelRatio,
    required super.processTimeout,
    required this.capturingDuration,
    required this.frameAmount,
  });

  double get realFrameRate =>
      frameAmount / (capturingDuration.inMilliseconds / 1000);
}
