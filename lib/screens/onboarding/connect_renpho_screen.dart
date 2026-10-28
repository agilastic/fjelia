import '../../l10n/l10n_ext.dart';
import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_widgets.dart';

const _accent = Color(0xFF9C27B0);

/// Renpho cloud sign-in (last step of the device chain).
class ConnectRenphoScreen extends ConsumerStatefulWidget {
  const ConnectRenphoScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectRenphoScreen> createState() =>
      _ConnectRenphoScreenState();
}

class _ConnectRenphoScreenState extends ConsumerState<ConnectRenphoScreen> {
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

  void _next() => Navigator.of(context).pop();

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(connectionActionsProvider)
          .signIn(ConnectionType.bodyScale, _email.text.trim(), _password.text);
      if (mounted) _next();
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
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFFCCCCCC)),
        title: const OnboardingStepIndicator(current: 6, total: 6),
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
                  icon: Icons.monitor_weight_rounded,
                  color: _accent,
                  title: context.l10n.connectRenpho,
                  subtitle:
                      'Sign in with your Renpho account to import body '
                      'weight and composition data.',
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
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Enter a valid email'
                      : null,
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
                  validator: (v) => v == null || v.isEmpty
                      ? context.l10n.passwordRequired
                      : null,
                ),
                const SizedBox(height: 24),
                if (_error != null) OnboardingErrorBanner(_error!),
                OnboardingInfoBox(
                  context.l10n.renphoCredentialsAreStoredEncrypted,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
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
                        : Text(context.l10n.connectRenpho),
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
