import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../data/providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final error = await context.read<AuthProvider>().login(
      _email.text,
      _password.text,
    );
    if (!mounted || error == null) return;
    showResultMessage(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final copy = AppCopy.of(context);
    return AuthShell(
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.welcomeBack,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 9),
            Text(
              copy.loginSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: auth.isLoading
                  ? null
                  : () {
                      _email.text = 'demo01@minisocial.local';
                      _password.text = 'Password123!';
                    },
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 19),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Chạm để dùng tài khoản demo · Password123!',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
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
              onSubmitted: (_) => _login(),
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: copy.password,
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => showForgotPasswordSheet(context, _email.text),
                child: Text(copy.forgotPassword),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: auth.isLoading ? null : _login,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(copy.login),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(copy.or),
                ),
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : auth.continueAsGuest,
              icon: const Icon(Icons.explore_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(copy.exploreAsGuest),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(copy.noAccount),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(copy.createAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showForgotPasswordSheet(
  BuildContext context,
  String initialEmail,
) async {
  final auth = context.read<AuthProvider>();
  final email = TextEditingController(text: initialEmail.trim());
  final token = TextEditingController();
  final password = TextEditingController();
  var resetToken = '';
  var requesting = false;
  var resetting = false;
  var obscure = true;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Forgot password',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: requesting || resetting
                    ? null
                    : () async {
                        setSheetState(() => requesting = true);
                        final result = await auth.requestPasswordReset(
                          email.text,
                        );
                        if (!sheetContext.mounted) return;
                        setSheetState(() {
                          requesting = false;
                          if (result != null && result.length > 30) {
                            resetToken = result;
                            token.text = result;
                          }
                        });
                        showResultMessage(
                          sheetContext,
                          result != null && result.length > 30
                              ? 'Reset token da tao, hay nhap mat khau moi.'
                              : result ?? 'Hay kiem tra email reset password.',
                          error: result == null,
                        );
                      },
                icon: requesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.key_rounded),
                label: const Text('Lay reset token'),
              ),
              if (resetToken.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  resetToken,
                  maxLines: 3,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: token,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reset token',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: obscure,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    tooltip: obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setSheetState(() => obscure = !obscure),
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: resetting
                    ? null
                    : () async {
                        setSheetState(() => resetting = true);
                        final error = await auth.resetPassword(
                          email: email.text,
                          token: token.text,
                          newPassword: password.text,
                        );
                        if (!sheetContext.mounted) return;
                        setSheetState(() => resetting = false);
                        if (error == null) {
                          Navigator.pop(sheetContext);
                          showResultMessage(
                            context,
                            'Da dat lai mat khau. Dang nhap lai bang mat khau moi.',
                          );
                        } else {
                          showResultMessage(sheetContext, error, error: true);
                        }
                      },
                icon: resetting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Reset password'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
