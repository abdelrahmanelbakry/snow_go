import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_type.dart';
import '../providers/jobs_provider.dart';
import '../widgets/snowgo_appbar.dart';

class JobFormScreen extends StatefulWidget {
  static const route = '/new-job';
  const JobFormScreen({super.key});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  DateTime? _when;
  ServiceType? _service;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<JobsProvider>().addJob(
      customerName: "Demo User", // mockup doesn’t show this field
      address: _addressCtrl.text.trim(),
      service: _service ?? ServiceType.driveway,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      scheduledAt: _when ?? DateTime.now(),
      notes: _notesCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
    preferredSize: const Size.fromHeight(96),
    child: AppBar(
    backgroundColor: Colors.blue,
    elevation: 0,
    titleSpacing: 0,
    title: Row(
    children: [
    const SizedBox(width: 16),
    Image.asset(
    'assets/snowgo_logo_white.png',
    height: 40,
    ),
    const SizedBox(width: 10),
    Text(
    'SnowGo',
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    ),
    ),
    ],
    ),
    actions: [
    Padding(
    padding: const EdgeInsets.only(right: 16),
    child: SizedBox(
    width: 28,
    height: 28,
    child: IconButton(
    padding: EdgeInsets.zero,
    icon: const Icon(Icons.notifications_none, size: 24),
    color: Colors.white,
    onPressed: () {},
    ),
    ),
    ),
    ],
    bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(
    height: 1,
    color: Colors.white.withOpacity(0.12),
    ),
    ),
    ),
    ),

    body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Enter details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(hintText: '1234 Main St'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(hintText: 'Apr 10, 2024'),
                onTap: () {
                  // TODO: show date picker
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceType>(
                value: _service,
                items: ServiceType.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                decoration: const InputDecoration(hintText: 'Service'),
                onChanged: (s) => setState(() => _service = s),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(hintText: 'Additional information'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Price'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E63F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submit,
                  child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
