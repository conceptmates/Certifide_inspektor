/// Helpers for turning a remote media URL string into a [Uri] that the native
/// players (AVURLAsset on iOS, ExoPlayer on Android) will accept.
///
/// Backend-served media (e.g. Django `MEDIA_URL`) preserves the original
/// uploaded filename, so admin-dashboard videos frequently contain spaces or
/// other characters that are illegal in a URI (`My Car Video.mp4`). Flutter's
/// HTTP-based widgets (`Image.network`) percent-encode the request path under
/// the hood, which is why images load fine. `VideoPlayerController.networkUrl`
/// hands the raw string straight to the native player, which silently rejects
/// the un-encoded URL — surfacing as a "video won't play" bug.
///
/// [mediaUri] normalises the string so both code paths behave the same.
Uri mediaUri(String raw) {
  final trimmed = raw.trim();
  // `Uri.encodeFull` escapes characters that are illegal in a URI (spaces,
  // unicode, etc.) while leaving the URI structure (`:/?#&=`) and any existing
  // `%xx` escapes untouched, so it is safe to apply to already-encoded URLs.
  return Uri.parse(Uri.encodeFull(trimmed));
}
