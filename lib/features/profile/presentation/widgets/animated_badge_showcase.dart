import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../../shared/widgets/app_colors.dart';

class AnimatedBadgeShowcase extends StatefulWidget {
  final List<Map<String, String>> badges;
  final String? currentUserId;

  const AnimatedBadgeShowcase({
    super.key,
    required this.badges,
    this.currentUserId,
  });

  @override
  State<AnimatedBadgeShowcase> createState() => _AnimatedBadgeShowcaseState();
}

class _AnimatedBadgeShowcaseState extends State<AnimatedBadgeShowcase>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late PageController _pageController;
  int _currentPage = 0;
  int _currentGlowingBadgeIndex = -1;
  final Random _random = Random();
  final Map<String, Color> _badgeColors = {}; // Cache for dominant colors
  static const int _badgesPerPage = 15; // 3 rows x 5 columns

  @override
  void initState() {
    super.initState();

    // Entrance animation controller
    _entranceController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 1600), // Covers all staggered animations
    );

    // Glow animation controller (for sequential badge glowing)
    // Duration is doubled to include fade-out (600ms fade in + 600ms fade out)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _selectNextGlowingBadge();
        }
      });

    // Page controller
    _pageController = PageController();

    // Start entrance animation
    _entranceController.forward();

    // Start glow animation after entrance completes
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _selectNextGlowingBadge();
      }
    });
  }

  void _selectNextGlowingBadge() {
    if (!mounted) return;

    // Get badges on current page
    final startIndex = _currentPage * _badgesPerPage;
    final endIndex = (startIndex + _badgesPerPage).clamp(0, _getBadgeCount());

    if (endIndex <= startIndex) return;

    // Select a random badge on current page (different from current)
    int nextIndex;
    do {
      nextIndex = startIndex + _random.nextInt(endIndex - startIndex);
    } while (
        nextIndex == _currentGlowingBadgeIndex && (endIndex - startIndex) > 1);

    setState(() {
      _currentGlowingBadgeIndex = nextIndex;
    });

    _glowController.forward(from: 0.0);
  }

  int _getBadgeCount() {
    return widget.badges.length;
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (_currentPage != page) {
      // Reset animation immediately before updating page
      _entranceController.reset();

      setState(() {
        _currentPage = page;
        _currentGlowingBadgeIndex = -1; // Reset glowing badge
      });

      // Start animation after a tiny delay to ensure reset takes effect
      Future.microtask(() {
        if (mounted) {
          _entranceController.forward();
        }
      });

      // Restart glow animation for new page
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _currentPage == page) {
          _selectNextGlowingBadge();
        }
      });
    }
  }

  Future<Color> _getDominantColor(String imageUrl) async {
    // Check cache first
    if (_badgeColors.containsKey(imageUrl)) {
      return _badgeColors[imageUrl]!;
    }

    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      Color dominantColor = paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          AppColors.primaryOrange;

      // Cache the color
      _badgeColors[imageUrl] = dominantColor;
      return dominantColor;
    } catch (e) {
      return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.badges.isEmpty) {
      return _buildEmptyState(context);
    }

    final displayBadges = widget.badges;

    // Calculate badge size for 3 rows x 5 columns
    final badgeSize = MediaQuery.of(context).size.width * 0.12;

    // Group badges into pages of 15
    final pages = <List<Map<String, String>>>[];
    for (int i = 0; i < displayBadges.length; i += _badgesPerPage) {
      final endIndex = (i + _badgesPerPage).clamp(0, displayBadges.length);
      pages.add(displayBadges.sublist(i, endIndex));
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, pageIndex) {
              final pageBadges = pages[pageIndex];
              final isCurrentPage = pageIndex == _currentPage;

              // Group badges into columns of 3 (3 rows)
              final columns = <List<Map<String, String>>>[];
              for (int i = 0; i < pageBadges.length; i += 3) {
                final column = <Map<String, String>>[
                  pageBadges[i],
                  if (i + 1 < pageBadges.length) pageBadges[i + 1],
                  if (i + 2 < pageBadges.length) pageBadges[i + 2],
                ];
                columns.add(column);
              }

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(columns.length, (columnIndex) {
                    final column = columns[columnIndex];
                    final globalStartIndex =
                        (pageIndex * _badgesPerPage) + (columnIndex * 3);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(column.length, (rowIndex) {
                        final globalIndex = globalStartIndex + rowIndex;
                        return _buildAnimatedBadge(
                          context,
                          column[rowIndex],
                          rowIndex +
                              (columnIndex *
                                  3), // Local index for animation stagger
                          globalIndex,
                          badgeSize,
                          isCurrentPage, // Pass whether this is current page
                        );
                      }),
                    );
                  }),
                ),
              );
            },
          ),
        ),
        // Page indicator dots
        if (pages.length > 1) _buildPageIndicator(pages.length),
      ],
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.025,
        bottom: MediaQuery.of(context).size.height * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = index == _currentPage;
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.01,
            ),
            width: isActive
                ? MediaQuery.of(context).size.width * 0.02
                : MediaQuery.of(context).size.width * 0.015,
            height: isActive
                ? MediaQuery.of(context).size.width * 0.02
                : MediaQuery.of(context).size.width * 0.015,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.primaryOrange
                  : AppColors.primaryOrange.withAlpha(100),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnimatedBadge(
    BuildContext context,
    Map<String, String> badge,
    int localIndex,
    int globalIndex,
    double badgeSize,
    bool isCurrentPage,
  ) {
    final badgeURL = badge['badgeURL'] ?? '';
    final eventId = badge['eventId'] ?? '';
    final delay = localIndex * 80; // 80ms stagger per badge

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        // Only animate if this is the current page
        if (!isCurrentPage) {
          // Non-current pages show as invisible
          return Opacity(
            opacity: 0.0,
            child: child,
          );
        }

        // Calculate progress with stagger delay
        final delayFraction = delay / 1600.0;
        final adjustedProgress =
            (_entranceController.value - delayFraction) / (1.0 - delayFraction);
        final progress = adjustedProgress.clamp(0.0, 1.0);

        // Start from invisible (0) and animate to visible (1)
        final scale = progress == 0.0 ? 0.0 : progress;
        final opacity = progress;
        final rotation = (1.0 - progress) * -0.26; // -15 degrees to 0

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: opacity,
              child: child,
            ),
          ),
        );
      },
      child: _buildGlowingBadge(
          context, badgeURL, eventId, badgeSize, globalIndex),
    );
  }

  Widget _buildGlowingBadge(
    BuildContext context,
    String badgeURL,
    String eventId,
    double badgeSize,
    int globalIndex,
  ) {
    final isGlowing = globalIndex == _currentGlowingBadgeIndex;

    if (!isGlowing) {
      // Static badge with subtle shadow
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrange.withAlpha(60),
              blurRadius: MediaQuery.of(context).size.width * 0.02,
              spreadRadius: 0,
            ),
          ],
        ),
        child: _buildBadgeContent(context, badgeURL, eventId, badgeSize),
      );
    }

    // Glowing badge with animated glow
    return FutureBuilder<Color>(
      future: _getDominantColor(badgeURL),
      builder: (context, snapshot) {
        final glowColor = snapshot.data ?? AppColors.primaryOrange;

        return AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            // Create fade-in and fade-out effect
            // 0.0 - 0.5: fade in (0 -> 1)
            // 0.5 - 1.0: fade out (1 -> 0)
            final rawValue = _glowController.value;
            final glowValue = rawValue <= 0.5
                ? rawValue * 2.0 // Fade in: 0.0-0.5 maps to 0.0-1.0
                : (1.0 - rawValue) * 2.0; // Fade out: 0.5-1.0 maps to 1.0-0.0

            final shadowBlur = MediaQuery.of(context).size.width * 0.03 +
                (MediaQuery.of(context).size.width * 0.025 * glowValue);
            final shadowSpread = MediaQuery.of(context).size.width * 0.0025 +
                (MediaQuery.of(context).size.width * 0.005 * glowValue);
            final shadowAlpha = (100 + (100 * glowValue)).toInt();

            return Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withAlpha(shadowAlpha),
                    blurRadius: shadowBlur,
                    spreadRadius: shadowSpread,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: _buildBadgeContent(context, badgeURL, eventId, badgeSize),
        );
      },
    );
  }

  Widget _buildBadgeContent(
    BuildContext context,
    String badgeURL,
    String eventId,
    double badgeSize,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(badgeSize / 2),
        onTap:
            eventId.isNotEmpty ? () => context.push('/event/$eventId') : null,
        child: Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.iceGlassGradient,
            border: Border.all(
              color: AppColors.auroraBorder,
              width: MediaQuery.of(context).size.width * 0.005,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: badgeURL,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.rosyBrown.withAlpha(100),
                      AppColors.pineGreen.withAlpha(80),
                    ],
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.05,
                    height: MediaQuery.of(context).size.width * 0.05,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: MediaQuery.of(context).size.width * 0.005,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.rosyBrown.withAlpha(80),
                      AppColors.pineGreen.withAlpha(60),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white.withAlpha(180),
                  size: badgeSize * 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.width * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rosyBrown.withAlpha(60),
                  AppColors.pineGreen.withAlpha(40),
                ],
              ),
              border: Border.all(
                color: AppColors.auroraBorder,
                width: MediaQuery.of(context).size.width * 0.005,
              ),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: Colors.white.withAlpha(150),
              size: MediaQuery.of(context).size.width * 0.12,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Text(
            'No badges yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            'Start participating in events to earn badges!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: MediaQuery.of(context).size.width * 0.035,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
