import '../../providers/connection_actions_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'onboarding_widgets.dart';

const _accent = Color(0xFFD0011B);

/// Polar AccessLink OAuth in the system browser (callback scheme `fjelia`).
class ConnectPolarScreen extends ConsumerStatefulWidget {
  const ConnectPolarScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<ConnectPolarScreen> createState() => _ConnectPolarScreenState();
}

class _ConnectPolarScreenState extends ConsumerState<ConnectPolarScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(connectionActionsProvider).authorize();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ConnectionFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error = 'Connection failed. Check your internet connection.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(leading: const BackButton(color: Color(0xFFCCCCCC))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const OnboardingDeviceHeader(
                icon: Icons.watch_rounded,
                color: _accent,
                title: 'Connect Polar',
                subtitle:
                    'Sign in with your Polar Flow account to sync sleep '
                    'stages, nightly HRV, resting HR and workout data.',
              ),
              const SizedBox(height: 36),
              if (_error != null) OnboardingErrorBanner(_error!),
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
                  onPressed: _loading ? null : _connect,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Sign in with Polar Flow'),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Syncs sleep stages · HRV · resting HR · workouts · steps',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
              ),
              const SizedBox(height: 28),
              const _FlowHistoryLogin(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional Flow login for older history and sending planned workouts.
class _FlowHistoryLogin extends ConsumerStatefulWidget {
  const _FlowHistoryLogin();

  @override
  ConsumerState<_FlowHistoryLogin> createState() => _FlowHistoryLoginState();
}

class _FlowHistoryLoginState extends ConsumerState<_FlowHistoryLogin> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _savedEmail;
  String? _message;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    ref.read(connectionActionsProvider).polarFlowEmail().then((e) {
      if (mounted) setState(() => _savedEmail = e);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(connectionActionsProvider)
          .savePolarFlowLogin(_email.text, _password.text);
      _password.clear();
      if (!mounted) return;
      setState(() {
        _savedEmail = _email.text.trim();
        _failed = false;
        _message =
            'Signed in. Planned workouts can now be sent to Polar. '
            'Older sessions are imported with the next full history sync.';
      });
    } on ConnectionFailure catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _message = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _message = 'Could not reach Polar. Check your connection.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    await ref.read(connectionActionsProvider).removePolarFlowLogin();
    if (mounted) {
      setState(() {
        _savedEmail = null;
        _message = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF999999);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FLOW LOGIN (OPTIONAL)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save your Polar Flow login to send planned workouts and import '
            'sessions older than 30 days. It stays in this device\'s keychain '
            'and is sent only to Polar. Send a workout from its planner sheet, '
            'then sync Polar Flow to your watch. Check that your Polar '
            'heart-rate zones match Fjelia.',
            style: TextStyle(fontSize: 12, height: 1.4, color: muted),
          ),
          const SizedBox(height: 12),
          if (_savedEmail != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text('Saved for $_savedEmail')),
                TextButton(onPressed: _remove, child: const Text('Remove')),
              ],
            ),
          ] else ...[
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(labelText: 'Polar e-mail'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Polar password'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check and save'),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(
                fontSize: 12,
                color: _failed ? Colors.orangeAccent : Colors.greenAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
