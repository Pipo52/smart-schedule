import '../l10n/generated/app_localizations.dart';
import '../services/ai_parser_service.dart';

String mimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'application/octet-stream';
}

String messageForAiParserError(
  AppLocalizations l10n,
  Object error,
) {
  if (error is AiParserException) {
    return switch (error.code) {
      AiParserErrorCode.fileTooLarge => l10n.smartImportFileTooLarge,
      AiParserErrorCode.malformedJson ||
      AiParserErrorCode.emptyResponse => l10n.smartImportMalformed,
      AiParserErrorCode.noLessons => l10n.smartImportEmpty,
      AiParserErrorCode.invalidKey => l10n.smartImportNetwork,
      AiParserErrorCode.network => '${l10n.smartImportNetwork} (Сервер: ${error.cause?.toString().contains("503") == true ? "Перегружен" : "Сбой"})',
      AiParserErrorCode.unknown =>
        l10n.smartImportError(error.cause?.toString() ?? error.toString()),
    };
  }
  return l10n.smartImportError(error.toString());
}
