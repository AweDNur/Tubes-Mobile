import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoriPage extends StatefulWidget {
  const HistoriPage({super.key});

  @override
  State<HistoriPage> createState() => _AbsensiPageState();
}

enum RekapMode { semua, satu }

class _AbsensiPageState extends State<HistoriPage> {
  String _username = '';
  String _searchNama = '';
  DateTime? _selectedDate;

  late final Stream<QuerySnapshot> _absensiStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Stream untuk ambil semua dokumen absensi terbaru
    _absensiStream = FirebaseFirestore.instance
        .collection('absensi')
        .orderBy('tanggal', descending: true)
        .snapshots();
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
          // HEADER
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // 🔍 SEARCH NAMA (KIRI)
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => _openRekapDialog(context),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama siswa...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchNama = value.toLowerCase();
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // 📅 PILIH TANGGAL
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.date_range),
                    tooltip: 'Pilih tanggal',
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // ❌ RESET TANGGAL
                if (_selectedDate != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Reset tanggal',
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // LIST ABSENSI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _absensiStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada histori absen'));
                }

                final filteredDocs = docs.where((doc) {
                  final nama = (doc['username'] ?? '').toString().toLowerCase();

                  final tanggalTs = doc['tanggal'] as Timestamp?;
                  final tanggal = tanggalTs?.toDate();

                  final matchNama = nama.contains(_searchNama);

                  final matchTanggal = _selectedDate == null
                      ? true
                      : tanggal != null &&
                            tanggal.year == _selectedDate!.year &&
                            tanggal.month == _selectedDate!.month &&
                            tanggal.day == _selectedDate!.day;

                  return matchNama && matchTanggal;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Belum ada histori absen'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;

                    final username = data['username'] ?? 'Tanpa Nama';
                    final jamMasuk = data['jamMasuk'] ?? '-';
                    final jamKeluar = data['jamKeluar'] ?? '-';

                    final tanggalTs = data['tanggal'] as Timestamp?;
                    final tanggal = tanggalTs?.toDate() ?? DateTime.now();

                    final hari =
                        '${tanggal.day.toString().padLeft(2, '0')}-'
                        '${tanggal.month.toString().padLeft(2, '0')}-'
                        '${tanggal.year}';

                    return RiwayatAbsensiCard(
                      nama: username,
                      hari: hari,
                      masuk: jamMasuk,
                      keluar: jamKeluar,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//rekap data
void _showRekapDialog(BuildContext context, List<Siswa> siswaList) {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  RekapMode mode = RekapMode.semua;
  String? selectedStudentUid;
  String? selectedStudentName;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Rekap Absensi'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BULAN
                  const Text('Bulan'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_namaBulan(index + 1)),
                      );
                    }),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMonth = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // TAHUN
                  const Text('Tahun'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    items: List.generate(8, (index) {
                      final year = 2023 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedYear = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // MODE REKAP
                  const Text('Mode Rekap'),
                  RadioListTile<RekapMode>(
                    title: const Text('Semua Siswa'),
                    value: RekapMode.semua,
                    groupValue: mode,
                    onChanged: (value) {
                      setDialogState(() {
                        mode = value!;
                        selectedStudentUid = null;
                        selectedStudentName = null;
                      });
                    },
                  ),
                  RadioListTile<RekapMode>(
                    title: const Text('Satu Siswa'),
                    value: RekapMode.satu,
                    groupValue: mode,
                    onChanged: (value) {
                      setDialogState(() {
                        mode = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 8),

                  // DROPDOWN SISWA (CONDITIONAL)
                  const Text('Nama Siswa'),
                  const SizedBox(height: 4),
                  IgnorePointer(
                    ignoring: mode == RekapMode.semua,
                    child: Opacity(
                      opacity: mode == RekapMode.semua ? 0.5 : 1,
                      child: DropdownButtonFormField<String>(
                        hint: const Text('Pilih siswa'),
                        value: selectedStudentUid,
                        items: siswaList.map((siswa) {
                          return DropdownMenuItem(
                            value: siswa.uid,
                            child: Text(siswa.nama),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedStudentUid = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BUTTONS
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () {
                  // VALIDASI
                  if (mode == RekapMode.satu && selectedStudentUid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih siswa terlebih dahulu'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  // NANTI: PANGGIL GENERATE PDF
                  debugPrint('Rekap: $selectedMonth/$selectedYear');
                  debugPrint('Mode: $mode');
                  debugPrint('Siswa: $selectedStudentName');
                },
                child: const Text('GENERATE'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _namaBulan(int bulan) {
  const bulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return bulanIndo[bulan - 1];
}

class Siswa {
  final String uid;
  final String nama;

  Siswa({required this.uid, required this.nama});
}

Future<List<Siswa>> _fetchSiswa() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('roles', isEqualTo: 'siswa')
      .orderBy('username')
      .get();

  return snapshot.docs.map((doc) {
    return Siswa(uid: doc.id, nama: doc['username'] ?? 'Tanpa Nama');
  }).toList();
}

Future<void> _openRekapDialog(BuildContext context) async {
  try {
    final siswaList = await _fetchSiswa();

    if (!context.mounted) return;

    _showRekapDialog(context, siswaList);
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gagal memuat data siswa')));
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
          // HEADER CARD
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

                // MASUK
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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

                // KELUAR
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
