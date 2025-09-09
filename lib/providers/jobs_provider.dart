import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/job.dart';
import '../models/service_type.dart';

class JobsProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<Job> _jobs = [];

  JobsProvider() {
    // Seed for design review
    _jobs.addAll([
      Job(
        id: _uuid.v4(),
        customerName: 'Sarah Nolan',
        address: '24 Winterberry Ave',
        service: ServiceType.driveway,
        price: 45.00,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        status: JobStatus.newRequest,
        notes: 'Driveway is steep; bring extra salt.',
      ),
      Job(
        id: _uuid.v4(),
        customerName: 'Mike Turner',
        address: '17 Frost Lane',
        service: ServiceType.salting,
        price: 25.50,
        scheduledAt: DateTime.now().add(const Duration(hours: 4, minutes: 30)),
        status: JobStatus.assigned,
      ),
    ]);
  }

  List<Job> get jobs =>
      List.unmodifiable(_jobs..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));

  void addJob({
    required String customerName,
    required String address,
    required ServiceType service,
    required double price,
    required DateTime scheduledAt,
    String? notes,
  }) {
    final job = Job(
      id: _uuid.v4(),
      customerName: customerName,
      address: address,
      service: service,
      price: price,
      scheduledAt: scheduledAt,
      notes: notes,
    );
    _jobs.add(job);
    notifyListeners();
  }

  void updateStatus(String id, JobStatus status) {
    final i = _jobs.indexWhere((j) => j.id == id);
    if (i == -1) return;
    _jobs[i] = _jobs[i].copyWith(status: status);
    notifyListeners();
  }

  Job? byId(String id) => _jobs.firstWhere((j) => j.id == id, orElse: () => null as Job);
}
