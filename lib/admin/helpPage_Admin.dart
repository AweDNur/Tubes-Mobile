import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF2E2ED6),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== FAQ TITLE =====
          Row(
            children: const [
              Icon(Icons.help_outline, size: 28),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAQ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== FAQ LIST =====
          _buildFaqItem(
            question: 'Cara Menambahkan Data Siswa?',
            answer:
                '1. Masuk ke Halaman Awal\n 2. Tekan Tombol "+" yang berwarna biru\n 3. Isi Pop dengan Data Siswa yang Valid\n 4. Tekan Tombol "Tambah"',
          ),
          _buildFaqItem(
            question: 'Cara Set Lokasi Absensi?',
            answer:
                '1. Masuk ke Halaman Set Lokasi\n 2. Pilih / Ketuk lokasi yang diinginkan\n 3. Pastikan lokasi yang dipilih dirasa sudah benar\n 4. Tekan Tombol "Simpan Lokasi"',
          ),
          _buildFaqItem(
            question: 'Cara Melihat Data Riwayat Absensi Para Siswa?',
            answer:
                '1. Masuk Halaman Profil Admin\n 2. Tekan Menu "Histori Absensi"\n 3. Lihat Data Riwayat Absensi Siswa yang Tercatat',
          ),
          _buildFaqItem(
            question: 'Aplikasi tidak berjalan semestinya?',
            answer:
                'Cobalah buka ulang aplikasi atau cek koneksi internet Anda.',
          ),
        ],
      ),
    );
  }

  static Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
