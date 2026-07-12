import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// AtmosphericBackground lives in glass_card.dart.

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    this.message =
        'Tính năng đang được hoàn thiện. Em dùng Gia sư AI hoặc các mục khác trước nhé.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(title),
        ),
        drawer: const AppDrawer(),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              child: Column(
                children: [
                  Icon(Icons.construction_rounded,
                      size: 48, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Sắp ra mắt',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Về trang chủ'),
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
