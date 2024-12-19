
import 'package:flutter/material.dart';

class SecondPage extends StatelessWidget {
  final VoidCallback onReturn;

  const SecondPage({super.key, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
        leading: BackButton(
          onPressed: () {
            onReturn();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: const Center(child: Text('Eyes were closed and head moved right!')),
    );
  }
}
