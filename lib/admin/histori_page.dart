import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoriPage extends StatefulWidget {
  const HistoriPage({super.key});

  @override
  State<HistoriPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<HistoriPage> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: Column(
        children: [
          // ================= HEADER (DIPERTAHANKAN) =================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
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

          const SizedBox(height: 12),

          // ================= LIST RIWAYAT =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                RiwayatAbsensiCard(
                  nama: 'Nama Siswa',
                  hari: 'Senin, 15 Des 2025',
                  masuk: '08.00',
                  keluar: '13.00',
                ),
                RiwayatAbsensiCard(
                  nama: 'Nama Siswa',
                  hari: 'Senin, 15 Des 2025',
                  masuk: '08.00',
                  keluar: '13.00',
                ),
                RiwayatAbsensiCard(
                  nama: 'Nama Siswa',
                  hari: 'Senin, 15 Des 2025',
                  masuk: '08.00',
                  keluar: '13.00',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RiwayatAbsensiCard extends StatelessWidget {
  final String nama;
  final String hari;
  final String masuk;
  final String keluar;

  const RiwayatAbsensiCard({
    super.key,
    required this.nama,
    required this.hari,
    required this.masuk,
    required this.keluar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER CARD =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1F2DBD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Center(
              child: Text(
                'RIWAYAT ABSENSI - $nama',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hari,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                // ===== MASUK =====
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        masuk,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ===== KELUAR =====
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        keluar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
