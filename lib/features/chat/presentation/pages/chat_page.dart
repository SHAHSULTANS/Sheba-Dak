import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartsheba/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:smartsheba/features/chat/domain/entities/chat_message.dart';
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

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc(); // Bloc instance তৈরি
    // এখানে BlocProvider context ব্যবহার করা যাবে না, তাই postpone করা যায়
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        _chatBloc.add(LoadMessagesEvent(
          bookingId: widget.bookingId,
          authUserId: authState.user.id,
          bookingCustomerId: widget.customerId,
          bookingProviderId: widget.providerId,
        ));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.close(); // Bloc dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
              ),
            ),
          ),
          title: Text('চ্যাট: Booking ${widget.bookingId}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.go('/my-bookings'),
          ),
        ),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ত্রুটি: ${authState.message}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, authState) {
            if (authState is! Authenticated ||
                (authState.user.id != widget.customerId &&
                    authState.user.id != widget.providerId)) {
              return Center(
                child: Text(
                  'অনুমোদিত নয়: এই বুকিংয়ের সাথে সম্পর্কিত নয়',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return BlocConsumer<ChatBloc, ChatState>(
              listener: (context, chatState) {
                if (chatState is ChatLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  });
                } else if (chatState is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ ত্রুটি: ${chatState.message}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, chatState) {
                List<ChatMessage> messages = [];
                bool isLoading = false;

                if (chatState is ChatLoading) {
                  isLoading = true;
                } else if (chatState is ChatLoaded) {
                  messages = chatState.messages;
                }

                return Column(
                  children: [
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : messages.isEmpty
                              ? Center(
                                  child: Text(
                                    'কোনো মেসেজ নেই। চ্যাট শুরু করুন!',
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isMe = message.senderId == authState.user.id;
                                    return Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.symmetric(vertical: 4.0),
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.message,
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                            Text(
                                              message.timestamp
                                                  .toString()
                                                  .substring(11, 16),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'এখানে বার্তা লিখুন...',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF9C27B0)),
                            onPressed: () {
                              if (_messageController.text.trim().isNotEmpty) {
                                _chatBloc.add(SendMessageEvent(
                                  ChatMessage(
                                    id: const Uuid().v4(),
                                    bookingId: widget.bookingId,
                                    senderId: authState.user.id,
                                    recipientId: authState.user.id == widget.customerId
                                        ? widget.providerId
                                        : widget.customerId,
                                    message: _messageController.text.trim(),
                                    timestamp: DateTime.now(),
                                  ),
                                  widget.customerId,
                                  widget.providerId,
                                ));
                                _messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

