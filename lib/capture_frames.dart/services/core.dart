import 'package:edit_the_image/capture_frames.dart/services/process.dart';
import 'package:edit_the_image/capture_frames.dart/services/session.dart';
import 'package:edit_the_image/capture_frames.dart/services/setting.dart';
import 'package:edit_the_image/capture_frames.dart/services/task_identifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rich_console/rich_console.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../formats.dart/abstract.dart';
import '../formats.dart/image.dart';
import '../formats.dart/motion.dart';
import 'capture.dart';
import 'exception.dart';
import 'notifier.dart';

class RenderController {
  KeyIdentifier? _globalTask;

  final UuidValue id;

  final LogLevel logLevel;

  final List<RenderSession> _activeSessions = [];

  RenderController({this.logLevel = LogLevel.debug})
      : id = UuidValue(const Uuid().v4());

  RenderSession<T, K> _createRenderSessionFrom<T extends RenderFormat,
          K extends RenderSettings>(
      DetachedRenderSession<T, K> detachedRenderSession,
      StreamController<RenderNotifier> notifier,
      [WidgetIdentifier? overwriteTask]) {
    assert(!kIsWeb, "Render does not support Web yet");
    assert(
        overwriteTask != null || _globalTask?.key.currentWidget != null,
        "RenderController must have a Render instance "
        "connected to create a session.");
    final session = RenderSession.fromDetached(
        detachedSession: detachedRenderSession,
        notifier: notifier,
        task: overwriteTask ?? _globalTask!,
        onDispose: () => _activeSessions.removeWhere(
            (s) => s.sessionId == detachedRenderSession.sessionId));
    _activeSessions.add(session);
    return session;
  }

  void _debugPrintOnStream(Stream<RenderNotifier> stream, String startMessage) {
    if (kDebugMode) {
      bool started = true;
      stream.listen((event) {
        if (started) {
          printRich("[Render plugin] $startMessage",
              foreground: Colors.lightGreen, bold: true, underline: true);
          started = false;
        }
        printRich(event.toString(),
            foreground: event.isError
                ? Colors.red
                : event.isResult
                    ? Colors.green
                    : event.isActivity
                        ? Colors.lightGreen
                        : event.isLog
                            ? Colors.blueGrey
                            : null);
      });
    }
  }

  Future<RenderResult> captureImage({
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
  }) async {
    final stream = captureImageWithStream(
      logLevel: logLevel ?? this.logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing image started");
    final out = await stream
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (out.isFatalError) throw (out as RenderError).exception;
    return out as RenderResult;
  }

  Future<RenderResult> captureImageFromWidget(
    BuildContext context,
    Widget widget, {
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
  }) async {
    final stream = captureImageFromWidgetWithStream(
      context,
      widget,
      logLevel: logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing image from widget started");
    final out = await stream
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (out.isFatalError) throw (out as RenderError).exception;
    return out as RenderResult;
  }

  Future<RenderResult> captureMotion(
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
  }) async {
    final stream = captureMotionWithStream(
      duration,
      logLevel: logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing motion started");
    final out = await stream
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (out.isFatalError) throw (out as RenderError).exception;
    return out as RenderResult;
  }

  Future<RenderResult> captureMotionFromWidget(
    BuildContext context,
    Widget widget,
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
  }) async {
    final stream = captureMotionFromWidgetWithStream(
      context,
      widget,
      duration,
      logLevel: logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing motion from widget started");
    final out = await stream
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (out.isFatalError) throw (out as RenderError).exception;
    return out as RenderResult;
  }

  Stream<RenderNotifier> captureImageWithStream({
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
    bool logInConsole = false,
  }) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(detachedSession, notifier);
      final capturer = RenderCapturer(session);
      final realSession = await capturer.single();
      final processor = ImageProcessor(realSession);
      await processor.process();
      await session.dispose();
    });
    if (logInConsole) {
      _debugPrintOnStream(notifier.stream, "Capturing image started");
    }
    return notifier.stream;
  }

  Stream<RenderNotifier> captureMotionWithStream(
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
    bool logInConsole = false,
  }) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(detachedSession, notifier);
      final capturer = RenderCapturer(session);
      final realSession = await capturer.run(duration);
      final processor = MotionProcessor(realSession);
      await processor.process();
      await session.dispose();
    });
    if (logInConsole) {
      _debugPrintOnStream(notifier.stream, "Capturing motion started");
    }
    return notifier.stream;
  }

  Stream<RenderNotifier> captureImageFromWidgetWithStream(
    BuildContext context,
    Widget widget, {
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
    bool logInConsole = false,
  }) {
    final widgetTask = WidgetIdentifier(controllerId: id, widget: widget);
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(
        detachedSession,
        notifier,
        widgetTask,
      );
      final capturer = RenderCapturer(session, context);
      final realSession = await capturer.single();
      final processor = ImageProcessor(realSession);
      await processor.process();
      await session.dispose();
    });
    if (logInConsole) {
      _debugPrintOnStream(
          notifier.stream,
          "Capturing image from "
          "widget started");
    }
    return notifier.stream;
  }

  Stream<RenderNotifier> captureMotionFromWidgetWithStream(
    BuildContext context,
    Widget widget,
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
    bool logInConsole = false,
  }) {
    final widgetTask = WidgetIdentifier(controllerId: id, widget: widget);
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(
        detachedSession,
        notifier,
        widgetTask,
      );
      final capturer = RenderCapturer(session, context);
      final realSession = await capturer.run(duration);
      final processor = MotionProcessor(realSession);
      await processor.process();
      await session.dispose();
    });
    if (logInConsole) {
      _debugPrintOnStream(
          notifier.stream,
          "Capturing motion from "
          "widget started");
    }
    return notifier.stream;
  }

  MotionRecorder recordMotion({
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
    bool logInConsole = false,
  }) {
    assert(!kIsWeb, "Render does not support Web yet");
    assert(
        _globalTask?.key.currentWidget != null,
        "RenderController must have a Render instance "
        "to start recording.");
    return MotionRecorder.start(
      format: format,
      capturingSettings: settings,
      task: _globalTask!,
      logLevel: logLevel ?? this.logLevel,
      controller: this,
      logInConsole: logInConsole,
    );
  }

  MotionRecorder recordMotionFromWidget(
    BuildContext context,
    Widget widget, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
    bool logInConsole = false,
  }) {
    assert(!kIsWeb, "Render does not support Web yet");
    return MotionRecorder.start(
      context: context,
      format: format,
      capturingSettings: settings,
      task: WidgetIdentifier(controllerId: id, widget: widget),
      logLevel: logLevel ?? this.logLevel,
      controller: this,
      logInConsole: logInConsole,
    );
  }
}

