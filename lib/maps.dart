import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  String _username = '';
  bool _canAbsenMasuk = true;
  bool _canAbsenKeluar = true;

  GoogleMapController? _mapController;
  static const double maxDistanceMeter = 3000;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkTodayAbsensi();
  }

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

  Future<void> _checkTodayAbsensi() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('absensi')
        .where('uid', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: todayStart)
        .where('timestamp', isLessThanOrEqualTo: todayEnd)
        .get();

    if (!mounted) return;
    setState(() {
      _canAbsenMasuk = !snapshot.docs.any(
        (doc) => (doc.data()['type'] as String).toLowerCase().contains('masuk'),
      );
      _canAbsenKeluar = !snapshot.docs.any(
        (doc) =>
            (doc.data()['type'] as String).toLowerCase().contains('keluar'),
      );
    });
  }

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> _handleAbsensi(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if ((type == 'Absen Masuk' && !_canAbsenMasuk) ||
        (type == 'Absen Keluar' && !_canAbsenKeluar)) {
      _showMessage(
        'Sudah absen ${type.contains('Masuk') ? 'masuk' : 'keluar'} hari ini',
      );
      return;
    }

    final docSettings = await FirebaseFirestore.instance
        .collection('settings')
        .doc('absensi')
        .get();
    final data = docSettings.data();
    if (data == null || data['latitude'] == null || data['longitude'] == null) {
      _showMessage('Lokasi absensi belum tersedia');
      return;
    }

    final LatLng absensiLocation = LatLng(data['latitude'], data['longitude']);

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
      absensiLocation.latitude,
      absensiLocation.longitude,
    );

    if (distance > maxDistanceMeter) {
      _showMessage(
        'Gagal $type\nJarak terlalu jauh (${(distance / 1000).toStringAsFixed(2)} KM)',
      );
      return;
    }

    await FirebaseFirestore.instance.collection('absensi').add({
      'uid': user.uid,
      'username': _username,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    await _checkTodayAbsensi();

    _showMessage(
      '$type berhasil\nJarak ${(distance / 1000).toStringAsFixed(2)} KM',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TOP BAR
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      const Text(
                        'Aplikasi Absensi Siswa',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _username.isNotEmpty ? _username : 'Memuat...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // MAP AREA
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('settings')
                      .doc('absensi')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final lat = data['latitude'] ?? -7.311269;
                    final lng = data['longitude'] ?? 112.728885;
                    final position = LatLng(lat, lng);

                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: position,
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('absensi'),
                          position: position,
                          infoWindow: const InfoWindow(title: 'Lokasi Absensi'),
                        ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLng(position),
                        );
                      },
                    );
                  },
                ),

                // BUTTON CARD
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
                            onPressed: () => _handleAbsensi('Absen Masuk'),
                            child: const Text(
                              'Absen Masuk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            onPressed: () => _handleAbsensi('Absen Keluar'),
                            child: const Text(
                              'Absen Keluar',
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
