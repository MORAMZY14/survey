import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/block_survey.dart';
import '../../services/survey_repository.dart';
import 'survey_detail_screen.dart';

class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({
    super.key,
    this.centralId,
    required this.currentUserId,
    required this.isAdmin,
  });

  final String? centralId;
  final String currentUserId;
  final bool isAdmin;

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  final _repository = SurveyRepository();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BlockSurvey>>(
      stream: _repository.watchSurveys(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SurveyError(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = _searchController.text.trim().toLowerCase();
        final surveys = snapshot.data!.where((survey) {
          final visibleToUser =
              widget.isAdmin ||
              survey.isApproved ||
              survey.createdBy == widget.currentUserId;
          if (!visibleToUser) {
            return false;
          }
          if (widget.centralId != null &&
              survey.centralId != widget.centralId) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return survey.blockName.toLowerCase().contains(query) ||
              survey.centralName.toLowerCase().contains(query) ||
              survey.address.toLowerCase().contains(query) ||
              survey.createdByName.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search Central, block, address, or surveyor',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            Expanded(
              child: surveys.isEmpty
                  ? _EmptySurveyList(hasSearch: query.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: () async => Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: surveys.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _SurveyCard(
                          survey: surveys[index],
                          isAdmin: widget.isAdmin,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.survey, required this.isAdmin});

  final BlockSurvey survey;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final date = survey.createdAt == null
        ? 'Syncing date…'
        : DateFormat('d MMM yyyy, h:mm a').format(survey.createdAt!.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SurveyDetailScreen(
              survey: survey,
              isAdmin: isAdmin,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: survey.blockPhotoUrl.isEmpty
                      ? Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.apartment_rounded),
                        )
                      : Image.network(
                          survey.blockPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFE8ECEA),
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            survey.blockName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusPill(survey: survey),
                      ],
                    ),
                    if (survey.address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        survey.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            survey.centralName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _SmallMetric(
                          icon: Icons.layers_outlined,
                          text: '${survey.totalFloors} floors',
                        ),
                        _SmallMetric(
                          icon: Icons.door_front_door_outlined,
                          text: '${survey.totalApartments} apartments',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(date, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.survey});

  final BlockSurvey survey;

  @override
  Widget build(BuildContext context) {
    final color = switch (survey.status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        survey.statusLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptySurveyList extends StatelessWidget {
  const _EmptySurveyList({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apartment_rounded, size: 56),
            const SizedBox(height: 12),
            Text(
              hasSearch ? 'No matching blocks' : 'No surveys yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Try a different search.'
                  : 'Open the map and tap a block to create the first survey.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurveyError extends StatelessWidget {
  const _SurveyError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load surveys.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
