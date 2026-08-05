import '../api/avatar_request.dart';
import 'rig_clip_pipeline.dart';

extension ExactPhaseRigClipPipeline on RigClipPipeline {
  /// Renders the exact requested phase without applying the camera sample modulo.
  ///
  /// Legacy [RigClipPipeline.renderSingle] remains available for source
  /// compatibility. New generator code uses this method so phases beyond the
  /// camera envelope resolve to their corresponding clip frame.
  RigPipelineClip renderExactSingle(AvatarRequest request) {
    if (request.rendering.reducedMotion && request.phase == 0) {
      final clip = renderClip(request, frameCount: 1);
      return RigPipelineClip(
        prepared: clip.prepared,
        frames: <RigPipelineFrame>[clip.frames.single],
        camera: clip.camera,
      );
    }
    if (request.phase < 16) return renderSingle(request);
    final clip = renderClip(request, frameCount: request.phase + 1);
    return RigPipelineClip(
      prepared: clip.prepared,
      frames: <RigPipelineFrame>[clip.frames[request.phase]],
      camera: clip.camera,
    );
  }
}
