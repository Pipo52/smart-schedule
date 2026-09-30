import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/services/ai_parser_service.dart';
import 'package:smart_schedule/utils/smart_import_utils.dart';

void main() {
  group('AiParserService & Smart Import Tests', () {
    final parser = AiParserService();

    test('schedule import and commands share one Gemini model id', () {
      expect(AiParserService.geminiModel, 'gemini-3.6-flash');
    });

    test('mimeTypeForPath detects mime types accurately from filename or path', () {
      expect(mimeTypeForPath('schedule.pdf'), 'application/pdf');
      expect(mimeTypeForPath('/path/to/table.PDF'), 'application/pdf');
      expect(mimeTypeForPath('photo.png'), 'image/png');
      expect(mimeTypeForPath('photo.jpg'), 'image/jpeg');
      expect(mimeTypeForPath('photo.jpeg'), 'image/jpeg');
      expect(mimeTypeForPath('photo.webp'), 'image/webp');
      expect(mimeTypeForPath('document.docx'), 'application/octet-stream');
    });

    test('parseScheduleFromBytes throws invalidKey when API key is empty', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3]);
      expect(
        () => parser.parseScheduleFromBytes(
          bytes: dummyBytes,
          mimeType: 'application/pdf',
          apiKey: '',
        ),
        throwsA(
          isA<AiParserException>().having(
            (e) => e.code,
            'code',
            AiParserErrorCode.invalidKey,
          ),
        ),
      );
    });

    test('parseScheduleFromBytes throws fileTooLarge when bytes exceed max limit', () async {
      // Create a dummy byte array that exceeds 15 MB
      final largeBytes = Uint8List(AiParserService.maxFileBytes + 1);
      expect(
        () => parser.parseScheduleFromBytes(
          bytes: largeBytes,
          mimeType: 'application/pdf',
          apiKey: 'test-key',
        ),
        throwsA(
          isA<AiParserException>().having(
            (e) => e.code,
            'code',
            AiParserErrorCode.fileTooLarge,
          ),
        ),
      );
    });
  });
}
