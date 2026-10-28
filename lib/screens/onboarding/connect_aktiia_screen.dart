import '../../l10n/l10n_ext.dart';
import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connect_garmin_screen.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFFFF8C00);

/// Sign-in for the Hilo (Aktiia) cloud, source of the cuffless BP readings.
class ConnectAktiiaScreen extends ConsumerStatefulWidget {
  const ConnectAktiiaScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectAktiiaScreen> createState() =>
      _ConnectAktiiaScreenState();
}

class _ConnectAktiiaScreenState extends ConsumerState<ConnectAktiiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
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
        MaterialPageRoute<void>(builder: (_) => const ConnectGarminScreen()),
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
      await ref
          .read(connectionActionsProvider)
          .signIn(
            ConnectionType.bloodPressure,
            _email.text.trim(),
            _password.text,
          );
      if (mounted) _next();
    } on ConnectionFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.l10n.connectionFailedCheckYourInternet);
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
        title: const OnboardingStepIndicator(current: 2, total: 6),
        actions: [
          TextButton(
            onPressed: _next,
            child: Text(
              context.l10n.skip,
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
                OnboardingDeviceHeader(
                  icon: Icons.monitor_heart_outlined,
                  color: _accent,
                  title: context.l10n.connectHiloService,
                  subtitle:
                      'Sign in with your Hilo account to import '
                      'continuous blood pressure data.',
                ),
                const SizedBox(height: 36),
                OnboardingInputLabel(context.l10n.email),
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
                OnboardingInputLabel(context.l10n.password),
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
                  validator: (v) => v == null || v.length < 4
                      ? context.l10n.passwordTooShort
                      : null,
                ),
                const SizedBox(height: 24),
                if (_error != null) OnboardingErrorBanner(_error!),
                OnboardingInfoBox(
                  context.l10n.theseCredentialsAreStoredEncrypted,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFF2A2A2A),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(context.l10n.connectHilo),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
