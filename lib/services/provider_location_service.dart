
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderLocationService {
  Timer? _timer;
  final int intervalSeconds;
  final _locations = FirebaseFirestore.instance.collection('locations');

  ProviderLocationService({this.intervalSeconds = 5});

  Future<void> startTracking({String? jobId}) async => goOnline(jobId: jobId);

  Future<void> goOnline({String? jobId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever || p == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    await _locations.doc(user.uid).set({
      'status': 'en_route',
      'jobId': jobId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _sendLocation(jobId: jobId);

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _sendLocation(jobId: jobId);
    });
  }

  Future<void> stopTracking({bool remove=false}) async => goOffline(remove: remove);

  Future<void> goOffline({bool remove=false}) async {
    _timer?.cancel();
    _timer = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _locations.doc(user.uid).set({
        'status': 'offline',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (remove) {
        await _locations.doc(user.uid).delete().catchError((_){});
      }
    }
  }

  Future<void> _sendLocation({String? jobId}) async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _locations.doc(uid).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
        if (jobId != null) 'jobId': jobId,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
