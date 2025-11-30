import 'package:flutter/material.dart';

class VoicePhraseRecorderWidget extends StatefulWidget {
  const VoicePhraseRecorderWidget({super.key});

  @override
  State<VoicePhraseRecorderWidget> createState() =>
      VoicePhraseRecorderWidgetState();
}

class VoicePhraseRecorderWidgetState extends State<VoicePhraseRecorderWidget> {
  bool isRecording = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Record Voice Phrase'),
      trailing: IconButton(
        icon: Icon(isRecording ? Icons.mic_off : Icons.mic),
        onPressed: () {
          setState(() {
            isRecording = !isRecording;
          });
        },
      ),
    );
  }
}
