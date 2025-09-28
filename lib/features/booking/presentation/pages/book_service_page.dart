// lib/features/booking/presentation/pages/book_service_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart'; // Role enum

class BookServicePage extends StatefulWidget {
  final String providerId;
  final String serviceCategory;
  final double price;

  const BookServicePage({
    super.key,
    required this.providerId,
    required this.serviceCategory,
    required this.price,
  });

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final descriptionController = TextEditingController();

  DateTime? get scheduledDateTime {
    if (selectedDate == null || selectedTime == null) return null;
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() => selectedTime = pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সেবা বুক করুন', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Show unauthorized message only if NOT Authenticated AND NOT Loading
          if (state is! Authenticated && state is! AuthLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'বুকিং দেওয়ার জন্য আপনাকে একজন গ্রাহক হিসেবে লগইন করতে হবে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.error),
                ),
              ),
            );
          }

          // Check if authenticated customer
          final bool isCustomer = state is Authenticated && state.user.role == Role.customer;

          // Block non-customer users
          if (state is Authenticated && !isCustomer) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'শুধুমাত্র গ্রাহকরাই বুকিং দিতে পারবেন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.error),
                ),
              ),
            );
          }

          // Authenticated customer OR loading: show form
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'পরিষেবা: ${widget.serviceCategory}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'মূল্য: ৳${widget.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16, color: AppColors.primary),
                ),
                const SizedBox(height: 24),

                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(
                    selectedDate == null
                        ? 'তারিখ নির্বাচন করুন'
                        : 'তারিখ: ${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                    style: TextStyle(
                      color: selectedDate == null ? AppColors.grey600 : AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDate,
                ),

                ListTile(
                  leading: const Icon(Icons.access_time, color: AppColors.primary),
                  title: Text(
                    selectedTime == null
                        ? 'সময় নির্বাচন করুন'
                        : 'সময়: ${selectedTime!.format(context)}',
                    style: TextStyle(
                      color: selectedTime == null ? AppColors.grey600 : AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectTime,
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'বিবরণ (ঐচ্ছিক)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is Authenticated) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('✅ বুকিং সফল হয়েছে! নিশ্চিতকরণের জন্য অপেক্ষা করুন।'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.go('/');
                      } else if (state is AuthError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('বুকিং ব্যর্থ: ${state.message}')),
                        );
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      if (isLoading) {
                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }

                      // Only show button if authenticated customer
                      if (!isCustomer) return const SizedBox.shrink();

                      return ElevatedButton.icon(
                        onPressed: () {
                          if (scheduledDateTime != null) {
                            context.read<AuthBloc>().add(
                                  CreateBookingEvent(
                                    providerId: widget.providerId,
                                    serviceCategory: widget.serviceCategory,
                                    scheduledAt: scheduledDateTime!,
                                    price: widget.price,
                                    description: descriptionController.text.isEmpty
                                        ? null
                                        : descriptionController.text,
                                  ),
                                );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('অনুগ্রহ করে তারিখ ও সময় নির্বাচন করুন।'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('বুকিং নিশ্চিত করুন', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
