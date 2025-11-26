import 'package:autovibe/services/native_service.dart';
import 'package:autovibe/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  final _nativeService = NativeService();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isChecking) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await _nativeService.checkDndPermission();
    if (granted) {
      widget.onPermissionGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.do_not_disturb_on, size: 40, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 32),
              const Text(
                'Grant Do Not Disturb\nAccess',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Auto Vibe needs Do Not Disturb access to automatically switch your phone to and from vibration mode according to your schedule, ensuring it works seamlessly even when the screen is off.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _isChecking = true);
                    await _nativeService.requestDndPermission();
                  },
                  child: const Text('Allow Access'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
