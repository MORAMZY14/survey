import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/central.dart';
import '../../services/central_repository.dart';

class CentralManagementScreen extends StatefulWidget {
  const CentralManagementScreen({super.key});

  @override
  State<CentralManagementScreen> createState() =>
      _CentralManagementScreenState();
}

class _CentralManagementScreenState extends State<CentralManagementScreen> {
  final _repository = CentralRepository();
  bool _creating = false;
  final _changing = <String>{};

  Future<void> _createCentral() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.hub_outlined),
        title: const Text('Create Central'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Central name',
              hintText: 'Example: El-Hadra',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (value) {
              final cleanName = value?.trim() ?? '';
              if (cleanName.length < 2) {
                return 'Enter at least 2 characters.';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || !mounted) {
      return;
    }

    setState(() => _creating = true);
    try {
      await _repository.createCentral(name);
      _showMessage('$name Central created.');
    } on CentralAlreadyExistsException catch (error) {
      _showMessage(error.toString());
    } on FirebaseException catch (error) {
      _showMessage(
        error.code == 'permission-denied'
            ? 'Only administrators can create Centrals.'
            : error.message ?? 'Could not create the Central.',
      );
    } catch (error) {
      _showMessage('Could not create the Central: $error');
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<void> _setActive(Central central, bool active) async {
    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Deactivate ${central.name}?'),
          content: const Text(
            'Existing surveys will remain visible, but surveyors cannot assign '
            'new surveys to this Central.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    setState(() => _changing.add(central.id));
    try {
      await _repository.setCentralActive(central, active);
    } on FirebaseException catch (error) {
      _showMessage(
        error.code == 'permission-denied'
            ? 'Only administrators can change Centrals.'
            : error.message ?? 'Could not update the Central.',
      );
    } finally {
      if (mounted) {
        setState(() => _changing.remove(central.id));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Centrals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _createCentral,
        icon: _creating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_business_rounded),
        label: Text(_creating ? 'Creating…' : 'Create Central'),
      ),
      body: StreamBuilder<List<Central>>(
        stream: _repository.watchCentrals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Centrals.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final centrals = snapshot.data!;
          if (centrals.isEmpty) {
            return const _EmptyCentrals();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: centrals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final central = centrals[index];
              final changing = _changing.contains(central.id);
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: central.active
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.hub_outlined),
                  ),
                  title: Text(
                    central.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    central.active
                        ? 'Available for new surveys'
                        : 'Inactive • Existing surveys are preserved',
                  ),
                  trailing: changing
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: central.active,
                          onChanged: (value) => _setActive(central, value),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyCentrals extends StatelessWidget {
  const _EmptyCentrals();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hub_outlined, size: 60),
            const SizedBox(height: 14),
            Text(
              'No Centrals yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Create El-Hadra, Karmouz, or another Central using the button '
              'below.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
