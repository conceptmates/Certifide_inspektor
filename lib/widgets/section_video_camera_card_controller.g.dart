// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_video_camera_card_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$videoCardControllerHash() =>
    r'c82c4f5adb3f0442fd7163edfa261ad0482cf5ef';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$VideoCardController
    extends BuildlessAutoDisposeNotifier<VideoCardState> {
  late final String cardId;

  VideoCardState build(
    String cardId,
  );
}

/// Owns the camera lifecycle and recording state for one card, keyed by a
/// stable [cardId] so each on-screen card gets its own autoDisposed instance.
/// Replaces the old `setState`-driven `State` so only widgets that watch this
/// provider rebuild, and the hardware is released via [Ref.onDispose].
///
/// Copied from [VideoCardController].
@ProviderFor(VideoCardController)
const videoCardControllerProvider = VideoCardControllerFamily();

/// Owns the camera lifecycle and recording state for one card, keyed by a
/// stable [cardId] so each on-screen card gets its own autoDisposed instance.
/// Replaces the old `setState`-driven `State` so only widgets that watch this
/// provider rebuild, and the hardware is released via [Ref.onDispose].
///
/// Copied from [VideoCardController].
class VideoCardControllerFamily extends Family<VideoCardState> {
  /// Owns the camera lifecycle and recording state for one card, keyed by a
  /// stable [cardId] so each on-screen card gets its own autoDisposed instance.
  /// Replaces the old `setState`-driven `State` so only widgets that watch this
  /// provider rebuild, and the hardware is released via [Ref.onDispose].
  ///
  /// Copied from [VideoCardController].
  const VideoCardControllerFamily();

  /// Owns the camera lifecycle and recording state for one card, keyed by a
  /// stable [cardId] so each on-screen card gets its own autoDisposed instance.
  /// Replaces the old `setState`-driven `State` so only widgets that watch this
  /// provider rebuild, and the hardware is released via [Ref.onDispose].
  ///
  /// Copied from [VideoCardController].
  VideoCardControllerProvider call(
    String cardId,
  ) {
    return VideoCardControllerProvider(
      cardId,
    );
  }

  @override
  VideoCardControllerProvider getProviderOverride(
    covariant VideoCardControllerProvider provider,
  ) {
    return call(
      provider.cardId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'videoCardControllerProvider';
}

/// Owns the camera lifecycle and recording state for one card, keyed by a
/// stable [cardId] so each on-screen card gets its own autoDisposed instance.
/// Replaces the old `setState`-driven `State` so only widgets that watch this
/// provider rebuild, and the hardware is released via [Ref.onDispose].
///
/// Copied from [VideoCardController].
class VideoCardControllerProvider extends AutoDisposeNotifierProviderImpl<
    VideoCardController, VideoCardState> {
  /// Owns the camera lifecycle and recording state for one card, keyed by a
  /// stable [cardId] so each on-screen card gets its own autoDisposed instance.
  /// Replaces the old `setState`-driven `State` so only widgets that watch this
  /// provider rebuild, and the hardware is released via [Ref.onDispose].
  ///
  /// Copied from [VideoCardController].
  VideoCardControllerProvider(
    String cardId,
  ) : this._internal(
          () => VideoCardController()..cardId = cardId,
          from: videoCardControllerProvider,
          name: r'videoCardControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$videoCardControllerHash,
          dependencies: VideoCardControllerFamily._dependencies,
          allTransitiveDependencies:
              VideoCardControllerFamily._allTransitiveDependencies,
          cardId: cardId,
        );

  VideoCardControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cardId,
  }) : super.internal();

  final String cardId;

  @override
  VideoCardState runNotifierBuild(
    covariant VideoCardController notifier,
  ) {
    return notifier.build(
      cardId,
    );
  }

  @override
  Override overrideWith(VideoCardController Function() create) {
    return ProviderOverride(
      origin: this,
      override: VideoCardControllerProvider._internal(
        () => create()..cardId = cardId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cardId: cardId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<VideoCardController, VideoCardState>
      createElement() {
    return _VideoCardControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VideoCardControllerProvider && other.cardId == cardId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cardId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VideoCardControllerRef on AutoDisposeNotifierProviderRef<VideoCardState> {
  /// The parameter `cardId` of this provider.
  String get cardId;
}

class _VideoCardControllerProviderElement
    extends AutoDisposeNotifierProviderElement<VideoCardController,
        VideoCardState> with VideoCardControllerRef {
  _VideoCardControllerProviderElement(super.provider);

  @override
  String get cardId => (origin as VideoCardControllerProvider).cardId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
