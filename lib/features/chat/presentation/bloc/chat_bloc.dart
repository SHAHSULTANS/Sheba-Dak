import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/features/chat/domain/entities/chat_message.dart';

abstract class ChatEvent {}

class LoadMessagesEvent extends ChatEvent {
  final String bookingId;
  final String authUserId;
  final String bookingCustomerId;
  final String bookingProviderId;

  LoadMessagesEvent({
    required this.bookingId,
    required this.authUserId,
    required this.bookingCustomerId,
    required this.bookingProviderId,
  });
}

class SendMessageEvent extends ChatEvent {
  final ChatMessage message;
  final String bookingCustomerId;
  final String bookingProviderId;

  SendMessageEvent(this.message, this.bookingCustomerId, this.bookingProviderId);
}

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  ChatLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;

  ChatError(this.message);
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<LoadMessagesEvent>((event, emit) async {
      emit(ChatLoading());
      try {
        final messages = await ApiClient.fetchMessages(
          event.bookingId,
          event.authUserId,
          event.bookingCustomerId,
          event.bookingProviderId,
        );
        emit(ChatLoaded(messages));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });

    on<SendMessageEvent>((event, emit) async {
      try {
        await ApiClient.sendMessage(
          event.message,
          event.message.senderId,
          event.bookingCustomerId,
          event.bookingProviderId,
        );
        // Reload messages after sending
        final messages = await ApiClient.fetchMessages(
          event.message.bookingId,
          event.message.senderId,
          event.bookingCustomerId,
          event.bookingProviderId,
        );
        emit(ChatLoaded(messages));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });
  }
}