// lib/features/booking/presentation/bloc/booking_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsheba/core/network/api_client.dart';
import 'package:smartsheba/features/booking/domain/entities/booking_entity.dart';
import 'package:smartsheba/features/booking/domain/entities/review_entity.dart';

// ---------------- EVENTS ----------------
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

class SubmitReviewEvent extends BookingEvent {
  final String bookingId;
  final String providerId;
  final String customerId;
  final int rating;
  final String? comment;

  SubmitReviewEvent({
    required this.bookingId,
    required this.providerId,
    required this.customerId,
    required this.rating,
    this.comment,
  });
}

class ResetBookingState extends BookingEvent {}

// ---------------- STATES ----------------
abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  final String bookingId;
  final String message;

  BookingSuccess({required this.bookingId, required this.message});
}

class BookingFailure extends BookingState {
  final String message;

  BookingFailure(this.message);
}

class ReviewSuccess extends BookingState {
  final String reviewId;
  final String message;

  ReviewSuccess({
    required this.reviewId,
    required this.message,
  });
}

class ReviewFailure extends BookingState {
  final String message;

  ReviewFailure(this.message);
}

// ---------------- BLOC IMPLEMENTATION ----------------
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
          emit(BookingSuccess(
            bookingId: response['id'],
            message: response['message'] ?? 'বুকিং সফলভাবে তৈরি হয়েছে',
          ));
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
          emit(BookingSuccess(
            bookingId: event.id,
            message: response['message'] ?? 'স্ট্যাটাস আপডেট সফল',
          ));
        } else {
          emit(BookingFailure(response['message'] ?? 'স্ট্যাটাস আপডেট ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        print('DEBUG: UpdateBookingStatusEvent error: $e');
        emit(BookingFailure('স্ট্যাটাস আপডেট ত্রুটি: $e'));
      }
    });

    on<SubmitReviewEvent>((event, emit) async {
      emit(BookingLoading());
      try {
        final response = await ApiClient.submitReview(
          event.bookingId,
          event.providerId,
          event.customerId,
          event.rating,
          event.comment,
        );

        print('DEBUG: SubmitReviewEvent response: $response'); // Debug log
        if (response['success'] == true) {
          print('DEBUG: Emitting ReviewSuccess for reviewId: ${response['id']}');
          emit(ReviewSuccess(
            reviewId: response['id'],
            message: response['message'] ?? 'রিভিউ সফলভাবে জমা দেওয়া হয়েছে',
          ));
        } else {
          print('DEBUG: Emitting ReviewFailure: ${response['message'] ?? 'রিভিউ জমা ব্যর্থ হয়েছে'}');
          emit(ReviewFailure(response['message'] ?? 'রিভিউ জমা ব্যর্থ হয়েছে'));
        }
      } catch (e) {
        print('DEBUG: SubmitReviewEvent error: $e');
        emit(ReviewFailure('রিভিউ জমা করার সময় ত্রুটি: $e'));
      }
    });

    on<ResetBookingState>((event, emit) {
      print('DEBUG: Resetting BookingBloc state to BookingInitial');
      emit(BookingInitial());
    });
  }
}