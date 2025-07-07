import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../models/vehicle_model.dart';
import '../controllers/vehicle_controller.dart';

class QRCodePage extends StatefulWidget {
  final VehicleModel vehicle;
  final VoidCallback? onVehicleUpdated;

  const QRCodePage({
    super.key,
    required this.vehicle,
    this.onVehicleUpdated,
  });

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  final VehicleController _vehicleController = VehicleController();
  final TextEditingController _qrContentController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  late VehicleModel _currentVehicle;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _qrContentController.text = _currentVehicle.qrContent;
  }

  @override
  void dispose() {
    _qrContentController.dispose();
    super.dispose();
  }

  Future<void> _updateQRContent() async {
    if (_qrContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod içeriği boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // QR içeriğini güncelle
      final updatedVehicle = _currentVehicle.copyWith(
        qrContent: _qrContentController.text.trim(),
      );

      // Veritabanını güncelle
      await _vehicleController.updateVehicle(updatedVehicle);

      setState(() {
        _currentVehicle = updatedVehicle;
        _isEditing = false;
        _isLoading = false;
      });

      // Callback'i çağır
      widget.onVehicleUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR kod içeriği güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareQRCode() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // QR kod widget'ını capture et
      RenderRepaintBoundary boundary = 
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Temporary dosya oluştur
      final directory = await getTemporaryDirectory();
      final fileName = 'QR_${_currentVehicle.name}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Ayrıca Downloads klasörüne de kaydet (Android için)
      if (Platform.isAndroid) {
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            final downloadFile = File('${downloadsDir.path}/$fileName');
            await downloadFile.writeAsBytes(pngBytes);
          }
        } catch (e) {
          // Downloads'a kaydetme başarısız olursa devam et
          print('Downloads klasörüne kaydetme hatası: $e');
        }
      }

      // Paylaş (Android paylaşım menüsünde dosya da görünecek)
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'QR Kod - ${_currentVehicle.name}\n\nAraç: ${_currentVehicle.name}\nPlaka: ${_currentVehicle.licensePlate}',
        subject: 'QR2Cars - ${_currentVehicle.name} QR Kodu',
      );

      setState(() {
        _isLoading = false;
      });

      // İndirme başarılı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR kod paylaşıldı ve Downloads klasörüne kaydedildi'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paylaşım hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void _resetToDefault() {
    final defaultContent = 'Araç: ${_currentVehicle.name}\nPlaka: ${_currentVehicle.licensePlate}\nSahip: QR2Cars Kullanıcısı';
    setState(() {
      _qrContentController.text = defaultContent;
    });
  }

  Future<void> _refreshQRCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Rastgele QR kod içeriği oluştur
      final now = DateTime.now();
      final randomId = now.millisecondsSinceEpoch.toString().substring(7);
      final newContent = '''QR2Cars Digital Araç Kartı 🚗

Araç: ${_currentVehicle.name}
Plaka: ${_currentVehicle.licensePlate}
Kod: #${randomId}
Tarih: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}

Sahip: QR2Cars Kullanıcısı
Durum: Aktif ✅

Bu QR kod ${now.day}/${now.month}/${now.year} tarihinde oluşturulmuştur.
QR2Cars uygulaması ile oluşturuldu.''';

      // QR içeriğini güncelle
      final updatedVehicle = _currentVehicle.copyWith(
        qrContent: newContent,
      );

      // Veritabanını güncelle
      await _vehicleController.updateVehicle(updatedVehicle);

      setState(() {
        _currentVehicle = updatedVehicle;
        _qrContentController.text = newContent;
        _isLoading = false;
      });

      // Callback'i çağır
      widget.onVehicleUpdated?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR kod yenilendi! Yeni kod: #$randomId'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR kod yenileme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          '${_currentVehicle.name} - QR Kod',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QR Kod Kartı
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Araç Bilgileri
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentVehicle.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Plaka: ${_currentVehicle.licensePlate}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // QR Kod
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: _currentVehicle.qrContent,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                     ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Düzenleme Alanı
            if (_isEditing) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Kod İçeriğini Düzenle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _qrContentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'QR kod içeriğini buraya yazın...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateQRContent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Güncelle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Eylem Butonları
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Paylaş ve İndir Butonu (Birleşik)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _shareQRCode,
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text(
                          'Paylaş ve İndir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Yenile Butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _refreshQRCode,
                        icon: const Icon(Icons.autorenew, size: 20),
                        label: const Text(
                          'Yeni QR Kod Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Bilgi Metni
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Paylaş butonuna basarak QR kodu hem paylaşabilir hem de cihazınıza indirebilirsiniz.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 