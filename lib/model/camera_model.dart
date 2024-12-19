class CameraModel {
  bool isFaceDetected = false;
  bool isEyesClosedDetected = false;
  bool isHeadMovedRight = false;

  CameraModel({
    this.isFaceDetected = false,
    this.isEyesClosedDetected = false,
    this.isHeadMovedRight = false,
  });
}