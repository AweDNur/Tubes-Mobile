import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetLocationPage extends StatefulWidget {
  const SetLocationPage({super.key});

  @override
  State<SetLocationPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<SetLocationPage> {
  String _username = '';

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAbsensiLocation();
  }

  LatLng _selectedLocation = _initialPosition;

  late GoogleMapController _mapController;

  static const LatLng _initialPosition = LatLng(-7.311269, 112.728885);

  static const double maxDistanceMeter = 3000;

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'] ?? user.displayName ?? 'User';
        });
      }
    } catch (_) {
      setState(() {
        _username = user.displayName ?? 'User';
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> _handleAbsensi(String type) async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      _showMessage('Izin lokasi ditolak');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );

    if (distance > maxDistanceMeter) {
      _showMessage(
        'Gagal $type\nJarak terlalu jauh (${(distance / 1000).toStringAsFixed(2)} KM)',
      );
      return;
    }

    // ✅ ABSEN BERHASIL
    _showMessage(
      '$type berhasil\nJarak ${(distance / 1000).toStringAsFixed(2)} KM',
    );

    // TODO: simpan ke Firebase
  }

  Future<void> _saveAbsensiLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('absensi')
          .set({
            'latitude': _selectedLocation.latitude,
            'longitude': _selectedLocation.longitude,
            'radius': maxDistanceMeter,
            'updatedBy': user.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _showMessage('Lokasi absensi berhasil disimpan');
    } catch (e) {
      _showMessage('Gagal menyimpan lokasi');
    }
  }

  Future<void> _loadAbsensiLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('absensi')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      _selectedLocation = LatLng(data['latitude'], data['longitude']);

      setState(() {});

      if (_mapReady) {
        _mapController.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
      }
    } catch (e) {
      debugPrint('Gagal load lokasi absensi: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// TOP BAR (AREA SENDIRI)
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: AssetImage('assets/avatar.jpg'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aplikasi Absensi Siswa',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _username.isNotEmpty ? _username : 'Memuat...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// MAP AREA
          Expanded(
            child: Stack(
              children: [
                /// GOOGLE MAP
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _initialPosition,
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('absensi'),
                      position: _selectedLocation,
                      infoWindow: const InfoWindow(title: 'Lokasi Absensi'),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onTap: (latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                    });
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapReady = true;
                  },
                ),

                /// BUTTON CARD (ABSEN)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 33,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E2ED6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              await _saveAbsensiLocation();
                            },
                            child: const Text(
                              'Set Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
