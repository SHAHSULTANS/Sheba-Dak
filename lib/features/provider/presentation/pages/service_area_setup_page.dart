// lib/features/provider/presentation/pages/service_area_setup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/theme/colors.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/features/provider/domain/entities/service_provider.dart';
// import 'package:smartsheba/c'

class ServiceAreaSetupPage extends StatefulWidget {
  final ServiceProvider? existingProvider;

  const ServiceAreaSetupPage({Key? key, this.existingProvider}) : super(key: key);

  @override
  State<ServiceAreaSetupPage> createState() => _ServiceAreaSetupPageState();
}

class _ServiceAreaSetupPageState extends State<ServiceAreaSetupPage> {
  final _formKey = GlobalKey<FormState>();
  late LatLng _businessLocation;
  double _serviceRadius = 10.0;
  final List<String> _servedAreas = [];
  final TextEditingController _areaController = TextEditingController();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getCurrentLocation();
  }

  void _initializeData() {
    if (widget.existingProvider != null) {
      _businessLocation = widget.existingProvider!.businessLocation ?? DummyData.dhanmondi;
      _serviceRadius = widget.existingProvider!.serviceRadius;
      _servedAreas.addAll(widget.existingProvider!.servedAreas);
      _isOnline = widget.existingProvider!.isOnline;
    } else {
      _businessLocation = DummyData.dhanmondi;
    }
  }

  void _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _businessLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('লোকেশন লোড করতে সমস্যা: $e')),
      );
    }
  }

  void _addServedArea() {
    final area = _areaController.text.trim();
    if (area.isNotEmpty && !_servedAreas.contains(area)) {
      setState(() {
        _servedAreas.add(area);
        _areaController.clear();
      });
    }
  }

  void _removeServedArea(String area) {
    setState(() {
      _servedAreas.remove(area);
    });
  }

  void _saveServiceArea() async {
    if (_formKey.currentState!.validate() && widget.existingProvider != null) {
      try {
        final result = await ApiClient.updateProviderServiceArea(
          widget.existingProvider!.id,
          _businessLocation,
          _serviceRadius,
          _servedAreas,
          _isOnline,
        );

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'সেভ করতে সমস্যা হয়েছে')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সেভ করতে সমস্যা: $e')),
        );
      }
    } else if (widget.existingProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('প্রোভাইডার তথ্য লোড করতে সমস্যা হয়েছে')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('সার্ভিস এরিয়া সেটআপ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveServiceArea,
            tooltip: 'সেভ করুন',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Business Location Section
              _buildLocationSection(),
              SizedBox(height: 24),
              
              // Service Radius Section
              _buildRadiusSection(),
              SizedBox(height: 24),
              
              // Served Areas Section
              _buildServedAreasSection(),
              SizedBox(height: 24),
              
              // Online Status
              _buildOnlineStatusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'বিজনেস লোকেশন',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Lat: ${_businessLocation.latitude.toStringAsFixed(4)}, '
              'Lng: ${_businessLocation.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.location_on),
              label: Text('কারেন্ট লোকেশন ব্যবহার করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'সার্ভিস রেডিয়াস',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text('${_serviceRadius.toStringAsFixed(1)} কিলোমিটার'),
            SizedBox(height: 8),
            Slider(
              value: _serviceRadius,
              min: 5.0,
              max: 50.0,
              divisions: 9,
              label: '${_serviceRadius.toStringAsFixed(1)} km',
              onChanged: (value) {
                setState(() {
                  _serviceRadius = value;
                });
              },
              activeColor: AppColors.primary,
            ),
            Text(
              'আপনি সর্বোচ্চ ${_serviceRadius.toStringAsFixed(1)} কিলোমিটার দূরত্ব পর্যন্ত সার্ভিস দিতে পারবেন',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServedAreasSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'সার্ভিস দেওয়া এলাকাসমূহ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: InputDecoration(
                      labelText: 'এলাকার নাম লিখুন',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: _addServedArea,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addServedArea(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_servedAreas.isNotEmpty) ...[
              Text(
                'সার্ভিসকৃত এলাকাসমূহ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _servedAreas.map((area) => Chip(
                  label: Text(area),
                  deleteIcon: Icon(Icons.close, size: 16),
                  onDeleted: () => _removeServedArea(area),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.online_prediction, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'অনলাইন স্ট্যাটাস',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Switch(
              value: _isOnline,
              onChanged: (value) {
                setState(() {
                  _isOnline = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
}