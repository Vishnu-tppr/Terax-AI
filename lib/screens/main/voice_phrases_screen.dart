import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/providers/settings_provider.dart';
import 'package:terax_ai_app/widgets/custom_app_bar.dart';
import 'package:terax_ai_app/widgets/empty_state.dart';

class VoicePhrasesScreen extends StatefulWidget {
  const VoicePhrasesScreen({super.key});

  @override
  State<VoicePhrasesScreen> createState() => _VoicePhrasesScreenState();
}

class _VoicePhrasesScreenState extends State<VoicePhrasesScreen> {
  final _phraseController = TextEditingController();

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  void _addPhrase() {
    final phrase = _phraseController.text.trim();
    if (phrase.isEmpty) return;

    final settingsProvider = context.read<SettingsProvider>();
    final currentPhrases =
        List<String>.from(settingsProvider.settings.voiceTriggerPhrases);
    currentPhrases.add(phrase.toLowerCase());

    settingsProvider.updateVoiceTriggerPhrases(currentPhrases);
    _phraseController.clear();
  }

  void _removePhrase(int index) {
    final settingsProvider = context.read<SettingsProvider>();
    final currentPhrases =
        List<String>.from(settingsProvider.settings.voiceTriggerPhrases);
    currentPhrases.removeAt(index);

    settingsProvider.updateVoiceTriggerPhrases(currentPhrases);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Voice Trigger Phrases'),
      body: Column(
        children: [
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                final phrases =
                    settingsProvider.settings.voiceTriggerPhrases;

                if (phrases.isEmpty) {
                  return const EmptyState(
                    assetPath: 'assets/images/no_phrases.svg',
                    title: 'No Phrases Yet',
                    message: 'Add your first voice trigger phrase',
                  );
                }

                return ListView.builder(
                  itemCount: phrases.length,
                  itemBuilder: (context, index) {
                    final phrase = phrases[index];
                    return ListTile(
                      title: Text(phrase),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removePhrase(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phraseController,
                    decoration: const InputDecoration(
                      labelText: 'New Phrase',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addPhrase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
