import 'dart:convert';
import 'dart:io';

void send(Map<String, dynamic> payload) {
  stdout.writeln(jsonEncode(payload));
}

void main() {
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    final message = jsonDecode(line) as Map<String, dynamic>;
    switch (message['type']) {
      case 'HELLO':
        send({
          'type': 'REGISTER',
          'protocol': 'ofp/1',
          'workerId': 'dart-json-01',
          'language': 'dart',
          'runtimeVersion': '3.12',
          'workerVersion': '0.1.0',
          'capabilities': [
            {'name': 'data.json-parse'}
          ]
        });
        break;
      case 'JOB_START':
        if (message['capability'] != 'data.json-parse') {
          send({'type': 'JOB_ERROR', 'jobId': message['jobId'], 'error': 'unsupported capability'});
          break;
        }
        final input = message['input'] as Map<String, dynamic>;
        final text = input['json'] as String;
        final parsed = jsonDecode(text);
        final length = parsed is List ? parsed.length : (parsed is Map ? parsed.length : 1);
        send({
          'type': 'JOB_RESULT',
          'jobId': message['jobId'],
          'output': {'kind': parsed.runtimeType.toString(), 'length': length}
        });
        break;
      case 'SHUTDOWN':
        exit(0);
    }
  });
}
