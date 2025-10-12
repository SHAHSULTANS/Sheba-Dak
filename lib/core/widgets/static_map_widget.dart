import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartsheba/core/services/location_service.dart';
import 'dart:typed_data';

class StaticMapWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String? markerLabel;
  const StaticMapWidget({super.key, required this.lat, required this.lng, this.markerLabel});

  @override
  State<StaticMapWidget> createState() => _StaticMapWidgetState();
}

class _StaticMapWidgetState extends State<StaticMapWidget> {
  Uint8List? _mapBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      final bytes = await LocationService().fetchStaticMap(widget.lat, widget.lng);
      if (mounted) {
        setState(() {
          _mapBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Map load failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _mapBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_mapBytes!, fit: BoxFit.cover),
              )
            : Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_off, size: 50, color: Colors.grey),
              );
  }
}