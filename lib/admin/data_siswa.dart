import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataSiswa extends StatefulWidget {
  const DataSiswa({super.key});

  @override
  State<DataSiswa> createState() => _DataSiswaState();
}

class _DataSiswaState extends State<DataSiswa> {
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

      // ================= FLOATING BUTTON (+) =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1F2DBD),
        onPressed: () {
          // TODO: tambah siswa
        },
        child: const Icon(Icons.add, size: 30, color: Colors.white,),
      ),

      body: Column(
        children: [
          // ================= HEADER (TETAP) =================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
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

          const SizedBox(height: 10),

          // ================= LIST DATA SISWA =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              itemCount: 7, // dummy
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: index % 2 == 0
                        ? const Color(0xFFE0E0E0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // ===== TEXT =====
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Nama Siswa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Roles : siswa',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== EDIT =====
                      Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // TODO: edit siswa
                          },
                        ),
                      ),

                      // ===== DELETE =====
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // TODO: hapus siswa
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}