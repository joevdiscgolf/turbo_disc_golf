import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/constants/pro_reference_videos.dart';

/// Returns the asset path for the pro reference video based on throw type and camera angle.
///
/// Currently only supports backhand throws.
/// Throws [UnsupportedError] if throw type is not backhand.
String getProReferenceVideoPath({
  required ThrowTechnique throwType,
  required CameraAngle cameraAngle,
}) {
  // For now, only backhand is supported
  if (throwType != ThrowTechnique.backhand) {
    throw UnsupportedError(
      'Pro reference videos are currently only available for backhand throws. '
      'Forehand support coming soon.',
    );
  }

  // Select video based on camera angle
  switch (cameraAngle) {
    case CameraAngle.side:
      return ProReferenceVideos.paulMcBethBackhandSide;
    case CameraAngle.rear:
      return ProReferenceVideos.paulMcBethBackhandRear;
  }
}
