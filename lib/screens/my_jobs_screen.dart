
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/provider_location_service.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override Widget build(BuildContext context) {
    final uid = 'homeowner1'; // demo placeholder
    return Scaffold(
      appBar: AppBar(title: const Text("My Jobs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').where('homeownerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No jobs yet."));
          return ListView.builder(itemCount: docs.length, itemBuilder: (context,i){
            final job = docs[i];
            final status = job['status'];
            return Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${job['address']} - \$${job['price']}", style: const TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
              Text("Size: ${job['size']} | Time: ${job['time']}"),
              const SizedBox(height:8),
              if (status == 'open') const Text('Status: Waiting for provider'),
              if (status == 'accepted' || status == 'scheduled' || status == 'en_route') Text('Status: ${status}'),
              const SizedBox(height:8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('jobs').doc(job.id).collection('counterOffers').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapOffers) {
                  if (!snapOffers.hasData) return const SizedBox.shrink();
                  final offers = snapOffers.data!.docs;
                  if (offers.isEmpty) return const SizedBox.shrink();
                  return Column(children: offers.map((od){
                    final o = od.data() as Map<String,dynamic>;
                    final proposed = o['proposedStart'] != null ? DateTime.tryParse(o['proposedStart']) : null;
                    final createdMs = o['createdAt'] != null ? (o['createdAt'] as Timestamp).millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch;
                    final expired = (DateTime.now().millisecondsSinceEpoch - createdMs) > 10 * 60 * 1000;
                    final offerStatus = (expired && o['status'] == 'pending') ? 'expired' : o['status'];
                    return Card(margin: const EdgeInsets.symmetric(vertical:4), child: ListTile(
                      title: Text('Provider: ${o['providerId']}'),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Offer: \$${o['price']} - Status: $offerStatus'),
                        if (proposed != null) Text('Proposed start: ${proposed.toLocal()}'),
                      ]),
                      trailing: offerStatus == 'pending' ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () async {
                          // Accept offer
                          final proposedStart = proposed ?? DateTime.now().toUtc();
                          final nowDt = DateTime.now().toUtc();
                          String newStatus;
                          if (proposedStart.isBefore(nowDt.add(const Duration(minutes:10)))) {
                            newStatus = 'en_route';
                            final svc = ProviderLocationService();
                            await svc.startTracking(jobId: job.id);
                          } else {
                            newStatus = 'scheduled';
                            final wait = proposedStart.difference(nowDt) - const Duration(minutes:10);
                            Future.delayed(wait, () async {
                              final svc = ProviderLocationService();
                              await svc.startTracking(jobId: job.id);
                              await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({'status':'en_route'});
                            });
                          }
                          await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({
                            'price': o['price'],
                            'providerId': o['providerId'],
                            'status': newStatus,
                            'scheduledStart': proposedStart.toIso8601String(),
                          });
                          await od.reference.update({'status':'accepted'});
                          await FirebaseFirestore.instance.collection('notifications').add({
                            'to': o['providerId'],
                            'title': 'Counter Offer Accepted',
                            'body': 'Your offer has been accepted.',
                            'timestamp': DateTime.now().millisecondsSinceEpoch,
                            'jobId': job.id,
                          });
                        }),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () async { await od.reference.update({'status':'declined'}); }),
                      ]) : null,
                    ));
                  }).toList());
                },
              ),
            ])));
          });
        },
      ),
    );
  }
}
