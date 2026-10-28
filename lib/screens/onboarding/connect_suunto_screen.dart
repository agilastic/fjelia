import '../../l10n/l10n_ext.dart';
import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connect_health_screen.dart';
import 'onboarding_widgets.dart';

const _accent = Color(0xFFCC1624);

/// Suunto sign-in: phone number → SMS PIN (same flow as the Suunto app).
class ConnectSuuntoScreen extends ConsumerStatefulWidget {
  const ConnectSuuntoScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectSuuntoScreen> createState() =>
      _ConnectSuuntoScreenState();
}

class _ConnectSuuntoScreenState extends ConsumerState<ConnectSuuntoScreen> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  bool _smsSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _next() {
    if (widget.fromOnboarding) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConnectHealthScreen()),
      );
    }
  }

  Future<void> _sendSms() async {
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    if (phone.isEmpty || !email.contains('@')) {
      setState(() => _error = context.l10n.enterYourPhoneNumberWith);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ref.read(connectionActionsProvider).requestSms(phone);
      if (!mounted) return;
      setState(() {
        _smsSent = ok;
        if (!ok) {
          _error = context.l10n.couldNotSendSmsCheck;
        }
      });
    } catch (e) {
      setState(() => _error = context.l10n.errorE(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final pin = _pin.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = context.l10n.enterThePinFromThe);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(connectionActionsProvider)
          .verifySms(_phone.text.trim(), pin, email: _email.text.trim());
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = context.l10n.incorrectPinPleaseTryAgain);
        return;
      }

      _next();
    } catch (e) {
      setState(() => _error = context.l10n.errorE(e));
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
        title: const OnboardingStepIndicator(current: 5, total: 6),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              OnboardingDeviceHeader(
                icon: Icons.watch_rounded,
                color: _accent,
                title: context.l10n.connectSuunto,
                subtitle:
                    'Sign in with your Suunto account to sync sleep, '
                    'recovery, HRV and activity data.',
              ),
              const SizedBox(height: 36),
              if (!_smsSent) ...[
                OnboardingInputLabel(context.l10n.phoneNumber),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: onboardingInputDecoration(
                    '+49 123 456 7890',
                    accent: _accent,
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingInputLabel(context.l10n.suuntoAccountEmail),
                const SizedBox(height: 8),
                TextField(
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
                const SizedBox(height: 6),
                Text(
                  context.l10n.theEmailIsUsedFor,
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
              ] else ...[
                Text(
                  context.l10n.smsSentToTrim(_phone.text.trim()),
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                OnboardingInputLabel(context.l10n.enterPinFromSms),
                const SizedBox(height: 8),
                TextField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 10,
                  ),
                  decoration: onboardingInputDecoration(
                    '------',
                    accent: _accent,
                    prefixIcon: const Icon(Icons.lock_outline, color: _accent),
                  ).copyWith(counterText: ''),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _sendSms,
                    child: Text(
                      context.l10n.resendSms,
                      style: TextStyle(color: _accent),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_error != null) OnboardingErrorBanner(_error!),
              OnboardingInfoBox(context.l10n.suuntoUsesSmsVerificationSame),
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
                  onPressed: _loading ? null : (_smsSent ? _verify : _sendSms),
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
                          _smsSent
                              ? context.l10n.verifyConnect
                              : context.l10n.sendSmsCode,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
