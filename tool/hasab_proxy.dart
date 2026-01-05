import 'dart:io';
import 'dart:convert';

Future<void> main(List<String> args) async {
  String apiKey = '';
  int port = 8787;
  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--api-key' && i + 1 < args.length) apiKey = args[++i];
    if (a == '--port' && i + 1 < args.length) port = int.parse(args[++i]);
  }
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  await for (final req in server) {
    final headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
    if (req.method == 'OPTIONS') {
      headers.forEach((k, v) => req.response.headers.add(k, v));
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      continue;
    }
    final path = req.uri.path;
    if (path == '/v1/tts/synthesize' && req.method == 'POST') {
      final body = await utf8.decodeStream(req);
      final client = HttpClient();
      final upstream = await client.postUrl(Uri.parse('https://hasab.co/v1/tts/synthesize'));
      upstream.headers.set('content-type', 'application/json');
      if (apiKey.isNotEmpty) upstream.headers.set('authorization', 'Bearer $apiKey');
      upstream.add(utf8.encode(body));
      final resp = await upstream.close();
      final data = await resp.fold<List<int>>(<int>[], (p, e) => p..addAll(e));
      headers.forEach((k, v) => req.response.headers.add(k, v));
      final ct = resp.headers.contentType?.toString() ?? 'audio/mpeg';
      req.response.headers.set('content-type', ct);
      req.response.statusCode = resp.statusCode;
      req.response.add(data);
      await req.response.close();
      continue;
    }
    headers.forEach((k, v) => req.response.headers.add(k, v));
    req.response.statusCode = HttpStatus.notFound;
    req.response.write('Not Found');
    await req.response.close();
  }
}
