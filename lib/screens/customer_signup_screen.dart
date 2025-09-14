import 'package:flutter/material.dart';

class CustomerSignupScreen extends StatefulWidget {
  static const route = '/customer-signup';
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0E63F6), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    // TODO: integrate backend / Firebase create user
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            // Logo (same as login)
            Column(
              children: [
                Image.asset('assets/logo.png', height: 80),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Create your account',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign up to book and track jobs.',
              style: TextStyle(color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                    decoration: _dec('Full name', icon: Icons.person_outline),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _email,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                      return ok ? null : 'Enter a valid email';
                    },
                    decoration: _dec('Email', icon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _password,
                    obscureText: _obscure1,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v == null || v.length < 8) return 'At least 8 characters';
                      if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
                        return 'Use letters and numbers';
                      }
                      return null;
                    },
                    decoration: _dec(
                      'Password',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                        icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure2,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => v == _password.text ? null : 'Passwords do not match',
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _dec(
                      'Confirm password',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                        icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Sign up button
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Sign up'),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Divider with "or"
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Color(0xFF9CA3AF))),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE5E7EB), height: 1)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Social buttons
                  _SocialButton(
                    label: 'Sign up with Google',
                    asset: 'assets/google_g.png',
                    onPressed: () {
                      // TODO: Google sign-in
                    },
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    label: 'Sign up with Apple',
                    asset: 'assets/apple_logo.png',
                    onPressed: () {
                      // TODO: Apple sign-in
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'By signing up you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ",
                          style: TextStyle(color: Color(0xFF6B7280))),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // back to login
                        child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String asset;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.asset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, height: 20),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
