import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_footer.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _membersController;

  final members = const [
    _TeamMember(name: 'DAKSH YADAV', assetPath: 'assets/team/daksh.bmp'),
    _TeamMember(name: 'SUJAL GAHLAWAT', assetPath: 'assets/team/madhav.bmp'),
    _TeamMember(name: 'MADHAV JHA', assetPath: 'assets/team/sujal.bmp'),
    _TeamMember(name: 'SAURAV CHAUDHARY', assetPath: 'assets/team/saurav.bmp'),
  ];

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _membersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _playSequence();
  }

  Future<void> _playSequence() async {
    await _introController.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _membersController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        foregroundColor: AppThemeColors.textPrimary(context),
        elevation: 0,
      ),
      body: AppChrome(
        padding: EdgeInsets.zero,
        safeBottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = constraints.maxWidth >= 760 ? 220.0 : 188.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const AccentHeadline(
                    title: 'The Team',
                    subtitle:
                        'The people behind the KineSentry experience.',
                    center: true,
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _introController,
                    builder: (context, _) {
                      final titleFade = CurvedAnimation(
                        parent: _introController,
                        curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
                      ).value;
                      final titleY = (1 - titleFade) * 26.0;

                      return Opacity(
                        opacity: titleFade,
                        child: Transform.translate(
                          offset: Offset(0, titleY),
                          child: const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _introController,
                    builder: (context, _) {
                      final logoFade = CurvedAnimation(
                        parent: _introController,
                        curve: const Interval(0.36, 1.0, curve: Curves.easeOutCubic),
                      ).value;
                      final logoY = (1 - logoFade) * 22.0;
                      final pulse = 1 + (logoFade * 0.02);

                      return Opacity(
                        opacity: logoFade,
                        child: Transform.translate(
                          offset: Offset(0, logoY),
                          child: Transform.scale(
                            scale: pulse,
                            child: Container(
                              height: logoSize,
                              width: logoSize,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF111827),
                                  width: 1.6,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: logoSize * 0.62,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _MembersGrid(
                    controller: _membersController,
                    members: members,
                  ),
                  AppFooter(light: !AppThemeColors.isDark(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MembersGrid extends StatelessWidget {
  const _MembersGrid({
    required this.controller,
    required this.members,
  });

  final AnimationController controller;
  final List<_TeamMember> members;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 950
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;

        return GridView.builder(
          itemCount: members.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 22,
            mainAxisSpacing: 24,
            childAspectRatio: columns == 1 ? 0.94 : 0.76,
          ),
          itemBuilder: (context, index) {
            final start = 0.08 + (index * 0.12);
            final end = (start + 0.46).clamp(0.0, 1.0);
            final animation = CurvedAnimation(
              parent: controller,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            );

            return _AnimatedMemberCard(
              member: members[index],
              animation: animation,
            );
          },
        );
      },
    );
  }
}

class _AnimatedMemberCard extends StatefulWidget {
  const _AnimatedMemberCard({
    required this.member,
    required this.animation,
  });

  final _TeamMember member;
  final Animation<double> animation;

  @override
  State<_AnimatedMemberCard> createState() => _AnimatedMemberCardState();
}

class _AnimatedMemberCardState extends State<_AnimatedMemberCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final t = widget.animation.value;
        final opacity = t.clamp(0.0, 1.0);
        final translateY = (1 - t) * 70.0;
        final scale = 0.9 + (t * 0.1);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: MouseRegion(
                onEnter: (_) => setState(() => hovered = true),
                onExit: (_) => setState(() => hovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(0.0, hovered ? -8.0 : 0.0)
                    ..scale(hovered ? 1.02 : 1.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            color: Colors.white,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: 230,
                                    height: 230,
                                    child: Image.asset(
                                      widget.member.assetPath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity: hovered ? 1 : 0,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFF111827)
                                              .withValues(alpha: .05),
                                          const Color(0xFF111827)
                                              .withValues(alpha: .12),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          color: hovered
                              ? const Color(0xFF111827)
                              : const Color(0xFF4B5563),
                          fontSize: hovered ? 21 : 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                        child: Text(
                          widget.member.name,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeamMember {
  const _TeamMember({
    required this.name,
    required this.assetPath,
  });

  final String name;
  final String assetPath;
}