class MotionRecorder<T extends MotionFormat> {
  final RenderController _controller;

  final MotionSettings capturingSettings;

  final T format;

  final bool logInConsole;

  final LogLevel logLevel;
  late final StreamController<RenderNotifier> _notifier;
  late final RenderSession<T, MotionSettings> _session;
  late final RenderCapturer<T> _capturer;

  MotionRecorder.start({
    required RenderController controller,
    required this.logLevel,
    required this.format,
    required this.capturingSettings,
    required TaskIdentifier task,
    required this.logInConsole,
    BuildContext? context,
  }) : _controller = controller {
    _notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, capturingSettings, logLevel)
        .then((detachedSession) {
      _session = _controller._createRenderSessionFrom(
        detachedSession,
        _notifier,
        task is WidgetIdentifier ? task : null,
      );
      _capturer = RenderCapturer(_session, context);
      _capturer.start();
    });
    if (logInConsole) {
      _controller._debugPrintOnStream(
          _notifier.stream, "Recording motion started");
    }
  }

  Stream<RenderNotifier> get stream => _notifier.stream;

  Future<RenderResult> stop() async {
    final realSession = await _capturer.finish();
    final processor = MotionProcessor(realSession);
    processor.process();
    final out = await stream
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (out.isFatalError) throw (out as RenderError).exception;
    _notifier.close();
    await _session.dispose();
    return out as RenderResult;
  }
}

class Render extends StatefulWidget {
  final RenderController? controller;

  final Widget child;

  const Render({
    Key? key,
    this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<Render> createState() => _RenderState();
}

class _RenderState extends State<Render> with WidgetsBindingObserver {
  final GlobalKey renderKey = GlobalKey();
  bool hasAttached = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final numberOfSessions = widget.controller?._activeSessions.length ?? 0;
      for (int i = 0; i < numberOfSessions; i++) {
        widget.controller?._activeSessions.first.recordError(
          const RenderException(
            "Application was paused during an active render session.",
            fatal: true,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.controller != null) {
      attach();
      hasAttached = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAttached && widget.controller != null) {
      attach();
      hasAttached = true;
    }
    return RepaintBoundary(
      key: renderKey,
      child: widget.child,
    );
  }

  void attach() {
    assert(widget.controller != null);
    widget.controller!._globalTask = KeyIdentifier(
      controllerId: widget.controller!.id,
      key: renderKey,
    );
    hasAttached = true;
  }
}
