import 'package:flutter/material.dart';

import '../models/central.dart';
import '../services/central_repository.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'survey/survey_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _centralRepository = CentralRepository();
  int _index = 0;
  String? _selectedCentralId;
  String _selectedCentralName = 'All Centrals';

  static const _titles = ['Survey map', 'Block surveys', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_index],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (_index < 2)
              Text(
                _selectedCentralName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        actions: [
          if (_index < 2)
            _CentralFilterButton(
              repository: _centralRepository,
              selectedCentralId: _selectedCentralId,
              onSelected: (central) {
                setState(() {
                  _selectedCentralId = central?.id;
                  _selectedCentralName = central?.name ?? 'All Centrals';
                });
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          MapScreen(centralId: _selectedCentralId),
          SurveyListScreen(centralId: _selectedCentralId),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Surveys',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CentralFilterButton extends StatelessWidget {
  const _CentralFilterButton({
    required this.repository,
    required this.selectedCentralId,
    required this.onSelected,
  });

  final CentralRepository repository;
  final String? selectedCentralId;
  final ValueChanged<Central?> onSelected;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Central>>(
      stream: repository.watchCentrals(),
      builder: (context, snapshot) {
        final centrals = snapshot.data ?? const <Central>[];
        return PopupMenuButton<String>(
          tooltip: 'Filter by Central',
          initialValue: selectedCentralId ?? '',
          icon: const Icon(Icons.filter_alt_outlined),
          onSelected: (id) {
            if (id.isEmpty) {
              onSelected(null);
              return;
            }
            for (final central in centrals) {
              if (central.id == id) {
                onSelected(central);
                return;
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: '',
              child: Row(
                children: [
                  Icon(Icons.public_rounded),
                  SizedBox(width: 10),
                  Text('All Centrals'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            for (final central in centrals)
              PopupMenuItem(
                value: central.id,
                child: Row(
                  children: [
                    Icon(
                      central.active
                          ? Icons.hub_outlined
                          : Icons.do_not_disturb_on_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(central.name)),
                    if (!central.active)
                      Text(
                        'Inactive',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
