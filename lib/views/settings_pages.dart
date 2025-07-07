import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/notification_model.dart';
import 'qr_code_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Profil Ayarları Sayfası
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isPhoneVerified = false;
  String? _storedPhone;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Mevcut kullanıcı bilgilerini yükle
    final currentUser = _authController.currentUser;
    _nameController.text = currentUser?.displayName ?? '';
    
    // Telefon numarasını SharedPreferences'tan yükle
    final prefs = await SharedPreferences.getInstance();
    _storedPhone = prefs.getString('user_phone');
    _isPhoneVerified = prefs.getBool('phone_verified') ?? false;
    
    if (_storedPhone != null) {
      _phoneController.text = _storedPhone!;
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('İsim alanı boş olamaz', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      
      if (user != null) {
        // İsmi güncelle
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        
        // Telefon numarasını kaydet
        if (_phoneController.text.trim().isNotEmpty) {
          await prefs.setString('user_phone', _phoneController.text.trim());
          
          // Telefon numarası değiştiyse doğrulama durumunu sıfırla
          if (_storedPhone != _phoneController.text.trim()) {
            await prefs.setBool('phone_verified', false);
            _isPhoneVerified = false;
          }
        }
        
        if (mounted) {
          _showMessage('Profil başarıyla güncellendi!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Profil güncellenirken hata oluştu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('Telefon numarası giriniz', isError: true);
      return;
    }

    // Basit doğrulama simülasyonu
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Telefon Doğrulama'),
          content: Text(
            '${_phoneController.text.trim()} numarasına SMS doğrulama kodu gönderildi.\n\n'
            'Bu demo sürümünde doğrulama otomatik olarak tamamlanacak.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Doğrulama durumunu güncelle
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('phone_verified', true);
                setState(() {
                  _isPhoneVerified = true;
                });
                
                _showMessage('Telefon numarası doğrulandı!');
              },
              child: const Text('Doğrula'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Ayarları'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _authController.userStream,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),
                
                // Profil Fotoğrafı
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue.shade600,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              _showPhotoUpdateDialog();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // İsim Alanı
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kişisel Bilgiler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // İsim Input
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
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
                      
                      // Telefon Numarası
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Telefon Numarası',
                                prefixIcon: Icon(Icons.phone, color: Colors.blue.shade600),
                                suffixIcon: _isPhoneVerified 
                                    ? Icon(Icons.verified, color: Colors.green.shade600)
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.shade600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isPhoneVerified ? null : _verifyPhone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isPhoneVerified 
                                  ? Colors.green.shade600 
                                  : Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(_isPhoneVerified ? 'Doğrulandı' : 'Doğrula'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email (sadece gösterim)
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          hintText: user?.email ?? 'Email bulunamadı',
                          prefixIcon: Icon(Icons.email, color: Colors.grey.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'E-posta adresi Google hesabınızdan gelir ve değiştirilemez.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Güncelle Butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Güncelleniyor...'),
                            ],
                          )
                        : const Text(
                            'Profili Güncelle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPhotoUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profil Fotoğrafı'),
          content: const Text(
            'Profil fotoğrafınız Google hesabınızdan gelir. '
            'Fotoğrafınızı değiştirmek için Google hesabınızın ayarlarından '
            'profil fotoğrafınızı güncelleyebilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

// Araç Ayarları Sayfası
class VehicleSettingsPage extends StatefulWidget {
  final VoidCallback? onVehicleChanged;
  const VehicleSettingsPage({super.key, this.onVehicleChanged});

  @override
  State<VehicleSettingsPage> createState() => _VehicleSettingsPageState();
}

class _VehicleSettingsPageState extends State<VehicleSettingsPage> {
  final VehicleController _vehicleController = VehicleController();
  List<VehicleModel> _vehicles = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    // dispose'da ekstra çağrı yapmıyoruz çünkü her işlemden sonra zaten çağırıyoruz
    super.dispose();
  }



  Future<void> _loadVehicles() async {
    final vehicles = await _vehicleController.getVehicles();
    setState(() {
      _vehicles = vehicles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç Ayarları'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVehicleDialog(),
          ),
        ],
      ),
      body: _vehicles.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Henüz araç eklenmemiş',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sağ üstteki + butonuna basarak ilk aracınızı ekleyebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Araç İkonu
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Araç Bilgileri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Plaka: ${vehicle.licensePlate}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Eklenme: ${_formatDate(vehicle.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // QR Kod Önizleme
                        GestureDetector(
                          onTap: () => _showQRCodePage(vehicle),
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: vehicle.qrContent,
                              version: QrVersions.auto,
                              size: 36.0,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Menü Butonu
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'qr') {
                              _showQRCodePage(vehicle);
                            } else if (value == 'edit') {
                              _showEditVehicleDialog(vehicle);
                            } else if (value == 'delete') {
                              _showDeleteConfirmDialog(vehicle);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'qr',
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('QR Kod'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Düzenle'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Sil'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddVehicleDialog() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Araç Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Araç Adı',
                  hintText: 'Örn: Beyaz BMW',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Plaka',
                  hintText: 'Örn: 34 ABC 123',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty &&
                    plateController.text.trim().isNotEmpty) {
                  final vehicle = VehicleModel(
                    id: _vehicleController.generateVehicleId(),
                    name: nameController.text.trim(),
                    licensePlate: plateController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  final success = await _vehicleController.addVehicle(vehicle);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      _hasChanges = true;
                      _loadVehicles();
                      print('🚗 Araç eklendi - anasayfa güncelleniyor...');
                      if (widget.onVehicleChanged != null) {
                        print('📞 Callback çağrılıyor...');
                        widget.onVehicleChanged!();
                        print('✅ Callback tamamlandı');
                      } else {
                        print('❌ Callback null!');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Araç başarıyla eklendi!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Araç eklenirken hata oluştu!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showEditVehicleDialog(VehicleModel vehicle) {
    final nameController = TextEditingController(text: vehicle.name);
    final plateController = TextEditingController(text: vehicle.licensePlate);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Araç Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Araç Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Plaka',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty &&
                    plateController.text.trim().isNotEmpty) {
                  final updatedVehicle = vehicle.copyWith(
                    name: nameController.text.trim(),
                    licensePlate: plateController.text.trim(),
                  );

                  final success = await _vehicleController.updateVehicle(updatedVehicle);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      _hasChanges = true;
                      _loadVehicles();
                      print('✏️ Araç düzenlendi - anasayfa güncelleniyor...');
                      if (widget.onVehicleChanged != null) {
                        print('📞 Callback çağrılıyor...');
                        widget.onVehicleChanged!();
                        print('✅ Callback tamamlandı');
                      } else {
                        print('❌ Callback null!');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Araç başarıyla güncellendi!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Araç güncellenirken hata oluştu!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Araç Sil'),
          content: Text('${vehicle.name} adlı aracı silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final success = await _vehicleController.deleteVehicle(vehicle.id);
                
                                  if (mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    _hasChanges = true;
                    _loadVehicles();
                    print('🗑️ Araç silindi - anasayfa güncelleniyor...');
                    if (widget.onVehicleChanged != null) {
                      print('📞 Callback çağrılıyor...');
                      widget.onVehicleChanged!();
                      print('✅ Callback tamamlandı');
                    } else {
                      print('❌ Callback null!');
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Araç başarıyla silindi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Araç silinirken hata oluştu!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showQRCodePage(VehicleModel vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodePage(
          vehicle: vehicle,
          onVehicleUpdated: () {
            // QR kod güncellediğinde araç listesini yenile
            _loadVehicles();
            // Ana sayfayı da güncelle
            if (widget.onVehicleChanged != null) {
              widget.onVehicleChanged!();
            }
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Bildirim Ayarları Sayfası
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _ledEnabled = false;
  String _notificationSound = 'Varsayılan';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _ledEnabled = prefs.getBool('led_enabled') ?? false;
      _notificationSound = prefs.getString('notification_sound') ?? 'Varsayılan';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('sms_notifications', _smsNotifications);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('led_enabled', _ledEnabled);
    await prefs.setString('notification_sound', _notificationSound);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bildirim Türleri
          _buildSectionHeader('Bildirim Türleri'),
          _buildNotificationTile(
            'Push Bildirimler',
            'Uygulama bildirimleri alın',
            Icons.notifications,
            _pushNotifications,
            (value) async {
              setState(() => _pushNotifications = value);
              await _saveSettings();
            },
          ),
          
          _buildNotificationTile(
            'E-posta Bildirimleri',
            'Önemli güncellemeler için e-posta alın',
            Icons.email,
            _emailNotifications,
            (value) async {
              setState(() => _emailNotifications = value);
              await _saveSettings();
            },
          ),
          
          _buildNotificationTile(
            'SMS Bildirimleri',
            'Acil durumlar için SMS alın',
            Icons.sms,
            _smsNotifications,
            (value) async {
              setState(() => _smsNotifications = value);
              await _saveSettings();
            },
          ),

          const SizedBox(height: 24),

          // Ses ve Titreşim
          _buildSectionHeader('Ses ve Titreşim'),
          _buildNotificationTile(
            'Bildirim Sesi',
            'Bildirimlerde ses çalınsın',
            Icons.volume_up,
            _soundEnabled,
            (value) async {
              setState(() => _soundEnabled = value);
              await _saveSettings();
            },
          ),

          _buildNotificationTile(
            'Titreşim',
            'Bildirimlerde titreşim olsun',
            Icons.vibration,
            _vibrationEnabled,
            (value) async {
              setState(() => _vibrationEnabled = value);
              await _saveSettings();
            },
          ),

          _buildNotificationTile(
            'LED Işığı',
            'Bildirim LED\'i yanıp sönsün',
            Icons.lightbulb_outline,
            _ledEnabled,
            (value) async {
              setState(() => _ledEnabled = value);
              await _saveSettings();
            },
          ),

          const SizedBox(height: 16),

          // Bildirim Sesi Seçimi
          Card(
            child: ListTile(
              leading: Icon(Icons.music_note, color: Colors.blue.shade600),
              title: const Text('Bildirim Sesi'),
              subtitle: Text(_notificationSound),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showSoundPicker,
            ),
          ),

          const SizedBox(height: 24),

          // Test Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.notification_add),
              label: const Text('Test Bildirimi Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: Colors.blue.shade600),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade600,
      ),
    );
  }

  void _showSoundPicker() {
    final sounds = [
      'Varsayılan',
      'Klasik',
      'Modern',
      'Doğa',
      'Zil Sesi',
      'Sessiz',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bildirim Sesi Seç'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sounds.map((sound) => RadioListTile<String>(
              title: Text(sound),
              value: sound,
              groupValue: _notificationSound,
              onChanged: (String? value) async {
                if (value != null) {
                  setState(() {
                    _notificationSound = value;
                  });
                  await _saveSettings();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  void _sendTestNotification() async {
    final notificationController = NotificationController();
    
    final testNotification = NotificationModel(
      id: notificationController.generateNotificationId(),
      title: 'Test Bildirimi',
      message: 'Bu bir test bildirimidir. Bildirim ayarlarınız çalışıyor!',
      createdAt: DateTime.now(),
      type: 'info',
    );

    final success = await notificationController.addNotification(testNotification);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test bildirimi gönderildi! Ana sayfada görebilirsiniz.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test bildirimi gönderilemedi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 