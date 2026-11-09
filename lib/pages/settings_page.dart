import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization.dart';
import '../providers/settings_provider.dart';
import '../services/biometric_service.dart';
import '../widgets/neu_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(context.tr('settings')),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, context.tr('language')),
          NeuContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildLangRadio(context, settings, 'English', 'en'),
                _buildLangRadio(context, settings, 'دری (Persian)', 'fa'),
                _buildLangRadio(context, settings, 'پښتو (Pashto)', 'ps'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Theme Section ──
          _buildSectionTitle(context, context.tr('theme')),
          NeuContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildThemeRadio(context, settings, context.tr('system_default'), ThemeMode.system),
                _buildThemeRadio(context, settings, context.tr('light_mode'), ThemeMode.light),
                _buildThemeRadio(context, settings, context.tr('dark_mode'), ThemeMode.dark),
              ],
            ),
          ),
          SizedBox(height: 24,),
          _buildSectionTitle(context, context.tr('security')),
          NeuContainer(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SwitchListTile(
              title:  Text(context.tr('app_lock')),
              subtitle:  Text(context.tr('require_auth')),
              value: settings.isAppLockEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (bool value) async {
                final success = await BiometricService.authenticate();
                if (success) {
                  if (context.mounted) {
                    context.read<SettingsProvider>().toggleAppLock(value);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? context.tr('auth_failed')
                            : context.tr('auth_failed_lock')),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLangRadio(BuildContext context, SettingsProvider settings, String title, String langCode) {
    return RadioListTile<String>(
      title: Text(title),
      value: langCode,
      groupValue: settings.locale.languageCode,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (val) {
        if (val != null) context.read<SettingsProvider>().changeLanguage(val);
      },
    );
  }

  Widget _buildThemeRadio(BuildContext context, SettingsProvider settings, String title, ThemeMode mode) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: mode,
      groupValue: settings.themeMode,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (val) {
        if (val != null) context.read<SettingsProvider>().changeTheme(val);
      },
    );
  }
}