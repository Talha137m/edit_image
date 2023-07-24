import 'dart:async';
import 'dart:io';
import 'package:edit_the_image/capture_frames.dart/services/setting.dart';
import 'package:edit_the_image/capture_frames.dart/services/task_identifier.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../formats.dart/abstract.dart';
import 'exception.dart';
import 'notifier.dart';

class DetachedRenderSession<T extends RenderFormat, K extends RenderSettings> {
  final String sessionId;

  final String temporaryDirectory;

  final String inputDirectory;

  final String outputDirectory;

  final String processDirectory;

  final K settings;

  final T format;

  final LogLevel logLevel;

  final SchedulerBinding binding;

  DetachedRenderSession({
    required this.logLevel,
    required this.binding,
    required this.outputDirectory,
    required this.inputDirectory,
    required this.sessionId,
    required this.temporaryDirectory,
    required this.processDirectory,
    required this.settings,
    required this.format,
  });

  static Future<DetachedRenderSession<T, K>>
      create<T extends RenderFormat, K extends RenderSettings>(
          T format, K settings, LogLevel logLevel) async {
    final tempDir = await getTemporaryDirectory();
    final sessionId = const Uuid().v4();
    return DetachedRenderSession<T, K>(
      logLevel: logLevel,
      binding: SchedulerBinding.instance,
      outputDirectory: "${tempDir.path}/render/$sessionId/output",
      inputDirectory: "${tempDir.path}/render/$sessionId/input",
      processDirectory: "${tempDir.path}/render/$sessionId/process",
      sessionId: sessionId,
      temporaryDirectory: tempDir.path,
      settings: settings,
      format: format,
    );
  }

  File _createFile(String path) {
    final outputFile = File(path);
    if (!outputFile.existsSync()) outputFile.createSync(recursive: true);
    return outputFile;
  }

  File createInputFile(String subPath) =>
      _createFile("$inputDirectory/$subPath");

  File createOutputFile(String subPath) =>
      _createFile("$outputDirectory/$subPath");

  File createProcessFile(String subPath) =>
      _createFile("$processDirectory/$subPath");

  double processingShare(RenderState state) {
    switch (state) {
      case RenderState.capturing:
        return 0.7 * (1 - format.processShare);
      case RenderState.handleCaptures:
        return 0.3 * (1 - format.processShare);
      case RenderState.processing:
        return format.processShare;
      case RenderState.finishing:
        return 0;
    }
  }
}

class RenderSession<T extends RenderFormat, K extends RenderSettings>
    extends DetachedRenderSession<T, K> {
  final TaskIdentifier task;

  final StreamController<RenderNotifier> _notifier;

  final DateTime startTime;

  final VoidCallback onDispose;

  RenderSession({
    required super.logLevel,
    required super.settings,
    required super.inputDirectory,
    required super.outputDirectory,
    required super.processDirectory,
    required super.sessionId,
    required super.temporaryDirectory,
    required super.format,
    required super.binding,
    required this.task,
    required this.onDispose,
    required StreamController<RenderNotifier> notifier,
    DateTime? startTime,
  })  : _notifier = notifier,
        startTime = startTime ?? DateTime.now();

  RenderState? _currentState;

  RenderSession.fromDetached({
    required DetachedRenderSession<T, K> detachedSession,
    required StreamController<RenderNotifier> notifier,
    required this.task,
    required this.onDispose,
    DateTime? startTime,
  })  : _notifier = notifier,
        startTime = DateTime.now(),
        super(
          logLevel: detachedSession.logLevel,
          binding: detachedSession.binding,
          format: detachedSession.format,
          settings: detachedSession.settings,
          processDirectory: detachedSession.processDirectory,
          inputDirectory: detachedSession.inputDirectory,
          outputDirectory: detachedSession.outputDirectory,
          sessionId: detachedSession.sessionId,
          temporaryDirectory: detachedSession.temporaryDirectory,
        );

  RenderSession<T, RealRenderSettings> upgrade(
      Duration capturingDuration, int frameAmount) {
    return RenderSession<T, RealRenderSettings>(
      settings: RealRenderSettings(
        pixelRatio: settings.pixelRatio,
        processTimeout: settings.processTimeout,
        capturingDuration: capturingDuration,
        frameAmount: frameAmount,
      ),
      onDispose: onDispose,
      startTime: startTime,
      logLevel: logLevel,
      inputDirectory: inputDirectory,
      outputDirectory: outputDirectory,
      processDirectory: processDirectory,
      sessionId: sessionId,
      temporaryDirectory: temporaryDirectory,
      format: format,
      binding: binding,
      task: task,
      notifier: _notifier,
    );
  }

  Duration get currentTimeStamp {
    return Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch -
          startTime.millisecondsSinceEpoch,
    );
  }

  void recordActivity(RenderState state, double? stateProgression,
      {String? message, String? details}) {
    if (logLevel == LogLevel.none || _notifier.isClosed) return;
    if (_currentState != state) _currentState = state;
    _notifier.add(
      RenderActivity(
        session: this,
        timestamp: currentTimeStamp,
        state: state,
        currentStateProgression: stateProgression ?? 0.5,
        message: message,
        details: details,
      ),
    );
  }

  void recordLog(String message) {
    if (logLevel != LogLevel.debug || _notifier.isClosed) return;
    _notifier.add(
      RenderLog(
        timestamp: currentTimeStamp,
        message: message,
      ),
    );
  }

  void recordError(RenderException exception) {
    if (_notifier.isClosed) return;
    _notifier.add(
      RenderError(
        timestamp: currentTimeStamp,
        fatal: exception.fatal,
        exception: exception,
      ),
    );
    if (exception.fatal) {
      dispose();
    }
  }

  void recordResult(File output, {String? message, String? details}) {
    if (_notifier.isClosed) return;
    _notifier.add(
      RenderResult(
        session: this,
        format: format,
        timestamp: currentTimeStamp,
        usedSettings: settings as RealRenderSettings,
        output: output,
        message: message,
        details: details,
      ),
    );
    dispose();
  }

  Future<void> dispose() async {
    onDispose();
    if (Directory(inputDirectory).existsSync()) {
      Directory(inputDirectory).deleteSync(recursive: true);
    }
    if (Directory(processDirectory).existsSync()) {
      Directory(processDirectory).deleteSync(recursive: true);
    }
    await _notifier.close();
  }
}
