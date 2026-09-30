import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/lesson.dart';
import '../models/semester_period.dart';
import '../models/task.dart';
import 'ai_file_io.dart' if (dart.library.js_interop) 'ai_file_web.dart';
export 'ai_file_io.dart' if (dart.library.js_interop) 'ai_file_web.dart';

enum AiParserErrorCode {
  fileTooLarge,
  emptyResponse,
  malformedJson,
  noLessons,
  invalidKey,
  network,
  unknown,
}

enum AiIntent { createTask, createLesson, cancelLesson, createPeriod, unknown }

class AiCommandResult {
  const AiCommandResult({
    required this.intent,
    this.task,
    this.lesson,
    this.cancelSubject,
    this.cancelDate,
    this.period,
  });

  final AiIntent intent;
  final Task? task;
  final Lesson? lesson;
  // Для cancel_lesson:
  final String? cancelSubject;
  final DateTime? cancelDate;
  // Для create_period:
  final SemesterPeriod? period;
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

  /// Live Gemini model. Change this only when the API returns model-not-found.
  static const String geminiModel = 'gemini-3.6-flash';

  static const String _prompt = '''
You are an expert data extractor. Extract the university class timetable from the attached PDF or image.
The timetable might be in Russian or Ukrainian. Translate the concepts to match the required English JSON fields.

Return ONLY a valid JSON array. No markdown, no commentary.

Each element must be an object with exactly these fields:
- "subjectName": string (course / subject name, keep original language)
- "type": one of "lecture", "practical", "laboratory". (Map 'Лекція/Лекция' to 'lecture', 'Семінар/Практика' to 'practical', 'Лаба/Лабораторна' to 'laboratory'. If unsure, use 'lecture')
- "room": string (classroom; empty string if unknown, keep original language)
- "lecturer": string (empty string if unknown, keep original language)
- "startTime": string in 24-hour "HH:mm" (example "09:00")
- "endTime": string in 24-hour "HH:mm" (example "10:30")
- "weekday": integer 1-6 where 1 is Monday and 6 is Saturday
- "weekType": one of "every", "week1", "week2" (Map alternating weeks to week1/week2, otherwise every)

If a class appears on multiple days, emit a separate object per day.
Make your BEST EFFORT to extract at least some classes even if the format is messy. Do not return [] unless the image is completely blank.
''';

  final Uuid _uuid;

