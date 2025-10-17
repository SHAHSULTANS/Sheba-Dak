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
      // ✅ FIX: Call as static method without creating instance
      final bytes = await LocationService.fetchStaticMap(widget.lat, widget.lng);
      if (mounted) {
        setState(() {
          _mapBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Map loading error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      // Only show snackbar if the widget is still in the tree
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('মানচিত্র লোড করতে সমস্যা: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'মানচিত্র লোড হচ্ছে...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _mapBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _mapBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorState();
                    },
                  ),
                )
              : _buildErrorState(),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'মানচিত্র লোড হয়নি',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadMap,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('আবার চেষ্টা করুন'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}