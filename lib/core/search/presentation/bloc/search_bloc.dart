import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../../../../core/location/domain/entities/location_entity.dart';
import '../../../../core/services/location_service.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

class SearchVoiceInput extends SearchEvent {
  final String text;
  const SearchVoiceInput(this.text);

  @override
  List<Object> get props => [text];
}

class SearchSuggestionRequested extends SearchEvent {
  final String query;
  const SearchSuggestionRequested(this.query);

  @override
  List<Object> get props => [query];
}

class SearchNearbyToggled extends SearchEvent {
  final bool enabled;
  const SearchNearbyToggled(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class SearchClear extends SearchEvent {
  @override
  List<Object> get props => [];
}

// States
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchSuccess extends SearchState {
  final SearchResultEntity results;
  final String query;
  final bool nearbyFilterEnabled;

  const SearchSuccess(this.results, this.query, {this.nearbyFilterEnabled = false});

  @override
  List<Object> get props => [results, query, nearbyFilterEnabled];
}

class SearchSuggestionLoaded extends SearchState {
  final List<String> suggestions;
  final String query;

  const SearchSuggestionLoaded(this.suggestions, this.query);

  @override
  List<Object> get props => [suggestions, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;
  final LocationService locationService;
  String _currentQuery = '';
  bool _nearbyFilterEnabled = false;
  LocationEntity? _userLocation;

  SearchBloc({
    required this.searchRepository,
    required this.locationService,
  }) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 500))
          .switchMap(mapper),
    );
    on<SearchVoiceInput>(_onSearchVoiceInput);

    on<SearchSuggestionRequested>(
      _onSearchSuggestionRequested,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<SearchNearbyToggled>(_onSearchNearbyToggled);
    on<SearchClear>(_onSearchClear);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentQuery = event.query;

    if (_currentQuery.isEmpty) {
      emit(SearchInitial());
      return;
    }
    emit(SearchLoading());
    try {
      // Get user location if nearby filter is enabled
      LocationEntity? userLocation;
      if (_nearbyFilterEnabled) {
        try {
          userLocation = await locationService.getCurrentLocationEntity();
          _userLocation = userLocation;
        } catch (e) {
          print('Location error: $e');
          // Continue search without location filtering
        }
      }
      final result = await searchRepository.searchServicesAndProviders(
        _currentQuery,
        userLocation: userLocation,
        nearbyFilterEnabled: _nearbyFilterEnabled,
        maxDistance: 50.0,
      );
      result.fold(
        (failure) => emit(SearchError(failure.message)),
        (results) => emit(SearchSuccess(
          results,
          _currentQuery,
          nearbyFilterEnabled: _nearbyFilterEnabled,
        )),
      );
    } catch (e) {
      emit(SearchError('সার্চ করতে সমস্যা: $e'));
    }
  }

  void _onSearchVoiceInput(
    SearchVoiceInput event,
    Emitter<SearchState> emit,
  ) {
    add(SearchQueryChanged(event.text));
  }

  Future<void> _onSearchSuggestionRequested(
    SearchSuggestionRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      return;
    }
    try {
      final result = await searchRepository.getSearchSuggestions(event.query);
      result.fold(
        (failure) => print('Suggestions error: ${failure.message}'),
        (suggestions) => emit(SearchSuggestionLoaded(suggestions, event.query)),
      );
    } catch (e) {
      // Don't emit error for suggestions failure
      print('Suggestions error: $e');
    }
  }

  void _onSearchNearbyToggled(
    SearchNearbyToggled event,
    Emitter<SearchState> emit,
  ) {
    _nearbyFilterEnabled = event.enabled;

    // Re-run search with new filter state if we have a current query
    if (_currentQuery.isNotEmpty) {
      add(SearchQueryChanged(_currentQuery));
    }
  }

  void _onSearchClear(
    SearchClear event,
    Emitter<SearchState> emit,
  ) {
    _currentQuery = '';
    _nearbyFilterEnabled = false;
    _userLocation = null;
    emit(SearchInitial());
  }
}