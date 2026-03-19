import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/jobs_provider.dart';
import '../widgets/map_picker.dart';
import '../models/service_type.dart';
import 'booking_confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  static const route = '/booking';

  /// You can pass a preselected address (e.g., from Home) if you already have it.
  final String? initialAddress;

  const BookingScreen({super.key, this.initialAddress});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _form = GlobalKey<FormState>();

  // Address & map
  String? _address; // kept in sync with MapPicker

  // Schedule
  bool _scheduleNow = true;
  DateTime? _date;
  TimeOfDay? _time;

  // Add-on(s)
  bool _addonSalting = false;

  // Price & notes
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _address = widget.initialAddress;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String _scheduleSummary() {
    if (_scheduleNow) return 'As soon as possible';
    if (_date == null || _time == null) return 'Pick date & time';
    final h = _time!.hourOfPeriod.toString().padLeft(2, '0');
    final m = _time!.minute.toString().padLeft(2, '0');
    final ampm = _time!.period == DayPeriod.am ? 'AM' : 'PM';
    return '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')} • $h:$m $ampm';
    // Keep simple/robust; you can swap to intl for locales later.
  }

  bool _isValidPrice(String v) => RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v.trim());

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    if (!_scheduleNow && (_date == null || _time == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date and time.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final jobsProvider = Provider.of<AtomicJobsProvider>(context, listen: false);
      
      final user = authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Compose scheduled date
      final DateTime scheduledAt;
      if (_scheduleNow) {
        scheduledAt = DateTime.now();
      } else {
        final d = _date!;
        final t = _time!;
        scheduledAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      }

      // Create job via backend
      final result = await jobsProvider.addJob(
        customerId: user.uid,
        customerName: user.displayName ?? 'Unknown',
        address: _address!,
        service: ServiceType.driveway,
        scheduledAt: scheduledAt,
        price: double.parse(_priceCtrl.text.trim()),
        addonSalting: _addonSalting,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      
      if (result.isSuccess) {
        // Navigate to confirmation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              address: _address!,
              scheduledAt: scheduledAt,
              primaryService: 'Driveway',
              addonSalting: _addonSalting,
              price: double.tryParse(_priceCtrl.text.trim()),
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create job: ${result.error}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating job: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/snowgo_mark_white.png', height: 28),
            const SizedBox(width: 8),
            const Text('New Booking',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Map picker hero
              SizedBox(
                height: 200,
                child: MapPicker(
                  initialAddress: _address,
                  onLocationSelected: (address, location) {
                    setState(() => _address = address);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Address field (read-only, mirrors map)
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _address ?? ''),
                decoration: _decoration('Address', icon: Icons.location_on_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please pick an address from the map'
                    : null,
                onTap: () {
                  // Optional: scroll to map or open a search modal
                },
              ),
              const SizedBox(height: 16),

              // WHEN
              const Text('When',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _CardSection(
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      dense: true,
                      value: true,
                      groupValue: _scheduleNow,
                      onChanged: (v) => setState(() => _scheduleNow = v ?? true),
                      title: const Text('As soon as possible'),
                    ),
                    const Divider(height: 1),
                    RadioListTile<bool>(
                      dense: true,
                      value: false,
                      groupValue: _scheduleNow,
                      onChanged: (v) => setState(() => _scheduleNow = v ?? false),
                      title: const Text('Schedule for later'),
                      subtitle: !_scheduleNow
                          ? Text(_scheduleSummary(),
                          style: const TextStyle(color: Color(0xFF6B7280)))
                          : null,
                      secondary: !_scheduleNow
                          ? IconButton(
                        tooltip: 'Pick date',
                        onPressed: _pickDate,
                        icon: const Icon(Icons.event_outlined),
                      )
                          : null,
                    ),
                    if (!_scheduleNow)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.event_outlined),
                                label: Text(_date == null
                                    ? 'Pick date'
                                    : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(Icons.access_time),
                                label: Text(_time == null
                                    ? 'Pick time'
                                    : _time!.format(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ADD-ON
              const Text('Add-ons',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _CardSection(
                child: SwitchListTile.adaptive(
                  value: _addonSalting,
                  onChanged: (v) => setState(() => _addonSalting = v),
                  title: const Text('Salting'),
                  subtitle: const Text('Add salting to snow clearing'),
                ),
              ),
              const SizedBox(height: 16),

              // PRICE
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration('Price (CA\$)', icon: Icons.payments_outlined)
                    .copyWith(hintText: 'e.g. 45 or 45.00'),
                validator: (v) =>
                (v == null || !_isValidPrice(v)) ? 'Enter a valid price' : null,
              ),
              const SizedBox(height: 14),

              // NOTES
              TextFormField(
                controller: _notesCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: _decoration('Notes (optional)', icon: Icons.notes_outlined),
              ),
              const SizedBox(height: 22),

              // CTA
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.white)),
                  )
                      : const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0E63F6), width: 1.6),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}

/// Lightweight card shell for grouped controls
class _CardSection extends StatelessWidget {
  final Widget child;
  const _CardSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

/// Data you’ll pass to the next step / backend.
class JobRequest {
  final String address;
  final DateTime scheduledAt;
  final bool scheduleNow;
  final bool addonSalting;
  final double price;
  final String? notes;

  JobRequest({
    required this.address,
    required this.scheduledAt,
    required this.scheduleNow,
    required this.addonSalting,
    required this.price,
    this.notes,
  });

  @override
  String toString() {
    return 'JobRequest(address: $address, at: $scheduledAt, now: $scheduleNow, salting: $addonSalting, price: $price, notes: $notes)';
  }
}
