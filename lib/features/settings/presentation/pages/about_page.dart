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
                    'EduSelf Địa lí AI là ứng dụng AI giám sát và đồng hành học tập môn Địa lí '
                    'dành cho học sinh THCS (Lớp 6–9 theo chương trình GDPT 2018). Ứng dụng giúp học sinh '
                    'hiểu sâu kiến thức địa lí tự nhiên và kinh tế - xã hội, rèn luyện kỹ năng đọc bản đồ, '
                    'phân tích bảng số liệu, và hình thành thói quen tự học chủ động.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Phương pháp sư phạm bám sát định hướng GDPT 2018: '
                    'kiên nhẫn, gợi mở từng bước, khuyến khích tư duy phản biện và liên hệ thực tiễn — '
                    'tuyệt đối không đưa ra đáp án sẵn.',
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
