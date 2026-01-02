import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

void main() async {
  await testQueue("hi");
}

Future<void> testQueue(String question) async {
  final sessionHash = "debug_${DateTime.now().millisecondsSinceEpoch}";
  final joinUrl = "https://thiobista-lanet-amharic-tutor.hf.space/queue/join";
  final dataUrl = "https://thiobista-lanet-amharic-tutor.hf.space/queue/data?session_hash=$sessionHash";

  print("Joining queue with hash: $sessionHash");
  final joinResponse = await http.post(
    Uri.parse(joinUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "fn_index": 1,
      "data": [question, []],
      "session_hash": sessionHash
    }),
  );

  print("Join status: ${joinResponse.statusCode}");

  print("Listening to SSE...");
  final client = http.Client();
  final request = http.Request('GET', Uri.parse(dataUrl));
  
  try {
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
            print("Raw Output Data: ${jsonEncode(data['output'])}");
            final output = data['output']['data'][0];
            print("Output[0]: '$output'");
            client.close();
          }
        } catch (e) {
          print("Parse error: $e");
        }
      }
    });
  } catch (e) {
    print("Stream error: $e");
  } finally {
    client.close();
  }
}
