import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://tigu1221-lanet-asr-server.hf.space/config';
  final response = await http.get(Uri.parse(url));
  final json = jsonDecode(response.body);
  final components = json['components'] as List;

  for (final c in components) {
    if (c['id'] == 0 || c['id'] == 1) {
      print('Component ${c['id']}:');
      print(const JsonEncoder.withIndent('  ').convert(c));
    }
  }
}
