import 'package:flutter/material.dart';

class ContactProviderPage extends StatelessWidget {
  const ContactProviderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোভাইডারের সাথে যোগাযোগ')),
      body: const Center(
        child: Text('যোগাযোগের ফর্ম বা চ্যাট ইন্টারফেস এখানে থাকবে (Week 5).'),
      ),
    );
  }
}