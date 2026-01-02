import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class LanetApiService {
  static const String baseUrl =
      "https://thiobista-lanet-amharic-tutor.hf.space";
  static const String joinUrl = "$baseUrl/queue/join";

  static Future<String> getAnswer(String question) async {
    final sessionHash = _generateSessionHash();
    final dataUrl = "$baseUrl/queue/data?session_hash=$sessionHash";
    final prompt = "ጥያቄ: $question\nመልስ:";

    try {
      // 1. Join the Queue
      final joinResponse = await http.post(
        Uri.parse(joinUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fn_index": 1, // 'respond' function index
          "data": [question, []], // [message, history]
          "session_hash": sessionHash
        }),
      );

      if (joinResponse.statusCode != 200) {
        return "Server busy. Try again later.";
      }

      // 2. Listen for SSE events
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(dataUrl));

      try {
        final response = await client.send(request);

        String? finalResult;

        await for (final line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            try {
              final data = jsonDecode(jsonStr);
              if (data['msg'] == 'process_completed') {
                // The chatbot returns [history, last_message] or similar structure
                // Debug output: {"data":["",[["hi","ሰላም (ሳላም)."]]]}
                // It seems data[0] is empty string, and data[1] is the history?
                // Let's check the structure.
                // If data[0] is empty, check data[1] (history) for the last response.

                var output = data['output']['data'][0];
                finalResult = output.toString();

                if (finalResult.isEmpty) {
                  // Check history
                  final history = data['output']['data'][1];
                  if (history is List && history.isNotEmpty) {
                    final lastPair = history.last; // [user_msg, bot_msg]
                    if (lastPair is List && lastPair.length > 1) {
                      finalResult = lastPair[1].toString();
                    }
                  }
                }

                // Clean up the result if needed (remove "መልስ:" prefix if present)
                if (finalResult.contains("መልስ:")) {
                  finalResult = finalResult.split("መልስ:").last.trim();
                }
                client.close();
                break;
              }
            } catch (e) {
              // Ignore parse errors for keep-alive packets
            }
          }
        }

        return finalResult ?? "No answer found.";
      } catch (e) {
        client.close();
        return "Connection error during stream.";
      }
    } catch (e) {
      return "Connection problem. Try again.";
    }
  }

  static String _generateSessionHash() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}
