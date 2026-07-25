import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/block_survey.dart';

class SurveyDetailScreen extends StatelessWidget {
  const SurveyDetailScreen({super.key, required this.survey});

  final BlockSurvey survey;

  @override
  Widget build(BuildContext context) {
    final createdAt = survey.createdAt == null
        ? 'Waiting for server timestamp'
        : DateFormat('d MMMM yyyy, h:mm a').format(survey.createdAt!.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(survey.blockName),
        actions: [
          IconButton(
            onPressed: () => _copyCoordinates(context),
            tooltip: 'Copy coordinates',
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _MarkedBlockPhoto(survey: survey),
          const SizedBox(height: 14),
          _DetailCard(
            title: 'Survey summary',
            icon: Icons.fact_check_outlined,
            child: Column(
              children: [
                _DetailRow(label: 'Status', value: survey.status),
                _DetailRow(label: 'Central', value: survey.centralName),
                _DetailRow(label: 'Surveyor', value: survey.createdByName),
                _DetailRow(label: 'Date', value: createdAt),
                _DetailRow(
                  label: 'Coordinates',
                  value:
                      '${survey.latitude.toStringAsFixed(6)}, '
                      '${survey.longitude.toStringAsFixed(6)}',
                ),
                if (survey.locationAccuracy > 0)
                  _DetailRow(
                    label: 'GPS accuracy',
                    value: '±${survey.locationAccuracy.round()} m',
                  ),
                if (survey.address.isNotEmpty)
                  _DetailRow(
                    label: 'Address',
                    value: survey.address,
                    showDivider: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailCard(
            title: 'Building layout',
            icon: Icons.layers_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        value: '${survey.totalFloors}',
                        label: 'Floors',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBox(
                        value: '${survey.totalApartments}',
                        label: 'Apartments',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBox(
                        value: '${survey.exceptionCount}',
                        label: 'Exceptions',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (var index = 0; index < survey.floors.length; index++) ...[
                  _FloorRow(
                    label: survey.floors[index].label,
                    apartmentCount: survey.floors[index].apartmentCount,
                    isException: survey.floors[index].isException,
                    notes: survey.floors[index].notes,
                  ),
                  if (index != survey.floors.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailCard(
            title: 'Internet-box plan',
            icon: Icons.router_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRow(
                  label: 'Mounting area',
                  value: survey.internetBox.mountingArea,
                  showDivider: survey.internetBox.notes.isNotEmpty,
                ),
                if (survey.internetBox.notes.isNotEmpty)
                  _DetailRow(
                    label: 'Instructions',
                    value: survey.internetBox.notes,
                    showDivider: false,
                  ),
                if (survey.internetBox.photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Close-up photo',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  _NetworkPhoto(
                    url: survey.internetBox.photoUrl,
                    onTap: () =>
                        _showPhoto(context, survey.internetBox.photoUrl),
                  ),
                ],
              ],
            ),
          ),
          if (survey.generalNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _DetailCard(
              title: 'General notes',
              icon: Icons.notes_rounded,
              child: Text(survey.generalNotes),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyCoordinates(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '${survey.latitude},${survey.longitude}'),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Coordinates copied.')));
    }
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close_rounded),
            ),
            title: const Text('Survey photo'),
          ),
          backgroundColor: Colors.black,
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: Image.network(
                url,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkedBlockPhoto extends StatelessWidget {
  const _MarkedBlockPhoto({required this.survey});

  final BlockSurvey survey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth / (16 / 10);
        return GestureDetector(
          onTap: survey.blockPhotoUrl.isEmpty
              ? null
              : () => _showPhoto(context, survey.blockPhotoUrl),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  survey.blockPhotoUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE8ECEA),
                          child: Center(
                            child: Icon(Icons.apartment_rounded, size: 64),
                          ),
                        )
                      : Image.network(
                          survey.blockPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFE8ECEA),
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                  Positioned(
                    left:
                        survey.internetBox.markerX * constraints.maxWidth - 22,
                    top: survey.internetBox.markerY * height - 44,
                    child: const _SavedMountMarker(),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.router_rounded,
                            color: Color(0xFFF39A44),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Proposed Internet-box point',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close_rounded),
            ),
            title: const Text('Block photo'),
          ),
          backgroundColor: Colors.black,
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(child: Image.network(url)),
          ),
        ),
      ),
    );
  }
}

class _SavedMountMarker extends StatelessWidget {
  const _SavedMountMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF39A44),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.router_rounded, color: Colors.white, size: 24),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _FloorRow extends StatelessWidget {
  const _FloorRow({
    required this.label,
    required this.apartmentCount,
    required this.isException,
    required this.notes,
  });

  final String label;
  final int apartmentCount;
  final bool isException;
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isException
            ? const Color(0xFFF39A44).withValues(alpha: 0.09)
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isException
              ? const Color(0xFFF39A44)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$apartmentCount apartment'
                '${apartmentCount == 1 ? '' : 's'}',
              ),
              if (isException) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFF39A44),
                ),
              ],
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFFE8ECEA),
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
      ),
    );
  }
}
