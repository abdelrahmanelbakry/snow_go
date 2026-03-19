import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class MapPicker extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialLocation;
  final Function(String address, LatLng location) onLocationSelected;

  const MapPicker({
    super.key,
    this.initialAddress,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _controller;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _currentLocation = const LatLng(45.4215, -75.6972); // Default to Ottawa
  String _currentAddress = '';
  bool _isLoading = false;
  List<String> _searchSuggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    try {
      LatLng? location;
      String? address;

      if (widget.initialLocation != null) {
        location = widget.initialLocation;
        address = await _locationService.getAddressFromCoordinates(
          location!.latitude,
          location.longitude,
        );
      } else if (widget.initialAddress != null) {
        location = await _locationService.getCoordinatesFromAddress(widget.initialAddress!);
        address = widget.initialAddress;
      } else {
        // Try to get current location
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          location = LatLng(position.latitude, position.longitude);
          address = await _locationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
        }
      }

      if (location != null) {
        setState(() {
          _currentLocation = location!;
          _currentAddress = address ?? '';
          _searchController.text = _currentAddress;
        });

        // Move camera to location
        _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
      }
    } catch (e) {
      print('Error initializing location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapTap(LatLng location) async {
    setState(() {
      _currentLocation = location;
      _isLoading = true;
    });

    try {
      final address = await _locationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      setState(() {
        _currentAddress = address ?? 'Unknown location';
        _searchController.text = _currentAddress;
        _isLoading = false;
      });

      widget.onLocationSelected(_currentAddress, location);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error getting address: $e');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _searchSuggestions = []);
      return;
    }

    try {
      final suggestions = await _locationService.searchAddresses(query);
      setState(() => _searchSuggestions = suggestions);
    } catch (e) {
      print('Error searching addresses: $e');
    }
  }

  Future<void> _selectAddress(String address) async {
    setState(() {
      _isLoading = true;
      _searchSuggestions = [];
      _searchController.text = address;
    });

    try {
      final location = await _locationService.getCoordinatesFromAddress(address);
      if (location != null) {
        setState(() {
          _currentLocation = location;
          _currentAddress = address;
        });

        _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );

        widget.onLocationSelected(address, location);
      }
    } catch (e) {
      print('Error selecting address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF0E63F6),
        foregroundColor: Colors.white,
        actions: [
          if (_currentAddress.isNotEmpty)
            TextButton(
              onPressed: () {
                widget.onLocationSelected(_currentAddress, _currentLocation);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15.0,
            ),
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _currentLocation,
                infoWindow: InfoWindow(
                  title: 'Selected Location',
                  snippet: _currentAddress,
                ),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          ),

          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for an address...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _searchAddress,
                  ),
                ),

                // Search suggestions
                if (_searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(suggestion),
                          onTap: () => _selectAddress(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Current location info
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress.isNotEmpty 
                        ? _currentAddress 
                        : 'Tap on the map to select a location',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
