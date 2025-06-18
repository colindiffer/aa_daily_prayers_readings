import 'lib/data/readings.dart';

void main() {
  print('Testing readings data...');
  
  // Test: Check default readings
  print('Default readings count: ${readings.length}');
  if (readings.isNotEmpty) {
    print('✅ Default readings loaded successfully');
    print('First reading: ${readings[0]['title']}');
    print('Second reading: ${readings[1]['title']}');
    print('Third reading: ${readings[2]['title']}');
  } else {
    print('❌ No default readings found');
  }
}
}
