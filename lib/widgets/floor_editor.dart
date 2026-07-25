import 'package:flutter/material.dart';

import '../models/floor_survey.dart';

class FloorEditor extends StatefulWidget {
  const FloorEditor({
    super.key,
    required this.floor,
    required this.defaultApartments,
    required this.onChanged,
  });

  final FloorSurvey floor;
  final int defaultApartments;
  final ValueChanged<FloorSurvey> onChanged;

  @override
  State<FloorEditor> createState() => _FloorEditorState();
}

class _FloorEditorState extends State<FloorEditor> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.floor.notes);
  }

  @override
  void didUpdateWidget(covariant FloorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.floor.notes != _notesController.text) {
      _notesController.text = widget.floor.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _update({int? apartmentCount, String? notes}) {
    final nextCount = apartmentCount ?? widget.floor.apartmentCount;
    final nextNotes = notes ?? widget.floor.notes;
    widget.onChanged(
      widget.floor.copyWith(
        apartmentCount: nextCount,
        notes: nextNotes,
        isException:
            nextCount != widget.defaultApartments ||
            nextNotes.trim().isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floor = widget.floor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: floor.isException
            ? const Color(0xFFF39A44).withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: floor.isException
              ? const Color(0xFFF39A44)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${floor.order + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  floor.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (floor.isException)
                const Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Exception'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Apartments on this floor')),
              _SmallIconButton(
                icon: Icons.remove_rounded,
                onPressed: floor.apartmentCount > 0
                    ? () => _update(apartmentCount: floor.apartmentCount - 1)
                    : null,
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '${floor.apartmentCount}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _SmallIconButton(
                icon: Icons.add_rounded,
                onPressed: floor.apartmentCount < 50
                    ? () => _update(apartmentCount: floor.apartmentCount + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Exception note (optional)',
              hintText: 'Example: commercial shop replaces apartment 2',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            onChanged: (value) => _update(notes: value),
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
    );
  }
}
