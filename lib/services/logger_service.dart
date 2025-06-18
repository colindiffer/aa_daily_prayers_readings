import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  File? _logFile;
  bool _initialized = false;
  final List<String> _pendingLogs = [];

  Future<void> init() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final String timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final String logFilePath =
          '${directory.path}/aa_readings_log_$timestamp.txt';

      _logFile = File(logFilePath);

      // Log some basic info to start the file
      await _logFile!.writeAsString(
        '=== AA Readings Log Started at ${DateTime.now()} ===\n',
        mode: FileMode.append,
      );

      // Write any pending logs
      for (final log in _pendingLogs) {
        await _logFile!.writeAsString(log, mode: FileMode.append);
      }
      _pendingLogs.clear();

      _initialized = true;
      log('LoggerService initialized successfully. Log file: $logFilePath');
    } catch (e) {
      debugPrint('Error initializing LoggerService: $e');
    }
  }

  void log(String message) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] $message\n';

    // Always print to console
    debugPrint(logMessage);

    if (_initialized && _logFile != null) {
      // Write to file
      try {
        _logFile!.writeAsString(logMessage, mode: FileMode.append);
      } catch (e) {
        debugPrint('Error writing to log file: $e');
      }
    } else {
      // Store for later if not initialized
      _pendingLogs.add(logMessage);
    }
  }

  Future<String> getLogFilePath() async {
    if (!_initialized || _logFile == null) {
      await init();
    }
    return _logFile?.path ?? 'Logger not initialized';
  }

  Future<String> getAllLogs() async {
    if (!_initialized || _logFile == null) {
      return 'Logger not initialized';
    }

    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }
}
