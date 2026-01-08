import 'dart:typed_data';

class BlobData {
  final Uint8List bytes;
  final String? mimeType;
  BlobData(this.bytes, [this.mimeType]);
}

Future<Uint8List> readFileBytesWeb(dynamic file) async {
  throw UnimplementedError('Web not supported on this platform');
}

Future<BlobData> fetchBlobData(String url) async {
  throw UnimplementedError('Web not supported on this platform');
}

dynamic createWebFile(List<Object> bits, String name) {
  throw UnimplementedError('Web not supported on this platform');
}

bool isWebFile(dynamic file) => false;
