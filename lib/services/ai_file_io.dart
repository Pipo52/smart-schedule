import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readAiFileBytes(String path) => File(path).readAsBytes();
