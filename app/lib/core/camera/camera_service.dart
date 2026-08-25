import 'package:camera/camera.dart' as camera;

/// Thin wrapper around the `camera` plugin so camera availability can be
/// mocked in widget tests.
class CameraService {
  const CameraService();

  Future<List<camera.CameraDescription>> availableCameras() =>
      camera.availableCameras();
}
