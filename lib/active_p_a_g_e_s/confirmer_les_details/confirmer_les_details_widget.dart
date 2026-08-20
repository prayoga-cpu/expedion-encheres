import '/app_shell.dart';
import 'package:flutter/material.dart';

import '/backend/expedion_api/expedion_api.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// **Confirmer les détails** — the screen that turns model-level extraction
/// accuracy into user-verified accuracy (ROADMAP.md §3).
///
/// After a bordereau is read by GPT-4.1 Vision, the client sees every field it
/// found, corrects anything wrong, and signs off. Only then is the quote
/// priced. Fields the model could not find are flagged rather than left as
/// silent blanks, because a missing dimension is the difference between an
/// accurate devis and a wrong one.
class ConfirmerLesDetailsWidget extends StatefulWidget {
  const ConfirmerLesDetailsWidget({
    super.key,
    required this.quoteId,
  });

  static const String routeName = 'ConfirmerLesDetails';
  static const String routePath = '/confirmerLesDetails';

  final String quoteId;

  @override
  State<ConfirmerLesDetailsWidget> createState() =>
      _ConfirmerLesDetailsWidgetState();
}

class _ConfirmerLesDetailsWidgetState extends State<ConfirmerLesDetailsWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {};
  Set<String> _missing = {};

  bool _loading = true;
  String? _loadErrorCode;
  double? _confidence;

  /// Field key → (label, labelEn, keyboard, mono).
  static const _fields = <_FieldSpec>[
    _FieldSpec('bordereauNumber', 'Numéro de bordereau', 'Slip number',
        mono: true),
    _FieldSpec('auctionHouseName', 'Maison de ventes', 'Auction house'),
    _FieldSpec('pickupAddress', 'Adresse de retrait', 'Collection address'),
    _FieldSpec('pickupPostalCode', 'Code postal de retrait',
        'Collection postal code',
        keyboard: TextInputType.number, mono: true),
    _FieldSpec('pickupCity', 'Ville de retrait', 'Collection city'),
    _FieldSpec('description', 'Description du lot', 'Lot description',
        maxLines: 3),
    _FieldSpec('lengthCm', 'Longueur (cm)', 'Length (cm)',
        keyboard: TextInputType.number, mono: true, numeric: true),
    _FieldSpec('widthCm', 'Largeur (cm)', 'Width (cm)',
        keyboard: TextInputType.number, mono: true, numeric: true),
    _FieldSpec('heightCm', 'Hauteur (cm)', 'Height (cm)',
        keyboard: TextInputType.number, mono: true, numeric: true),
    _FieldSpec('weightKg', 'Poids (kg)', 'Weight (kg)',
        keyboard: TextInputType.number, mono: true, numeric: true),
    _FieldSpec('deliveryAddress', 'Adresse de livraison', 'Delivery address'),
    _FieldSpec('deliveryPostalCode', 'Code postal de livraison',
        'Delivery postal code',
        keyboard: TextInputType.number, mono: true),
    _FieldSpec('deliveryCity', 'Ville de livraison', 'Delivery city'),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f.key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await ExpedionApi.getQuote(widget.quoteId);
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _loadErrorCode = result.code;
      });
      return;
    }

    final quote = result.map;
    for (final f in _fields) {
      final value = quote[f.key];
      _controllers[f.key]!.text = value == null ? '' : value.toString();
    }

    setState(() {
      _loading = false;
      _confidence = (quote['extractionConfidence'] as num?)?.toDouble();
      // Anything the extraction left empty is what the client must supply.
      _missing = _fields
          .where((f) => (_controllers[f.key]!.text).trim().isEmpty)
          .map((f) => f.key)
          .toSet();
    });
  }

  Map<String, dynamic> _payload() {
    final payload = <String, dynamic>{'confirmExtraction': true};
    for (final f in _fields) {
      final raw = _controllers[f.key]!.text.trim();
      if (raw.isEmpty) continue;
      payload[f.key] =
          f.numeric ? double.tryParse(raw.replaceAll(',', '.')) : raw;
    }
    return payload;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await ExpedionApi.updateQuote(widget.quoteId, _payload());
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            xpdApiErrorMessage(
              context,
              result.code,
              fallbackFr: 'Échec de l’enregistrement',
              fallbackEn: 'Save failed.',
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          xpdT(
            context,
            'Détails confirmés. Votre devis est en cours de calcul.',
            'Details confirmed. Your quote is being calculated.',
          ),
        ),
      ),
    );
    context.safePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: XpdPage(
        current: XpdDestination.quotes,
        onBack: () => context.safePop(),
        body: SafeArea(child: _body(theme)),
      ),
    );
  }

  Widget _body(FlutterFlowTheme theme) {
    if (_loading) {
      return DSPageLoader(
        message: xpdT(context, 'Lecture du bordereau…', 'Reading the slip…'),
      );
    }

    if (_loadErrorCode != null) {
      return DSEmptyState(
        icon: Icons.error_outline_rounded,
        title: xpdT(context, 'Devis introuvable', 'Quote not found'),
        description: xpdApiErrorMessage(
          context,
          _loadErrorCode,
          fallbackFr: 'Devis introuvable.',
          fallbackEn: 'Quote not found.',
        ),
        variant: DSEmptyStateVariant.page,
        action: DSButton(
          label: xpdT(context, 'Réessayer', 'Try again'),
          icon: Icons.refresh_rounded,
          onPressed: () {
            setState(() {
              _loading = true;
              _loadErrorCode = null;
            });
            return _load();
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DSStepper(
              steps: [
                xpdT(context, 'Bordereau', 'Slip'),
                xpdT(context, 'Détails', 'Details'),
                xpdT(context, 'Devis', 'Quote'),
              ],
              currentStep: 1,
            ),
            _banner(theme),
            const SizedBox(height: DSSize.sectionGap),
            for (final f in _fields) ...[
              DSTextField(
                controller: _controllers[f.key],
                label: xpdT(context, f.label, f.labelEn),
                mono: f.mono,
                maxLines: f.maxLines,
                keyboardType: f.keyboard,
                helperText: _missing.contains(f.key)
                    ? xpdT(
                        context,
                        'Non trouvé sur le bordereau — merci de compléter',
                        'Not found on the slip — please fill in',
                      )
                    : null,
                validator: (value) {
                  if (!f.numeric) return null;
                  final raw = (value ?? '').trim();
                  if (raw.isEmpty) return null;
                  final parsed = double.tryParse(raw.replaceAll(',', '.'));
                  if (parsed == null) {
                    return xpdT(
                      context,
                      'Valeur numérique attendue',
                      'A numeric value is expected',
                    );
                  }
                  if (parsed <= 0) {
                    return xpdT(
                      context,
                      'Doit être supérieur à 0',
                      'Must be greater than 0',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
            ],
            const SizedBox(height: 8.0),
            DSButton(
              label: xpdT(
                context,
                'Confirmer et calculer le devis',
                'Confirm and calculate the quote',
              ),
              icon: Icons.check_rounded,
              expand: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 12.0),
            Text(
              xpdT(
                context,
                'Les dimensions déterminent le prix. Vérifiez-les avant de '
                'confirmer.',
                'Dimensions determine the price. Check them before '
                'confirming.',
              ),
              textAlign: TextAlign.center,
              style: theme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Tells the client how much of the slip was read, and how much is on them.
  Widget _banner(FlutterFlowTheme theme) {
    final missingCount = _missing.length;
    final status = missingCount == 0 ? DSStatus.success : DSStatus.warning;
    final title = missingCount == 0
        ? xpdT(context, 'Bordereau lu intégralement', 'Slip read in full')
        : xpdT(
            context,
            '$missingCount champ${missingCount > 1 ? 's' : ''} à compléter',
            '$missingCount field${missingCount > 1 ? 's' : ''} to complete',
          );
    final confidenceText = _confidence == null
        ? null
        : xpdT(
            context,
            'Confiance de lecture : ${(_confidence! * 100).round()} %',
            'Reading confidence: ${(_confidence! * 100).round()} %',
          );

    return Container(
      padding: const EdgeInsets.all(DSSize.cardPadding),
      decoration: BoxDecoration(
        color: status.background(context),
        borderRadius: BorderRadius.circular(DSShape.card),
        border: Border.all(
          color: status.border(context),
          width: DSShape.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            missingCount == 0
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 20.0,
            color: status.foreground(context),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.labelMedium.copyWith(
                    color: status.foreground(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  confidenceText ??
                      xpdT(
                        context,
                        'Vérifiez chaque champ avant de confirmer.',
                        'Check each field before confirming.',
                      ),
                  style: theme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldSpec {
  const _FieldSpec(
    this.key,
    this.label,
    this.labelEn, {
    this.keyboard,
    this.mono = false,
    this.numeric = false,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final String labelEn;
  final TextInputType? keyboard;
  final bool mono;
  final bool numeric;
  final int maxLines;
}
