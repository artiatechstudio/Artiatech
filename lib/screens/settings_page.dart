import 'package:flutter/material.dart';
import '../main.dart'; // الوصول لـ themeNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentLanguage = 'Arabic (العربية)';
  String _notificationStatus = 'On (مفعل)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات أرتياتك'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const SizedBox(height: 10),
          
          _buildSectionHeader('المظهر والتخصيص'),
          _buildDropdownTile(
            icon: Icons.brightness_6_outlined,
            title: 'وضع الشاشة',
            subtitle: 'تغيير سمة التطبيق (ليلي/نهاري)',
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) => DropdownButton<ThemeMode>(
                value: currentMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.light, child: Text('مضيء')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('مظلم')),
                  DropdownMenuItem(value: ThemeMode.system, child: Text('تلقائي')),
                ],
                onChanged: (newMode) {
                  if (newMode != null) themeNotifier.value = newMode;
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          _buildDropdownTile(
            icon: Icons.language_outlined,
            title: 'لغة التطبيق',
            subtitle: 'اختر لغة الواحدة والرسائل',
            child: DropdownButton<String>(
              value: _currentLanguage,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Arabic (العربية)', child: Text('العربية')),
                DropdownMenuItem(value: 'English', child: Text('English')),
              ],
              onChanged: (newVal) {
                if (newVal != null) setState(() => _currentLanguage = newVal);
              },
            ),
          ),

          const SizedBox(height: 30),
          _buildSectionHeader('التنبيهات والأصوات'),
          
          _buildDropdownTile(
            icon: Icons.notifications_active_outlined,
            title: 'إشعارات النظام',
            subtitle: 'تفعيل إشعارات المتابعة والجديد',
            child: DropdownButton<String>(
              value: _notificationStatus,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'On (مفعل)', child: Text('تشغيل')),
                DropdownMenuItem(value: 'Off (معطل)', child: Text('إيقاف')),
              ],
              onChanged: (newVal) {
                if (newVal != null) setState(() => _notificationStatus = newVal);
              },
            ),
          ),

          const SizedBox(height: 20),
          _buildDropdownTile(
            icon: Icons.volume_up_outlined,
            title: 'المؤثرات الصوتية',
            subtitle: 'أصوات النقر والتفاعل داخل التطبيق',
            child: ValueListenableBuilder<bool>(
              valueListenable: soundNotifier,
              builder: (context, isEnabled, _) => Switch(
                value: isEnabled,
                activeColor: Colors.blueAccent,
                onChanged: (val) => soundNotifier.value = val,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  Widget _buildDropdownTile({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
