import '../../theme/fjelia_style.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_widgets.dart';

const _accent = Color(0xFFFF6B1A);

/// Signs in to MyWhoosh, whose indoor rides then come in with every sync.
class ConnectMyWhooshScreen extends ConsumerStatefulWidget {
  const ConnectMyWhooshScreen({super.key});

  @override
  ConsumerState<ConnectMyWhooshScreen> createState() =>
      _ConnectMyWhooshScreenState();
}

class _ConnectMyWhooshScreenState extends ConsumerState<ConnectMyWhooshScreen> {
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

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(connectionActionsProvider)
          .signIn(ConnectionType.myWhoosh, _email.text.trim(), _password.text);
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = context.l10n.loginFailedCheckYourEmail);
        return;
      }
      Navigator.of(context).pop();
    } on SignedInElsewhere {
      setState(() => _error = context.l10n.myWhooshSignedInElsewhere);
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
      appBar: AppBar(leading: BackButton(color: duo(0xFFCCCCCC, 0xFF374151))),
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
                  icon: Icons.directions_bike_rounded,
                  color: _accent,
                  title: context.l10n.connectMyWhoosh,
                  subtitle: context.l10n.myWhooshSubtitle,
                ),
                const SizedBox(height: 36),
                OnboardingInputLabel(context.l10n.email),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: TextStyle(color: fjInk),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? context.l10n.email : null,
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
                  validator: (v) =>
                      (v ?? '').isEmpty ? context.l10n.password : null,
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
                const SizedBox(height: 24),
                if (_error != null) OnboardingErrorBanner(_error!),
                OnboardingInfoBox(context.l10n.myWhooshCredentialsInfo),
                const SizedBox(height: 32),
                OnboardingPrimaryButton(
                  label: context.l10n.connectMyWhoosh,
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
