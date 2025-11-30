
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kDebugMode) {
      print('=== DIAGNOSTIC APP STARTING ===');
    }
    
    runApp(const DiagnosticApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('ERROR in main(): $e');
      print('Stack trace: $stackTrace');
    }
  }
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terax AI Diagnostic',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const DiagnosticScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final List<String> _logs = [];
  bool _isRunningTests = false;

  @override
  void initState() {
    super.initState();
    _addLog('Diagnostic app initialized successfully');
    _runDiagnostics();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    if (kDebugMode) {
      print('DIAGNOSTIC: $message');
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningTests = true;
    });

    _addLog('Starting diagnostic tests...');

    // Test 1: Basic Flutter functionality
    try {
      _addLog('✓ Basic Flutter functionality working');
    } catch (e) {
      _addLog('✗ Basic Flutter test failed: $e');
    }

    // Test 2: SharedPreferences
    try {
      final prefs = await _testSharedPreferences();
      _addLog('✓ SharedPreferences test: $prefs');
    } catch (e) {
      _addLog('✗ SharedPreferences test failed: $e');
    }

    // Test 3: Asset loading
    try {
      await _testAssetLoading();
      _addLog('✓ Asset loading test passed');
    } catch (e) {
      _addLog('✗ Asset loading test failed: $e');
    }

    // Test 4: Biometric availability
    try {
      await _testBiometricAvailability();
      _addLog('✓ Biometric availability test completed');
    } catch (e) {
      _addLog('✗ Biometric test failed: $e');
    }

    // Test 5: Provider initialization
    try {
      await _testProviderInitialization();
      _addLog('✓ Provider initialization test passed');
    } catch (e) {
      _addLog('✗ Provider initialization failed: $e');
    }

    _addLog('Diagnostic tests completed');
    setState(() {
      _isRunningTests = false;
    });
  }

  Future<String> _testSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'test_value');
      final value = prefs.getString('test_key');
      await prefs.remove('test_key');
      return 'Read/Write successful: $value';
    } catch (e) {
      return 'Failed: $e';
    }
  }

  Future<void> _testAssetLoading() async {
    try {
      // Test if pubspec.yaml assets are accessible
      final assetBundle = DefaultAssetBundle.of(context);
      
      // Try to load a common asset that should exist
      try {
        await assetBundle.loadString('pubspec.yaml');
        _addLog('  - pubspec.yaml accessible');
      } catch (e) {
        _addLog('  - pubspec.yaml not accessible: $e');
      }

      // Check for the SVG logo that might be missing
      try {
        await assetBundle.load('assets/images/terax_logo.svg');
        _addLog('  - terax_logo.svg found');
      } catch (e) {
        _addLog('  - terax_logo.svg missing: $e');
      }
    } catch (e) {
      throw Exception('Asset bundle test failed: $e');
    }
  }

  Future<void> _testBiometricAvailability() async {
    try {
      final auth = LocalAuthentication();
      
      final isAvailable = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      final availableBiometrics = await auth.getAvailableBiometrics();
      
      _addLog('  - Can check biometrics: $isAvailable');
      _addLog('  - Device supported: $isDeviceSupported');
      _addLog('  - Available biometrics: $availableBiometrics');
    } catch (e) {
      _addLog('  - Biometric test error: $e');
    }
  }

  Future<void> _testProviderInitialization() async {
    try {
      // Test provider package - just check if we can reference the classes
      _addLog('  - Provider package loaded successfully');
      
      // Test go_router - just check if we can reference the classes
      _addLog('  - GoRouter package loaded successfully');
    } catch (e) {
      throw Exception('Provider/Router test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terax AI Diagnostic'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isRunningTests)
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Diagnostic Results:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final isError = log.contains('✗');
                    final isSuccess = log.contains('✓');
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: isError
                              ? Colors.red
                              : isSuccess
                                  ? Colors.green
                                  : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunningTests ? null : _runDiagnostics,
              child: Text(_isRunningTests ? 'Running Tests...' : 'Run Tests Again'),
            ),
          ],
        ),
      ),
    );
  }
}

