import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripspending/providers/settings_provider.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // Appearance section
              _buildSectionHeader(context, 'Appearance'),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeName(settings.themeMode)),
                onTap: () => _showThemeDialog(context, settings),
              ),
              const Divider(),

              // Default settings section
              _buildSectionHeader(context, 'Defaults'),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Default Currency'),
                subtitle: Text(settings.defaultCurrency),
                onTap: () => _showCurrencyDialog(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('OCR Languages'),
                subtitle: Text(settings.defaultLanguages.join(', ')),
                onTap: () => _showLanguagesDialog(context, settings),
              ),
              const Divider(),

              // About section
              _buildSectionHeader(context, 'About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('TripSpending'),
                subtitle: const Text('Version 1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Data Storage'),
                subtitle: const Text('All data is stored locally on your device'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeName(mode)),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: SettingsProvider.currencies.length,
            itemBuilder: (context, index) {
              final currency = SettingsProvider.currencies[index];
              return RadioListTile<String>(
                title: Text('${currency['code']} - ${currency['name']}'),
                secondary: Text(currency['symbol'] ?? ''),
                value: currency['code']!,
                groupValue: settings.defaultCurrency,
                onChanged: (value) {
                  if (value != null) {
                    settings.setDefaultCurrency(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLanguagesDialog(BuildContext context, SettingsProvider settings) {
    final selectedLanguages = List<String>.from(settings.defaultLanguages);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('OCR Languages'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: SettingsProvider.ocrLanguages.length,
                itemBuilder: (context, index) {
                  final lang = SettingsProvider.ocrLanguages[index];
                  final isSelected = selectedLanguages.contains(lang['code']);

                  return CheckboxListTile(
                    title: Text(lang['name']!),
                    subtitle: Text(lang['code']!),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedLanguages.add(lang['code']!);
                        } else {
                          selectedLanguages.remove(lang['code']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedLanguages.isNotEmpty) {
                    settings.setDefaultLanguages(selectedLanguages);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
