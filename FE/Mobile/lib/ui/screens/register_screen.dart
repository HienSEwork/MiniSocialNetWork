import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../data/providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final copy = AppCopy.of(context);
    FocusScope.of(context).unfocus();
    final error = await context.read<AuthProvider>().register(
      _email.text,
      _password.text,
      _name.text,
    );
    if (!mounted) return;
    if (error == null) {
      showResultMessage(context, copy.registerSuccess);
      context.pop();
    } else {
      showResultMessage(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final copy = AppCopy.of(context);
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton.filledTonal(
              tooltip: copy.back,
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            copy.createProfile,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 9),
          Text(
            copy.registerSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _name,
            enabled: !auth.isLoading,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: copy.displayName,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            enabled: !auth.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            enabled: !auth.isLoading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
            decoration: InputDecoration(
              labelText: copy.password,
              helperText: copy.passwordHelp,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? copy.showPassword : copy.hidePassword,
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: auth.isLoading ? null : _register,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Text(copy.createAccount),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            copy.safeUseNote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
