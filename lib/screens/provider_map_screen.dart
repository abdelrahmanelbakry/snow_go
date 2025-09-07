
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProviderMapScreen extends StatefulWidget {
  final String providerId;
  final String jobId;
  const ProviderMapScreen({super.key, required this.providerId, required this.jobId});
  @override State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  final locs = FirebaseFirestore.instance.collection('locations');
  Marker? providerMarker;
  GoogleMapController? mapController;
  StreamSubscription<DocumentSnapshot>? _sub;

  @override void initState() {
    super.initState();
    _sub = locs.doc(widget.providerId).snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String,dynamic>;
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      final pos = LatLng(lat, lng);
      setState(() {
        providerMarker = Marker(markerId: MarkerId(widget.providerId), position: pos, infoWindow: const InfoWindow(title: 'Provider'));
      });
      mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    });
  }

  @override void dispose() {
    _sub?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final initial = CameraPosition(target: LatLng(47.5, -52.7), zoom: 12);
    final markers = providerMarker != null ? {providerMarker!} : <Marker>{};
    return Scaffold(appBar: AppBar(title: const Text('Provider Location')), body: GoogleMap(initialCameraPosition: initial, markers: markers, onMapCreated: (c) => mapController = c, myLocationEnabled: true));
  }
}
