import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import '../view_model/camera_view_model.dart';
import 'second_screen.dart';


class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CameraViewModel()..initializeCamera(),
      child: Scaffold(
        body: Consumer<CameraViewModel>(
          builder: (context, viewModel, child) {
            // Ensure the controller is not null and is initialized before accessing the CameraPreview
            if (viewModel.controller == null || !viewModel.controller!.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            // Check if we need to navigate and do so after the build phase
            if (viewModel.eyesClosedDetected && viewModel.headMovedRight && !viewModel.hasNavigated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                viewModel.setNavigated(true); // Set navigation status after the build phase

                // Navigate to the next page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecondPage()),
                );

                // Dispose camera resources after navigation
                viewModel.disposeCamera();
              });
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
