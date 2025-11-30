import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/providers/settings_provider.dart';
import 'package:terax_ai_app/services/real_voice_service.dart';

class CustomPhrasesScreen extends StatefulWidget {
  const CustomPhrasesScreen({super.key});

  @override
  State<CustomPhrasesScreen> createState() => _CustomPhrasesScreenState();
}

class _CustomPhrasesScreenState extends State<CustomPhrasesScreen> {
  final TextEditingController _phraseController = TextEditingController();
  final RealVoiceService _voiceService = RealVoiceService.instance;
  List<String> _customPhrases = [];

  @override
  void initState() {
    super.initState();
    _loadCustomPhrases();
  }

  void _loadCustomPhrases() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    setState(() {
      _customPhrases = List.from(settingsProvider.settings.voiceTriggerPhrases);
    });
    // Initialize voice service with custom phrases
    _voiceService.updateCustomTriggerPhrases(_customPhrases);
  }

  void _addPhrase() {
    final phrase = _phraseController.text.trim();
    if (phrase.isNotEmpty && !_customPhrases.contains(phrase.toLowerCase())) {
      setState(() {
        _customPhrases.add(phrase.toLowerCase());
      });
      _voiceService.addCustomTriggerPhrase(phrase);
      _saveCustomPhrases();
      _phraseController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added phrase: "$phrase"'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (_customPhrases.contains(phrase.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This phrase already exists'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removePhrase(String phrase) {
    setState(() {
      _customPhrases.remove(phrase);
    });
    _voiceService.removeCustomTriggerPhrase(phrase);
    _saveCustomPhrases();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed phrase: "$phrase"'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _saveCustomPhrases() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final updatedSettings = settingsProvider.settings.copyWith(
      voiceTriggerPhrases: _customPhrases,
    );
    settingsProvider.updateSettings(updatedSettings);
  }

  void _testPhrase(String phrase) async {
    // Simulate voice detection for testing
    try {
      final result = await _voiceService.analyzeVoiceInput(phrase);
      if (!mounted) return;

      final message = result.isEmergency
          ? 'Emergency detected! ✅ (${(result.confidence * 100).toStringAsFixed(1)}%)'
          : 'No emergency detected ❌';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test result: $message'),
          backgroundColor: result.isEmergency
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Voice Phrases'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Voice Triggers',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add custom phrases that will trigger emergency mode when spoken. These work alongside the default phrases like "help me" and "emergency".',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Add new phrase section
            Text(
              'Add New Phrase',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phraseController,
                    decoration: InputDecoration(
                      hintText: 'Enter a custom trigger phrase...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.mic),
                    ),
                    onSubmitted: (_) => _addPhrase(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addPhrase,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Default phrases section
            Text(
              'Default Phrases (Built-in)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _voiceService.defaultTriggerPhrases.map((phrase) {
                return Chip(
                  label: Text(phrase),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  avatar: Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Custom phrases section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Custom Phrases',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_customPhrases.length} phrases',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom phrases list
            Expanded(
              child: _customPhrases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_off,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No custom phrases yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your own trigger phrases above',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _customPhrases.length,
                      itemBuilder: (context, index) {
                        final phrase = _customPhrases[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.mic,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              phrase,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () => _testPhrase(phrase),
                                  tooltip: 'Test phrase',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () => _removePhrase(phrase),
                                  tooltip: 'Remove phrase',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
