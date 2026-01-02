import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testQueue();
}

Future<void> testQueue() async {
  final sessionHash = "test_sess_${DateTime.now().millisecondsSinceEpoch}";
  final joinUrl = "https://thiobista-lanet-amharic-tutor.hf.space/queue/join";
  final dataUrl =
      "https://thiobista-lanet-amharic-tutor.hf.space/queue/data?session_hash=$sessionHash";

  print("Joining queue with hash: $sessionHash");
  final joinResponse = await http.post(
    Uri.parse(joinUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "fn_index": 1,
      "data": ["hello", []],
      "session_hash": sessionHash
    }),
  );

  print("Join status: ${joinResponse.statusCode}");
  if (joinResponse.statusCode != 200) {
    print("Join failed: ${joinResponse.body}");
    return;
  }

  print("Listening to SSE...");
  final client = http.Client();
  final request = http.Request('GET', Uri.parse(dataUrl));
  final response = await client.send(request);

  await response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
    if (line.startsWith('data: ')) {
      final jsonStr = line.substring(6);
      try {
        final data = jsonDecode(jsonStr);
        print("Event: ${data['msg']}");
        if (data['msg'] == 'process_completed') {
          print("Result: ${data['output']['data'][0]}"); // Expecting the text
          client.close(); // Stop listening
        }
      } catch (e) {
        print("Parse error: $e");
      }
    }
  });
}
