import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> writeBackupFile(
  String contents, {
  required String filename,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(contents);
  return file.path;
}

Future<String> readBackupFile(String path) => File(path).readAsString();
