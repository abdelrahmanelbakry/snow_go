import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _busy = false;
  String? _err;

  Future<void> _signup() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _err = null; });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signUp(
      _email.text.trim(),
      _password.text.trim(),
      _name.text.trim(),
      _selectedRole,
    );
    
    if (success) {
      if (!mounted) return;
      // AuthWrapper will handle navigation automatically
      Navigator.of(context).pop();
    } else {
      setState(() { _err = authProvider.error; });
    }
    
    setState(() { _busy = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Create account")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (v) => (v==null || v.trim().isEmpty) ? "Enter your name" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v==null || !v.contains('@')) ? "Enter a valid email" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (v) => (v==null || v.length<6) ? "Min 6 characters" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      decoration: const InputDecoration(labelText: "Confirm password"),
                      obscureText: true,
                      validator: (v) => (v != _password.text) ? "Passwords do not match" : null,
                    ),
                    const SizedBox(height: 16),
                    // Role Selection
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'I am a:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          RadioListTile<UserRole>(
                            title: const Text('Customer'),
                            subtitle: const Text('I need snow clearing services'),
                            value: UserRole.customer,
                            groupValue: _selectedRole,
                            onChanged: (value) => setState(() => _selectedRole = value!),
                          ),
                          RadioListTile<UserRole>(
                            title: const Text('Service Provider'),
                            subtitle: const Text('I provide snow clearing services'),
                            value: UserRole.provider,
                            groupValue: _selectedRole,
                            onChanged: (value) => setState(() => _selectedRole = value!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_err != null) Text(_err!, style: TextStyle(color: cs.error)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _signup,
                        child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text("Create ${_selectedRole == UserRole.customer ? 'Customer' : 'Provider'} Account"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
