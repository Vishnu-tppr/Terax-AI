import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/emergency_message_service.dart';

/// Emergency Message Demo Widget - Shows all available templates and generated messages
class EmergencyMessageDemo extends StatefulWidget {
  const EmergencyMessageDemo({super.key});

  @override
  State<EmergencyMessageDemo> createState() => _EmergencyMessageDemoState();
}

class _EmergencyMessageDemoState extends State<EmergencyMessageDemo> {
  String _selectedEmergencyType = 'personal_safety';
  EmergencyMessage? _generatedMessage;
  bool _isGenerating = false;

  final Map<String, String> _emergencyTypeNames = {
    'accident': '🚗 Accident Alert',
    'medical_emergency': '🏥 Medical Emergency',
    'personal_safety': '⚠️ Personal Safety Threat',
    'fire_emergency': '🔥 Fire Emergency',
    'trapped_stuck': '🆘 Stuck/Trapped Situation',
    'stalking': '👁️ Stalking/Following',
    'domestic_violence': '🏠 Domestic Violence',
    'child_danger': '👶 Child in Danger',
    'mental_health_crisis': '🧠 Mental Health Crisis',
    'human_trafficking': '🚨 Human Trafficking',
    'general_emergency': '🚨 General Emergency',
  };

  @override
  void initState() {
    super.initState();
    _generateMessage();
  }

  Future<void> _generateMessage() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final message =
          await EmergencyMessageService.instance.generateEmergencyMessage(
        emergencyType: _selectedEmergencyType,
        currentLocation: '123 Main Street, Downtown, City 12345',
        latitude: 40.7128,
        longitude: -74.0060,
        userName: 'Sarah Johnson',
        additionalContext: {
          'confidence_score': 85,
          'threat_level': 'HIGH',
          'voice_analysis': 'Distress detected in voice patterns',
          'behavioral_indicators': 'Unusual location deviation detected',
        },
      );

      setState(() {
        _generatedMessage = message;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Message Templates'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildEmergencyTypeSelector(),
            const SizedBox(height: 24),
            if (_isGenerating) _buildLoadingIndicator(),
            if (!_isGenerating && _generatedMessage != null) ...[
              _buildMessagePreview(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: Colors.red.shade600, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'TeraxAI Emergency Message System',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Dynamic emergency message templates with multi-channel delivery (SMS, WhatsApp, Email). Select an emergency type to see the generated messages.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Emergency Type:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedEmergencyType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _emergencyTypeNames.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEmergencyType = value;
                  });
                  _generateMessage();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating emergency messages...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagePreview() {
    if (_generatedMessage == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildMessageCard(
          'SMS Message',
          _generatedMessage!.smsMessage,
          Icons.sms,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildMessageCard(
          'WhatsApp Message',
          _generatedMessage!.whatsappMessage,
          Icons.chat,
          Colors.green.shade700,
        ),
        const SizedBox(height: 16),
        _buildEmailCard(),
      ],
    );
  }

  Widget _buildMessageCard(
      String title, String message, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _copyToClipboard(message),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCard() {
    if (_generatedMessage == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Email Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      _copyToClipboard(_generatedMessage!.emailMessage.subject),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy subject to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Subject:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _generatedMessage!.emailMessage.subject,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Email Body:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _generatedMessage!.emailMessage.htmlBody,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Actions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testSMSDelivery,
                    icon: const Icon(Icons.sms),
                    label: const Text('Test SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testWhatsAppDelivery,
                    icon: const Icon(Icons.chat),
                    label: const Text('Test WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testEmailDelivery,
                icon: const Icon(Icons.email),
                label: const Text('Test Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  Future<void> _testSMSDelivery() async {
    if (_generatedMessage == null) return;

    try {
      final result =
          await EmergencyMessageService.instance.sendEmergencyMessage(
        message: _generatedMessage!,
        phoneNumbers: ['1234567890'],
        emailAddresses: [],
        sendSMS: true,
        sendWhatsApp: false,
        sendEmail: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result.success ? 'SMS test successful!' : 'SMS test failed'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SMS test error: $e')),
        );
      }
    }
  }

  Future<void> _testWhatsAppDelivery() async {
    if (_generatedMessage == null) return;

    try {
      final result =
          await EmergencyMessageService.instance.sendEmergencyMessage(
        message: _generatedMessage!,
        phoneNumbers: ['1234567890'],
        emailAddresses: [],
        sendSMS: false,
        sendWhatsApp: true,
        sendEmail: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? 'WhatsApp test successful!'
                : 'WhatsApp test failed'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp test error: $e')),
        );
      }
    }
  }

  Future<void> _testEmailDelivery() async {
    if (_generatedMessage == null) return;

    try {
      final result =
          await EmergencyMessageService.instance.sendEmergencyMessage(
        message: _generatedMessage!,
        phoneNumbers: [],
        emailAddresses: ['test@example.com'],
        sendSMS: false,
        sendWhatsApp: false,
        sendEmail: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? 'Email test successful!'
                : 'Email test failed'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email test error: $e')),
        );
      }
    }
  }
}
