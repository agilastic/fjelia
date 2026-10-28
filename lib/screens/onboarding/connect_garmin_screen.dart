import '../../l10n/l10n_ext.dart';
import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connect_coros_screen.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFF4FC3F7);

/// Garmin Connect sign-in, with the two-factor code step when required.
class ConnectGarminScreen extends ConsumerStatefulWidget {
  const ConnectGarminScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectGarminScreen> createState() =>
      _ConnectGarminScreenState();
}

class _ConnectGarminScreenState extends ConsumerState<ConnectGarminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _mfaRequired = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _next() {
    if (widget.fromOnboarding) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConnectCorosScreen()),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final actions = ref.read(connectionActionsProvider);
    try {
      if (_mfaRequired) {
        await actions.verifyCode(_email.text.trim(), _code.text.trim());
      } else {
        await actions.signIn(
          ConnectionType.garmin,
          _email.text.trim(),
          _password.text,
        );
      }
      if (mounted) _next();
    } on VerificationRequired {
      setState(() => _mfaRequired = true);
    } on ConnectionFailure catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('[Garmin] sign-in failed: ${e.runtimeType}: $e\n$st');
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
        title: const OnboardingStepIndicator(current: 3, total: 6),
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
                  icon: Icons.watch_outlined,
                  color: _accent,
                  title: context.l10n.connectGarmin,
                  subtitle:
                      'Sign in with your Garmin Connect account to '
                      'import HRV, sleep, and activity data.',
                ),
                const SizedBox(height: 36),
                if (_mfaRequired)
                  _MfaSection(controller: _code)
                else ...[
                  OnboardingInputLabel(context.l10n.garminConnectEmail),
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
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_error != null) OnboardingErrorBanner(_error!),
                OnboardingInfoBox(
                  context.l10n.garminCredentialsAreStoredEncrypted,
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
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _mfaRequired
                                ? context.l10n.verifyMfaCode
                                : context.l10n.connectGarmin,
                          ),
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

class _MfaSection extends StatelessWidget {
  const _MfaSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accent.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withAlpha(80)),
          ),
          child: Row(
            children: [
              const Icon(Icons.smartphone_outlined, size: 20, color: _accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Garmin requires two-factor authentication. Check your '
                  'Garmin Connect app or email for the verification code.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: _accent, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OnboardingInputLabel(context.l10n.verificationCode),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 28,
              letterSpacing: 10,
            ),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            border: border(Colors.transparent, 0),
            enabledBorder: border(const Color(0xFF333333), 1),
            focusedBorder: border(_accent, 1.5),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? context.l10n.enterTheVerificationCode
              : null,
        ),
      ],
    );
  }
}
