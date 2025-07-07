import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'settings_pages.dart';

class SettingsDrawer extends StatefulWidget {
  final VoidCallback? onVehicleChanged;
  
  const SettingsDrawer({
    super.key,
    this.onVehicleChanged,
  });

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  final AuthController _authController = AuthController();
  String? _userPhone;
  bool _isPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    final verified = prefs.getBool('phone_verified') ?? false;
    
    if (mounted) {
      setState(() {
        _userPhone = phone;
        _isPhoneVerified = verified;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
          return Drawer(
        child: StreamBuilder<UserModel?>(
          stream: _authController.userStream,
        builder: (context, snapshot) {
          final user = snapshot.data;
          
          return Column(
            children: [
              // Header - Kullanıcı Profili
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade800,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Profil Fotoğrafı
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // İsim
                    Text(
                      user?.displayName ?? 'Kullanıcı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      user?.email ?? 'Email bulunamadı',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    
                    // Telefon
                    if (_userPhone != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _userPhone!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (_isPhoneVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Ayarlar Listesi
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSettingsSection(
                      context,
                      title: 'Hesap',
                      items: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.person_outline,
                          title: 'Profil Ayarları',
                          subtitle: 'Kişisel bilgilerinizi yönetin',
                          onTap: () async {
                            Navigator.pop(context);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
                            );
                            // Profil ayarlarından dönünce telefon bilgilerini güncelle
                            _loadUserPhone();
                          },
                        ),
                      ],
                    ),
                    
                    _buildSettingsSection(
                      context,
                      title: 'Araç',
                      items: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.directions_car_outlined,
                          title: 'Araç Ayarları',
                          subtitle: 'Araç bilgilerinizi düzenleyin',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleSettingsPage(
                                  onVehicleChanged: widget.onVehicleChanged ?? () {
                                    print('📱 Drawer callback bulunamadı!');
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    
                    _buildSettingsSection(
                      context,
                      title: 'Uygulama',
                      items: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.notifications_outlined,
                          title: 'Bildirim Ayarları',
                          subtitle: 'Bildirim tercihlerinizi ayarlayın',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'QR2Cars v1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue.shade600).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }
}