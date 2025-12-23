import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF2E2ED6),
      ),
      body: _isPermissionGranted
          ? MobileScanner(
              onDetect: (barcode) {
                final String? code = barcode.barcodes.first.rawValue;

                if (code != null) {
                  Navigator.pop(context, code);
                }
              },
            )
          : _permissionDeniedView(),
    );
  }

  Widget _permissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Izin kamera diperlukan\nuntuk scan barcode',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _requestCameraPermission,
            child: const Text('Izinkan Kamera'),
          ),
        ],
      ),
    );
  }
}
