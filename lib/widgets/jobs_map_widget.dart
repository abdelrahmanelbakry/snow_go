import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/atomic_job.dart';
import '../models/service_type.dart';
import '../services/location_service.dart';

class JobsMapWidget extends StatefulWidget {
  final List<AtomicJob> jobs;
  final double height;
  final bool showCurrentLocation;

  const JobsMapWidget({
    super.key,
    required this.jobs,
    this.height = 200,
    this.showCurrentLocation = true,
  });

  @override
  State<JobsMapWidget> createState() => _JobsMapWidgetState();
}

class _JobsMapWidgetState extends State<JobsMapWidget> {
  GoogleMapController? _controller;
  final LocationService _locationService = LocationService();
  Set<Marker> _markers = {};
  LatLng _center = const LatLng(45.4215, -75.6972); // Default to Ottawa
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(JobsMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobs != widget.jobs) {
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location if requested
      if (widget.showCurrentLocation) {
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          _center = LatLng(position.latitude, position.longitude);
        }
      }

      await _updateMarkers();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _updateMarkers() async {
    final Set<Marker> markers = {};

    // Add current location marker if requested
    if (widget.showCurrentLocation) {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      }
    }

    // Add job location markers
    for (int i = 0; i < widget.jobs.length; i++) {
      final job = widget.jobs[i];
      try {
        final coordinates = await _locationService.getCoordinatesFromAddress(job.address);
        if (coordinates != null) {
          markers.add(
            Marker(
              markerId: MarkerId('job_${job.id}'),
              position: coordinates,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(job.status),
              ),
              infoWindow: InfoWindow(
                title: job.address,
                snippet: '${job.service.iconEmoji} ${job.service.name} - \$${job.price.toStringAsFixed(2)}',
              ),
            ),
          );
        }
      } catch (e) {
        // Skip jobs with invalid addresses
        continue;
      }
    }

    if (mounted) {
      setState(() => _markers = markers);
    }

    // Adjust camera to show all markers
    if (_controller != null && markers.isNotEmpty) {
      _fitMarkersInView(markers);
    }
  }

  double _getMarkerColor(JobStatus status) {
    switch (status) {
      case JobStatus.newRequest:
        return BitmapDescriptor.hueRed;
      case JobStatus.assigned:
        return BitmapDescriptor.hueOrange;
      case JobStatus.inProgress:
        return BitmapDescriptor.hueYellow;
      case JobStatus.completed:
        return BitmapDescriptor.hueGreen;
      case JobStatus.cancelled:
        return BitmapDescriptor.hueViolet;
    }
  }

  void _fitMarkersInView(Set<Marker> markers) {
    if (markers.isEmpty) return;

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      minLat = minLat > marker.position.latitude ? marker.position.latitude : minLat;
      maxLat = maxLat < marker.position.latitude ? marker.position.latitude : maxLat;
      minLng = minLng > marker.position.longitude ? marker.position.longitude : minLng;
      maxLng = maxLng < marker.position.longitude ? marker.position.longitude : maxLng;
    }

    _controller?.animateCamera(
      CameraUpdateExt.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error fallback UI if Google Maps fails to load
    if (_hasError) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              const Text(
                'Map temporarily unavailable',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Jobs: ${widget.jobs.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.jobs.isEmpty && !widget.showCurrentLocation) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No jobs to display on map',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            try {
              _controller = controller;
              if (_markers.isNotEmpty) {
                _fitMarkersInView(_markers);
              }
            } catch (e) {
              setState(() {
                _hasError = true;
              });
            }
          },
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 12.0,
          ),
          markers: _markers,
          myLocationEnabled: widget.showCurrentLocation,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }
}

// Extension to handle LatLngBounds camera updates
extension CameraUpdateExt on CameraUpdate {
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) {
    return CameraUpdate.newLatLngBounds(bounds, padding);
  }
}
