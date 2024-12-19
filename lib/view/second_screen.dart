
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/camera_view_model.dart';

class SecondPage extends StatelessWidget {

  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraViewModel()..diposeController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Second Page'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: const Center(child: Text('Eyes were closed and head moved right!')),
      ),
    );
  }
}
