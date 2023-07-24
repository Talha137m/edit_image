import 'dart:io';
import 'package:edit_the_image/capture_frames.dart/services/session.dart';
import 'package:edit_the_image/capture_frames.dart/services/setting.dart';

import '../formats.dart/abstract.dart';
import 'exception.dart';

abstract class RenderNotifier {
  final Duration timestamp;

  RenderNotifier({
    required this.timestamp,
  });

  @override
  String toString();

  bool get isResult => this is RenderResult;

  bool get isError => this is RenderError;

  bool get isActivity => this is RenderActivity;

  bool get isLog => this is RenderLog;

  bool get isFatalError => isError && (this as RenderError).fatal;
}

class RenderError extends RenderNotifier {
  final RenderException exception;

  final bool fatal;

  RenderError({
    required this.fatal,
    required this.exception,
    required super.timestamp,
  });

  @override
  String toString() {
    return "RenderError(timestamp: $timestamp, exception: $exception, fatal: $fatal)";
  }
}

class RenderLog extends RenderNotifier {
  final String message;

  RenderLog({
    required this.message,
    required super.timestamp,
  });

  @override
  String toString() {
    return "RenderLog(timestamp: $timestamp, message: ${message.replaceAll(RegExp(r"\s+"), " ")})";
  }
}

class RenderActivity extends RenderNotifier {
  final String? message;

  final String? details;

  final RenderState state;

  final double currentStateProgression;

  final RenderSession _session;

  RenderActivity({
    required this.state,
    required this.currentStateProgression,
    this.message,
    this.details,
    required RenderSession session,
    required super.timestamp,
  })  : _session = session,
        assert(
          currentStateProgression >= 0.0 && currentStateProgression <= 1.0,
        );

  Duration? get timeRemaining {
    final expectedTime = totalExpectedTime;
    if (expectedTime == null) return null;
    return Duration(
      milliseconds: expectedTime.inMilliseconds - timestamp.inMilliseconds,
    );
  }

  double get progressPercentage {
    final percentagePassed = RenderState.values
        .sublist(0, RenderState.values.indexOf(state))
        .fold(
            0.0,
            (previousValue, element) =>
                previousValue + _session.processingShare(element));
    return currentStateProgression * _session.processingShare(state) +
        percentagePassed;
  }

  Duration? get totalExpectedTime {
    final progress = progressPercentage;
    if (progress == 0.0) return null;
    return Duration(milliseconds: timestamp.inMilliseconds ~/ progress);
  }

  @override
  String toString() {
    return "RenderActivity(timestamp: $timestamp, state: ${state.name} message:"
        " $message, ${details != null ? "details: $details, " : ""}"
        "timeRemaining: ${timeRemaining?.inMinutes}:"
        "${timeRemaining?.inSeconds},"
        " progressPercentage: "
        "${(progressPercentage * 100).toStringAsPrecision(3)}%,"
        " totalExpectedTime: ${totalExpectedTime?.inMinutes}:"
        "${totalExpectedTime?.inSeconds})";
  }
}

class RenderResult extends RenderActivity {
  final File output;

  final RealRenderSettings usedSettings;

  final RenderFormat format;

  RenderResult({
    required this.format,
    required this.output,
    required this.usedSettings,
    super.message,
    super.details,
    required super.timestamp,
    required RenderSession session,
  }) : super(
          state: RenderState.finishing,
          currentStateProgression: 1,
          session: session,
        );

  Duration get totalRenderTime => timestamp;

  @override
  String toString() {
    return "RenderResult(timestamp: $timestamp, "
        "${message != null ? "message: $message, " : ""}"
        "totalRenderTime: $totalRenderTime)";
  }
}

enum RenderState {
  capturing,

  handleCaptures,

  processing,

  finishing;
}

enum LogLevel {
  none,
  activity,
  debug
}
