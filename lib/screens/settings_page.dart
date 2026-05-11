// settings_page.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import 'home_page.dart';

// =====================================================
// SETTINGS ITEM MODEL (OOP)
// =====================================================
class SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// =====================================================
// SETTINGS PAGE
// =====================================================
class SettingsPage extends StatelessWidget {
  final AuthUser user;
  final VoidCallback onLogout;

  const SettingsPage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  bool get dark => ThemeProvider().isDarkMode;

  @override
  Widget build(BuildContext context) {

    final items = [

      SettingItem(
        title: 'About Us',
        subtitle: 'Learn more about TICKETY',
        icon: Icons.info_outline_rounded,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AboutPage(),
            ),
          );
        },
      ),

      SettingItem(
        title: 'Privacy Policy',
        subtitle: 'Read our privacy policy',
        icon: Icons.privacy_tip_outlined,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ExtensionPage(
                title: 'Privacy Policy',
              ),
            ),
          );
        },
      ),

      SettingItem(
        title: 'Terms & Conditions',
        subtitle: 'Application terms',
        icon: Icons.article_outlined,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ExtensionPage(
                title: 'Terms & Conditions',
              ),
            ),
          );
        },
      ),

      SettingItem(
        title: 'Logout',
        subtitle: 'Sign out of your account',
        icon: Icons.logout_rounded,
        color: AppTheme.crimson,
        onTap: onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface(dark),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface(dark),
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textPrimary(dark),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [

          // PROFILE CARD
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.crimson,
                  AppTheme.darkCrimson,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [

                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DARK MODE
          SwitchListTile(
            value: dark,
            activeColor: AppTheme.crimson,
            onChanged: (_) {
              ThemeProvider().toggleTheme();
            },
            title: Text(
              'Dark Mode',
              style: TextStyle(
                color: AppTheme.textPrimary(dark),
              ),
            ),
            secondary: Icon(
              dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: AppTheme.crimson,
            ),
          ),

          const SizedBox(height: 10),

          // SETTINGS LIST
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {

                final item = items[index];

                return SettingTile(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// REUSABLE TILE
// =====================================================
class SettingTile extends StatelessWidget {

  final SettingItem item;

  const SettingTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {

    final dark = ThemeProvider().isDarkMode;

    return ListTile(

      onTap: item.onTap,

      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.icon,
          color: item.color,
        ),
      ),

      title: Text(
        item.title,
        style: TextStyle(
          color: AppTheme.textPrimary(dark),
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(
        item.subtitle,
        style: TextStyle(
          color: AppTheme.textMuted(dark),
        ),
      ),

      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted(dark),
      ),
    );
  }
}

// =====================================================
// ABOUT PAGE
// =====================================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {

    final dark = ThemeProvider().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.surface(dark),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface(dark),
        title: Text(
          'About Us',
          style: TextStyle(
            color: AppTheme.textPrimary(dark),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.crimson,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.confirmation_num_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 25),

            Text(
              'TICKETY',
              style: TextStyle(
                color: AppTheme.textPrimary(dark),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Smart Queue Management System',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted(dark),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'TICKETY helps users manage service queues and digital tickets easily with a modern interface.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary(dark),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EXTENSION PAGE TEMPLATE
// Create future pages using this class
// =====================================================
class ExtensionPage extends StatelessWidget {

  final String title;

  const ExtensionPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    final dark = ThemeProvider().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.surface(dark),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface(dark),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary(dark),
          ),
        ),
      ),

      body: Center(
        child: Text(
          '$title Page',
          style: TextStyle(
            color: AppTheme.textPrimary(dark),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}