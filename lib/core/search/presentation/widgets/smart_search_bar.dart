import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import 'voice_search_button.dart';

class SmartSearchBar extends StatefulWidget {
  final Function(String) onSearchSubmitted;
  final bool showNearbyFilter;
  final ValueChanged<bool>? onNearbyFilterChanged;

  const SmartSearchBar({
    super.key,
    required this.onSearchSubmitted,
    this.showNearbyFilter = false,
    this.onNearbyFilterChanged,
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isListening = false;
  bool _nearbyFilterEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final query = _controller.text;
    if (query.isNotEmpty) {
      context.read<SearchBloc>().add(SearchSuggestionRequested(query));
    }
  }

  void _onVoiceResult(String text) {
    _controller.text = text;
    context.read<SearchBloc>().add(SearchVoiceInput(text));
    widget.onSearchSubmitted(text);
  }

  void _onListeningStateChange(bool isListening) {
    setState(() {
      _isListening = isListening;
    });
  }

  void _toggleNearbyFilter(bool value) {
    setState(() {
      _nearbyFilterEnabled = value;
    });
    context.read<SearchBloc>().add(SearchNearbyToggled(value));
    widget.onNearbyFilterChanged?.call(value);
  }

  void _clearSearch() {
    _controller.clear();
    context.read<SearchBloc>().add(SearchClear());
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: _isListening ? Colors.red : Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'সার্ভিস বা প্রোভাইডার সার্চ করুন...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: widget.onSearchSubmitted,
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSearch,
                  tooltip: 'পরিষ্কার করুন',
                ),
              if (widget.showNearbyFilter)
                BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(
                        _nearbyFilterEnabled ? Icons.location_on : Icons.location_off,
                        color: _nearbyFilterEnabled ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _toggleNearbyFilter(!_nearbyFilterEnabled),
                      tooltip: _nearbyFilterEnabled ? 'কাছাকাছি সার্চ চালু' : 'কাছাকাছি সার্চ বন্ধ',
                    );
                  },
                ),
              VoiceSearchButton(
                onVoiceResult: _onVoiceResult,
                onListeningStateChange: _onListeningStateChange,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchSuggestionLoaded && state.query == _controller.text) {
              return _buildSuggestions(state.suggestions);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: suggestions.map((suggestion) => ListTile(
          leading: const Icon(Icons.search, size: 20),
          title: Text(suggestion),
          onTap: () {
            _controller.text = suggestion;
            context.read<SearchBloc>().add(SearchQueryChanged(suggestion));
            widget.onSearchSubmitted(suggestion);
            _focusNode.unfocus();
          },
        )).toList(),
      ),
    );
  }
}