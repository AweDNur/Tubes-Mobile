import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetLocationPage extends StatefulWidget {
  const SetLocationPage({super.key});

  @override
  State<SetLocationPage> createState() => _SetLocationPageState();
}

class _SetLocationPageState extends State<SetLocationPage> {
  String _username = '';
  GoogleMapController? _mapController;

  LatLng? _selectedLocation;
  double _radius = 1000;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAbsensiLocation();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _username = doc['username'];
      });
    }
  }

  Future<void> _loadAbsensiLocation() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('absensi')
        .get();

    if (doc.exists) {
      setState(() {
        _selectedLocation = LatLng(doc['latitude'], doc['longitude']);
        _radius = doc['radius'].toDouble();
        _loading = false;
      });
    } else {
      // default pertama kali
      setState(() {
        _selectedLocation = const LatLng(-7.311269, 112.728885);
        _loading = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedLocation == null) return;

    await FirebaseFirestore.instance.collection('settings').doc('absensi').set({
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'radius': _radius,
      'updatedBy': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokasi absensi berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.jpg'),
              ),
              title: const Text('Set Lokasi Absensi'),
              subtitle: Text(_username),
            ),
          ),

          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('lokasi_absensi'),
                  position: _selectedLocation!,
                ),
              },
              onTap: (latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E2ED6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saveLocation,
                  child: const Text(
                    'Simpan Lokasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
