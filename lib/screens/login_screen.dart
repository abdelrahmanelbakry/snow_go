import 'package:flutter/material.dart';
import 'package:snow_go/screens/root_nav.dart';
import 'provider_signup_screen.dart';
import 'customer_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    Navigator.pushReplacementNamed(context, RootNav.route);
    //
    // if (!(_form.currentState?.validate() ?? false)) return;
    // setState(() => _loading = true);
    // // TODO: Integrate your auth (Firebase Auth, etc.)
    // await Future.delayed(const Duration(milliseconds: 800));
    // if (!mounted) return;
    // setState(() => _loading = false);
    // On success: Navigator.pushReplacementNamed(context, HomeScreen.route);
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
            const SizedBox(height: 8),
            // Logo + wordmark
            Column(
              children: [
                // Replace with your transparent PNG/SVG
                Image.asset('assets/logo_transparent_2.png', height: 250)
                //,
              //  const SizedBox(height: 8)
              ],
            ),
            //const SizedBox(height: 28),

            Form(
              key: _form,
              child: Column(
                children: [
                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                      return ok ? null : 'Enter a valid email';
                    },
                    decoration: _input('Email'),
                  ),
                  const SizedBox(height: 14),
                  // Password
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    onFieldSubmitted: (_) => _login(),
                    decoration: _input('Password').copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Login button
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            _DividerWithText(text: 'or'),
            const SizedBox(height: 14),

            // Google button
            _SocialButton(
              label: 'Sign in with Google',
              asset: 'assets/google_g.png',
              onPressed: () {
                // TODO: Google sign-in
              },
            ),
            const SizedBox(height: 12),

            // Apple button
            _SocialButton(
              label: 'Sign in with Apple',
              asset: 'assets/apple_logo.png',
              onPressed: () {
                // TODO: Apple sign-in
              },
            ),

            const SizedBox(height: 20),
        // Bottom links
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don’t have an account? ",
                    style: TextStyle(color: Color(0xFF6B7280))),
                TextButton(
                  onPressed: () {
                     Navigator.pushNamed(context, CustomerSignupScreen.route);
                  },
                  child: const Text('Sign up',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                 Navigator.pushNamed(context, ProviderSignupScreen.route);
              },
              child: const Text(
                'Sign up as a service provider',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E63F6),
                ),
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
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

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: const Color(0xFFE5E7EB)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(color: Color(0xFF9CA3AF))),
        ),
        line,
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String asset;
  final VoidCallback onPressed;

  const _SocialButton({required this.label, required this.asset, required this.onPressed});

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
