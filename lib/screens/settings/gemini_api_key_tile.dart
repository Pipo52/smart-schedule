import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/settings_provider.dart';

class GeminiApiKeyTile extends StatefulWidget {
  const GeminiApiKeyTile({super.key});

  @override
  State<GeminiApiKeyTile> createState() => _GeminiApiKeyTileState();
}

class _GeminiApiKeyTileState extends State<GeminiApiKeyTile> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SettingsProvider>().settings.geminiApiKey ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    await context.read<SettingsProvider>().setGeminiApiKey(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsGeminiApiKeySaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            obscureText: _obscured,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: l10n.settingsGeminiApiKey,
              hintText: l10n.settingsGeminiApiKeyHint,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.save,
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ],
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsGeminiApiKeyHelp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
