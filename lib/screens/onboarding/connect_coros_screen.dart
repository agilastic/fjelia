import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connect_suunto_screen.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFF00A8E8);

class ConnectCorosScreen extends ConsumerStatefulWidget {
  const ConnectCorosScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectCorosScreen> createState() => _ConnectCorosScreenState();
}

class _ConnectCorosScreenState extends ConsumerState<ConnectCorosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _region = 'eu';
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _next() {
    if (widget.fromOnboarding) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConnectSuuntoScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(connectionActionsProvider)
          .signIn(
            ConnectionType.coros,
            _email.text.trim(),
            _password.text,
            region: _region,
          );
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = 'Login failed. Check your email and password.');
        return;
      }

      _next();
    } catch (_) {
      setState(
        () => _error = 'Connection failed. Check your credentials and internet connection.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFFCCCCCC)),
        title: const OnboardingStepIndicator(current: 4, total: 6),
        actions: [
          TextButton(
            onPressed: _next,
            child: const Text(
              'Skip',
              style: TextStyle(color: Color(0xFFCCCCCC)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const OnboardingDeviceHeader(
                  icon: Icons.watch_rounded,
                  color: _accent,
                  title: 'Connect Coros',
                  subtitle:
                      'Sign in with your Coros account to sync nightly '
                      'HRV, resting HR, VO₂max and sleep stages.',
                ),
                const SizedBox(height: 36),
                const OnboardingInputLabel('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: onboardingInputDecoration(
                    'you@example.com',
                    accent: _accent,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const OnboardingInputLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      onboardingInputDecoration(
                        '••••••••',
                        accent: _accent,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: _accent,
                        ),
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF888888),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                const OnboardingInputLabel('Region'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _region,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: onboardingInputDecoration('', accent: _accent)
                      .copyWith(
                        prefixIcon: const Icon(
                          Icons.public_outlined,
                          color: _accent,
                        ),
                      ),
                  items: const [
                    DropdownMenuItem(value: 'eu', child: Text('Europe')),
                    DropdownMenuItem(value: 'us', child: Text('United States')),
                    DropdownMenuItem(value: 'asia', child: Text('Asia')),
                  ],
                  onChanged: (v) => setState(() => _region = v ?? 'eu'),
                ),
                const SizedBox(height: 24),
                if (_error != null) OnboardingErrorBanner(_error!),
                const OnboardingInfoBox(
                  'Coros credentials are stored encrypted on your device. '
                  'Fjelia reads data directly from the Coros cloud API. This '
                  'uses the same API as the Coros Training Hub web app.',
                ),
                const SizedBox(height: 32),
                _PrimaryButton(
                  label: 'Connect Coros',
                  color: _accent,
                  loading: _loading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2A2A2A),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(label),
      ),
    );
  }
}
