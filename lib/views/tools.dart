import 'dart:io';

import 'package:flclashx/common/common.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key});

  @override
  ConsumerState<ToolsView> createState() => _ToolsViewState();
}

class _ToolsViewState extends ConsumerState<ToolsView> {
  static const _bgColor = Color(0xFF0A0A0F);
  static const _surfaceColor = Color(0xFF1A1A2E);
  static const _accentPurple = Color(0xFF6C63FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFF9E9E9E);
  static const _textTertiary = Color(0xFF666666);

  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _updateProfiles() async {
    final profiles = ref.read(profilesProvider);
    int updated = 0;
    for (final profile in profiles) {
      if (profile.type == ProfileType.file) continue;
      try {
        await globalState.appController.updateProfile(profile);
        updated++;
      } catch (e) {
        // ignore individual failures
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Обновлено подписок: $updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);
    final currentProfileId = ref.watch(currentProfileIdProvider);
    final totalTraffic = ref.watch(totalTrafficProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text(
          'Настройки',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Subscription import section
          _buildSectionTitle('Подписка'),
          _buildCard(
            child: Column(
              children: [
                _ImportSubscriptionTile(),
                if (profiles.isNotEmpty) ...[
                  const Divider(height: 1, color: _textTertiary),
                  ListTile(
                    leading: const Icon(Icons.update, color: _accentPurple),
                    title: const Text('Обновить подписки', style: TextStyle(color: _textPrimary)),
                    subtitle: Text(
                      '${profiles.length} подписок',
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: _textTertiary),
                    onTap: _updateProfiles,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Server list section
          if (profiles.isNotEmpty) ...[
            _buildSectionTitle('Серверы'),
            _buildCard(
              child: Column(
                children: profiles.map((profile) {
                  final isSelected = profile.id == currentProfileId;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? _accentPurple : _textTertiary,
                    ),
                    title: Text(
                      profile.label ?? profile.id,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      profile.type == ProfileType.url ? 'URL подписка' : 'Файл',
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                    trailing: profile.type == ProfileType.url
                        ? const Icon(Icons.cloud_done_outlined, color: _textSecondary, size: 18)
                        : const Icon(Icons.insert_drive_file_outlined, color: _textSecondary, size: 18),
                    onTap: () {
                      ref.read(currentProfileIdProvider.notifier).value = profile.id;
                      globalState.appController.handleChangeProfile();
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Language section
          _buildSectionTitle('Язык'),
          _buildCard(
            child: const ListTile(
              leading: Icon(Icons.language, color: _accentPurple),
              title: Text('Русский', style: TextStyle(color: _textPrimary)),
              trailing: Icon(Icons.check_circle, color: _accentPurple, size: 20),
            ),
          ),
          const SizedBox(height: 24),

          // Traffic stats
          _buildSectionTitle('Статистика'),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    icon: Icons.arrow_downward,
                    label: 'Скачано',
                    value: _formatBytes(totalTraffic.down),
                    color: Colors.green,
                  ),
                  _StatBox(
                    icon: Icons.arrow_upward,
                    label: 'Отправлено',
                    value: _formatBytes(totalTraffic.up),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About section
          _buildSectionTitle('О приложении'),
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: _accentPurple),
                  title: const Text('Версия', style: TextStyle(color: _textPrimary)),
                  trailing: Text(
                    _version,
                    style: const TextStyle(color: _textSecondary),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.code, color: _accentPurple),
                  title: Text('FlClashR', style: TextStyle(color: _textPrimary)),
                  subtitle: Text(
                    'Безопасный VPN-клиент на базе ClashMeta',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _ImportSubscriptionTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ImportSubscriptionTile> createState() => _ImportSubscriptionTileState();
}

class _ImportSubscriptionTileState extends ConsumerState<_ImportSubscriptionTile> {
  final _controller = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() => _isImporting = true);
    try {
      await globalState.appController.addProfileFormURL(url);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подписка добавлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            style: const TextStyle(color: Color(0xFFFFFFFF)),
            decoration: InputDecoration(
              hintText: 'Ссылка на подписку',
              hintStyle: const TextStyle(color: Color(0xFF666666)),
              filled: true,
              fillColor: const Color(0xFF0A0A0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6C63FF)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isImporting ? null : _import,
              child: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Добавить подписку'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
        ),
      ],
    );
  }
}
