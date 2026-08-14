import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Bottom sheet matching `expeditoo-ship/src/components/ui/sheet.tsx`:
/// `bg-background`, a `bg-black/50` overlay, and — per the Expedion roadmap —
/// a 16px radius on the top corners only.
///
/// Returns whatever [builder]'s route is popped with.
Future<T?> showDSSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showHandle = true,

  /// Fraction of the screen height the sheet may occupy.
  double maxHeightFactor = 0.9,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (sheetContext) => DSSheetContainer(
      title: title,
      showHandle: showHandle,
      maxHeightFactor: maxHeightFactor,
      child: Builder(builder: builder),
    ),
  );
}

class DSSheetContainer extends StatelessWidget {
  const DSSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.maxHeightFactor = 0.9,
  });

  final Widget child;
  final String? title;
  final bool showHandle;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFactor,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DSShape.sheet),
        ),
        border: Border(
          top: BorderSide(color: theme.alternate, width: DSShape.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Lift the sheet above the keyboard when a field inside is focused.
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Center(
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: theme.alternate,
                        borderRadius: BorderRadius.circular(DSShape.pill),
                      ),
                    ),
                  ),
                ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                  child: Text(title!, style: theme.titleMedium),
                ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