  Future<List<Lesson>> parseScheduleFromFile(
    String filePath,
    String mimeType,
    String apiKey,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Smart import from a file path is unavailable on web.',
      );
    }
    if (apiKey.trim().isEmpty) {
      throw AiParserException(AiParserErrorCode.invalidKey);
    }

    final bytes = await readAiFileBytes(filePath);
    return parseScheduleFromBytes(
      bytes: bytes,
      mimeType: mimeType,
      apiKey: apiKey,
    );
  }

  Future<List<Lesson>> parseScheduleFromBytes({
    required Uint8List bytes,
    required String mimeType,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AiParserException(AiParserErrorCode.invalidKey);
    }
    if (bytes.length > maxFileBytes) {
      throw AiParserException(AiParserErrorCode.fileTooLarge);
    }

    final model = GenerativeModel(
      model: geminiModel,
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );

    final GenerateContentResponse response;
    try {
      response = await model.generateContent([
        Content.multi([TextPart(_prompt), DataPart(mimeType, bytes)]),
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
    } catch (e) {
      throw AiParserException(AiParserErrorCode.network, e);
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

  Future<AiCommandResult> parseCommand({
    required String text,
    required String apiKey,
    required DateTime now,
    required String profileId,
    List<String> existingSubjects = const [],
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AiParserException(AiParserErrorCode.invalidKey);
    }

    final model = GenerativeModel(
      model: geminiModel,
      apiKey: apiKey.trim(),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );

    final subjectContext = existingSubjects.isNotEmpty
        ? 'Known subjects in the user\'s schedule: ${existingSubjects.join(", ")}. '
              'When the user mentions a subject, match it to one of these names '
              'EXACTLY (preserve spelling and language). If no match is found, '
              'use the subject name as the user wrote it.'
        : '';

    final prompt =
        'You are a smart calendar assistant. '
        'Parse the user\'s natural-language request and determine the intent.\n'
        'Current date/time for reference: ${now.toIso8601String()}.\n'
        '$subjectContext\n\n'
        'Rules:\n'
        '- If the user wants to add a task, homework, deadline, or reminder '
        '→ intent = "create_task"\n'
        '- If the user wants to add a recurring class/lesson to their weekly '
        'schedule → intent = "create_lesson"\n'
        '- If the user wants to CANCEL or SKIP a specific class on a '
        'specific day → intent = "cancel_lesson"\n'
        '- If the user wants to add a semester period (exam session, '
        'holidays, study period, retake weeks, etc.) → intent = '
        '"create_period"\n'
        '- Otherwise → intent = "unknown"\n\n'
        'Return ONLY a valid JSON object with this exact structure:\n'
        '{\n'
        '  "intent": "create_task" | "create_lesson" | "cancel_lesson" | '
        '"create_period" | "unknown",\n'
        '  "task": {\n'
        '    "title": "short task title (string)",\n'
        '    "linkedSubject": "subject name or null",\n'
        '    "dueDate": "ISO 8601 datetime string. Calculate the exact date '
        'from the user\'s text relative to the current date/time.",\n'
        '    "priority": "low" | "medium" | "high"\n'
        '  },\n'
        '  "lesson": {\n'
        '    "subjectName": "subject name (string)",\n'
        '    "type": "lecture" | "practical" | "laboratory",\n'
        '    "room": "room string or empty",\n'
        '    "lecturer": "lecturer string or empty",\n'
        '    "startTime": "HH:mm (24h)",\n'
        '    "endTime": "HH:mm (24h)",\n'
        '    "weekday": 1-6 (1=Monday, 6=Saturday),\n'
        '    "weekType": "every" | "week1" | "week2"\n'
        '  },\n'
        '  "cancel": {\n'
        '    "subject": "subject name that should be cancelled",\n'
        '    "date": "ISO 8601 date of the class to cancel"\n'
        '  },\n'
        '  "period": {\n'
        '    "name": "period name",\n'
        '    "type": "study" | "exam" | "holiday" | "retake" | '
        '"publicHoliday" | "other",\n'
        '    "startDate": "ISO 8601 date",\n'
        '    "endDate": "ISO 8601 date"\n'
        '  }\n'
        '}\n'
        'Populate ONLY the object matching the intent. Set the others to '
        'null.\n\n'
        'User request: $text';

    final GenerateContentResponse response;
    try {
      response = await model.generateContent([Content.text(prompt)]);
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
    } catch (e) {
      throw AiParserException(AiParserErrorCode.network, e);
    }

    final raw = response.text?.trim() ?? '';
    if (raw.isEmpty) {
      throw AiParserException(AiParserErrorCode.emptyResponse);
    }

    final Map<String, dynamic> decoded;
    try {
      final decodedJson = jsonDecode(_stripMarkdownFence(raw));
      if (decodedJson is! Map) {
        throw const FormatException('Expected a JSON object.');
      }
      decoded = Map<String, dynamic>.from(decodedJson);
    } catch (e) {
      throw AiParserException(AiParserErrorCode.malformedJson, e);
    }

    final intent = decoded['intent'] as String? ?? 'unknown';
    if (intent == 'create_task' && decoded['task'] is Map) {
      final taskJson = Map<String, dynamic>.from(decoded['task'] as Map);
      final priority = Priority.values.firstWhere(
        (item) => item.name == taskJson['priority']?.toString().toLowerCase(),
        orElse: () => Priority.medium,
      );
      return AiCommandResult(
        intent: AiIntent.createTask,
        task: Task(
          id: _uuid.v4(),
          title: _nonEmptyString(taskJson['title'], 'Task'),
          linkedSubject: _nullableString(taskJson['linkedSubject']),
          dueDate:
              DateTime.tryParse(taskJson['dueDate']?.toString() ?? '') ??
              now.add(const Duration(days: 1)),
          priority: priority,
          profileId: profileId,
        ),
      );
    }
    if (intent == 'create_lesson' && decoded['lesson'] is Map) {
      final lessonJson = Map<String, dynamic>.from(decoded['lesson'] as Map);
      final weekday = (lessonJson['weekday'] as num?)?.toInt() ?? 1;
      return AiCommandResult(
        intent: AiIntent.createLesson,
        lesson: Lesson(
          id: _uuid.v4(),
          subjectName: _nonEmptyString(lessonJson['subjectName'], 'Lesson'),
          type: _parseLessonType(lessonJson['type']),
          room: _nullableString(lessonJson['room']) ?? '',
          lecturer: _nullableString(lessonJson['lecturer']) ?? '',
          startTime: _normalizeTime(lessonJson['startTime']),
          endTime: _normalizeTime(lessonJson['endTime']),
          weekday: weekday < 1 ? 1 : (weekday > 6 ? 6 : weekday),
          weekType: _parseWeekType(lessonJson['weekType']),
          profileId: profileId,
        ),
      );
    }
    if (intent == 'cancel_lesson' && decoded['cancel'] is Map) {
      final cancelJson = Map<String, dynamic>.from(decoded['cancel'] as Map);
      return AiCommandResult(
        intent: AiIntent.cancelLesson,
        cancelSubject: _nullableString(cancelJson['subject']),
        cancelDate: DateTime.tryParse(cancelJson['date']?.toString() ?? ''),
      );
    }
    if (intent == 'create_period' && decoded['period'] is Map) {
      final periodJson = Map<String, dynamic>.from(decoded['period'] as Map);
      final typeStr = (periodJson['type'] as String?)?.toLowerCase() ?? 'other';
      final periodType = SemesterPeriodType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => SemesterPeriodType.other,
      );
      return AiCommandResult(
        intent: AiIntent.createPeriod,
        period: SemesterPeriod(
          id: _uuid.v4(),
          name: _nonEmptyString(periodJson['name'], 'Period'),
          startDate:
              DateTime.tryParse(periodJson['startDate']?.toString() ?? '') ??
              now,
          endDate:
              DateTime.tryParse(periodJson['endDate']?.toString() ?? '') ??
              now.add(const Duration(days: 7)),
          type: periodType,
          profileId: profileId,
        ),
      );
    }
    return const AiCommandResult(intent: AiIntent.unknown);
  }

  String _nonEmptyString(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
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
      text = text.replaceFirst(
        RegExp(r'^```(?:json)?\s*', caseSensitive: false),
        '',
      );
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
      profileId: 'default',
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
    final value = (raw?.toString() ?? 'every').toLowerCase().replaceAll(
      RegExp(r'[\s_-]'),
      '',
    );
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
