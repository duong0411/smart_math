import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/engine_service.dart';

class RegistryPage extends StatelessWidget {
  const RegistryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<EngineService>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Face Registry',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enrollment via UI not fully wired up yet.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Enroll Person'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: engine.persons.isEmpty
                ? const Center(
                    child: Text(
                      'No persons registered yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: engine.persons.length,
                    itemBuilder: (context, index) {
                      final person = engine.persons[index];
                      return Card(
                        color: const Color(0xFF1E1E2E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF2E2E3A)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(
                            person.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          subtitle: Text('ID: ${person.id}', style: const TextStyle(color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              engine.deletePerson(person.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
