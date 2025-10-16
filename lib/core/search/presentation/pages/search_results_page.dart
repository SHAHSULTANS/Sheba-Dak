import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/search_bloc.dart';
import '../../../../features/home/domain/entities/service.dart';
import '../../../../features/home/domain/entities/service_category.dart';
import '../../../../features/provider/domain/entities/service_provider.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('"$query" এর ফলাফল', style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchSuccess && state.nearbyFilterEnabled) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 20),
                      SizedBox(width: 4),
                      Text('কাছাকাছি', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchSuccess && state.query == query) {
            final results = state.results;

            if (results.totalResults == 0) {
              return _buildEmptyState(query);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (results.categories.isNotEmpty) ...[
                  _buildSectionTitle('ক্যাটাগরি (${results.categories.length})'),
                  ...results.categories.map((category) => _buildCategoryItem(category, context)),
                  const SizedBox(height: 16),
                ],
                if (results.services.isNotEmpty) ...[
                  _buildSectionTitle('সার্ভিস (${results.services.length})'),
                  ...results.services.map((service) => _buildServiceItem(service, context)),
                  const SizedBox(height: 16),
                ],
                if (results.providers.isNotEmpty) ...[
                  _buildSectionTitle('প্রোভাইডার (${results.providers.length})'),
                  ...results.providers.map((provider) => _buildProviderItem(provider, context)),
                ],
              ],
            );
          } else if (state is SearchError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SearchBloc>().add(SearchQueryChanged(query));
                    },
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState(query);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCategoryItem(ServiceCategory category, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.category, color: Colors.blue),
        title: Text(category.name),
        subtitle: Text('${category.name} সার্ভিস'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('/services/${category.id}');
        },
      ),
    );
  }

  Widget _buildServiceItem(Service service, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.build, color: Colors.orange),
        title: Text(service.name),
        subtitle: Text(service.description),
        trailing: Text('৳${service.price}'),
        onTap: () {
          // Navigate to service detail if needed
          context.push('/service-detail/${service.id}');
        },
      ),
    );
  }

  Widget _buildProviderItem(ServiceProvider provider, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            provider.name.isNotEmpty ? provider.name[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(provider.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${provider.rating.toStringAsFixed(1)}'),
              ],
            ),
            Text(provider.description.length > 50
                ? '${provider.description.substring(0, 50)}...'
                : provider.description),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('/provider-detail/${provider.id}');
        },
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '"$query" এর জন্য কোন ফলাফল পাওয়া যায়নি',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'ভিন্ন কীওয়ার্ড দিয়ে চেষ্টা করুন',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}