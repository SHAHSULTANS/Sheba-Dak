// lib/core/location/presentation/pages/address_input_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartsheba/core/location/domain/repositories/location_repository.dart';
import 'package:smartsheba/core/location/presentation/bloc/location_event.dart';
import 'package:smartsheba/core/location/presentation/bloc/location_state.dart';
import '../bloc/location_bloc.dart';
import '../../domain/entities/address_entity.dart';
import 'location_permission_page.dart';

class AddressInputPage extends StatefulWidget {
  final AddressEntity? initialAddress;
  const AddressInputPage({super.key, this.initialAddress});

  @override
  State<AddressInputPage> createState() => _AddressInputPageState();
}

class _AddressInputPageState extends State<AddressInputPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _searchController.text = widget.initialAddress!.formattedAddress;
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty && query.length > 2) {
        context.read<LocationBloc>().add(SearchAddress(query));
      }
    });
  }

  void _selectAddress(AddressEntity address) {
    context.read<LocationBloc>().add(SelectAddress(address));
  }

  // ✅ UPDATED: Handles permission request BEFORE sending event to BLoC
  void _useCurrentLocation() async {
    print("yes");
    // Step 1: Check current permission status
    var permission = await Geolocator.checkPermission();

    // Step 2: If denied, request permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Step 3: Handle final permission state
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        // permission == LocationPermission.restricted ||
        permission == LocationPermission.unableToDetermine) {
      
      // Show custom permission guide page
      final granted = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationPermissionPage()),
      );

      if (granted == true) {
        context.read<LocationBloc>().add(const GetCurrentLocation());
      }
      return;
    }

    // Step 4: Check if location service is enabled
    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লোকেশন সার্ভিস চালু করুন।')),
      );
      return;
    }

    // Step 5: All good — request current location
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      context.read<LocationBloc>().add(const GetCurrentLocation());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ঠিকানা নির্বাচন করুন'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _useCurrentLocation,
            tooltip: 'বর্তমান লোকেশন ব্যবহার করুন',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'ঠিকানা খুঁজুন...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<LocationBloc, LocationState>(
              listener: (context, state) async {
                // Handle successful address selection
                if (state.selectedAddress != null) {
                  final result = state.selectedAddress;
                  context.read<LocationBloc>().add(const SelectAddress(null));
                  Navigator.of(context).pop(result);
                  return;
                }

                // Trigger reverse geocoding after getting coordinates
                if (state.currentLocation != null && state.selectedAddress == null) {
                  context.read<LocationBloc>().add(
                    ReverseGeocodeLocation(state.currentLocation!),
                  );
                }

                // Handle errors from BLoC (e.g., network, geocoding fail)
                if (state.error != null) {
                  final errorType = state.error!.type;
                  final errorMessage = state.error!.message;

                  if (errorType == LocationErrorType.serviceDisabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('লোকেশন সার্ভিস চালু করুন।')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }

                  context.read<LocationBloc>().add(const ClearLocationError());
                }
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.searchResults.isEmpty && _searchController.text.isEmpty) {
                  return _buildEmptyState(context);
                }

                if (state.searchResults.isEmpty && _searchController.text.isNotEmpty) {
                  return _buildNoResults(context);
                }

                return ListView.builder(
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final address = state.searchResults[index];
                    return _buildAddressItem(address);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          'ঠিকানা খুঁজুন',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'সার্ভিসের লোকেশন খুঁজতে ঠিকানা লিখুন',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          'কোন ফলাফল পাওয়া যায়নি',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ভিন্ন কীওয়ার্ড দিয়ে চেষ্টা করুন',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressItem(AddressEntity address) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined, color: Colors.blue),
      title: Text(
        address.shortAddress.isNotEmpty
            ? address.shortAddress
            : address.formattedAddress,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        address.cityArea.isNotEmpty
            ? address.cityArea
            : address.formattedAddress,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _selectAddress(address),
    );
  }
}