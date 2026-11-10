import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

/// Big, forgiving button for users who may not read well:
/// large target, icon + text, strong colour.
class BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;
  const BigButton({super.key, required this.icon, required this.label, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        label: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 32),
            tooltip: app.t('listen'),
            onPressed: () => app.voice.speak(widget.promptKey),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: widget.body,
        ),
      ),
      bottomNavigationBar: widget.bottomBar == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.bottomBar,
              ),
            ),
    );
  }
}
