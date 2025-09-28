import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';

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
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) setState(() => selectedTime = pickedTime);
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
          // Unauthorized / non-customer
          if (state is! Authenticated) {
            return _buildUnauthorizedMessage(
                'বুকিং দেওয়ার জন্য আপনাকে লগইন করতে হবে।');
          }
          if (state.user.role != Role.customer) {
            return _buildUnauthorizedMessage(
                'শুধুমাত্র গ্রাহকরাই বুকিং দিতে পারবেন।');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  icon: Icons.category_outlined,
                  title: 'পরিষেবা',
                  child: Text(widget.serviceCategory,
                      style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.attach_money,
                  title: 'মূল্য',
                  child: Text('৳${widget.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                _buildSelectableCard(
                  icon: Icons.calendar_today,
                  label: selectedDate == null
                      ? 'তারিখ নির্বাচন করুন'
                      : 'তারিখ: ${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                _buildSelectableCard(
                  icon: Icons.access_time,
                  label: selectedTime == null
                      ? 'সময় নির্বাচন করুন'
                      : 'সময়: ${selectedTime!.format(context)}',
                  onTap: _selectTime,
                ),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 32),
                _buildSubmitButton(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnauthorizedMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: AppColors.error)),
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon, required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              child,
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCard(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(label,
            style: TextStyle(
                color:
                    label.contains('নির্বাচন') ? AppColors.grey600 : AppColors.textPrimary)),
        trailing: const Icon(Icons.edit, color: Colors.grey),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'বিবরণ (ঐচ্ছিক)',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthState state) {
    final isLoading = state is AuthLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : () {
                if (scheduledDateTime != null) {
                  context.read<AuthBloc>().add(CreateBookingEvent(
                        providerId: widget.providerId,
                        serviceCategory: widget.serviceCategory,
                        scheduledAt: scheduledDateTime!,
                        price: widget.price,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                      ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('অনুগ্রহ করে তারিখ ও সময় নির্বাচন করুন।')));
                }
              },
        icon: isLoading
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline, color: Colors.white),
        label: Text(
          isLoading ? 'প্রসেসিং...' : 'বুকিং নিশ্চিত করুন',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}
