import 'package:eduself_study_app/core/config/app_config.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('About'),
        ),
        drawer: const AppDrawer(),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('Version ${AppConfig.appVersion}'),
                  const SizedBox(height: 16),
                  const Text(
                    'EduSelf Ngữ Văn AI hỗ trợ học sinh THCS lớp 6–9 học môn '
                    'Ngữ văn: đọc hiểu, tiếng Việt, tập làm văn và cảm thụ văn học.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Phong cách sư phạm: kiên nhẫn, khích lệ, gợi mở từng bước '
                    'để học sinh tự hiểu bài — không viết hộ ngay từ đầu.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
