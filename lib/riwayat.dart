import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  String _username = '';
  Map<String, Map<String, String>> _absensiData =
      {};

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await initializeDateFormatting('id_ID', null);
    await _loadUserData();
    await _loadAbsensi();
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

  Future<void> _loadAbsensi() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('absensi')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final Map<String, Map<String, String>> tempData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp == null) continue;

        final type = data['type'] as String? ?? '';
        final dateStr = DateFormat(
          'EEEE, dd MMM yyyy',
          'id_ID',
        ).format(timestamp.toDate());
        final timeStr = DateFormat('HH.mm').format(timestamp.toDate());

        if (!tempData.containsKey(dateStr)) {
          tempData[dateStr] = {'masuk': '-', 'keluar': '-'};
        }

        if (type.toLowerCase().contains('masuk')) {
          tempData[dateStr]!['masuk'] = timeStr;
        } else if (type.toLowerCase().contains('keluar')) {
          tempData[dateStr]!['keluar'] = timeStr;
        }
      }

      setState(() {
        _absensiData = tempData;
      });
    } catch (e) {
      debugPrint('Gagal load absensi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      body: Column(
        children: [
          // ================= HEADER =================
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
                    Text(
                      'Aplikasi Absensi Siswa',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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

          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1F2DBD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'RIWAYAT ABSENSI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: _absensiData.isEmpty
                        ? const Center(child: Text('Belum ada data absensi'))
                        : ListView(
                            padding: const EdgeInsets.all(14),
                            children: _absensiData.entries.map((entry) {
                              final date = entry.key;
                              final masuk = entry.value['masuk'] ?? '-';
                              final keluar = entry.value['keluar'] ?? '-';
                              return AbsensiItem(
                                hari: date,
                                masuk: masuk,
                                keluar: keluar,
                              );
                            }).toList(),
                          ),
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

class AbsensiItem extends StatelessWidget {
  final String hari;
  final String masuk;
  final String keluar;

  const AbsensiItem({
    super.key,
    required this.hari,
    required this.masuk,
    required this.keluar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hari, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Masuk', style: TextStyle(color: Colors.white)),
              Text(masuk, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Keluar', style: TextStyle(color: Colors.white)),
              Text(keluar, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
