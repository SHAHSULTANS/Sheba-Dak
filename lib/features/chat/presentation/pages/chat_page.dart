import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:smartsheba/features/chat/domain/entities/chat_message.dart';
import 'package:smartsheba/features/auth/domain/entities/user_entity.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final String bookingId;
  final String customerId;
  final String providerId;

  const ChatPage({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late ChatBloc _chatBloc;
  
  // Animation controllers
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  
  // State variables
  bool _isSending = false;
  bool _showTypingIndicator = false;
  String _otherUserName = 'Provider';
  String _otherUserRole = 'Provider';

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc();
    
    // Initialize animations
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _startPolling();
    });

    // Auto-scroll when keyboard appears
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animated: true);
        });
      }
    });
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // Load messages
      _chatBloc.add(LoadMessagesEvent(
        bookingId: widget.bookingId,
        authUserId: authState.user.id,
        bookingCustomerId: widget.customerId,
        bookingProviderId: widget.providerId,
      ));
      
      // Load user details
      _loadOtherUserDetails(authState.user.id);
    }
  }

  void _loadOtherUserDetails(String currentUserId) async {
    try {
      final otherUserId = currentUserId == widget.customerId 
          ? widget.providerId 
          : widget.customerId;
      final user = await ApiClient.getUserById(otherUserId);
      
      setState(() {
        _otherUserName = user.name ?? 'User';
        _otherUserRole = currentUserId == widget.customerId ? 'Provider' : 'Customer';
      });
    } catch (e) {
      // Fallback to default names
    }
  }

  void _startPolling() {
    // Simulate typing indicator (in real app, this would come from WebSocket)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showTypingIndicator = true);
        _typingAnimationController.repeat(reverse: true);
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showTypingIndicator = false);
            _typingAnimationController.reset();
          }
        });
      }
    });
  }

  void _scrollToBottom({bool animated = false}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isSending = true);

    try {
      final message = ChatMessage(
        id: const Uuid().v4(),
        bookingId: widget.bookingId,
        senderId: authState.user.id,
        recipientId: authState.user.id == widget.customerId
            ? widget.providerId
            : widget.customerId,
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
      );

      _chatBloc.add(SendMessageEvent(
        message,
        widget.customerId,
        widget.providerId,
      ));

      _messageController.clear();
      _scrollToBottom(animated: true);
    } catch (e) {
      // Error handled by bloc
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Send Attachment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _handleImageSelection(),
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _handleCameraCapture(),
                    ),
                    _buildAttachmentOption(
                      icon: Icons.description,
                      label: 'Document',
                      onTap: () => _handleDocumentSelection(),
                    ),
                    _buildAttachmentOption(
                      icon: Icons.location_on,
                      label: 'Location',
                      onTap: () => _handleLocationShare(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleImageSelection() {
    Navigator.pop(context);
    // Implement image selection
  }

  void _handleCameraCapture() {
    Navigator.pop(context);
    // Implement camera capture
  }

  void _handleDocumentSelection() {
    Navigator.pop(context);
    // Implement document selection
  }

  void _handleLocationShare() {
    Navigator.pop(context);
    // Implement location sharing
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Custom App Bar
            _buildAppBar(theme),
            // Chat Area
            Expanded(
              child: BlocConsumer<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is! Authenticated ||
                      (authState.user.id != widget.customerId &&
                          authState.user.id != widget.providerId)) {
                    return _buildUnauthorizedView(theme);
                  }

                  return BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, chatState) {
                      List<ChatMessage> messages = [];
                      bool isLoading = false;

                      if (chatState is ChatLoading) {
                        isLoading = true;
                      } else if (chatState is ChatLoaded) {
                        messages = chatState.messages;
                      }

                      return Stack(
                        children: [
                          // Chat Messages
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: const AssetImage('assets'), // Add subtle pattern
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.grey.shade50.withOpacity(0.3),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                            child: isLoading
                                ? _buildLoadingView()
                                : messages.isEmpty
                                    ? _buildEmptyChatView()
                                    : _buildMessageList(messages, authState.user.id),
                          ),
                          // Typing Indicator
                          if (_showTypingIndicator) _buildTypingIndicator(),
                        ],
                      );
                    },
                  );
                },
                listener: (context, authState) {
                  if (authState is AuthError) {
                    _showErrorSnackBar(authState.message);
                  }
                },
              ),
            ),
            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              // User Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  _otherUserName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otherUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _otherUserRole,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showBookingDetails,
                tooltip: 'Booking Details',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, String currentUserId) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length + 1, // +1 for extra space at bottom
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const SizedBox(height: 8); // Bottom padding
        }
        
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showDateHeader = index == 0 || 
            _isDifferentDay(messages[index - 1].timestamp, message.timestamp);

        return Column(
          children: [
            // Date Header
            if (showDateHeader) _buildDateHeader(message.timestamp),
            // Message Bubble
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar for received messages
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                _otherUserName[0].toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFF2196F3)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Message Text
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            // Delivery Status
            Icon(
              Icons.done_all,
              size: 16,
              color: Colors.blue.shade300,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDateHeader(date),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Positioned(
      bottom: 80,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                _otherUserName[0].toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_otherUserName is typing',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _typingAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
            onPressed: _showAttachmentOptions,
            tooltip: 'Attach File',
          ),
          // Message Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  // Emoji Button
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600),
                    onPressed: () {}, // Implement emoji picker
                    tooltip: 'Emoji',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              tooltip: 'Send Message',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade300),
                const SizedBox(width: 8),
              ],
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'You are not authorized to view this chat',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/my-bookings'),
            child: const Text('Back to Bookings'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails() {
    // Implement booking details modal
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  bool _isDifferentDay(DateTime previous, DateTime current) {
    return previous.day != current.day ||
        previous.month != current.month ||
        previous.year != current.year;
  }
}