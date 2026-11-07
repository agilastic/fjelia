import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';
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
        setState(() => _error = context.l10n.loginFailedCheckYourEmail);
        return;
      }

      _next();
    } catch (_) {
      setState(
        () => _error = context.l10n.connectionFailedCheckYourCredentials,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: duo(0xFF111111, 0xFFF2F4F7),
      appBar: AppBar(
        leading: BackButton(color: duo(0xFFCCCCCC, 0xFF374151)),
        title: const OnboardingStepIndicator(current: 4, total: 6),
        actions: [
          TextButton(
            onPressed: _next,
            child: Text(
              context.l10n.skip,
              style: TextStyle(color: duo(0xFFCCCCCC, 0xFF374151)),
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
                OnboardingDeviceHeader(
                  icon: Icons.watch_rounded,
                  color: _accent,
                  title: context.l10n.connectCoros,
                  subtitle:
                      'Sign in with your Coros account to sync nightly '
                      'HRV, resting HR, VO₂max and sleep stages.',
                ),
                const SizedBox(height: 36),
                OnboardingInputLabel(context.l10n.email),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: fjInk),
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
                OnboardingInputLabel(context.l10n.password),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  style: TextStyle(color: fjInk),
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
                            color: duo(0xFF888888, 0xFF6B7280),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                OnboardingInputLabel(context.l10n.region),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _region,
                  dropdownColor: duo(0xFF1E1E1E, 0xFFFFFFFF),
                  style: TextStyle(color: fjInk, fontSize: 15),
                  decoration: onboardingInputDecoration('', accent: _accent)
                      .copyWith(
                        prefixIcon: Icon(Icons.public_outlined, color: _accent),
                      ),
                  items: [
                    DropdownMenuItem(
                      value: 'eu',
                      child: Text(context.l10n.europe),
                    ),
                    DropdownMenuItem(
                      value: 'us',
                      child: Text(context.l10n.unitedStates),
                    ),
                    DropdownMenuItem(
                      value: 'asia',
                      child: Text(context.l10n.asia),
                    ),
                  ],
                  onChanged: (v) => setState(() => _region = v ?? 'eu'),
                ),
                const SizedBox(height: 24),
                if (_error != null) OnboardingErrorBanner(_error!),
                OnboardingInfoBox(
                  context.l10n.corosCredentialsAreStoredEncrypted,
                ),
                const SizedBox(height: 32),
                OnboardingPrimaryButton(
                  label: context.l10n.connectCoros,
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
