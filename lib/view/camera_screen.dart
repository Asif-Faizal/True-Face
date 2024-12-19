// screens/camera_page.dart
import 'package:flutter/material.dart';
import 'package:liveliness_checker/second_screen.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import 'view_model/camera_view_model.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraViewModel()..initializeCamera(),
      child: Scaffold(
        body: Consumer<CameraViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.controller == null || !viewModel.controller!.value.isInitialized&& !viewModel.hasNavigated) {
              return const Center(child: CircularProgressIndicator());
            }
            viewModel.checkForNavigation();
             if (viewModel.eyesClosedDetected && viewModel.headMovedRight) {
              // Navigate to another page if both are true
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondPage()), // AnotherPage is the page you want to navigate to.
                );
              });
              // viewModel.disposeCamera();
              // viewModel.dispose();
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(viewModel.isFaceDetected ? 15 : 13),
                        border: Border.all(
                          width: viewModel.isFaceDetected ? 5 : 3,
                          color: viewModel.isFaceDetected ? Colors.green : Colors.red,
                        ),
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CameraPreview(viewModel.controller!)),
                    ),
                    Positioned(
                      top: 22,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!viewModel.isFaceDetected)
                              const Text(
                                'Face not detected',
                                style: TextStyle(color: Colors.red),
                              )
                            else if (!viewModel.eyesClosedDetected)
                              const Text(
                                'Please blink',
                                style: TextStyle(color: Colors.yellow),
                              )
                            else if (viewModel.eyesClosedDetected && !viewModel.headMovedRight)
                              const Text(
                                'Please rotate your head to the left',
                                style: TextStyle(color: Colors.yellow),
                              ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  viewModel.eyesClosedDetected ? Icons.done : Icons.close,
                                  color: viewModel.eyesClosedDetected
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Blink Detected',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  viewModel.headMovedRight ? Icons.done : Icons.close,
                                  color: viewModel.headMovedRight
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Head Movement',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}