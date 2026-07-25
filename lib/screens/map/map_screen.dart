import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/block_survey.dart';
import '../../services/location_service.dart';
import '../../services/survey_repository.dart';
import '../survey/new_survey_screen.dart';
import '../survey/survey_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.centralId});

  final String? centralId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _cairo = LatLng(30.0444, 31.2357);

  final _locationService = LocationService();
  final _repository = SurveyRepository();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _selectedPoint;
  String? _locationError;
  bool _loadingLocation = true;
  List<BlockSurvey> _latestSurveys = const [];

  @override
  void initState() {
    super.initState();
    _findCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _findCurrentLocation() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
        _locationError = null;
      });
    }

    try {
      final position = await _locationService.determinePosition();
      final target = LatLng(position.latitude, position.longitude);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 19),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationError = _friendlyLocationError(error);
        _loadingLocation = false;
      });
    }
  }

  Future<void> _selectPoint(LatLng point) async {
    BlockSurvey? nearby;
    var closestDistance = double.infinity;

    for (final survey in _latestSurveys) {
      final distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        survey.latitude,
        survey.longitude,
      );
      if (distance < 15 && distance < closestDistance) {
        closestDistance = distance;
        nearby = survey;
      }
    }

    if (nearby != null && mounted) {
      final action = await showDialog<_NearbyAction>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.location_searching_rounded),
          title: const Text('Block already surveyed nearby'),
          content: Text(
            '${nearby!.blockName} is approximately '
            '${closestDistance.round()} m from this point in '
            '${nearby.centralName}.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _NearbyAction.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _NearbyAction.openExisting),
              child: const Text('Open existing'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _NearbyAction.continueSurvey),
              child: const Text('Survey anyway'),
            ),
          ],
        ),
      );

      if (!mounted || action == null || action == _NearbyAction.cancel) {
        return;
      }
      if (action == _NearbyAction.openExisting) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SurveyDetailScreen(survey: nearby!),
          ),
        );
        return;
      }
    }

    if (mounted) {
      setState(() => _selectedPoint = point);
    }
  }

  Future<void> _startSurvey() async {
    final point = _selectedPoint;
    if (point == null) {
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NewSurveyScreen(
          location: point,
          locationAccuracy: _currentPosition?.accuracy ?? 0,
          initialCentralId: widget.centralId,
        ),
      ),
    );

    if (created == true && mounted) {
      setState(() => _selectedPoint = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Block survey saved.')));
    }
  }

  Set<Marker> _markers(List<BlockSurvey> surveys) {
    final markers = surveys.map((survey) {
      final hue = switch (survey.status) {
        'approved' => BitmapDescriptor.hueGreen,
        'rejected' => BitmapDescriptor.hueRed,
        _ => BitmapDescriptor.hueOrange,
      };

      return Marker(
        markerId: MarkerId(survey.id),
        position: LatLng(survey.latitude, survey.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: survey.blockName,
          snippet:
              '${survey.centralName} • ${survey.totalFloors} floors • '
              '${survey.totalApartments} apartments',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SurveyDetailScreen(survey: survey),
            ),
          ),
        ),
      );
    }).toSet();

    final selectedPoint = _selectedPoint;
    if (selectedPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected-block'),
          position: selectedPoint,
          zIndexInt: 1000,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'New survey location'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BlockSurvey>>(
      stream: _repository.watchSurveys(),
      builder: (context, snapshot) {
        final allSurveys = snapshot.data ?? const <BlockSurvey>[];
        _latestSurveys = allSurveys;
        final surveys = widget.centralId == null
            ? allSurveys
            : allSurveys
                  .where((survey) => survey.centralId == widget.centralId)
                  .toList();

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _cairo,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                final position = _currentPosition;
                if (position != null) {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 19,
                      ),
                    ),
                  );
                }
              },
              onTap: _selectPoint,
              markers: _markers(surveys),
              myLocationEnabled: _currentPosition != null,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(
                bottom: _selectedPoint == null ? 40 : 170,
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 72,
              child: _InstructionCard(
                loading: snapshot.connectionState == ConnectionState.waiting,
                surveyCount: surveys.length,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: FloatingActionButton.small(
                heroTag: 'my-location',
                onPressed: _loadingLocation ? null : _findCurrentLocation,
                tooltip: 'My location',
                child: _loadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
            if (_locationError != null)
              Positioned(
                top: 88,
                left: 12,
                right: 12,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _locationError!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _findCurrentLocation,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selectedPoint != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_location_alt_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected block',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                                '${_selectedPoint!.longitude.toStringAsFixed(6)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _selectedPoint = null),
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                        ),
                        FilledButton(
                          onPressed: _startSurvey,
                          child: const Text('Survey'),
                        ),
                      ],
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

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.loading, required this.surveyCount});

  final bool loading;
  final int surveyCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tap the exact apartment block to start a survey.',
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            if (loading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Badge(
                label: Text('$surveyCount'),
                child: const Icon(Icons.apartment_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

enum _NearbyAction { cancel, openExisting, continueSurvey }

String _friendlyLocationError(Object error) {
  if (error is SurveyLocationException) {
    return error.message;
  }
  return 'Could not read GPS. You can still select the block manually.';
}
