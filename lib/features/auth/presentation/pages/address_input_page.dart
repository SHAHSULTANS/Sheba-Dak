import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartsheba/core/services/location_service.dart';
import 'package:smartsheba/core/utils/validators.dart';
import 'package:smartsheba/core/widgets/static_map_widget.dart';
import '../bloc/auth_bloc.dart';

class AddressInputPage extends StatefulWidget {
  const AddressInputPage({super.key});

  @override
  State<AddressInputPage> createState() => _AddressInputPageState();
}

class _AddressInputPageState extends State<AddressInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  bool _locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationPermissionDenied = true;
            _isLoadingLocation = false;
          });
          _showPermissionDeniedDialog();
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationPermissionDenied = true;
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('লোকেশন পারমিশন দেওয়া হয়নি। ম্যানুয়ালি ঠিকানা লিখুন।'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _getCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationPermissionDenied = true;
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('পারমিশন চেক করতে সমস্যা: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService().getCurrentLocation();

      if (mounted) {
        setState(() {
          _currentLocation = position;
          _locationPermissionDenied = false;
          _addressController.text =
              'Detected: Near ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationPermissionDenied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('লোকেশন আনতে ব্যর্থ হয়েছে: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('লোকেশন পারমিশন প্রয়োজন'),
        content: const Text(
          'লোকেশন পারমিশন স্থায়ীভাবে বন্ধ করা হয়েছে। সেটিংস থেকে চালু করুন অথবা ম্যানুয়ালি ঠিকানা লিখুন।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ম্যানুয়ালি লিখব'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
            },
            child: const Text('সেটিংস খুলুন'),
          ),
        ],
      ),
    );
  }

  // ✅ CRITICAL: SIMPLIFIED CONFIRM METHOD - NO BLO C UPDATES DURING BOOKING
  void _confirmAddress() {
    if (_formKey.currentState?.validate() ?? false) {
      // Build full address
      final fullAddressParts = [
        _addressController.text.trim(),
        _cityController.text.trim(),
        if (_postalCodeController.text.trim().isNotEmpty)
          _postalCodeController.text.trim(),
      ].where((part) => part.isNotEmpty).toList();

      final fullAddress = fullAddressParts.join(', ');

      if (fullAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('কমপক্ষে একটি ঠিকানার তথ্য দিন'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = {
        'address': fullAddress,
        'position': _currentLocation,
        'city': _cityController.text.trim(),
        'postalCode': _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
      };

      print('🔍 AddressInputPage: Confirming address: $fullAddress');
      print('🔍 Result: $result');
      print('🔍 Can pop: ${Navigator.of(context).canPop()}');

      // ✅ IMMEDIATE POP - NO DELAYS, NO BLO C UPDATES
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
        print('🔍 Popped with result');
      } else {
        print('🔍 Cannot pop, using context.pop fallback');
        // Fallback for edge cases
        Navigator.of(context, rootNavigator: true).pop(result);
      }

      // ✅ NO AuthBloc update here - it interferes with booking flow
      // Profile updates should happen separately in profile settings
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে সকল প্রয়োজনীয় ফিল্ড পূরণ করুন'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সেবার ঠিকানা'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationPermissionDenied
                            ? 'লোকেশন পারমিশন নেই। ম্যানুয়ালি ঠিকানা লিখুন।'
                            : 'আপনার সেবার ঠিকানা প্রদান করুন',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'বিস্তারিত ঠিকানা *',
                  hintText: 'ঘর নং, রাস্তা, এলাকা ইত্যাদি',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'বিস্তারিত ঠিকানা দিন';
                  }
                  return Validators.validateAddress(value);
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // City Field
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'শহর *',
                  hintText: 'ঢাকা, চট্টগ্রাম ইত্যাদি',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.requiredValidator,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Postal Code Field
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'পোস্টাল কোড (ঐচ্ছিক)',
                  hintText: 'যেমন: ১২০০',
                  prefixIcon: Icon(Icons.local_post_office),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.postalCodeValidator,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _requestLocationPermission,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _locationPermissionDenied ? Icons.location_off : Icons.my_location,
                        ),
                  label: Text(
                    _currentLocation == null
                        ? (_locationPermissionDenied ? 'লোকেশন আবার চেষ্টা করুন' : 'আমার লোকেশন পান')
                        : 'লোকেশন আপডেট করুন',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _locationPermissionDenied ? Colors.orange : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Static Map (if location available)
              if (_currentLocation != null) ...[
                const Text(
                  'লোকেশন নিশ্চিত করুন:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: StaticMapWidget(
                      lat: _currentLocation!.latitude,
                      lng: _currentLocation!.longitude,
                      markerLabel: 'আপনি',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'লোকেশন সনাক্ত: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.green.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'নিশ্চিত করুন ও সংরক্ষণ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Help text
              Text(
                _currentLocation == null
                    ? 'লোকেশন ছাড়াও ম্যানুয়াল ঠিকানা দিতে পারবেন'
                    : 'ঠিকানা কনফার্ম করে সংরক্ষণ করুন',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}