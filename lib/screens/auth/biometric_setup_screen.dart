import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:terax_ai_app/providers/settings_provider.dart';
import 'package:terax_ai_app/services/biometric_auth_service.dart';
import 'package:terax_ai_app/widgets/pin_input_widget.dart';

class BiometricSetupScreen extends StatefulWidget {
  final bool isInitialSetup;
  final VoidCallback? onComplete;

  const BiometricSetupScreen({
    super.key,
    this.isInitialSetup = false,
    this.onComplete,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService.instance;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinSetup = false;
  bool _showPinSetup = false;
  String _setupStep = 'check'; // check, biometric, pin, complete
  List<BiometricType> _availableBiometrics = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _biometricService.initialize();
      final availability = await _biometricService.checkAvailability();
      final enabled = await _biometricService.isBiometricEnabled();
      final pinSetup = await _biometricService.isPinSetup();

      setState(() {
        _biometricAvailable = availability.isAvailable;
        _availableBiometrics = availability.availableTypes;
        _biometricEnabled = enabled;
        _pinSetup = pinSetup;
        _setupStep = _biometricAvailable ? 'biometric' : 'pin';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking biometric availability: $e';
        _setupStep = 'pin';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enableBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _biometricService.authenticate(
        reason: 'Enable biometric authentication for secure access',
      );

      if (result.isAuthenticated) {
        await _biometricService.setBiometricEnabled(true);

        // Update settings provider
        if (mounted) {
          final settingsProvider =
              Provider.of<SettingsProvider>(context, listen: false);
          await settingsProvider.updateBiometricAuth(true);
        }

        setState(() {
          _biometricEnabled = true;
          _setupStep = 'pin';
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Biometric authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error enabling biometric authentication: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupPin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _biometricService.setupPin(pin);

      if (success) {
        setState(() {
          _pinSetup = true;
          _setupStep = 'complete';
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to setup PIN. Please ensure it\'s 4-6 digits.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error setting up PIN: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _completeSetup() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Setup'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 32),
                  _buildCurrentStep(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(1, _setupStep != 'check'),
        _buildStepLine(_setupStep == 'pin' || _setupStep == 'complete'),
        _buildStepDot(2, _setupStep == 'complete'),
      ],
    );
  }

  Widget _buildStepDot(int step, bool isCompleted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              )
            : Text(
                '$step',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_setupStep) {
      case 'biometric':
        return _buildBiometricStep();
      case 'pin':
        return _showPinSetup ? _buildPinInputStep() : _buildPinSetupStep();
      case 'complete':
        return _buildCompleteStep();
      default:
        return _buildCheckingStep();
    }
  }

  Widget _buildCheckingStep() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking biometric availability...'),
        ],
      ),
    );
  }

  Widget _buildBiometricStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enable Biometric Authentication',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your device supports ${_availableBiometrics.map((type) => _getBiometricTypeName(type)).join(', ')}. '
          'Enable biometric authentication for quick and secure access.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _setupStep = 'pin';
                  });
                },
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _enableBiometric,
                child: const Text('Enable'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinSetupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setup Security PIN',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Set up a 4-6 digit PIN as a backup authentication method. '
          'This PIN will be used when biometric authentication is not available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showPinSetup = true;
            });
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Setup PIN'),
        ),
        const SizedBox(height: 16),
        if (!widget.isInitialSetup)
          TextButton(
            onPressed: _completeSetup,
            child: const Text('Skip for now'),
          ),
      ],
    );
  }

  Widget _buildPinInputStep() {
    return PinInputWidget(
      title: 'Create Security PIN',
      subtitle: 'Enter a 4-6 digit PIN for backup authentication',
      pinLength: 4,
      onPinEntered: _setupPin,
      onCancel: () {
        setState(() {
          _showPinSetup = false;
        });
      },
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Icon(
          Icons.security,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Security Setup Complete!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your security settings have been configured successfully. '
          'You can now use ${[
            if (_biometricEnabled) 'biometric authentication',
            if (_pinSetup) 'PIN',
          ].join(' and ')} '
          'authentication to access secure features.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _completeSetup,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris Recognition';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}
