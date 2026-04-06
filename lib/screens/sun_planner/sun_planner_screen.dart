import 'dart:math' as math;

import 'package:camera_assistant/domain/calculators/sun_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class SunPlannerScreen extends StatefulWidget {
  final AppSettings? settings;

  const SunPlannerScreen({super.key, this.settings});

  @override
  State<SunPlannerScreen> createState() => _SunPlannerScreenState();
}

class _SunPlannerScreenState extends State<SunPlannerScreen> {
  final _lat = TextEditingController(text: '48.8566');
  final _lon = TextEditingController(text: '2.3522');
  final _mapController = MapController();

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _result = 'Sun details will appear here.';
  SolarPosition? _solarPosition;

  DateTime get _activeDateTime => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  String _formatSelectedTime() {
    final use12Hour = (widget.settings?.timeUnit ?? '24h') == '12h';
    final hour24 = _time.hour;
    final minute = _time.minute.toString().padLeft(2, '0');
    if (!use12Hour) {
      return '${hour24.toString().padLeft(2, '0')}:$minute';
    }
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    _lat.addListener(_calculateLive);
    _lon.addListener(_calculateLive);
    _calculate();
  }

  @override
  void dispose() {
    _lat.removeListener(_calculateLive);
    _lon.removeListener(_calculateLive);
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _calculateLive() => _calculate(live: true);

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (selected != null) {
      setState(() => _date = selected);
      _calculate();
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (selected != null) {
      setState(() => _time = selected);
      _calculate();
    }
  }

  void _setMapLocation(double lat, double lon) {
    _lat.text = lat.toStringAsFixed(5);
    _lon.text = lon.toStringAsFixed(5);
    _mapController.move(LatLng(lat, lon), _mapController.camera.zoom);
  }

  Future<void> _useCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(
          const SnackBar(
            content:
                Text('Location service is disabled. Enable GPS and try again.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _setMapLocation(position.latitude, position.longitude);
      _calculate();
    } on MissingPluginException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Location plugin not available yet. Fully restart with flutter run.'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to fetch current location.')),
      );
    }
  }

  void _calculate({bool live = false}) {
    final lat = parseDouble(_lat.text);
    final lon = parseDouble(_lon.text);

    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      setState(() {
        _result = live
            ? _result
            : 'Use valid coordinates (lat -90..90, lon -180..180).';
        _solarPosition = null;
      });
      return;
    }

    final tzHours =
        DateTime(_date.year, _date.month, _date.day).timeZoneOffset.inMinutes /
            60.0;

    String fmt(DateTime? dt) {
      if (dt == null) {
        return 'N/A';
      }
      final use12Hour = (widget.settings?.timeUnit ?? '24h') == '12h';
      return formatTime(dt, use12Hour: use12Hour);
    }

    final sunrise =
        SunCalculator.calculateSunEvent(_date, lat, lon, 90.833, true, tzHours);
    final sunset = SunCalculator.calculateSunEvent(
        _date, lat, lon, 90.833, false, tzHours);

    final civilDawn =
        SunCalculator.calculateSunEvent(_date, lat, lon, 96, true, tzHours);
    final civilDusk =
        SunCalculator.calculateSunEvent(_date, lat, lon, 96, false, tzHours);

    final nauticalDawn =
        SunCalculator.calculateSunEvent(_date, lat, lon, 102, true, tzHours);
    final nauticalDusk =
        SunCalculator.calculateSunEvent(_date, lat, lon, 102, false, tzHours);

    final astroDawn =
        SunCalculator.calculateSunEvent(_date, lat, lon, 108, true, tzHours);
    final astroDusk =
        SunCalculator.calculateSunEvent(_date, lat, lon, 108, false, tzHours);

    final blueStartMorning =
        SunCalculator.calculateSunEvent(_date, lat, lon, 96, true, tzHours);
    final blueEndMorning =
        SunCalculator.calculateSunEvent(_date, lat, lon, 94, true, tzHours);
    final blueStartEvening =
        SunCalculator.calculateSunEvent(_date, lat, lon, 94, false, tzHours);
    final blueEndEvening =
        SunCalculator.calculateSunEvent(_date, lat, lon, 96, false, tzHours);

    final goldenStartMorning =
        SunCalculator.calculateSunEvent(_date, lat, lon, 94, true, tzHours);
    final goldenEndMorning =
        SunCalculator.calculateSunEvent(_date, lat, lon, 84, true, tzHours);
    final goldenStartEvening =
        SunCalculator.calculateSunEvent(_date, lat, lon, 84, false, tzHours);
    final goldenEndEvening =
        SunCalculator.calculateSunEvent(_date, lat, lon, 94, false, tzHours);

    final solar =
        SunCalculator.calculateSolarPosition(_activeDateTime, lat, lon);

    setState(() {
      _solarPosition = solar;
      _result =
          'Date: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}\n'
          'Time: ${_formatSelectedTime()}\n\n'
          'Sunrise: ${fmt(sunrise)}\n'
          'Sunset: ${fmt(sunset)}\n\n'
          'Civil dawn/dusk: ${fmt(civilDawn)} / ${fmt(civilDusk)}\n'
          'Nautical dawn/dusk: ${fmt(nauticalDawn)} / ${fmt(nauticalDusk)}\n'
          'Astronomical dawn/dusk: ${fmt(astroDawn)} / ${fmt(astroDusk)}\n\n'
          'Blue hour AM: ${fmt(blueStartMorning)} - ${fmt(blueEndMorning)}\n'
          'Golden hour AM: ${fmt(goldenStartMorning)} - ${fmt(goldenEndMorning)}\n'
          'Golden hour PM: ${fmt(goldenStartEvening)} - ${fmt(goldenEndEvening)}\n'
          'Blue hour PM: ${fmt(blueStartEvening)} - ${fmt(blueEndEvening)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lat = parseDouble(_lat.text) ?? 48.8566;
    final lon = parseDouble(_lon.text) ?? 2.3522;
    final mapCenter = LatLng(lat.clamp(-90.0, 90.0), lon.clamp(-180.0, 180.0));
    final sunEndpoint = _solarPosition == null
        ? null
        : _destinationPoint(mapCenter, _solarPosition!.azimuthDeg, 5.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionCard(
            title: 'Position & Time',
            subtitle: 'Tap the map or enter coordinates to update the plan.',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 260,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 10,
                      onTap: (tapPos, point) {
                        _setMapLocation(point.latitude, point.longitude);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'camera_assistant',
                        tileProvider: NetworkTileProvider(
                          cachingProvider: const DisabledMapCachingProvider(),
                        ),
                      ),
                      if (sunEndpoint != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [mapCenter, sunEndpoint],
                              color: Colors.orange,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: mapCenter,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.place,
                                color: Colors.red, size: 32),
                          ),
                          if (sunEndpoint != null)
                            Marker(
                              point: sunEndpoint,
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.wb_sunny,
                                  color: Colors.amber, size: 28),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              NumField(controller: _lat, label: 'Latitude', suffix: 'deg'),
              NumField(controller: _lon, label: 'Longitude', suffix: 'deg'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  TextButton(
                      onPressed: _pickDate, child: const Text('Change date')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text('Time: ${_formatSelectedTime()}'),
                  ),
                  TextButton(
                      onPressed: _pickTime, child: const Text('Change time')),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _mapController.rotate(0),
                  icon: const Icon(Icons.explore_off),
                  label: const Text('Reset Map North'),
                ),
              ),
            ],
          ),
          SectionCard(
            title: 'Sun Position',
            children: [
              if (_solarPosition == null)
                const Text('Enter a valid location to see the sun position.')
              else
                _SunPositionView(position: _solarPosition!),
            ],
          ),
          SectionCard(title: 'Output', children: [Text(_result)]),
        ],
      ),
    );
  }

  LatLng _destinationPoint(LatLng start, double bearingDeg, double distanceKm) {
    const earthRadiusKm = 6371.0;
    final distanceRad = distanceKm / earthRadiusKm;
    final bearing = bearingDeg * math.pi / 180.0;
    final lat1 = start.latitude * math.pi / 180.0;
    final lon1 = start.longitude * math.pi / 180.0;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(distanceRad) +
          math.cos(lat1) * math.sin(distanceRad) * math.cos(bearing),
    );

    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(distanceRad) * math.cos(lat1),
          math.cos(distanceRad) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180.0 / math.pi, lon2 * 180.0 / math.pi);
  }
}

class _SunPositionView extends StatelessWidget {
  const _SunPositionView({required this.position});

  final SolarPosition position;

  @override
  Widget build(BuildContext context) {
    final az = position.azimuthDeg;
    final alt = position.altitudeDeg;
    final normalizedAz = az / 360.0;
    final normalizedAlt = ((alt + 90) / 180).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Azimuth: ${az.toStringAsFixed(1)}°'),
        Text('Elevation: ${alt.toStringAsFixed(1)}°'),
        const SizedBox(height: 10),
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final x = constraints.maxWidth * normalizedAz;
              final y = constraints.maxHeight * (1 - normalizedAlt);
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: constraints.maxHeight * 0.5,
                    child: Container(height: 1, color: Colors.white24),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: constraints.maxHeight * 0.5,
                    child: Center(
                      child: Text(
                        'Horizon',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x - 10).clamp(0.0, constraints.maxWidth - 20),
                    top: (y - 10).clamp(0.0, constraints.maxHeight - 20),
                    child: const Icon(Icons.wb_sunny,
                        color: Colors.amber, size: 20),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
