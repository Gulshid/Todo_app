import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:todo/src/view/todo_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _particleController;
  late final AnimationController _exitController;

  // ── Animations ──────────────────────────────────────────────────────────
  late final Animation<double> _bgScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotate;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _ringScale1;
  late final Animation<double> _ringScale2;
  late final Animation<double> _ringOpacity1;
  late final Animation<double> _ringOpacity2;
  late final Animation<Offset> _titleSlide;
  late final Animation<double>  _titleOpacity;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double>  _subtitleOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progressOpacity;
  late final Animation<double> _progressValue;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  // ── Particles ────────────────────────────────────────────────────────────
  final List<_Particle> _particles = [];
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _buildParticles();
    _setupControllers();
    _setupAnimations();
    _startSequence();
  }

  void _buildParticles() {
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 3 + _rng.nextDouble() * 6,
        speed: 0.3 + _rng.nextDouble() * 0.7,
        phase: _rng.nextDouble() * math.pi * 2,
        color: _rng.nextBool()
            ? const Color(0xFF818CF8)
            : const Color(0xFFA78BFA),
      ));
    }
  }

  void _setupControllers() {
    _bgController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _logoController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
    _textController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _particleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _exitController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  }

  void _setupAnimations() {
    // Background
    _bgScale = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOutCubic));

    // Logo — spring pop
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.93)
          .chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.93, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(_logoController);

    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)));

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));

    // Ripple rings
    _ringScale1 = Tween<double>(begin: 0.7, end: 2.2).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _ringOpacity1 = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));

    _ringScale2 = Tween<double>(begin: 0.7, end: 2.8).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _ringOpacity2 = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Text
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic)));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.0, 0.55, curve: Curves.easeIn)));

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic)));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeIn)));

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.55, 1.0, curve: Curves.easeIn)));

    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.7, 1.0, curve: Curves.easeIn)));

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController,
          curve: const Interval(0.65, 1.0, curve: Curves.easeInOut)));

    // Exit
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic));
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  Future<void> _startSequence() async {
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    // Wait for progress bar to fill + hold
    await Future.delayed(const Duration(milliseconds: 2200));
    await _exitController.forward();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const TodoPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController, _logoController,
          _textController, _particleController, _exitController,
        ]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitOpacity,
            child: ScaleTransition(
              scale: _exitScale,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F0F1A),
                      Color(0xFF1A1040),
                      Color(0xFF0D1B3E),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: ScaleTransition(
                  scale: _bgScale,
                  child: Stack(
                    children: [
                      // ── Floating particles ──────────────────────────────
                      ..._particles.map((p) => _buildParticle(p, size)),

                      // ── Glow blobs ──────────────────────────────────────
                      Positioned(
                        top: size.height * 0.1,
                        left: size.width * 0.05,
                        child: _GlowBlob(
                          color: const Color(0xFF6366F1),
                          size: size.width * 0.7,
                          opacity: 0.12,
                        ),
                      ),
                      Positioned(
                        bottom: size.height * 0.05,
                        right: size.width * 0.0,
                        child: _GlowBlob(
                          color: const Color(0xFF8B5CF6),
                          size: size.width * 0.6,
                          opacity: 0.10,
                        ),
                      ),
                      Positioned(
                        top: size.height * 0.45,
                        right: size.width * 0.1,
                        child: _GlowBlob(
                          color: const Color(0xFF0EA5E9),
                          size: size.width * 0.4,
                          opacity: 0.07,
                        ),
                      ),

                      // ── Main content ────────────────────────────────────
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            _buildLogo(size),
                            SizedBox(height: size.height * 0.045),
                            // Title
                            _buildTitle(),
                            const SizedBox(height: 10),
                            // Tagline
                            _buildTagline(),
                            SizedBox(height: size.height * 0.07),
                            // Progress
                            _buildProgress(size),
                          ],
                        ),
                      ),

                      // ── Version badge ───────────────────────────────────
                      Positioned(
                        bottom: 32,
                        left: 0, right: 0,
                        child: FadeTransition(
                          opacity: _taglineOpacity,
                          child: const Text(
                            'Version 2.0.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0x556366F1),
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(_Particle p, Size size) {
    final t = _particleController.value;
    final dy = ((t * p.speed + p.phase / (math.pi * 2)) % 1.0);
    final dx = math.sin(t * math.pi * 2 * p.speed + p.phase) * 0.04;
    final opacity = (math.sin(t * math.pi * 2 * p.speed + p.phase) + 1) / 2;

    return Positioned(
      left: (p.x + dx) * size.width,
      top: (1.0 - dy) * size.height,
      child: Opacity(
        opacity: opacity * 0.6,
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.color,
            boxShadow: [
              BoxShadow(color: p.color.withOpacity(0.5), blurRadius: p.size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Size size) {
    final logoSize = size.width * 0.28;
    return Transform.rotate(
      angle: _logoRotate.value,
      child: Opacity(
        opacity: _logoOpacity.value,
        child: Transform.scale(
          scale: _logoScale.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple 2
              Transform.scale(
                scale: _ringScale2.value,
                child: Opacity(
                  opacity: _ringOpacity2.value,
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              // Outer ripple 1
              Transform.scale(
                scale: _ringScale1.value,
                child: Opacity(
                  opacity: _ringOpacity1.value,
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // Subtle glow ring
              Container(
                width: logoSize + 24,
                height: logoSize + 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Logo container
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.55),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 60,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shine overlay
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: logoSize * 0.45,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(logoSize / 2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: logoSize * 0.52,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        SlideTransition(
          position: _titleSlide,
          child: FadeTransition(
            opacity: _titleOpacity,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE0E7FF), Color(0xFFA5B4FC), Color(0xFFC4B5FD)],
              ).createShader(bounds),
              child: const Text(
                'TaskMaster',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SlideTransition(
          position: _subtitleSlide,
          child: FadeTransition(
            opacity: _subtitleOpacity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, const Color(0xFF818CF8).withOpacity(0.7)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SMART TASK MANAGEMENT',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF818CF8).withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Organize your day.\nAchieve your goals.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.38),
            fontSize: 14.5,
            height: 1.65,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(Size size) {
    return FadeTransition(
      opacity: _progressOpacity,
      child: Column(
        children: [
          SizedBox(
            width: size.width * 0.45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _progressValue.value,
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _progressValue.value < 0.4
                ? 'Initializing...'
                : _progressValue.value < 0.75
                    ? 'Loading your tasks...'
                    : 'Ready!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _Particle {
  final double x, y, size, speed, phase;
  final Color color;
  const _Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.phase, required this.color,
  });
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowBlob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}