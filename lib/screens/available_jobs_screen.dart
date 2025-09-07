
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailableJobsScreen extends StatelessWidget {
  const AvailableJobsScreen({super.key});

  Future<void> _makeCounterOffer(BuildContext context, String jobId, num currentPrice) async {
    final priceController = TextEditingController(text: currentPrice.toString());
    final proposedController = TextEditingController(text: DateTime.now().toUtc().toIso8601String());
    await showDialog(context: context, builder: (context){
      return AlertDialog(
        title: const Text("Make Counter Offer"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Your offer (\$)")),
          const SizedBox(height:8),
          TextField(controller: proposedController, decoration: const InputDecoration(labelText: "Proposed start (ISO) e.g. 2025-09-07T18:30:00Z")),
        ]),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? 'provider1';
            final amount = double.tryParse(priceController.text.trim()) ?? currentPrice.toDouble();
            final docRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
            await docRef.collection('counterOffers').add({
              'providerId': uid,
              'price': amount,
              'proposedStart': proposedController.text.trim(),
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) Navigator.pop(context);
          }, child: const Text("Submit")),
        ],
      );
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Jobs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').where('status', isEqualTo: 'open').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No jobs available"));
          return ListView.builder(itemCount: docs.length, itemBuilder: (context,i){
            final job = docs[i];
            return Card(margin: const EdgeInsets.all(8), child: ListTile(
              title: Text("${job['address']} - \$${job['price']}"),
              subtitle: Text("Size: ${job['size']} | Time: ${job['time']}"),
              trailing: Wrap(spacing:8, children: [
                ElevatedButton(onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'provider1';
                  await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({'status':'accepted','providerId':uid});
                }, child: const Text("Accept")),
                OutlinedButton(onPressed: ()=> _makeCounterOffer(context, job.id, job['price']), child: const Text("Counter")),
              ],),
            ));
          });
        },
      ),
    );
  }
}
