import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/notification_model.dart';
import 'settings_drawer.dart';
import 'settings_pages.dart';
import 'qr_code_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final AuthController _authController = AuthController();
  final VehicleController _vehicleController = VehicleController();
  final NotificationController _notificationController = NotificationController();
  bool _isLoading = false;
  List<VehicleModel> _vehicles = [];
  List<NotificationModel> _notifications = [];
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    print('🔄 _loadData çağrıldı - forceRefresh: $forceRefresh');
    
    // Debounce: Son yenilemeden 1 saniye geçmemişse güncelleme yapma (forceRefresh hariç)
    if (!forceRefresh) {
      final now = DateTime.now();
      if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 1) {
        print('⏰ Debounce nedeniyle güncelleme atlandı');
        return;
      }
      _lastRefresh = now;
    }

    setState(() {
      _isLoading = true;
    });

    final vehicles = await _vehicleController.getVehicles();
    print('📊 Yüklenen araç sayısı: ${vehicles.length}');
    for (int i = 0; i < vehicles.length; i++) {
      print('  ${i + 1}. ${vehicles[i].name} - ${vehicles[i].licensePlate}');
    }
    
    // Örnek bildirimler oluştur (ilk açılışta)
    await _notificationController.createSampleNotifications();
    
    // Güncellenmiş bildirimleri al
    final updatedNotifications = await _notificationController.getNotifications();
    
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _notifications = updatedNotifications;
        _isLoading = false;
      });
      print('✅ setState tamamlandı - UI güncellendi');
    } else {
      print('❌ Widget mounted değil - setState atlandı');
    }
  }



  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yaparken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          print('🎯 Focus listener tetiklendi - sayfa focus\'a geldi');
          // Sayfa focus'a geldiğinde verileri yenile
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              print('🎯 Focus listener - _loadData çağrılıyor');
              _loadData(forceRefresh: true);
            } else {
              print('🎯 Focus listener - widget mounted değil');
            }
          });
        } else {
          print('🎯 Focus listener - sayfa focus\'u kaybetti');
        }
      },
      child: Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: SettingsDrawer(
        onVehicleChanged: () {
          print('📱 Drawer callback tetiklendi - anasayfa güncelleniyor!');
          _loadData(forceRefresh: true);
        },
      ),
      appBar: AppBar(
        title: const Text(
          'QR2Cars',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _showSignOutDialog,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _authController.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(
              child: Text('Kullanıcı bilgisi bulunamadı'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),
                
                // Profil Kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                    children: [
                      // Profil Fotoğrafı
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.blue.shade600,
                              )
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // İsim
                      Text(
                        user.displayName ?? 'Kullanıcı',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      Text(
                        user.email ?? 'Email bulunamadı',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Hoş geldin mesajı
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'QR2Cars uygulamasına hoş geldiniz! 🚗',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Bildirimler Bölümü
                _buildNotificationSection(),
                
                const SizedBox(height: 24),
                
                // Araçlar Bölümü
                _buildVehicleSection(),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Son Bildirimler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                if (_notifications.isNotEmpty)
                  Text(
                    '${_notifications.length}',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          if (_notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz bildirim yok',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_notifications.take(3)).map((notification) => 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.grey.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                                             ),
                   ],
                 ),
               ),
             ),
           
           if (_notifications.length > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Tüm bildirimleri göster
                  },
                  child: Text(
                    '+${_notifications.length - 3} daha fazla bildirim',
                    style: TextStyle(color: Colors.blue.shade600),
                  ),
                ),
              ),
            )
          else 
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Araçlarım',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                if (_vehicles.isNotEmpty)
                  Text(
                    '${_vehicles.length}',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          
          if (_vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Henüz araç eklenmemiş',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Araç ayarları sayfasına git
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleSettingsPage(
                              onVehicleChanged: () {
                                // Anında güncelleme - debounce'u atla
                                print('📱 Anasayfa callback tetiklendi!');
                                print('📱 Araç listesi güncelleniyor...');
                                _loadData(forceRefresh: true);
                                print('📱 _loadData çağrısı tamamlandı');
                              },
                            ),
                          ),
                        );
                        // Sayfadan döndükten sonra da güncelleme yap
                        if (result == true) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Araç Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_vehicles.take(2)).map((vehicle) => 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Plaka: ${vehicle.licensePlate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // QR Kod Önizleme
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRCodePage(
                              vehicle: vehicle,
                              onVehicleUpdated: () {
                                _loadData(forceRefresh: true);
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: vehicle.qrContent,
                          version: QrVersions.auto,
                          size: 32.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                   ],
                 ),
               ),
             ),
           
           if (_vehicles.length > 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Ayarlar çekmecesini aç ve araç ayarlarına git
                    Scaffold.of(context).openDrawer();
                  },
                  child: Text(
                    '+${_vehicles.length - 2} daha fazla araç',
                    style: TextStyle(color: Colors.blue.shade600),
                  ),
                ),
              ),
            )
          else 
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
} 