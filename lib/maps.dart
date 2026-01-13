import 'dart:async';
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
  static const double maxDistanceMeter = 1000;

  StreamSubscription<DocumentSnapshot>? _lokasiListener;

  LatLng? _lokasiAbsensi;
  double _maxDistanceMeter = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenLokasiAbsensi();
  }

  @override
  void dispose() {
    _lokasiListener?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ===================== UTIL =====================
  String _getTodayDocId() {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '${user.uid}_$date';
  }

  String _formatJam(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Timestamp _todayTimestamp() {
    final now = DateTime.now();
    return Timestamp.fromDate(DateTime(now.year, now.month, now.day));
  }

  // ===================== LOAD USER =====================
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;
    setState(() {
      _username = doc['username'] ?? user.displayName ?? 'User';
    });
  }

  // ===================== REALTIME LOKASI =====================
  void _listenLokasiAbsensi() {
    _lokasiListener = FirebaseFirestore.instance
        .collection('settings')
        .doc('absensi')
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          if (!mounted) return; // ✅ PENTING

          final lat = doc['latitude'];
          final lng = doc['longitude'];

          setState(() {
            _lokasiAbsensi = LatLng(lat, lng);
            _maxDistanceMeter = doc['radius'].toDouble();
          });

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(_lokasiAbsensi!),
            );
          }
        });
  }

  // ===================== PERMISSION =====================
  Future<bool> _checkLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // ===================== ABSENSI =====================
  Future<void> _handleAbsensi(String type) async {
    if (_lokasiAbsensi == null) {
      _showMessage('Lokasi absensi belum tersedia');
      return;
    }

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
      _lokasiAbsensi!.latitude,
      _lokasiAbsensi!.longitude,
    );

    if (distance > _maxDistanceMeter) {
      _showMessage(
        'Gagal $type\nJarak terlalu jauh (${(distance / 1000).toStringAsFixed(2)} KM)',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final docId = _getTodayDocId();
    final docRef = FirebaseFirestore.instance.collection('absensi').doc(docId);
    final snap = await docRef.get();

    // ===== ABSEN MASUK =====
    if (type == 'Absen Masuk') {
      if (snap.exists && snap.data()?['jamMasuk'] != null) {
        _showMessage('Kamu sudah absen masuk hari ini');
        return;
      }

      await docRef.set({
        'uid': user.uid,
        'username': _username,
        'tanggal': _todayTimestamp(),
        'jamMasuk': _formatJam(DateTime.now()),
        'latMasuk': position.latitude,
        'lngMasuk': position.longitude,
        'status': 'hadir',
      }, SetOptions(merge: true));

      _showMessage('Absen Masuk berhasil');
    }

    // ===== ABSEN KELUAR =====
    if (type == 'Absen Keluar') {
      final freshSnap = await docRef.get(); // 🔥 ambil ulang

      if (!freshSnap.exists || freshSnap.data()?['jamMasuk'] == null) {
        _showMessage('Kamu belum absen masuk');
        return;
      }

      if (freshSnap.data()?['jamKeluar'] != null) {
        _showMessage('Kamu sudah absen keluar');
        return;
      }

      await docRef.update({
        'jamKeluar': _formatJam(DateTime.now()),
        'latKeluar': position.latitude,
        'lngKeluar': position.longitude,
      });

      _showMessage('Absen Keluar berhasil');
    }
  }

  // ===================== UI =====================
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
          // ===== HEADER =====
          SafeArea(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.jpg'),
              ),
              title: const Text('Aplikasi Absensi Siswa'),
              subtitle: Text(_username.isNotEmpty ? _username : 'Memuat...'),
            ),
          ),

          // ===== MAP =====
          Expanded(
            child: _lokasiAbsensi == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _lokasiAbsensi!,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('lokasi'),
                            position: _lokasiAbsensi!,
                            infoWindow: const InfoWindow(
                              title: 'Lokasi Absensi',
                            ),
                          ),
                        },
                        myLocationEnabled: true,
                        zoomControlsEnabled: false,
                        onMapCreated: (c) => _mapController = c,
                      ),

                      // ===== BUTTON =====
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _handleAbsensi('Absen Masuk'),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _handleAbsensi('Absen Keluar'),
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
