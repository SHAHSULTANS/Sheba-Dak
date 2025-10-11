import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsheba/core/location/presentation/bloc/location_event.dart';
import 'package:smartsheba/core/location/presentation/bloc/location_state.dart';
import '../bloc/location_bloc.dart';

class LocationPermissionPage extends StatelessWidget {
  const LocationPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Location Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'লোকেশন এক্সেস প্রয়োজন',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'সেবা প্রদানের জন্য আপনার বর্তমান অবস্থান জানা প্রয়োজন। '
                'আপনার লোকেশন শুধুমাত্র সার্ভিস বুকিং এবং প্রোভাইডার খোঁজার জন্য ব্যবহার করা হবে।',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 2),
              
              // Permission Buttons
              BlocConsumer<LocationBloc, LocationState>(
                listener: (context, state) {
                  if (state.hasPermission) {
                    Navigator.of(context).pop(true);
                  } else if (state.isPermissionDeniedForever) {
                    _showPermissionDeniedDialog(context);
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : () {
                            context.read<LocationBloc>().add(
                              const RequestLocationPermission(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'লোকেশন এক্সেস দিন',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'এখনই নয়',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('লোকেশন পারমিশন প্রয়োজন'),
        content: const Text(
          'লোকেশন এক্সেস ম্যানুয়ালি সক্ষম করতে হবে। '
          'দয়া করে অ্যাপ সেটিংস থেকে লোকেশন পারমিশন দিন।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open app settings
              // You can use app_settings package for this
            },
            child: const Text('সেটিংস'),
          ),
        ],
      ),
    );
  }
}