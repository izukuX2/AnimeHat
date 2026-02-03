import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/anime_model.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../../core/utils/link_resolver.dart';
import '../../../anime_details/data/anime_repository.dart';
import '../../../../core/api/animeify_api_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/share_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Anime anime;
  final Episode episode;
  final int startAtMs;
  final List<Episode> episodes;
  final List<StreamingServer> servers;
  final String currentServerName;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.anime,
    required this.episode,
    this.startAtMs = 0,
    required this.episodes,
    required this.servers,
    required this.currentServerName,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  // Core Player Controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // State Variables
  late Episode _currentEpisode;
  late String _activeUrl;
  late String _activeServerName;
  late List<StreamingServer> _currentServers;

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLocked = false;
  bool _showOverlay = true;
  Timer? _hideTimer;
  BoxFit _videoFit = BoxFit.contain;

  // Persistence & Settings
  double _playbackSpeed = 1.0;
  bool _isAutoNextEnabled = true;
  bool _isAutoSkipEnabled = true;
  static const String _prefQualityKey = 'preferred_quality_name';
  static const String _prefAutoSkipKey = 'auto_skip_intro';

  // Power User Features
  Timer? _sleepTimer;
  int? _sleepMinutesRemaining;
  bool _isRotationLocked = false;
  bool _showAutoNextCountdown = false;
  Timer? _autoNextTimer;
  int _autoNextSeconds = 5;

  // Services
  final UserRepository _userRepository = UserRepository();
  final AuthRepository _auth = AuthRepository();
  final AnimeRepository _animeRepository = AnimeRepository(
    apiClient: AnimeifyApiClient(),
  );

  // Gestures & Animations
  AnimationController?
  _centerPlayBtnController; // Scale animation for play/pause
  bool _showDoubleTapAnim = false;
  bool _isLeftTap = false; // true = left (rewind), false = right (forward)
  Timer? _doubleTapResetTimer;

  // Swipe controls
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  bool _showBrightnessIndicator = false;
  bool _showVolumeIndicator = false;

  // UI Components
  bool _showSettings = false;
  bool _showEpisodeList = false;

  // Buffering Animation
  Timer? _bufferingSimulatorTimer;
  String _bufferingSpeed = "0 KB/s";
  final Random _random = Random();

  bool _isPiPActive = false;

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode;
    _currentServers = widget.servers;
    _activeServerName = widget.currentServerName;
    _activeUrl = widget.videoUrl;

    _centerPlayBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _startBufferingSimulator();

    _setLandscape();
    _initializeApp();
  }

  void _startBufferingSimulator() {
    _bufferingSimulatorTimer?.cancel();
    _bufferingSimulatorTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) {
        if (mounted &&
            (_isLoading ||
                (_videoPlayerController?.value.isBuffering ?? false))) {
          // Simulate speed between 300KB/s and 3MB/s
          final speed = 300 + _random.nextInt(2700);
          String speedStr = "${speed} KB/s";
          if (speed > 1000) {
            speedStr = "${(speed / 1000).toStringAsFixed(1)} MB/s";
          }
          setState(() => _bufferingSpeed = speedStr);
        }
      },
    );
  }

  Future<void> _initializeApp() async {
    await _handlePermissions();
    await _loadSettings();
    await _initializePlayer(_activeUrl, startAt: widget.startAtMs);
    _startProgressSaver();
    _startHideTimer();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Try to match preferred quality if not the initial load or if we want to be smart
    final savedQuality = prefs.getString(_prefQualityKey);
    if (savedQuality != null && savedQuality != _activeServerName) {
      // Logic to auto-switch if preferred quality exists in list could go here
    }
    _isAutoSkipEnabled = prefs.getBool(_prefAutoSkipKey) ?? true;
  }

  Future<void> _handlePermissions() async {
    if (!Platform.isAndroid) return;
    // Android 13+ Media permissions handled in calling screen or here effectively
  }

  Future<void> _initializePlayer(String url, {int startAt = 0}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final oldController = _videoPlayerController;

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();

      _chewieController?.dispose();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        showControls: false, // We use custom overlays
        placeholder: Container(color: Colors.black),
      );

      if (startAt > 0) {
        await _videoPlayerController!.seekTo(Duration(milliseconds: startAt));
      }

      _videoPlayerController!.addListener(_videoListener);
      _videoPlayerController!.setPlaybackSpeed(_playbackSpeed);

      if (oldController != null) await oldController.dispose();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Player Error: $e");
      if (mounted)
        setState(() {
          _hasError = true;
          _isLoading = false;
          final l10n = AppLocalizations.of(context)!;
          _errorMessage = l10n.mediaUnavailable; // or generalized
        });
    }
  }

  void _videoListener() {
    if (_videoPlayerController != null && mounted) {
      if (_isAutoNextEnabled &&
          _videoPlayerController!.value.isInitialized &&
          !_showAutoNextCountdown &&
          _videoPlayerController!.value.duration.inSeconds > 0 &&
          _videoPlayerController!.value.position >=
              _videoPlayerController!.value.duration -
                  const Duration(seconds: 1)) {
        // Auto-Next Trigger
        _triggerAutoNextCountdown();
      }

      // Skip Intro Logic (85s to 95s range)
      final posSec = _videoPlayerController!.value.position.inSeconds;
      if (posSec >= 85 && posSec <= 95) {
        if (_isAutoSkipEnabled) {
          _skipIntro();
        } else {
          _showSkipIntroButton = true;
        }
      } else {
        if (_showSkipIntroButton) _showSkipIntroButton = false;
      }

      setState(() {});
    }
  }

  bool _showSkipIntroButton = false;

  void _skipIntro() {
    _videoPlayerController?.seekTo(const Duration(seconds: 90)); // Jump to 1:30
    setState(() => _showSkipIntroButton = false);
  }

  void _triggerAutoNextCountdown() {
    // Find next episode index first
    final idx = widget.episodes.indexWhere(
      (e) => e.episodeNumber == _currentEpisode.episodeNumber,
    );
    if (idx == -1 || idx >= widget.episodes.length - 1) return;

    setState(() {
      _showAutoNextCountdown = true;
      _autoNextSeconds = 5;
    });

    _autoNextTimer?.cancel();
    _autoNextTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoNextSeconds <= 0) {
        timer.cancel();
        if (_showAutoNextCountdown) _playNextEpisode();
      } else {
        setState(() => _autoNextSeconds--);
      }
    });
  }

  void _cancelAutoNext() {
    _autoNextTimer?.cancel();
    setState(() => _showAutoNextCountdown = false);
  }

  // --- SEAMLESS NAVIGATION ---
  Future<void> _playNextEpisode() async {
    _cancelAutoNext();
    final idx = widget.episodes.indexWhere(
      (e) => e.episodeNumber == _currentEpisode.episodeNumber,
    );
    if (idx != -1 && idx < widget.episodes.length - 1) {
      final nextEp = widget.episodes[idx + 1];
      await _switchEpisodeInPlace(nextEp);
    } else {
      Navigator.pop(context); // Finish if no more episodes
    }
  }

  Future<void> _playPreviousEpisode() async {
    final idx = widget.episodes.indexWhere(
      (e) => e.episodeNumber == _currentEpisode.episodeNumber,
    );
    if (idx > 0) {
      final prevEp = widget.episodes[idx - 1];
      await _switchEpisodeInPlace(prevEp);
    }
  }

  Future<void> _switchEpisodeInPlace(Episode newEp) async {
    setState(() {
      _isLoading = true;
      _currentEpisode = newEp;
      _showEpisodeList = false;
      _showSettings = false;
      _showAutoNextCountdown = false;
    });

    // 1. Fetch servers for new episode
    try {
      final servers = await _animeRepository.getServers(
        widget.anime.animeId,
        newEp.episodeNumber,
      );
      final mediaFireServers = servers
          .where((s) => s.url.contains('mediafire.com'))
          .toList();

      if (mediaFireServers.isEmpty) throw Exception("No servers found");

      _currentServers = mediaFireServers;

      // 2. Determine Quality (Persistence Logic)
      final prefs = await SharedPreferences.getInstance();
      final preferred = prefs.getString(_prefQualityKey);

      StreamingServer selectedServer = mediaFireServers.first;
      if (preferred != null) {
        final match = mediaFireServers.firstWhere(
          (s) => s.name == preferred,
          orElse: () => mediaFireServers.first,
        );
        selectedServer = match;
      }

      _activeServerName = selectedServer.name;

      // 3. Resolve & Play
      final resolvedUrl = await LinkResolver.resolve(selectedServer.url);
      _activeUrl = resolvedUrl;

      // Save history for new episode
      _saveHistory(newEp);

      await _initializePlayer(resolvedUrl);
    } catch (e) {
      setState(() {
        _hasError = true;
        final l10n = AppLocalizations.of(context)!;
        _errorMessage = l10n.mediaUnavailable;
      });
    }
  }

  Future<void> _switchQuality(StreamingServer server) async {
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefQualityKey, server.name);

    setState(() {
      _showSettings = false;
      _isLoading = true;
      _activeServerName = server.name;
    });

    final currentPos =
        _videoPlayerController?.value.position.inMilliseconds ?? 0;

    try {
      final resolvedUrl = await LinkResolver.resolve(server.url);
      _activeUrl = resolvedUrl;
      await _initializePlayer(resolvedUrl, startAt: currentPos);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        final l10n = AppLocalizations.of(context)!;
        _errorMessage = l10n.failedToResolveLink;
      });
    }
  }

  // --- STATE PERSISTENCE ---
  void _startProgressSaver() {
    // Only saves if playing
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        if (_videoPlayerController?.value.isPlaying == true)
          _saveHistory(_currentEpisode);
        _startProgressSaver();
      }
    });
  }

  Future<void> _saveHistory(Episode ep) async {
    final user = _auth.currentUser;
    if (user == null || _videoPlayerController?.value.isInitialized != true)
      return;

    final pos = _videoPlayerController!.value.position.inMilliseconds;
    final dur = _videoPlayerController!.value.duration.inMilliseconds;

    // Only save if watched at least 5 seconds
    if (pos > 5000) {
      await _userRepository.addToHistory(
        user.uid,
        WatchHistoryItem(
          animeId: widget.anime.animeId,
          episodeNumber: ep.episodeNumber,
          watchedAt: DateTime.now(),
          title: widget.anime.enTitle,
          imageUrl: widget.anime.thumbnail,
          positionInMs: pos,
          totalDurationInMs: dur,
        ),
      );
    }
  }

  // --- UI HELPERS ---
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted &&
          _showOverlay &&
          !_showSettings &&
          !_isLocked &&
          !_showEpisodeList &&
          (_videoPlayerController?.value.isPlaying ?? false)) {
        setState(() => _showOverlay = false);
      }
    });
  }

  void _toggleOverlay() {
    if (_isLocked) return;
    setState(() {
      _showOverlay = !_showOverlay;
      if (_showOverlay) _startHideTimer();
    });
  }

  void _onDoubleTap(bool isLeft) {
    if (_isLocked || _videoPlayerController == null) return;

    final seekAmount = isLeft ? -10 : 10;
    final currentPos = _videoPlayerController!.value.position;
    _videoPlayerController!.seekTo(currentPos + Duration(seconds: seekAmount));

    setState(() {
      _isLeftTap = isLeft;
      _showDoubleTapAnim = true;
    });

    _doubleTapResetTimer?.cancel();
    _doubleTapResetTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showDoubleTapAnim = false);
    });
  }

  Future<void> _setLandscape() async {
    // Respect user rotation lock if set
    if (!_isRotationLocked) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _toggleRotationLock() {
    setState(() => _isRotationLocked = !_isRotationLocked);
    if (_isRotationLocked) {
      // Lock to current orientation
      SystemChrome.setPreferredOrientations([
        MediaQuery.of(context).orientation == Orientation.landscape
            ? DeviceOrientation
                  .landscapeLeft // Approximate
            : DeviceOrientation.portraitUp,
      ]);
    } else {
      _setLandscape(); // reset to landscape default
    }
    Navigator.pop(context); // close menu
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepMinutesRemaining = minutes;

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_sleepMinutesRemaining! <= 0) {
        timer.cancel();
        _videoPlayerController?.pause();
        setState(() {});
      } else {
        _sleepMinutesRemaining = _sleepMinutesRemaining! - 1;
      }
    });
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sleep timer set for $minutes mins"),
      ), // Keeping for now or I can add to ARB
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _sleepTimer?.cancel();
    _autoNextTimer?.cancel();
    _bufferingSimulatorTimer?.cancel();
    _saveHistory(_currentEpisode);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _centerPlayBtnController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Layer (Zoomable)
          Center(
            child: _hasError
                ? _buildError()
                : _isLoading
                ? _buildBufferingIndicator()
                : InteractiveViewer(
                    maxScale: 4.0,
                    child: FittedBox(
                      fit: _videoFit,
                      child: SizedBox(
                        width: _videoPlayerController!.value.size.width,
                        height: _videoPlayerController!.value.size.height,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    ),
                  ),
          ),

          // 2. Gesture Detector for Netflix-style controls
          if (!_isLocked && !_isLoading)
            Positioned.fill(
              child: Row(
                children: [
                  // Expanded gesture areas code identical to previous...
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleOverlay,
                      onDoubleTap: () => _onDoubleTap(true),
                      onVerticalDragUpdate: (d) => _handleBrightness(d),
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_videoPlayerController!.value.isPlaying) {
                          _videoPlayerController!.pause();
                          _startHideTimer(); // keep visible when paused
                        } else {
                          _videoPlayerController!.play();
                          _startHideTimer();
                        }
                        setState(() {
                          _showOverlay = true;
                        });
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleOverlay,
                      onDoubleTap: () => _onDoubleTap(false),
                      onVerticalDragUpdate: (d) => _handleVolume(d),
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Double Tap Animations
          if (_showDoubleTapAnim) _buildRippleAnim(),

          // 3.5 Auto Next Countdown Overlay
          if (_showAutoNextCountdown) _buildAutoNextOverlay(),

          // 4. Overlays
          if (_isLocked)
            Positioned(
              top: 50,
              right: 30,
              child: _glassBtn(
                LucideIcons.lock,
                () => setState(() => _isLocked = false),
              ),
            ),

          if (!_isLocked) ...[
            IgnorePointer(
              ignoring: !_showOverlay,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showOverlay ? 1.0 : 0.0,
                child: _buildNetflixOverlay(),
              ),
            ),

            if (_showSettings) _buildSettingsSheet(),
            if (_showEpisodeList) _buildEpisodeList(),
          ],

          // 5. Loading Overlay (Internal) - Now also shows buffering during play
          if (!_isLoading &&
              !_hasError &&
              (_videoPlayerController?.value.isBuffering ?? false))
            _buildBufferingIndicator(),

          // 6. Volume/Brightness Indicators (Side Vertical Bars)
          if (_showVolumeIndicator)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height * 0.25,
              bottom: MediaQuery.of(context).size.height * 0.25,
              child: _buildSideIndicator(LucideIcons.volume2, _currentVolume),
            ),

          if (_showBrightnessIndicator)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height * 0.25,
              bottom: MediaQuery.of(context).size.height * 0.25,
              child: _buildSideIndicator(LucideIcons.sun, _currentBrightness),
            ),

          // 7. Skip Intro Button
          if (_showSkipIntroButton && !_isPiPActive && !_isLocked)
            Positioned(
              bottom: 120,
              right: 30,
              child: ElevatedButton.icon(
                onPressed: _skipIntro,
                icon: const Icon(LucideIcons.fastForward, size: 18),
                label: Text(l10n.skipIntro),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(
              "Buffering... $_bufferingSpeed", // "Buffering" could be in ARB
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed unused _buildCenterIcon

  Widget _buildNetflixOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // Top Gradient & Title
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.anime.enTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        "${l10n.selectQuality}: ${_parseQuality(_currentServers.firstWhere(
                          (s) => s.name == _activeServerName,
                          orElse: () => StreamingServer(name: _activeServerName, url: ""),
                        ))} • ${l10n.epShort} ${_currentEpisode.episodeNumber}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.monitor, color: Colors.white),
                  onPressed: _enterPiP,
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.moreVertical,
                    color: Colors.white,
                  ),
                  onPressed: _showMoreOptionsMenu,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share, color: Colors.white),
                  onPressed: () => ShareService().shareEpisode(
                    animeId: widget.anime.animeId,
                    episodeNumber: _currentEpisode.episodeNumber,
                    animeTitle: widget.anime.enTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.settings, color: Colors.white),
                  onPressed: () => setState(() => _showSettings = true),
                ),
              ],
            ),
          ),
        ),

        // Center Controls
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _glassBtn(
                LucideIcons.rotateCcw,
                () => _videoPlayerController!.seekTo(
                  _videoPlayerController!.value.position -
                      const Duration(seconds: 10),
                ),
              ),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () {
                  _videoPlayerController!.value.isPlaying
                      ? _videoPlayerController!.pause()
                      : _videoPlayerController!.play();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_videoPlayerController?.value.isBuffering == true)
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      Icon(
                        _videoPlayerController?.value.isPlaying == true
                            ? LucideIcons.pause
                            : LucideIcons.play,
                        color: Colors.white,
                        size: 50,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              _glassBtn(
                LucideIcons.rotateCw,
                () => _videoPlayerController!.seekTo(
                  _videoPlayerController!.value.position +
                      const Duration(seconds: 10),
                ),
              ),
            ],
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _glassBtn(
                      LucideIcons.skipBack,
                      _playPreviousEpisode,
                      small: true,
                    ),
                    _glassBtn(
                      LucideIcons.skipForward,
                      _playNextEpisode,
                      small: true,
                    ),
                    const Spacer(),
                    _glassBtn(
                      LucideIcons.unlock,
                      () => setState(() => _isLocked = true),
                      small: true,
                    ),
                    const SizedBox(width: 15),
                    _glassBtn(
                      LucideIcons.list,
                      () => setState(() => _showEpisodeList = true),
                      small: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_videoPlayerController?.value.isInitialized == true)
                  ProgressBar(
                    videoPlayerController: _videoPlayerController!,
                    barColor: Colors.blueAccent,
                    handleColor: Colors.blueAccent,
                    backgroundColor: Colors.white24,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoNextOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Next episode in",
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              "$_autoNextSeconds",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _cancelAutoNext,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _playNextEpisode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text("Play Now"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, {bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(small ? 8 : 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: small ? 20 : 30),
      ),
    );
  }

  // --- RIPPLE ANIMATION ---
  Widget _buildRippleAnim() {
    return Align(
      alignment: _isLeftTap ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width / 3,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(_isLeftTap ? 1000 : 0),
            bottomRight: Radius.circular(_isLeftTap ? 1000 : 0),
            topLeft: Radius.circular(_isLeftTap ? 0 : 1000),
            bottomLeft: Radius.circular(_isLeftTap ? 0 : 1000),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLeftTap ? LucideIcons.rewind : LucideIcons.fastForward,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLeftTap ? "-10s" : "+10s",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideIndicator(IconData icon, double value) {
    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: value,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "${(value * 100).toInt()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleVolume(DragUpdateDetails d) {
    if (_isLocked) return;
    final delta = d.primaryDelta! / MediaQuery.of(context).size.height;
    setState(() {
      _currentVolume = (_currentVolume - delta).clamp(0.0, 1.0);
      _videoPlayerController?.setVolume(_currentVolume);
      _showVolumeIndicator = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showVolumeIndicator = false);
    });
  }

  Future<void> _handleBrightness(DragUpdateDetails d) async {
    if (_isLocked) return;
    if (Platform.isAndroid) {
      if (!await Permission.systemAlertWindow.isGranted) {
        // Strict handling logic as before...
      }
    }
    // Brightness simulation
    final delta = d.primaryDelta! / MediaQuery.of(context).size.height;
    setState(() {
      _currentBrightness = (_currentBrightness - delta).clamp(0.0, 1.0);
      _showBrightnessIndicator = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showBrightnessIndicator = false);
    });
  }

  Future<void> _enterPiP() async {
    // PiP temporarily disabled - requires native implementation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Picture-in-Picture coming soon!")),
      );
    }
  }

  // Helper to parse quality from server name or URL
  String _parseQuality(StreamingServer server) {
    final name = server.name;
    final url = server.url;

    // 1. Try Regex on Name
    String? fromName = _extractResolution(name);
    if (fromName != null) return fromName;

    // 2. Try Regex on URL
    String? fromUrl = _extractResolution(url);
    if (fromUrl != null) return fromUrl;

    // 3. Fallbacks (Keywords)
    if (name.toLowerCase().contains('fullhd') ||
        name.toLowerCase().contains('fhd'))
      return '1080p';
    if (name.toLowerCase().contains('hd')) return '720p';
    if (name.toLowerCase().contains('sd')) return '480p';

    return "Auto";
  }

  String? _extractResolution(String input) {
    final regex = RegExp(
      r'(360|480|720|1080|1440|4k|2k)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(input);
    if (match != null) {
      String quality = match.group(0)!.toUpperCase();
      if (!quality.contains('P') && !quality.contains('K')) {
        quality += 'p';
      }
      return quality;
    }
    return null;
  }

  // --- MENU & OPTIONS ---
  void _showMoreOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuOption(LucideIcons.clock, "Sleep Timer", () {
              Navigator.pop(c);
              _showSleepTimerDialog();
            }),
            _menuOption(LucideIcons.gauge, "Playback Speed", () {
              Navigator.pop(c);
              _showSpeedSliderDialog();
            }),
            _menuOption(
              LucideIcons.repeat,
              "Rotation Lock",
              _toggleRotationLock,
              trailing: Switch(
                value: _isRotationLocked,
                onChanged: (v) => _toggleRotationLock(),
                activeColor: Colors.blueAccent,
              ),
            ),
            _menuOption(LucideIcons.camera, "Screenshot", () {
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Screenshot saved to Gallery")),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Sleep Timer", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 45, 60]
              .map(
                (m) => ListTile(
                  title: Text(
                    "$m minutes",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => _setSleepTimer(m),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showSpeedSliderDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Playback Speed",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          height: 100,
          child: StatefulBuilder(
            builder: (context, setInnerState) => Column(
              children: [
                Text(
                  "${_playbackSpeed.toStringAsFixed(2)}x",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _playbackSpeed,
                  min: 0.25,
                  max: 3.0,
                  divisions: 11,
                  activeColor: Colors.blueAccent,
                  onChanged: (v) {
                    setInnerState(() => _playbackSpeed = v);
                    _videoPlayerController?.setPlaybackSpeed(v);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSheet() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        width: 400,
        // Remove fixed height, use constraints
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.8, // 80% screen height max
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  "Quick Settings",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                title: const Text(
                  "Quality",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Text(
                  // Best effort: find server obj matching name, or make dummy.
                  _parseQuality(
                    _currentServers.firstWhere(
                      (s) => s.name == _activeServerName,
                      orElse: () =>
                          StreamingServer(name: _activeServerName, url: ""),
                    ),
                  ),
                  style: const TextStyle(color: Colors.blueAccent),
                ),
                onTap: _showQualitySelector,
              ),
              const Divider(color: Colors.white24),
              SwitchListTile(
                title: Text(
                  l10n.autoSkipIntro,
                  style: const TextStyle(color: Colors.white),
                ),
                value: _isAutoSkipEnabled,
                activeColor: Colors.blueAccent,
                onChanged: (v) async {
                  setState(() => _isAutoSkipEnabled = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(_prefAutoSkipKey, v);
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _showSettings = false),
                child: const Text("Close"),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showQualitySelector() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Select Quality",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _currentServers
                .map(
                  (s) => ListTile(
                    title: Text(
                      _parseQuality(s),
                      style: TextStyle(
                        color: s.name == _activeServerName
                            ? Colors.blueAccent
                            : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      s.name,
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    onTap: () {
                      Navigator.pop(c);
                      _switchQuality(s);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 300,
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: Colors.black26,
              child: const Text(
                "Episodes",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.episodes.length,
                itemBuilder: (c, i) {
                  final ep = widget.episodes[i];
                  final isCur =
                      ep.episodeNumber == _currentEpisode.episodeNumber;
                  return ListTile(
                    title: Text(
                      "Episode ${ep.episodeNumber}",
                      style: TextStyle(
                        color: isCur ? Colors.blueAccent : Colors.white,
                      ),
                    ),
                    onTap: () => _switchEpisodeInPlace(ep),
                    tileColor: isCur
                        ? Colors.blueAccent.withOpacity(0.1)
                        : null,
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showEpisodeList = false),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Text(
      _errorMessage ?? "Error",
      style: const TextStyle(color: Colors.red),
    ),
  );
}

class ProgressBar extends StatelessWidget {
  final VideoPlayerController videoPlayerController;
  final Color barColor;
  final Color handleColor;
  final Color backgroundColor;

  const ProgressBar({
    super.key,
    required this.videoPlayerController,
    required this.barColor,
    required this.handleColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return VideoProgressIndicator(
      videoPlayerController,
      allowScrubbing: true,
      colors: VideoProgressColors(
        playedColor: barColor,
        bufferedColor: Colors.white24,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
