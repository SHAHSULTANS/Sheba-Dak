import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsheba/core/network/api_client.dart';
import '../../domain/entities/booking_entity.dart';

abstract class BookingEvent {}

class CreateBookingEvent extends BookingEvent {
  final String customerId;
  final String providerId;
  final String serviceCategory;
  final DateTime scheduledAt;
  final double price;
  final String? description;

  CreateBookingEvent({
    required this.customerId,
    required this.providerId,
    required this.serviceCategory,
    required this.scheduledAt,
    required this.price,
    this.description,
  });
}

class UpdateBookingStatusEvent extends BookingEvent {
  final String id;
  final BookingStatus newStatus;
  final String authRole;

  UpdateBookingStatusEvent({
    required this.id,
    required this.newStatus,
    required this.authRole,
  });
}

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  final String bookingId; // Added for navigation
  BookingSuccess(this.bookingId);
}

class BookingFailure extends BookingState {
  final String message;
  BookingFailure(this.message);
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(BookingInitial()) {
    on<CreateBookingEvent>((event, emit) async {
      emit(BookingLoading());
      try {
        final response = await ApiClient.createBooking(
          event.customerId,
          event.providerId,
          event.serviceCategory,
          event.scheduledAt,
          event.price,
          event.description,
        );
        if (response['success'] == true) {
          emit(BookingSuccess(response['id']));
        } else {
          emit(BookingFailure(response['message'] ?? 'বুকিং ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(BookingFailure('বুকিং করার সময় ত্রুটি: $e'));
      }
    });

    on<UpdateBookingStatusEvent>((event, emit) async {
      emit(BookingLoading());
      try {
        final response = await ApiClient.updateBookingStatus(
          event.id,
          event.newStatus,
          event.authRole,
        );
        if (response['success'] == true) {
          emit(BookingSuccess(event.id));
        } else {
          emit(BookingFailure(response['message'] ?? 'স্ট্যাটাস আপডেট ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        emit(BookingFailure('স্ট্যাটাস আপডেট ত্রুটি: $e'));
      }
    });
  }
}