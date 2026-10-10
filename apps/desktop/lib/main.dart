import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/engine_service.dart';
import 'features/monitoring/monitoring_page.dart';
import 'features/registry/registry_page.dart';

void main() {
  runApp(const FaceRecogApp());
}

class FaceRecogApp extends StatelessWidget {
  const FaceRecogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EngineService()),
      ],
      child: MaterialApp(
        title: 'Face Recognition MVP',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          fontFamily: 'Inter',
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5CF6),
            secondary: Color(0xFF10B981),
            surface: Color(0xFF1E1E2E),
          ),
        ),
        home: const MainLayout(),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MonitoringPage(),
    const RegistryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: const Color(0xFF161622),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.videocam_outlined),
                selectedIcon: Icon(Icons.videocam),
                label: Text('Monitor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Registry'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
