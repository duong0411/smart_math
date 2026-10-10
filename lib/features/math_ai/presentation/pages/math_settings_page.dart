import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/core/settings/app_settings_store.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MathSettingsPage extends ConsumerStatefulWidget {
  const MathSettingsPage({super.key});

  @override
  ConsumerState<MathSettingsPage> createState() => _MathSettingsPageState();
}

class _MathSettingsPageState extends ConsumerState<MathSettingsPage> {
  late final TextEditingController _keyController;
  late final TextEditingController _nameController;
  int? _grade;
  var _obscureKey = true;
  var _keySynced = false;
  var _profileSynced = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final raw = _keyController.text.trim();
    if (raw.isEmpty) {
      await ref.read(geminiApiKeyProvider.notifier).save('');
      AppToast.success('Đã xoá API key');
      setState(() {});
      return;
    }

    final normalized = AppSettingsStore.sanitizeSecret(raw);
    if (!AppSettingsStore.looksLikeGeminiApiKey(normalized)) {
      AppToast.error(
        'Key không hợp lệ. Hãy lấy key từ Google AI Studio '
        '(bắt đầu bằng AIza… hoặc AQ.…).',
      );
      return;
    }

    await ref.read(geminiApiKeyProvider.notifier).save(normalized);
    final saved = ref.read(geminiApiKeyProvider).valueOrNull?.trim() ?? '';
    if (saved.isEmpty) {
      AppToast.error('Lưu API key thất bại. Thử dán lại key rồi Lưu.');
    } else {
      _keyController.text = saved;
      final fixedPrefix = !raw.trim().startsWith('AQ.') && saved.startsWith('AQ.');
      AppToast.success(
        fixedPrefix
            ? 'Đã tự thêm AQ. và lưu Gemini API key'
            : 'Đã lưu Gemini API key',
      );
    }
    setState(() {});
  }

  Future<void> _saveProfile() async {
    final grade = _grade == null ? null : SupportedGrades.normalize(_grade);
    final profile = MathStudentProfile(
      displayName: _nameController.text.trim(),
      gradeLevel: grade,
    );
    await ref.read(mathProfileProvider.notifier).save(profile);
    setState(() => _grade = grade);
    AppToast.success('Đã lưu hồ sơ học sinh');
  }

  @override
  Widget build(BuildContext context) {
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final profileAsync = ref.watch(mathProfileProvider);

    if (!_keySynced && keyAsync.hasValue) {
      _keyController.text = keyAsync.valueOrNull ?? '';
      _keySynced = true;
    }
    if (!_profileSynced && profileAsync.hasValue) {
      final profile = profileAsync.valueOrNull;
      if (profile != null) {
        _nameController.text = profile.displayName;
        _grade = profile.gradeLevel == null
            ? null
            : SupportedGrades.normalize(profile.gradeLevel);
      }
      _profileSynced = true;
    }

    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    final hasKey = _keyController.text.trim().isNotEmpty;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Cài đặt'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gemini API key',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dán API key từ Google AI Studio. Key được lưu an toàn trên thiết bị, không gửi lên server của app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      hintText: 'AQ.… hoặc AIza…',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveKey,
                          child: Text(hasKey ? 'Lưu API key' : 'Xoá / lưu trống'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          launchUrl(
                            Uri.parse('https://aistudio.google.com/apikey'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: const Text('Lấy key'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hồ sơ học sinh',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradeLevelSelector(
                    value: _grade,
                    onChanged: (v) => setState(() => _grade = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _saveProfile,
                    child: const Text('Lưu hồ sơ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao diện',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Hệ thống'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Sáng'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Tối'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selected) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(selected.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Về ứng dụng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(AppConfig.appName),
                  Text(AppConfig.appTagline),
                  Text('Phiên bản ${AppConfig.appVersion}'),
                  Text(AppConfig.storageMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
