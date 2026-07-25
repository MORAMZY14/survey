import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/block_survey.dart';
import '../../models/central.dart';
import '../../models/floor_survey.dart';
import '../../models/internet_box_plan.dart';
import '../../services/central_repository.dart';
import '../../services/survey_repository.dart';
import '../../utils/geohash.dart';
import '../../widgets/counter_field.dart';
import '../../widgets/floor_editor.dart';
import '../../widgets/photo_capture_card.dart';
import '../../widgets/photo_marker_editor.dart';

class NewSurveyScreen extends StatefulWidget {
  const NewSurveyScreen({
    super.key,
    required this.location,
    required this.locationAccuracy,
    this.initialCentralId,
  });

  final LatLng location;
  final double locationAccuracy;
  final String? initialCentralId;

  @override
  State<NewSurveyScreen> createState() => _NewSurveyScreenState();
}

class _NewSurveyScreenState extends State<NewSurveyScreen> {
  static const _mountingAreas = [
    'Main entrance',
    'Ground-floor lobby',
    'Stairwell',
    'Exterior wall',
    'Utility room',
    'Roof',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _blockNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _generalNotesController = TextEditingController();
  final _boxNotesController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _centralRepository = CentralRepository();
  final _repository = SurveyRepository();

  late final StreamSubscription<List<Central>> _centralSubscription;
  List<Central> _centrals = const [];
  String? _selectedCentralId;
  bool _loadingCentrals = true;
  Object? _centralError;

  int _totalFloors = 1;
  int _defaultApartments = 1;
  bool _startsWithGroundFloor = false;
  late List<FloorSurvey> _floors;

  XFile? _blockPhoto;
  XFile? _internetBoxPhoto;
  double? _markerX;
  double? _markerY;
  String _mountingArea = _mountingAreas.first;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCentralId = widget.initialCentralId;
    _floors = generateFloors(
      totalFloors: _totalFloors,
      defaultApartments: _defaultApartments,
      startsWithGroundFloor: _startsWithGroundFloor,
    );
    _watchCentrals();
    _recoverLostPhoto();
  }

  @override
  void dispose() {
    _centralSubscription.cancel();
    _blockNameController.dispose();
    _addressController.dispose();
    _generalNotesController.dispose();
    _boxNotesController.dispose();
    super.dispose();
  }

  void _watchCentrals() {
    _centralSubscription = _centralRepository
        .watchCentrals(activeOnly: true)
        .listen(
          (centrals) {
            if (!mounted) {
              return;
            }

            final selectionStillExists = centrals.any(
              (central) => central.id == _selectedCentralId,
            );
            setState(() {
              _centrals = centrals;
              _loadingCentrals = false;
              _centralError = null;
              if (!selectionStillExists) {
                _selectedCentralId = centrals.length == 1
                    ? centrals.single.id
                    : null;
              }
            });
          },
          onError: (Object error) {
            if (!mounted) {
              return;
            }
            setState(() {
              _centralError = error;
              _loadingCentrals = false;
            });
          },
        );
  }

  Future<void> _recoverLostPhoto() async {
    final response = await _imagePicker.retrieveLostData();
    if (!mounted || response.isEmpty || response.files == null) {
      return;
    }

    final recovered = response.files!.first;
    setState(() {
      if (_blockPhoto == null) {
        _blockPhoto = recovered;
        _markerX = null;
        _markerY = null;
      } else {
        _internetBoxPhoto = recovered;
      }
    });
  }

  void _updateFloorStructure({
    int? totalFloors,
    int? defaultApartments,
    bool? startsWithGroundFloor,
  }) {
    final nextTotal = totalFloors ?? _totalFloors;
    final nextDefault = defaultApartments ?? _defaultApartments;
    final nextGround = startsWithGroundFloor ?? _startsWithGroundFloor;
    final generated = generateFloors(
      totalFloors: nextTotal,
      defaultApartments: nextDefault,
      startsWithGroundFloor: nextGround,
    );

    final merged = List.generate(generated.length, (index) {
      final base = generated[index];
      if (index >= _floors.length) {
        return base;
      }

      final previous = _floors[index];
      final count = previous.apartmentCount == _defaultApartments
          ? nextDefault
          : previous.apartmentCount;
      return base.copyWith(
        apartmentCount: count,
        notes: previous.notes,
        isException: count != nextDefault || previous.notes.trim().isNotEmpty,
      );
    });

    setState(() {
      _totalFloors = nextTotal;
      _defaultApartments = nextDefault;
      _startsWithGroundFloor = nextGround;
      _floors = merged;
    });
  }

