import 'package:flutter/material.dart';
import 'histori_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = '';

  String _photoUrl = '';
  bool _loadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data();
    setState(() {
      _username = data?['username'] ?? 'User';
      _photoUrl = data?['photoUrl'] ?? '';
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _loadingPhoto = true);

    try {
      final file = File(image.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      final uploadTask = await ref.putFile(file);

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'photoUrl': downloadUrl,
        }, SetOptions(merge: true));

        setState(() {
          _photoUrl = downloadUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
    } finally {
      setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// HEADER BIRU
          Container(
            height: 160,
            width: double.infinity,
            color: const Color(0xFF2E2ED6),
          ),

          /// FOTO PROFIL (OVERLAP)
          Transform.translate(
            offset: const Offset(0, -50),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _photoUrl.isNotEmpty
                        ? NetworkImage(_photoUrl)
                        : const AssetImage('assets/avatar.jpg')
                              as ImageProvider,
                  ),
                ),
                if (_loadingPhoto)
                  const Positioned.fill(child: CircularProgressIndicator()),
              ],
            ),
          ),

          /// NAMA
          Transform.translate(
            offset: const Offset(0, -40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2ED6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _username.isNotEmpty ? _username : 'Memuat...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// MENU LIST
          _menuItem(
            icon: Icons.photo_camera,
            title: 'Ubah Foto Profil',
            onTap: () {
              _pickAndUploadPhoto();
            },
          ),
          _menuItem(
            icon: Icons.qr_code_scanner,
            title: 'Histori Absensi',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoriPage()),
              );

              if (result != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Hasil Scan: $result')));
              }
            },
          ),
          _menuItem(icon: Icons.help_outline, title: 'Help', onTap: () {}),

          const SizedBox(height: 10),

          /// LOGOUT (WARNA BIRU)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2ED6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  _logout(context);
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// WIDGET MENU ITEM
  /// =========================
  static Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}