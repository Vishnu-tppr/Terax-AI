import 'package:logging/logging.dart';

final logger = Logger('TeraxAIApp');

void setupLogger() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // In a real app, you would use a logging framework like file logger, crashlytics, etc.
  });
}