import 'dart:io';

void main() async {
  print('🔍 Flutter Connection Debugging Tool 🔍');
  print('======================================');

  // Check Flutter version
  await _runCommand('flutter --version');

  print('\n📱 Checking connected devices:');
  await _runCommand('flutter devices');

  print('\n🧪 Testing Flutter doctor:');
  await _runCommand('flutter doctor -v');

  print('\n🔄 Clearing derived data:');
  await _runCommand('flutter clean');

  print('\n♨️ Hot restart may help. When app is running, press:');
  print('   - "R" in the terminal');
  print('   - Or use "Flutter: Hot Restart" from command palette');

  print('\n🔌 Checking port availability:');
  await _checkCommonDebugPorts();

  print('\n💡 Recommended next steps:');
  print(' 1. Run "flutter clean" then "flutter pub get"');
  print(' 2. Try running with "--debug-port=<port>" with an available port');
  print(
    ' 3. Try using "flutter run --pid-file=/tmp/flutter.pid" to track the process',
  );
  print(' 4. Ensure firewall isn\'t blocking Flutter debug connections');
  print(
    ' 5. Try running the app with "flutter run --verbose" for more details',
  );
  print(' 6. Run the app using the VS Code launch configuration provided');
}

Future<void> _runCommand(String command) async {
  print('\n> $command');
  try {
    final parts = command.split(' ');
    final process = await Process.start(
      parts.first,
      parts.skip(1).toList(),
      mode: ProcessStartMode.inheritStdio,
    );
    await process.exitCode;
  } catch (e) {
    print('Error running command: $e');
  }
}

Future<void> _checkCommonDebugPorts() async {
  final ports = [8080, 8888, 53494, 53495, 53496];

  for (final port in ports) {
    try {
      final socket = await ServerSocket.bind('127.0.0.1', port, shared: true);
      print(' ✓ Port $port is available');
      await socket.close();
    } catch (e) {
      print(' ✗ Port $port is in use or blocked');
    }
  }
}
