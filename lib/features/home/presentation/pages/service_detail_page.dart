import 'package:flutter/material.dart';

class ServiceDetailPage extends StatelessWidget {
  final String id;

  const ServiceDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('সেবার তালিকা', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Text(
          'Category ID: $id এর জন্য সেবার তালিকা শীঘ্রই আসছে...',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}