import 'dart:io';
import 'package:edit_the_image/capture_frames.dart/services/session.dart';
import 'package:edit_the_image/capture_frames.dart/services/setting.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/log.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import '../formats.dart/abstract.dart';
import 'exception.dart';
import 'notifier.dart';

abstract class RenderProcessor<T extends RenderFormat> {
  final RenderSession<T, RealRenderSettings> session;

  RenderProcessor(this.session);

  bool _processing = false;

  String get inputPath;

  Future<void> process() async {
    if (_processing) {
      throw const RenderException(
          "Cannot start new process, during an active one.");
    }
    _processing = true;
    try {
      final output = await _processTask(session.format.processShare);
      session.recordResult(output);
      _processing = false;
    } on RenderException catch (error) {
      session.recordError(error);
    }
  }

  Future<File> _processTask(double progressShare) async {
    final mainOutputFile =
        session.createOutputFile("output_main.${session.format.extension}");

    final operation = session.format.processor(
      inputPath: inputPath,
      outputPath: mainOutputFile.path,
      frameRate: session.settings.realFrameRate,
    );
    await _executeCommand(
      operation.arguments,
      progressShare: progressShare,
    );
    return mainOutputFile;
  }

  Future<void> _executeCommand(List<String> command,
      {required double progressShare}) async {
    final ffmpegSession = await FFmpegSession.create(
      command,
      (ffmpegSession) async {
        session.recordActivity(
          RenderState.processing,
          progressShare,
          message: "Completed ffmpeg operation",
          details: "[async notification] Ffmpeg session completed: "
              "${ffmpegSession.getSessionId()}, time needed: "
              "${await ffmpegSession.getDuration()}, execution: "
              "${ffmpegSession.getCommand()}, logs: "
              "${await ffmpegSession.getLogsAsString()}, return code: "
              "${await ffmpegSession.getReturnCode()}, stack trace: "
              "${await ffmpegSession.getFailStackTrace()}",
        );
      },
      (Log log) {
        final message = log.getMessage();
        if (message.toLowerCase().contains("error")) {
          session.recordError(RenderException(
            "[Ffmpeg execution error] $message",
            fatal: true,
          ));
        } else {
          session.recordLog(message);
        }
      },
      (Statistics statistics) {
        final progression = ((statistics.getTime() * 100) ~/
                    session.settings.capturingDuration.inMilliseconds)
                .clamp(0, 100) /
            100;
        session.recordActivity(
          RenderState.processing,
          progression.toDouble(),
          message: "Converting captures",
        );
      },
    );
    await FFmpegKitConfig.ffmpegExecute(ffmpegSession).timeout(
      session.settings.processTimeout,
      onTimeout: () {
        session.recordError(
          const RenderException(
            "Processing session timeout",
            fatal: true,
          ),
        );
        ffmpegSession.cancel();
      },
    );
  }
}

class ImageProcessor extends RenderProcessor<ImageFormat> {
  ImageProcessor(super.session);

  @override
  String get inputPath => "${session.inputDirectory}/frame0.png";
}

class MotionProcessor extends RenderProcessor<MotionFormat> {
  MotionProcessor(super.session);

  @override
  String get inputPath => "${session.inputDirectory}/frame%d.png";
}
