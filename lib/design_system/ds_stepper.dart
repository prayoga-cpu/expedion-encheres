import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Mirrors `expeditoo-ship/src/components/Stepper.tsx`, the step indicator on
/// the Expeditoo create-listing flow.
///
/// 40px circles: filled `primary` once reached, with a `ring-2 ring-primary/30`
/// halo on the current step and `muted` for steps not yet reached. Completed
/// steps show a check instead of their number. Underneath, a 4px `muted` track
/// fills with `primary` to `(currentStep + 1) / steps.length`.
class DSStepper extends StatelessWidget {
  const DSStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTap,
  });

  final List<String> steps;

  /// Zero-based.
  final int currentStep;

  /// Only steps at or before [currentStep] are tappable, matching the web
  /// component's `disabled={index > currentStep}`.
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final progress = steps.isEmpty
        ? 0.0
        : (currentStep + 1).clamp(0, steps.length) / steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(child: _step(context, theme, i)),
          ],
        ),
        const SizedBox(height: 16.0),
        // `h-1 bg-muted rounded-full overflow-hidden`
        ClipRRect(
          borderRadius: BorderRadius.circular(DSShape.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4.0,
            backgroundColor: theme.secondary,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
        const SizedBox(height: DSSize.sectionGap),
      ],
    );
  }

  Widget _step(BuildContext context, FlutterFlowTheme theme, int index) {
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;
    final isReached = isDone || isCurrent;
    final tappable = onStepTap != null && index <= currentStep;

    final circle = AnimatedContainer(
      duration: DSMotion.duration,
      curve: DSMotion.curve,
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: isReached ? theme.primary : theme.secondary,
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.30),
                  blurRadius: 0.0,
                  spreadRadius: 2.0,
                ),
              ]
            : const <BoxShadow>[],
      ),
      alignment: Alignment.center,
      child: isDone
          ? Icon(Icons.check_rounded, size: 24.0, color: theme.info)
          : Text(
              '${index + 1}',
              style: theme.labelMedium.copyWith(
                color: isReached ? theme.info : theme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tappable
            ? Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onStepTap!(index),
                  customBorder: const CircleBorder(),
                  child: circle,
                ),
              )
            : circle,
        const SizedBox(height: 8.0),
        // `text-xs font-medium text-center text-muted-foreground max-w-[100px]`
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100.0),
          child: Text(
            steps[index],
            textAlign: TextAlign.center,
            style: theme.labelSmall.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
