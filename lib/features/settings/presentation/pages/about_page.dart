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
                    'EduSelf is an AI study companion for Vietnamese students '
                    'in grades 6–9 (THCS). It helps learners understand concepts, '
                    'practice step by step, and build self-study habits.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Teaching style follows the EduSelf Study AI Pro guide: '
                    'patient, encouraging, and focused on understanding — '
                    'not giving answers immediately.',
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
