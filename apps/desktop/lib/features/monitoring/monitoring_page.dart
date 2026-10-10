import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/engine_service.dart';
import 'dart:typed_data';
import 'dart:convert';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineService>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Monitoring',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E2E3A)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (engine.isEngineReady && engine.latestEvent.containsKey('frame'))
                    Image.memory(
                      base64Decode(engine.latestEvent['frame']),
                      fit: BoxFit.cover,
                      gaplessPlayback: true, // Tránh chớp nháy khi load frame mới
                    )
                  else if (engine.isEngineReady)
                    const Center(child: CircularProgressIndicator())
                  else
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Connecting to Engine...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  
                  if (engine.latestEvent.containsKey('bbox'))
                    _buildBoundingBox(engine.latestEvent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBoundingBox(Map<String, dynamic> event) {
    return Positioned(
      top: 100, // Normally map this to the real bbox proportional coordinates
      left: 100,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 2),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            color: Colors.greenAccent,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              event['name'] ?? 'Unknown',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
