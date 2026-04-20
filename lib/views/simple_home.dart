import 'package:flclashx/common/russia_preset.dart';
import 'package:flclashx/controller.dart';
import 'package:flclashx/providers/providers.dart';
import 'package:flclashx/common/common.dart';
import 'package:flclashx/state.dart';
import 'package:flclashx/core/crash_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tools.dart';

class SimpleHomeView extends ConsumerStatefulWidget {
  const SimpleHomeView({super.key});

  @override
  ConsumerState<SimpleHomeView> createState() => _SimpleHomeViewState();
}

class _SimpleHomeViewState extends ConsumerState<SimpleHomeView>
    with SingleTickerProviderStateMixin {
  static const _bgColor = Color(0xFF0A0A0F);
  static const _surfaceColor = Color(0xFF1A1A2E);
  static const _accentPurple = Color(0xFF6C63FF);
  static const _onGreen = Color(0xFF4CAF50);
  static const _offGray = Color(0xFF757575);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFF9E9E9E);
  static const _textTertiary = Color(0xFF666666);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleConnection(bool isStarted) async {
    try {
      await globalState.appController.updateStatus(!isStarted);
    } catch (e, stack) {
      await CrashLogger.instance.logError(e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка VPN: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openModes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Режимы',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Выберите готовый набор настроек',
                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),
                const SizedBox(height: 24),
                _ModeButton(
                  icon: Icons.flag_rounded,
                  title: 'Россия 2026',
                  subtitle: 'YouTube и Telegram через VPN. Банки напрямую.',
                  accentColor: Colors.redAccent,
                  onTap: () {
                    applyRussia2026Preset(ref);
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пресет "Россия 2026" применен'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModeButton(
                  icon: Icons.download_rounded,
                  title: 'Импорт ключа',
                  subtitle: 'Вставить ссылку на подписку',
                  accentColor: _onGreen,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showImportDialog();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    try {
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Импорт подписки', style: TextStyle(color: _textPrimary)),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: _textPrimary),
              decoration: InputDecoration(
                hintText: 'Вставьте ссылку на подписку',
                hintStyle: const TextStyle(color: _textTertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _accentPurple),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена', style: TextStyle(color: _textSecondary)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accentPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Импортировать'),
              ),
            ],
          );
        },
      );
      if (shouldImport == true && controller.text.isNotEmpty) {
        await globalState.appController.addProfileFormURL(controller.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Подписка импортирована')),
          );
        }
      }
    } finally {
      controller.dispose();
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

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '';
    final seconds = (ms / 1000).round();
    final mins = seconds ~/ 60;
    final hrs = mins ~/ 60;
    if (hrs > 0) return '${hrs}ч ${mins % 60}мин';
    if (mins > 0) return '${mins}мин ${seconds % 60}сек';
    return '${seconds}сек';
  }

  @override
  Widget build(BuildContext context) {
    final isStarted = ref.watch(runTimeProvider.select((state) => state != null));
    final runTime = ref.watch(runTimeProvider);
    final totalTraffic = ref.watch(totalTrafficProvider);
    final currentProfile = ref.watch(currentProfileProvider);

    final serverName = currentProfile?.label ?? currentProfile?.id ?? 'Нет сервера';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top bar with settings
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: _textSecondary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ToolsView()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Shield icon
              Icon(
                isStarted ? Icons.shield_moon_rounded : Icons.shield_outlined,
                size: 72,
                color: isStarted ? _onGreen : _offGray,
              ),
              const SizedBox(height: 16),
              // App name
              const Text(
                'FlClashR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              // Status text
              Text(
                isStarted ? 'Защищено' : 'Отключено',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isStarted ? _onGreen : _offGray,
                ),
              ),
              if (isStarted && runTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDuration(runTime),
                  style: const TextStyle(fontSize: 14, color: _textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              // Server name
              Text(
                serverName,
                style: const TextStyle(fontSize: 14, color: _textTertiary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Main toggle button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: isStarted
                            ? [_onGreen.withOpacity(0.8), _onGreen]
                            : [_accentPurple.withOpacity(0.8), _accentPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isStarted
                              ? _onGreen.withOpacity(0.3)
                              : _accentPurple.withOpacity(0.3),
                          blurRadius: isStarted ? 16 + _pulseAnimation.value : 12,
                          spreadRadius: isStarted ? _pulseAnimation.value : 0,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => _toggleConnection(isStarted),
                    child: Center(
                      child: Text(
                        isStarted ? 'Отключить' : 'Включить',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Mode button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Material(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _openModes,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 22, color: _textSecondary),
                          SizedBox(width: 16),
                          Text('Режимы', style: TextStyle(fontSize: 16, color: _textPrimary)),
                          Spacer(),
                          Icon(Icons.chevron_right_rounded, color: _textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Traffic stats
              if (isStarted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _TrafficStat(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Скачано',
                        value: _formatBytes(totalTraffic.down),
                        color: _onGreen,
                      ),
                      Container(width: 1, height: 40, color: _textTertiary.withOpacity(0.3)),
                      _TrafficStat(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Отправлено',
                        value: _formatBytes(totalTraffic.up),
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'from pavel with love',
                style: TextStyle(fontSize: 12, color: _textTertiary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrafficStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TrafficStat({
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textSecondary),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF222222),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: accentColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