  void _updateFloor(int index, FloorSurvey floor) {
    setState(() {
      _floors = [..._floors]..[index] = floor;
    });
  }

  Future<void> _choosePhoto(_PhotoTarget target) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                target == _PhotoTarget.block
                    ? 'Add block photo'
                    : 'Add mounting-point photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final photo = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (photo == null || !mounted) {
      return;
    }

    setState(() {
      if (target == _PhotoTarget.block) {
        _blockPhoto = photo;
        _markerX = null;
        _markerY = null;
      } else {
        _internetBoxPhoto = photo;
      }
    });
  }

  Future<void> _saveSurvey() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      _showMessage('Please correct the highlighted fields.');
      return;
    }
    Central? selectedCentral;
    for (final central in _centrals) {
      if (central.id == _selectedCentralId) {
        selectedCentral = central;
        break;
      }
    }
    if (selectedCentral == null) {
      _showMessage(
        'Select a Central. An administrator must create one first if the list '
        'is empty.',
      );
      return;
    }
    if (_blockPhoto == null) {
      _showMessage('Add a clear photo of the apartment block.');
      return;
    }
    if (_markerX == null || _markerY == null) {
      _showMessage(
        'Tap the block photo to mark where the Internet box should be mounted.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Your session ended. Please sign in again.');
      return;
    }

    setState(() => _saving = true);

    final survey = BlockSurvey(
      id: '',
      centralId: selectedCentral.id,
      centralName: selectedCentral.name,
      blockName: _blockNameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
      locationAccuracy: widget.locationAccuracy,
      geohash: Geohash.encode(
        widget.location.latitude,
        widget.location.longitude,
      ),
      defaultApartmentsPerFloor: _defaultApartments,
      startsWithGroundFloor: _startsWithGroundFloor,
      floors: _floors,
      blockPhotoUrl: '',
      blockPhotoStoragePath: '',
      internetBox: InternetBoxPlan(
        mountingArea: _mountingArea,
        notes: _boxNotesController.text.trim(),
        markerX: _markerX!,
        markerY: _markerY!,
      ),
      generalNotes: _generalNotesController.text.trim(),
      status: 'submitted',
      createdBy: user.uid,
      createdByName:
          user.displayName ?? user.email?.split('@').first ?? 'Surveyor',
    );

    try {
      await _repository.createSurvey(
        survey: survey,
        blockPhoto: _blockPhoto!,
        internetBoxPhoto: _internetBoxPhoto,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showMessage(
        'The survey could not be saved. Check Firebase Storage and your '
        'Internet connection.\n$error',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final totalApartments = _floors.fold(
      0,
      (total, floor) => total + floor.apartmentCount,
    );
    final exceptions = _floors.where((floor) => floor.isException).length;

    return Scaffold(
      appBar: AppBar(title: const Text('New block survey')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              children: [
                _LocationBanner(
                  location: widget.location,
                  accuracy: widget.locationAccuracy,
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.hub_outlined,
                  title: 'Central',
                  subtitle: 'Assign this apartment block to its Central.',
                  child: _buildCentralField(),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.apartment_rounded,
                  title: 'Block details',
                  subtitle: 'Identify the apartment block.',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _blockNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Block name or number',
                          hintText: 'Example: Block A-12',
                          prefixIcon: Icon(Icons.domain_outlined),
                        ),
                        validator: (value) {
                          if ((value?.trim().length ?? 0) < 2) {
                            return 'Enter a block name or number.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        textCapitalization: TextCapitalization.words,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address or landmark (optional)',
                          hintText: 'Street, district, or nearby landmark',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.layers_rounded,
                  title: 'Floors and apartments',
                  subtitle:
                      'Set the normal layout, then edit exceptional floors.',
                  child: Column(
                    children: [
                      CounterField(
                        label: 'Total floors',
                        value: _totalFloors,
                        minimum: 1,
                        maximum: 100,
                        icon: Icons.layers_outlined,
                        onChanged: (value) =>
                            _updateFloorStructure(totalFloors: value),
                      ),
                      const SizedBox(height: 10),
                      CounterField(
                        label: 'Default apartments per floor',
                        value: _defaultApartments,
                        minimum: 0,
                        maximum: 50,
                        icon: Icons.door_front_door_outlined,
                        onChanged: (value) =>
                            _updateFloorStructure(defaultApartments: value),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('First level is the ground floor'),
                        subtitle: Text(
                          _startsWithGroundFloor
                              ? 'Levels: Ground, Floor 1, Floor 2…'
                              : 'Levels: Floor 1, Floor 2, Floor 3…',
                        ),
                        value: _startsWithGroundFloor,
                        onChanged: (value) =>
                            _updateFloorStructure(startsWithGroundFloor: value),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 6,
                          children: [
                            _SummaryValue(
                              value: '$_totalFloors',
                              label: 'floors',
                            ),
                            _SummaryValue(
                              value: '$totalApartments',
                              label: 'apartments',
                            ),
                            _SummaryValue(
                              value: '$exceptions',
                              label: 'exceptions',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var index = 0; index < _floors.length; index++) ...[
                        FloorEditor(
                          key: ValueKey('floor-$index'),
                          floor: _floors[index],
                          defaultApartments: _defaultApartments,
                          onChanged: (floor) => _updateFloor(index, floor),
                        ),
                        if (index != _floors.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.photo_camera_rounded,
                  title: 'Block photo',
                  subtitle:
                      'Take a clear photo showing the front of the block.',
                  child: Column(
                    children: [
                      PhotoCaptureCard(
                        title: 'Apartment block',
                        subtitle: 'Use a clear, well-lit front view.',
                        photo: _blockPhoto,
                        requiredPhoto: true,
                        onAdd: () => _choosePhoto(_PhotoTarget.block),
                        onRemove: () => setState(() {
                          _blockPhoto = null;
                          _markerX = null;
                          _markerY = null;
                        }),
                      ),
                      if (_blockPhoto != null) ...[
                        const SizedBox(height: 18),
                        PhotoMarkerEditor(
                          photo: _blockPhoto!,
                          markerX: _markerX,
                          markerY: _markerY,
                          onMarkerChanged: (x, y) => setState(() {
                            _markerX = x;
                            _markerY = y;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.router_rounded,
                  title: 'Internet-box plan',
                  subtitle:
                      'Describe and photograph the proposed mounting point.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _mountingArea,
                        decoration: const InputDecoration(
                          labelText: 'Mounting area',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        items: _mountingAreas
                            .map(
                              (area) => DropdownMenuItem(
                                value: area,
                                child: Text(area),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _mountingArea = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _boxNotesController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Mounting instructions',
                          hintText:
                              'Height, wall side, cable route, obstacles…',
                          prefixIcon: Icon(Icons.construction_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PhotoCaptureCard(
                        title: 'Close-up of mounting point',
                        subtitle:
                            'Optional evidence showing the wall or surface.',
                        photo: _internetBoxPhoto,
                        onAdd: () => _choosePhoto(_PhotoTarget.internetBox),
                        onRemove: () =>
                            setState(() => _internetBoxPhoto = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.notes_rounded,
                  title: 'General notes',
                  subtitle: 'Record access issues or other observations.',
                  child: TextFormField(
                    controller: _generalNotesController,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Building condition, contact person, access notes…',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveSurvey,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _saving ? 'Uploading survey…' : 'Save survey to Firebase',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralField() {
    if (_loadingCentrals) {
      return const Row(
        children: [
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading Centrals…'),
        ],
      );
    }

    if (_centralError != null) {
      return Text(
        'Could not load Centrals. Check your connection and Firebase rules.\n'
        '$_centralError',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    if (_centrals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.admin_panel_settings_outlined),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No active Centrals are available. Ask an administrator to '
                'create El-Hadra, Karmouz, or the required Central from the '
                'Profile screen.',
              ),
            ),
          ],
        ),
      );
    }

    final selectedExists = _centrals.any(
      (central) => central.id == _selectedCentralId,
    );
    return DropdownButtonFormField<String>(
      key: ValueKey(
        'central-${_selectedCentralId ?? 'none'}-${_centrals.length}',
      ),
      initialValue: selectedExists ? _selectedCentralId : null,
      decoration: const InputDecoration(
        labelText: 'Central',
        prefixIcon: Icon(Icons.business_outlined),
      ),
      hint: const Text('Select the Central'),
      items: _centrals
          .map(
            (central) =>
                DropdownMenuItem(value: central.id, child: Text(central.name)),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedCentralId = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select a Central.';
        }
        return null;
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.location, required this.accuracy});

  final LatLng location;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gps_fixed_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPS survey point',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${location.latitude.toStringAsFixed(6)}, '
                    '${location.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (accuracy > 0)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text('±${accuracy.round()} m'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

enum _PhotoTarget { block, internetBox }
