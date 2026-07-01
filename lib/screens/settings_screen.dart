import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const SectionTitle('Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const _Leading(
                        Icons.dark_mode_rounded, Color(0xFF5B6CF0)),
                    title: const Text('Dark theme'),
                    value: settings.darkTheme,
                    onChanged: (v) =>
                        context.read<SettingsProvider>().setDarkTheme(v),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const _Leading(
                        Icons.payments_rounded, Color(0xFF1AA179)),
                    title: const Text('Currency'),
                    subtitle: Text(_currencyName(settings.currency)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _pickCurrency(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionTitle('Data'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const _Leading(
                        Icons.backup_rounded, Color(0xFF2F80ED)),
                    title: const Text('Backup'),
                    subtitle: const Text('Save & share a copy of your data'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _backup(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const _Leading(
                        Icons.restore_rounded, Color(0xFFE8871E)),
                    title: const Text('Restore'),
                    subtitle: const Text('Restore from a previous backup'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _restore(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const SectionTitle('About'),
            const AppCard(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _Leading(Icons.info_outline_rounded, Color(0xFF6B7280)),
                title: Text('Expense Tracker'),
                subtitle: Text('Version 1.0.0 · Offline · Stored locally'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currencyName(String symbol) {
    final match = SettingsProvider.currencyOptions.firstWhere(
      (e) => e.key == symbol,
      orElse: () => MapEntry(symbol, symbol),
    );
    return match.value;
  }

  void _pickCurrency(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final current = sheetContext.read<SettingsProvider>().currency;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Select currency',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              ...SettingsProvider.currencyOptions.map(
                (opt) => RadioListTile<String>(
                  value: opt.key,
                  groupValue: current,
                  title: Text(opt.value),
                  onChanged: (v) {
                    if (v != null) {
                      sheetContext.read<SettingsProvider>().setCurrency(v);
                    }
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
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

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Restore from backup',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              ...backups.map((file) {
                final stat = file.statSync();
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file_rounded),
                  title: Text(p.basename(file.path),
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    DateFormat('d MMM yyyy, h:mm a').format(stat.modified),
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
        title: const Text('Restore backup?'),
        content: const Text(
            'This replaces your current data with the selected backup. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
        const SnackBar(content: Text('Database restored')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }
}

class _Leading extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Leading(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
