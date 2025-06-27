import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PersistentLogger {
  static PersistentLogger? _instance;
  static PersistentLogger get instance => _instance ??= PersistentLogger._();

  PersistentLogger._();

  File? _logFile;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/tts_debug_$today.log');

      // Write session start marker
      await _writeToFile('=== NEW SESSION STARTED ===');

      _initialized = true;
    } catch (e) {
      print('Failed to initialize persistent logger: $e');
    }
  }

  Future<void> log(String level, String message) async {
    if (!_initialized) {
      await initialize();
    }

    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logEntry = '[$timestamp] [$level] $message';

    // Also print to console for development
    print(logEntry);

    // Write to persistent file
    await _writeToFile(logEntry);
  }

  Future<void> _writeToFile(String content) async {
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$content\n', mode: FileMode.append);
      }
    } catch (e) {
      print('Failed to write to log file: $e');
    }
  }

  // Convenience methods
  Future<void> info(String message) => log('INFO', message);
  Future<void> debug(String message) => log('DEBUG', message);
  Future<void> warning(String message) => log('WARN', message);
  Future<void> error(String message) => log('ERROR', message);
  Future<void> tts(String message) => log('TTS', message);
  Future<void> multiple(String message) => log('MULTIPLE', message);

  // Get log content for display in app
  Future<String> getLogContent() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (e) {
      return 'Error reading log file: $e';
    }
    return 'No log file found';
  }

  // Clear logs (alias for clearAllLogs for backward compatibility)
  Future<void> clearLogs() async {
    await clearAllLogs();
  }

  // Get log file path for sharing
  String? get logFilePath => _logFile?.path;

  // Get all logs as a list of entries
  Future<List<String>> getAllLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        final content = await _logFile!.readAsString();
        return content
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }
    } catch (e) {
      return ['Error reading log file: $e'];
    }
    return [];
  }

  // Export logs to a shareable file
  Future<File> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final exportFile =
          File('${directory.path}/tts_logs_export_$timestamp.txt');

      if (_logFile != null && await _logFile!.exists()) {
        final content = await _logFile!.readAsString();
        await exportFile.writeAsString(content);
      } else {
        await exportFile.writeAsString('No logs available');
      }

      return exportFile;
    } catch (e) {
      throw Exception('Failed to export logs: $e');
    }
  }

  // Clear all logs (including old log files)
  Future<void> clearAllLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        await for (final file in logDir.list()) {
          if (file is File && file.path.contains('tts_debug_')) {
            await file.delete();
          }
        }
      }

      await initialize(); // Recreate current log file
    } catch (e) {
      print('Error clearing all logs: $e');
    }
  }
}
