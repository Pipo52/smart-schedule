import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson.dart';

enum AiParserErrorCode {
  fileTooLarge,
  emptyResponse,
  malformedJson,
  noLessons,
  invalidKey,
  network,
  unknown,
}

class AiParserException implements Exception {
  AiParserException(this.code, [this.cause]);

  final AiParserErrorCode code;
  final Object? cause;

  @override
  String toString() => 'AiParserException($code, $cause)';
}

/// Sends a schedule PDF/image to Gemini and maps the JSON reply to [Lesson]s.
class AiParserService {
  AiParserService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const int maxFileBytes = 15 * 1024 * 1024;

  static const String _prompt = '''
You extract a university class timetable from the attached PDF or image.

Return ONLY a valid JSON array. No markdown, no commentary, no trailing text.

Each element must be an object with exactly these fields:
- "subjectName": string (course / subject name)
- "type": one of "lecture", "practical", "laboratory"
- "room": string (classroom; empty string if unknown)
- "lecturer": string (empty string if unknown)
- "startTime": string in 24-hour "HH:mm" (example "09:00")
- "endTime": string in 24-hour "HH:mm" (example "10:30")
- "weekday": integer 1-6 where 1 is Monday and 6 is Saturday
- "weekType": one of "every", "week1", "week2"
  Use "week1" / "week2" when the timetable shows alternating weeks.
  Use "every" when the class happens every week.

If a class appears on multiple days, emit a separate object per day.
If nothing can be extracted, return [].
''';

  final Uuid _uuid;

  Future<List<Lesson>> parseScheduleFromFile(
    String filePath,
    String mimeType,
    String apiKey,
  ) async {
    if (apiKey.trim().isEmpty) {
      throw AiParserException(AiParserErrorCode.invalidKey);
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    if (bytes.length > maxFileBytes) {
      throw AiParserException(AiParserErrorCode.fileTooLarge);
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );

    final GenerateContentResponse response;
    try {
      response = await model.generateContent([
        Content.multi([
          TextPart(_prompt),
          DataPart(mimeType, bytes),
        ]),
      ]);
    } on InvalidApiKey catch (e) {
      throw AiParserException(AiParserErrorCode.invalidKey, e);
    } on GenerativeAIException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('api key') ||
          message.contains('permission') ||
          message.contains('401') ||
          message.contains('403')) {
        throw AiParserException(AiParserErrorCode.invalidKey, e);
      }
      throw AiParserException(AiParserErrorCode.network, e);
    } on SocketException catch (e) {
      throw AiParserException(AiParserErrorCode.network, e);
    } on HandshakeException catch (e) {
      throw AiParserException(AiParserErrorCode.network, e);
    } catch (e) {
      throw AiParserException(AiParserErrorCode.unknown, e);
    }

    final raw = response.text?.trim() ?? '';
    if (raw.isEmpty) {
      throw AiParserException(AiParserErrorCode.emptyResponse);
    }

    final decoded = _decodeJsonArray(raw);
    if (decoded.isEmpty) {
      throw AiParserException(AiParserErrorCode.noLessons);
    }

    return decoded.map(_lessonFromJson).toList();
  }

  List<Map<String, dynamic>> _decodeJsonArray(String raw) {
    final jsonText = _stripMarkdownFence(raw);
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (decoded is Map && decoded['lessons'] is List) {
        return (decoded['lessons'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      throw AiParserException(AiParserErrorCode.malformedJson);
    } on FormatException catch (e) {
      throw AiParserException(AiParserErrorCode.malformedJson, e);
    } on AiParserException {
      rethrow;
    } catch (e) {
      throw AiParserException(AiParserErrorCode.malformedJson, e);
    }
  }

  String _stripMarkdownFence(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text.trim();
  }

  Lesson _lessonFromJson(Map<String, dynamic> json) {
    final weekday = (json['weekday'] as num?)?.toInt() ?? 1;
    return Lesson(
      id: _uuid.v4(),
      subjectName: (json['subjectName'] as String?)?.trim().isNotEmpty == true
          ? (json['subjectName'] as String).trim()
          : 'Untitled',
      type: _parseLessonType(json['type']),
      room: (json['room'] as String?)?.trim() ?? '',
      lecturer: (json['lecturer'] as String?)?.trim() ?? '',
      startTime: _normalizeTime(json['startTime']),
      endTime: _normalizeTime(json['endTime']),
      weekday: weekday < 1 ? 1 : (weekday > 6 ? 6 : weekday),
      weekType: _parseWeekType(json['weekType']),
    );
  }

  LessonType _parseLessonType(Object? raw) {
    final value = (raw?.toString() ?? 'lecture').toLowerCase().trim();
    return LessonType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LessonType.lecture,
    );
  }

  WeekType _parseWeekType(Object? raw) {
    final value = (raw?.toString() ?? 'every')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]'), '');
    return switch (value) {
      'week1' || '1' || 'odd' => WeekType.week1,
      'week2' || '2' || 'even' => WeekType.week2,
      _ => WeekType.every,
    };
  }

  String _normalizeTime(Object? raw) {
    final source = raw?.toString().trim() ?? '09:00';
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(source);
    if (match == null) return '09:00';
    final hours = int.parse(match.group(1)!).clamp(0, 23);
    final minutes = int.parse(match.group(2)!).clamp(0, 59);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
