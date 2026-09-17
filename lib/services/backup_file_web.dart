Future<String> writeBackupFile(String contents, {required String filename}) {
  throw UnsupportedError('Backup export is not available on web.');
}

Future<String> readBackupFile(String path) {
  throw UnsupportedError('Backup import is not available on web.');
}
