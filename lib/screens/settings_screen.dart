import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 130),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),

            _Group(
              title: 'Appearance',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const _LeadingIcon(
                      icon: Icons.dark_mode_rounded, color: Color(0xFF7C5CFC)),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Use the dark premium theme'),
                  value: settings.darkTheme,
                  onChanged: (v) =>
                      context.read<SettingsProvider>().setDarkTheme(v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LeadingIcon(
                      icon: Icons.currency_exchange_rounded,
                      color: Color(0xFF00E0B8)),
                  title: const Text('Currency'),
                  subtitle: Text(_currencyName(settings.currency)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _pickCurrency(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _Group(
              title: 'Data',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LeadingIcon(
                      icon: Icons.backup_rounded, color: Color(0xFF42A5F5)),
                  title: const Text('Backup Database'),
                  subtitle: const Text('Save & share a copy of your data'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _backup(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LeadingIcon(
                      icon: Icons.restore_rounded, color: Color(0xFFFFA726)),
                  title: const Text('Restore Database'),
                  subtitle: const Text('Restore from a previous backup'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _restore(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LeadingIcon(
                      icon: Icons.delete_forever_rounded,
                      color: Color(0xFFEF5350)),
                  title: const Text('Reset Data'),
                  subtitle: const Text('Delete all recorded expenses'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _reset(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _Group(
              title: 'About',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _LeadingIcon(
                      icon: Icons.info_rounded, color: Color(0xFF78909C)),
                  title: const Text('Expense Tracker'),
                  subtitle: const Text(
                      'Version 1.0.0 • Offline • Stored locally with SQLite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _currencyName(String symbol) {
    final match = SettingsProvider.currencyOptions
        .firstWhere((e) => e.key == symbol,
            orElse: () => MapEntry(symbol, symbol));
    return match.value;
  }

  void _pickCurrency(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final current = sheetContext.read<SettingsProvider>().currency;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Select Currency',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                ...SettingsProvider.currencyOptions.map((opt) => RadioListTile<String>(
                      value: opt.key,
                      groupValue: current,
                      title: Text(opt.value),
                      onChanged: (v) {
                        if (v != null) {
                          sheetContext
                              .read<SettingsProvider>()
                              .setCurrency(v);
                        }
                        Navigator.pop(sheetContext);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _backup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await ExportService.backupDatabase();
      messenger.showSnackBar(
        SnackBar(content: Text('Backup created: ${p.basename(path)}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final backups = await ExportService.listBackups();
    if (!context.mounted) return;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No backups found. Create a backup first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Restore from Backup',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              ...backups.map((file) {
                final stat = file.statSync();
                final name = p.basename(file.path);
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file_rounded),
                  title: Text(name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '${DateFormat('d MMM yyyy, h:mm a').format(stat.modified)} • ${_fileSize(stat.size)}',
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmRestore(context, file.path);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRestore(BuildContext context, String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
            'This will replace your current data with the selected backup. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ExportService.restoreDatabase(path);
      if (!context.mounted) return;
      await context.read<ExpenseProvider>().load();
      await context.read<SettingsProvider>().refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Database restored successfully')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
            'This permanently deletes every recorded expense. '
            'Consider creating a backup first. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<ExpenseProvider>().resetAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been reset')),
    );
  }

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _LeadingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
