import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

abstract class TaskIdentifier {
  final UuidValue controllerId;

  TaskIdentifier({
    required this.controllerId,
  });
}

class WidgetIdentifier extends TaskIdentifier {
  final Widget widget;

  WidgetIdentifier({
    required super.controllerId,
    required this.widget,
  });
}

class KeyIdentifier extends TaskIdentifier {
  final GlobalKey key;

  KeyIdentifier({
    required super.controllerId,
    required this.key,
  });
}
