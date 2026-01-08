import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

class BlobData {
  final Uint8List bytes;
  final String? mimeType;
  BlobData(this.bytes, [this.mimeType]);
}

Future<Uint8List> readFileBytesWeb(dynamic file) async {
  if (file is! html.File) {
    throw ArgumentError('Expected html.File');
  }
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.onLoad.listen((event) {
    final bytes = reader.result as List<int>;
    completer.complete(Uint8List.fromList(bytes));
  });

  reader.onError.listen((error) {
    completer.completeError('Error reading file: $error');
  });

  reader.readAsArrayBuffer(file);

  return await completer.future;
}

Future<BlobData> fetchBlobData(String url) async {
  final completer = Completer<BlobData>();
  final request = html.HttpRequest();
  request.open('GET', url);
  request.responseType = 'arraybuffer';

  request.onLoad.listen((event) {
    if (request.status == 200) {
      final buffer = request.response as ByteBuffer;
      final bytes = Uint8List.view(buffer);
      final mime = request.getResponseHeader('Content-Type');
      completer.complete(BlobData(bytes, mime));
    } else {
      completer.completeError('Failed to fetch blob: ${request.statusText}');
    }
  });

  request.onError.listen((event) {
    completer.completeError('Error fetching blob');
  });

  request.send();
  return completer.future;
}

dynamic createWebFile(List<Object> bits, String name) {
  return html.File(bits, name);
}

bool isWebFile(dynamic file) => file is html.File;
