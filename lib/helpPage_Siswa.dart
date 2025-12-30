import 'package:flutter/material.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

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
            question: 'Cara Melihat Riwayat Absen Saya?',
            answer:
                'Semua Riwayat Absen Anda dapat dilihat pada halaman utama aplikasi.',
          ),
          _buildFaqItem(
            question: 'Cara Melakukan Absensi?',
            answer:
                '1. Masuk ke Halaman Absensi\n 2. Pilih Jenis Absensi\n 3. Tunggu Sampai muncul notifikasi absensi berhasil\n 4. Lihat Kembali ke halaman utama untuk memastikan absensi tercatat',
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
