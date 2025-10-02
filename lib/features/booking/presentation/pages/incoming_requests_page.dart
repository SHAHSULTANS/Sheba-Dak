import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/theme/app_theme.dart';
import 'package:smartsheba/core/utils/dummy_data.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/booking/presentation/bloc/booking_bloc.dart';
import '../../domain/entities/booking_entity.dart';

class IncomingRequestsPage extends StatefulWidget {
  const IncomingRequestsPage({super.key});

  @override
  State<IncomingRequestsPage> createState() => _IncomingRequestsPageState();
}

class _IncomingRequestsPageState extends State<IncomingRequestsPage> {
  int _refreshCounter = 0;
  final Map<String, bool> _processingBookings = {};

  void _updateBookingStatus(BuildContext context, BookingEntity booking, BookingStatus status) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _processingBookings[booking.id] = true;
      });

      context.read<BookingBloc>().add(
        UpdateBookingStatusEvent(
          id: booking.id,
          newStatus: status,
          authRole: 'provider', // Fixed: Direct string
        ),
      );
    }
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _refreshCounter++;
      _processingBookings.clear();
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ রিকোয়েস্ট তালিকা রিফ্রেশ করা হয়েছে'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
            ),
          ),
        ),
        title: const Text(
          'নতুন বুকিং রিকোয়েস্ট',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/provider-dashboard'),
        ),
        actions: [
          BlocBuilder<BookingBloc, BookingState>(
            builder: (context, bookingState) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.refresh, color: Colors.white),
                    if (bookingState is BookingLoading)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _refreshBookings,
                tooltip: 'রিফ্রেশ করুন',
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BookingBloc, BookingState>(
            listener: (context, bookingState) {
              if (bookingState is BookingSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ বুকিং স্ট্যাটাস আপডেট সফল'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                // Auto-refresh after successful update
                _refreshBookings();
              } else if (bookingState is BookingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ ${bookingState.message}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {
                  _processingBookings.clear();
                });
              }
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          key: ValueKey(_refreshCounter),
          builder: (context, authState) {
            if (authState is Authenticated && authState.user.role == Role.provider) {
              final bookings = DummyData.getPendingBookingsByProvider(authState.user.id);

              if (bookings.isEmpty) {
                return _buildEmptyState(context, theme);
              }

              return RefreshIndicator(
                onRefresh: _refreshBookings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final isProcessing = _processingBookings[booking.id] == true;

                    return _buildBookingCard(context, booking, theme, isProcessing);
                  },
                ),
              );
            }

            return _buildUnauthorizedState(context, theme);
          },
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingEntity booking, ThemeData theme, bool isProcessing) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: isProcessing ? 1 : 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isProcessing ? Colors.grey.shade100 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      _getCategoryIcon(booking.serviceCategory),
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      booking.serviceCategory,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isProcessing ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isProcessing ? 'প্রক্রিয়াকরণ...' : 'অপেক্ষমাণ',
                      style: TextStyle(
                        color: isProcessing ? Colors.grey : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Details
              _buildInfoRow(Icons.calendar_today, 'তারিখ: ${_formatDate(booking.scheduledAt)}', theme, isProcessing),
              _buildInfoRow(Icons.access_time, 'সময়: ${_formatTime(booking.scheduledAt)}', theme, isProcessing),
              _buildInfoRow(Icons.attach_money, 'মূল্য: ৳${booking.price.toStringAsFixed(0)}', theme, isProcessing),
              if (booking.description != null && booking.description!.isNotEmpty)
                _buildInfoRow(Icons.description, 'বিবরণ: ${booking.description!}', theme, isProcessing),
              
              const SizedBox(height: 16),
              
              // Actions or Processing State
              if (isProcessing) _buildProcessingState(),
              if (!isProcessing) _buildActionButtons(context, booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme, bool isProcessing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isProcessing ? Colors.grey : Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isProcessing ? Colors.grey : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingEntity booking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Chat Button
        IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
          onPressed: () {
            context.go('/chat/${booking.id}/${booking.customerId}/${booking.providerId}');
          },
          tooltip: 'গ্রাহকের সাথে চ্যাট করুন',
        ),
        
        // Action Buttons
        Row(
          children: [
            // Accept Button
            ElevatedButton.icon(
              onPressed: () => _showConfirmationDialog(
                context, 
                booking, 
                BookingStatus.confirmed,
                'বুকিং গ্রহণ করুন',
                'আপনি কি এই বুকিংটি গ্রহণ করতে চান? এটি আপনার কাজের তালিকায় যুক্ত হবে।',
                Colors.green,
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('গ্রহণ করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 8),
            
            // Decline Button
            OutlinedButton.icon(
              onPressed: () => _showConfirmationDialog(
                context, 
                booking, 
                BookingStatus.cancelled,
                'বুকিং প্রত্যাখ্যান করুন', 
                'আপনি কি এই বুকিংটি প্রত্যাখ্যান করতে চান? এটি গ্রাহককে বাতিল বলে দেখানো হবে।',
                Colors.red,
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('প্রত্যাখ্যান করুন'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'প্রক্রিয়াকরণ চলছে...',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog(
    BuildContext context, 
    BookingEntity booking, 
    BookingStatus status, 
    String title, 
    String content,
    Color color,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: color)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না, ফিরে যান'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Text(status == BookingStatus.confirmed ? 'গ্রহণ করুন' : 'প্রত্যাখ্যান করুন'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _updateBookingStatus(context, booking, status);
    }
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'কোনো নতুন রিকোয়েস্ট নেই',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'গ্রাহকদের রিকোয়েস্ট এলে এখানে দেখানো হবে',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/provider-dashboard'),
            icon: const Icon(Icons.dashboard),
            label: const Text('ড্যাশবোর্ডে ফিরুন'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'অনুমোদিত নয়',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'শুধুমাত্র প্রোভাইডাররা এই পৃষ্ঠাটি দেখতে পারেন',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing': return Icons.plumbing;
      case 'electrical': return Icons.electrical_services;
      case 'cleaning': return Icons.cleaning_services;
      default: return Icons.build;
    }
  }

  String _formatDate(DateTime date) => '${date.day}-${date.month}-${date.year}';
  
  String _formatTime(DateTime date) {
    final time = TimeOfDay.fromDateTime(date);
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}