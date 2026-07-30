import '../render_model.dart';

/// Coordinates whole-avatar animation channels.
///
/// Idle animation deliberately does not translate the completed avatar inside
/// the fixed 48×48 render surface. Translating the full composition clips pixels
/// at one edge and exposes an empty strip at the opposite edge, which produces
/// unstable framing in previews and exported sprite sheets.
///
/// Idle remains animated through the local channels owned by the individual
/// renderers: blink, hair wind, jewelry swing, smoke, aura pulse and particles.
/// Keeping the anatomical silhouette anchored also preserves a constant sprite
/// footprint across every frame.
final class AvatarMotionRenderer implements AvatarPartRenderer {
  const AvatarMotionRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    // Intentionally no global spatial transform. Local renderers animate their
    // own geometry without moving the avatar outside the fixed canvas.
  }
}
