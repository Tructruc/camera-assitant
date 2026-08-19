/// Root application composition for the Photography Assistant.
library;

import 'package:flutter/material.dart';

/// Root widget for the offline field toolkit.
class PhotographyAssistantApp extends StatelessWidget {
  const PhotographyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Photography Assistant')),
        body: const Center(child: Text('Your offline field toolkit')),
      ),
      title: 'Photography Assistant',
    );
  }
}
