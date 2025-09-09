import 'package:flutter/material.dart';

class ProviderSignupScreen extends StatefulWidget {
  static const route = '/provider-signup';
  const ProviderSignupScreen({super.key});

  @override
  State<ProviderSignupScreen> createState() => _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends State<ProviderSignupScreen> {
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _business = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  // Multi-select service types
  static const _allServices = <String>[
    'Driveway clearing',
    'Salting'
  ];
  final Set<String> _selected = {'Driveway clearing'};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _business.dispose();
    _phone.dispose();
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
    final ok = _form.currentState?.validate() ?? false;
    if (!ok) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service type')),
      );
      return;
    }
    setState(() => _loading = true);
    // TODO: integrate your backend / Firebase createUser + profile
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
            // Logo (same structure as login)
            Column(
              children: [
                Image.asset('assets/logo.png', height: 120)
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Join as a Service Provider',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your business and start accepting snow removal jobs.',
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
                    controller: _business,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter business name' : null,
                    decoration: _dec('Business name', icon: Icons.store_outlined),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phone,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 7)
                        ? 'Enter a valid phone'
                        : null,
                    decoration: _dec('Phone number', icon: Icons.phone_outlined),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Service type(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ServiceTypeChips(
                    all: _allServices,
                    selected: _selected,
                    onChanged: (label) => setState(() {
                      if (_selected.contains(label)) {
                        _selected.remove(label);
                      } else {
                        _selected.add(label);
                      }
                    }),
                  ),

                  const SizedBox(height: 16),

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

                  SizedBox(
                    width: double.infinity,
                    height: 56,
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
                          : const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'By signing up you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 18),

                  Column(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Already have an account? Log in',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigator.pushNamed(context, SignupScreen.route); // customer signup
                        },
                        child: const Text('Sign up as a customer instead',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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

class _ServiceTypeChips extends StatelessWidget {
  final List<String> all;
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  const _ServiceTypeChips({
    required this.all,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((label) {
        final isSelected = selected.contains(label);
        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? blue : const Color(0xFF374151),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(label),
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected ? const Color(0xFFD6E4FF) : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFFE6F0FF), // subtle blue fill
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
      }).toList(),
    );
  }
}
