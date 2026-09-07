import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/post_auth.dart';
import '../providers/auth_provider.dart' as local;
import '../services/auth_service.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _verificationId;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final authService = context.read<AuthService>();

    try {
      await authService.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Rare auto-retrieval path.
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            await context.read<local.AuthProvider>().refreshAfterExternalSignIn();
            await navigateAfterAuthenticated(context);
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _error = e.message ?? e.code;
            _busy = false;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _busy = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId ??= verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _confirm() async {
    final id = _verificationId;
    if (id == null) {
      setState(() => _error = 'Verification not ready yet.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await context.read<local.AuthProvider>().signInWithPhoneCode(
            verificationId: id,
            smsCode: _codeController.text.trim(),
          );
      if (!mounted) return;
      await navigateAfterAuthenticated(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter SMS code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Code sent to ${widget.phoneNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SMS code',
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify & continue'),
            ),
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: const Text('Resend code'),
            ),
          ],
        ),
      ),
    );
  }
}