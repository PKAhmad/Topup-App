import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

/// Design language copied from the CEO's Expense Tracker app:
/// warm cream background with soft blue glows, white glass cards,
/// ink-navy text, and a neon-blue gradient for primary actions.
class AppColors {
  static const ink = Color(0xFF182740);
  static const muted = Color(0xFF62748E);
  static const blue = Color(0xFF0091FF);
  static const blueLight = Color(0xFF3FC1FF);
  static const creamTop = Color(0xFFFCF9F2);
  static const creamMid = Color(0xFFFAF5EA);
  static const creamBottom = Color(0xFFF6F0E2);
  static const cardShadow = Color(0x21183C78); // rgba(24,64,120,.13)
}

/// The Expense Tracker backdrop: cream gradient + two soft blue glows.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.creamTop, AppColors.creamMid, AppColors.creamBottom],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.blue.withValues(alpha: 0.32), AppColors.blue.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA5D8FF).withValues(alpha: 0.45),
                    const Color(0xFFA5D8FF).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// White glass card, Expense Tracker style: translucent white fill, bright
/// white edge, soft navy shadow, 22px radius. (No live blur — the translucent
/// fill over the gradient gives the same look and scrolls smoothly.)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: selected ? 0.92 : 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? AppColors.blue : Colors.white.withValues(alpha: 0.85),
          width: selected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: card,
    );
  }
}

/// Big, forgiving button for users who may not read well:
/// large target, icon + text. Primary = Expense Tracker's neon-blue
/// gradient; a passed [color] tints the gradient (green = yes, red = no).
class BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;
  const BigButton({super.key, required this.icon, required this.label, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final top = color == null ? AppColors.blueLight : Color.lerp(color, Colors.white, 0.25)!;
    final bottom = color ?? AppColors.blue;
    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled ? LinearGradient(colors: [top, bottom], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
        color: enabled ? null : AppColors.muted.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: enabled
            ? [BoxShadow(color: bottom.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              Flexible(
                child: Text(label,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shell for every wizard step: title, a speaker button that replays
/// the step's voice prompt, and automatic prompt playback when the step opens.
class StepScaffold extends StatefulWidget {
  final String title;
  final String promptKey;
  final Widget body;
  final Widget? bottomBar;
  final bool autoSpeak;
  const StepScaffold({
    super.key,
    required this.title,
    required this.promptKey,
    required this.body,
    this.bottomBar,
    this.autoSpeak = true,
  });

  @override
  State<StepScaffold> createState() => _StepScaffoldState();
}

class _StepScaffoldState extends State<StepScaffold> {
  @override
  void initState() {
    super.initState();
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppState>().voice.speak(widget.promptKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.creamBottom,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(widget.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink)),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                boxShadow: const [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.volume_up, size: 30, color: AppColors.blue),
                tooltip: app.t('listen'),
                onPressed: () => app.voice.speak(widget.promptKey),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: widget.body,
          ),
        ),
      ),
      bottomNavigationBar: widget.bottomBar == null
          ? null
          : Container(
              color: AppColors.creamBottom,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: widget.bottomBar,
                ),
              ),
            ),
    );
  }
}
