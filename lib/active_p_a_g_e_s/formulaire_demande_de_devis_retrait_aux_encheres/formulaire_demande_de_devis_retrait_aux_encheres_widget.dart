import '/app_shell.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/expedion_api/quote_repository.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/geocoding/nominatim_geocoder.dart';
import '/backend/quote_draft.dart';
import '/design_system/ds_address_autocomplete.dart';
import '/design_system/ds_button.dart';
import '/design_system/ds_card.dart';
import '/design_system/ds_l10n.dart';
import '/design_system/ds_text_field.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';

/// The manual devis form: everything Expeditoo needs to price a lot collection
/// when there is no bordereau to read it off.
///
/// It asks for exactly what `POST /api/expedion/quotes` stores and the pricing
/// step reads — pickup, lot, dimensions, declared value, delivery — plus the
/// bordereau if the client has one. Identity is not asked for: the session
/// already carries it, so the four name/e-mail/phone fields this form used to
/// open with were retyping.
///
/// A few operational details the server has no column for (recipient, delivery
/// phone, how the lot is packed) are folded into `comment` rather than dropped,
/// which is what the bordereau form does with its own extras.
class FormulaireDemandeDeDevisRetraitAuxEncheresWidget extends StatefulWidget {
  const FormulaireDemandeDeDevisRetraitAuxEncheresWidget({super.key});

  static String routeName = 'Formulaire-demande-de-devis-retrait-aux-encheres';
  static String routePath = '/formulaireDemandeDeDevisRetraitAuxEncheres';

  @override
  State<FormulaireDemandeDeDevisRetraitAuxEncheresWidget> createState() =>
      _FormulaireDemandeDeDevisRetraitAuxEncheresWidgetState();
}

/// How the lot is presented for collection. The server has no column for it,
/// so it rides along in the comment where the ops team reads it.
enum _Packing { unpacked, protected, packed }

class _FormulaireDemandeDeDevisRetraitAuxEncheresWidgetState
    extends State<FormulaireDemandeDeDevisRetraitAuxEncheresWidget> {
  final _formKey = GlobalKey<FormState>();

  // Pickup.
  final _auctionHouse = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _pickupPostalCode = TextEditingController();
  final _pickupCity = TextEditingController();

  /// Set when the visitor picks a suggestion out of [DSAddressAutocomplete]
  /// rather than typing free-form. Purely a client-side "this address really
  /// does resolve to a point" confirmation — the server geocodes and trusts
  /// its own copy of the coordinates once the address is saved
  /// (`expedionService.geocodeMissingCoordinates`), so nothing here is sent
  /// to the API. Cleared whenever the address text changes so a stale
  /// confirmation can never survive an edit.
  GeocodeSuggestion? _pickupPosition;

  // The lot.
  final _description = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _declaredValue = TextEditingController();

  // Bordereau.
  final _bordereauNumber = TextEditingController();
  bool _bordereauPaid = false;

  // Delivery.
  final _deliveryAddress = TextEditingController();
  final _deliveryPostalCode = TextEditingController();
  final _deliveryCity = TextEditingController();
  final _recipientName = TextEditingController();
  final _deliveryPhone = TextEditingController();

  /// Same role as [_pickupPosition], for the delivery address.
  GeocodeSuggestion? _deliveryPosition;

  final _comment = TextEditingController();

  _Packing _packing = _Packing.unpacked;

  // Attachments.
  FFUploadedFile? _bordereauFile;
  String _bordereauUrl = '';
  bool _uploadingBordereau = false;

  final _photoUrls = <String>[];
  bool _uploadingPhotos = false;

  /// The express-card bordereau's upload while it is in flight. Submit awaits
  /// it, so saving early cannot silently drop the file.
  Future<void>? _draftBordereauUpload;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pickupAddress.addListener(_clearPickupPositionIfEdited);
    _deliveryAddress.addListener(_clearDeliveryPositionIfEdited);

    // Whatever the landing page's express/quote card collected, so the visitor
    // does not retype what they already told us. Null unless they arrived from
    // one of those forms ([QuoteDraft.consume] clears as it reads).
    final draft = QuoteDraft.consume();
    final delivery = draft?.deliveryParts;

    // The landing page asks for the auction house as one free-text line
    // ("Drouot, Paris 9e"), which is exactly this field.
    _auctionHouse.text = draft?.pickup ?? '';
    _declaredValue.text = draft?.hammerPrice ?? '';

    // The express card only knows a lot count and type — park that here as a
    // starting description the visitor completes.
    _description.text = [
      if ((draft?.lotCount ?? '').isNotEmpty) '${draft!.lotCount} lot(s)',
      if ((draft?.lotType ?? '').isNotEmpty) draft!.lotType,
    ].join(' — ');

    // The landing page collects delivery as one "33000 Bordeaux" line;
    // [QuoteDraft.deliveryParts] splits it for these two fields.
    _deliveryPostalCode.text = delivery?.postcode ?? '';
    _deliveryCity.text = delivery?.city ?? '';

    // The collection deadline has no field of its own — it belongs with the
    // other notes rather than being dropped.
    if ((draft?.deadline ?? '').isNotEmpty) {
      _comment.text = 'Deadline de retrait : ${draft!.deadline}';
    }

    _stageDraftBordereau(draft?.bordereau);
  }

  /// Carries a bordereau attached on the landing page in as though it had been
  /// picked here: shown locally right away, uploaded post-frame.
  void _stageDraftBordereau(SelectedFile? draftBordereau) {
    if (draftBordereau == null || draftBordereau.bytes.isEmpty) return;

    final staged = FFUploadedFile(
      name: draftBordereau.storagePath.split('/').last,
      bytes: draftBordereau.bytes,
      originalFilename: draftBordereau.originalFilename,
    );
    _bordereauFile = staged;

    final uploadDone = Completer<void>();
    _draftBordereauUpload = uploadDone.future;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _uploadingBordereau = true);
      String? url;
      try {
        url =
            await uploadData(draftBordereau.storagePath, draftBordereau.bytes);
      } catch (_) {
        url = null; // Best effort — the visitor can re-pick the file.
      }
      if (mounted) {
        setState(() {
          _uploadingBordereau = false;
          // Only claim the slot if it is still the staged file: while this was
          // in flight the visitor may have picked their own bordereau (or
          // removed this one), and that choice wins.
          if (url != null && identical(_bordereauFile, staged)) {
            _bordereauUrl = url;
          }
        });
      }
      uploadDone.complete();
    });
  }

  void _clearPickupPositionIfEdited() {
    if (_pickupPosition != null &&
        _pickupAddress.text != _pickupPosition!.address) {
      setState(() => _pickupPosition = null);
    }
  }

  void _clearDeliveryPositionIfEdited() {
    if (_deliveryPosition != null &&
        _deliveryAddress.text != _deliveryPosition!.address) {
      setState(() => _deliveryPosition = null);
    }
  }

  @override
  void dispose() {
    _pickupAddress.removeListener(_clearPickupPositionIfEdited);
    _deliveryAddress.removeListener(_clearDeliveryPositionIfEdited);
    for (final c in [
      _auctionHouse,
      _pickupAddress,
      _pickupPostalCode,
      _pickupCity,
      _description,
      _length,
      _width,
      _height,
      _weight,
      _declaredValue,
      _bordereauNumber,
      _deliveryAddress,
      _deliveryPostalCode,
      _deliveryCity,
      _recipientName,
      _deliveryPhone,
      _comment,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================================================
  // Attachments
  // ==========================================================================

  Future<void> _pickBordereau() async {
    final files = await selectFiles(
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      multiFile: false,
    );
    if (files == null || files.isEmpty) return;

    final file = files.first;
    final local = FFUploadedFile(
      name: file.storagePath.split('/').last,
      bytes: file.bytes,
      originalFilename: file.originalFilename,
    );

    setState(() {
      _bordereauFile = local;
      _bordereauUrl = '';
      _uploadingBordereau = true;
    });

    String? url;
    try {
      url = await uploadData(file.storagePath, file.bytes);
    } catch (_) {
      url = null;
    }
    if (!mounted) return;

    setState(() {
      _uploadingBordereau = false;
      if (url != null && identical(_bordereauFile, local)) {
        _bordereauUrl = url;
      }
    });

    if (url == null && mounted) {
      _say(
        frText: "L'envoi du bordereau a échoué. Réessayez.",
        enText: 'Uploading the slip failed. Try again.',
      );
    }
  }

  Future<void> _pickPhotos() async {
    final media = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
      imageQuality: 80,
    );
    if (media == null || media.isEmpty) return;
    if (!media.every((m) => validateFileFormat(m.storagePath, context))) return;

    setState(() => _uploadingPhotos = true);
    final urls = (await Future.wait(
      media.map((m) async {
        try {
          return await uploadData(m.storagePath, m.bytes);
        } catch (_) {
          return null;
        }
      }),
    ))
        .whereType<String>()
        .toList();

    if (!mounted) return;
    setState(() {
      _uploadingPhotos = false;
      _photoUrls.addAll(urls);
    });

    if (urls.length != media.length && mounted) {
      _say(
        frText: "Certaines photos n'ont pas pu être envoyées.",
        enText: 'Some photos could not be uploaded.',
      );
    }
  }

  // ==========================================================================
  // Save
  // ==========================================================================

  /// Everything the server has no column for, gathered where ops will read it.
  String _buildComment() {
    final packing = switch (_packing) {
      _Packing.unpacked => 'Non emballé / non protégé',
      _Packing.protected => 'Protégé',
      _Packing.packed => 'Emballé',
    };

    return [
      _comment.text.trim(),
      'État du lot : $packing',
      if (_recipientName.text.trim().isNotEmpty)
        'Destinataire : ${_recipientName.text.trim()}',
      if (_deliveryPhone.text.trim().isNotEmpty)
        'Téléphone de livraison : ${_deliveryPhone.text.trim()}',
    ].where((line) => line.isNotEmpty).join('\n');
  }

  /// "1 250,50" and "1250.5" both become 125050.
  static int? _euroTextToCents(String raw) {
    final cleaned =
        raw.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.');
    final value = double.tryParse(cleaned);
    return value == null ? null : (value * 100).round();
  }

  static double? _numberOrNull(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _say(
        frText: 'Complétez les champs obligatoires.',
        enText: 'Fill in the required fields.',
      );
      return;
    }

    setState(() => _saving = true);

    // The express-card bordereau may still be in flight; wait for it so the
    // attachment is not dropped from the quote.
    await _draftBordereauUpload;

    final result = await QuoteRepository.create({
      'auctionHouseName': _auctionHouse.text.trim(),
      'pickupAddress': _pickupAddress.text.trim(),
      'pickupPostalCode': _pickupPostalCode.text.trim(),
      'pickupCity': _pickupCity.text.trim(),
      'description': _description.text.trim(),
      'lengthCm': _numberOrNull(_length.text),
      'widthCm': _numberOrNull(_width.text),
      'heightCm': _numberOrNull(_height.text),
      'weightKg': _numberOrNull(_weight.text),
      'declaredValueCents': _euroTextToCents(_declaredValue.text),
      'bordereauNumber': _bordereauNumber.text.trim(),
      'bordereauPaid': _bordereauPaid,
      if (_bordereauUrl.isNotEmpty) 'bordereauDocUrl': _bordereauUrl,
      if (_photoUrls.isNotEmpty) 'photoUrls': _photoUrls,
      'deliveryAddress': _deliveryAddress.text.trim(),
      'deliveryPostalCode': _deliveryPostalCode.text.trim(),
      'deliveryCity': _deliveryCity.text.trim(),
      'comment': _buildComment(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.succeeded) {
      final message = result.needsSignIn
          ? xpdT(context, 'Connectez-vous pour enregistrer votre demande.',
              'Sign in to save your request.')
          : xpdApiErrorMessage(
              context,
              result.code,
              fallbackFr: "L'enregistrement a échoué. Réessayez.",
              fallbackEn: 'Saving failed. Try again.',
            );
      _say(frText: message, enText: message);
      if (result.needsSignIn) {
        context.pushNamed(SeConnecterWidget.routeName);
      }
      return;
    }

    _say(
      frText: 'Demande enregistrée. Votre devis arrive sous 48 h.',
      enText: 'Request saved. Your quote will arrive within 48 h.',
    );
    context.pushNamed(MesDevisWidget.routeName);
  }

  void _say({required String frText, required String enText}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(FFLocalizations.of(context)
            .getVariableText(frText: frText, enText: enText)),
      ),
    );
  }

  String _t({required String fr, required String en}) =>
      FFLocalizations.of(context).getVariableText(frText: fr, enText: en);

  String? _required(String? value) => (value ?? '').trim().isEmpty
      ? _t(fr: 'Champ obligatoire', en: 'Required')
      : null;

  /// Exactly 5 digits once non-digits are stripped — the same shape
  /// `normalisePostalCode` requires server-side before a quote can publish
  /// (`expedion-escalation.service.ts`). Catching "75001 Cedex" or a 4-digit
  /// typo here means the client hears about it immediately, instead of the
  /// quote sitting blocked until an admin notices.
  String? _postalCode(String? value) {
    final missing = _required(value);
    if (missing != null) return missing;
    final digits = value!.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 5
        ? null
        : _t(fr: 'Code postal à 5 chiffres', en: '5-digit postcode');
  }

  /// Weight is the one dimension `escalationBlockers` actually gates
  /// publishing on (length/width/height are optional there) — see
  /// `escalationBlockers` in `expedion-escalation.service.ts`.
  String? _weightRequired(String? value) {
    final missing = _required(value);
    if (missing != null) return missing;
    final parsed = _numberOrNull(value!);
    return (parsed == null || parsed <= 0)
        ? _t(fr: 'Poids invalide', en: 'Invalid weight')
        : null;
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: XpdPage(
        current: XpdDestination.requestQuote,
        onBack: () => context.safePop(),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 40.0),
                  children: [
                    Text(
                      _t(
                        fr: 'Ces informations nous permettent de chiffrer le '
                            'retrait et la livraison de votre lot.',
                        en: 'These details let us price the collection and '
                            'delivery of your lot.',
                      ),
                      style:
                          theme.bodyMedium.override(color: theme.secondaryText),
                    ),
                    const SizedBox(height: 20.0),
                    _pickupSection(theme),
                    const SizedBox(height: 16.0),
                    _lotSection(theme),
                    const SizedBox(height: 16.0),
                    _bordereauSection(theme),
                    const SizedBox(height: 16.0),
                    _deliverySection(theme),
                    const SizedBox(height: 16.0),
                    _notesSection(theme),
                    const SizedBox(height: 24.0),
                    DSButton(
                      label: _t(fr: 'Enregistrer', en: 'Save'),
                      icon: Icons.check_rounded,
                      expand: true,
                      size: DSButtonSize.lg,
                      onPressed:
                          _saving || _uploadingBordereau || _uploadingPhotos
                              ? null
                              : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.0, color: theme.primary),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  style: theme.titleSmall.override(color: theme.primaryText),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ],
          const SizedBox(height: 16.0),
          ...children,
        ],
      ),
    );
  }

  Widget _pickupSection(FlutterFlowTheme theme) => _section(
        theme,
        icon: Icons.gavel_rounded,
        title: _t(fr: 'Retrait', en: 'Collection'),
        subtitle: _t(
          fr: 'Où le lot doit être récupéré.',
          en: 'Where the lot is collected from.',
        ),
        children: [
          DSTextField(
            controller: _auctionHouse,
            label: _t(fr: 'Maison de ventes *', en: 'Auction house *'),
            hintText: 'Drouot, Paris 9e',
            validator: _required,
          ),
          const SizedBox(height: 12.0),
          DSAddressAutocomplete(
            controller: _pickupAddress,
            label: _t(fr: 'Adresse de retrait *', en: 'Collection address *'),
            helperText: _t(
              fr: 'Commencez à taper pour choisir une adresse reconnue.',
              en: 'Start typing to pick a recognised address.',
            ),
            validator: _required,
            onSelected: (suggestion) => setState(() {
              _pickupPosition = suggestion;
              if (suggestion.postalCode.isNotEmpty) {
                _pickupPostalCode.text = suggestion.postalCode;
              }
              if (suggestion.city.isNotEmpty) {
                _pickupCity.text = suggestion.city;
              }
            }),
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DSTextField(
                  controller: _pickupPostalCode,
                  label: _t(fr: 'Code postal *', en: 'Postcode *'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  mono: true,
                  validator: _postalCode,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                flex: 2,
                child: DSTextField(
                  controller: _pickupCity,
                  label: _t(fr: 'Ville *', en: 'City *'),
                  validator: _required,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          DSPositionConfirmedChip(suggestion: _pickupPosition),
        ],
      );

  Widget _lotSection(FlutterFlowTheme theme) => _section(
        theme,
        icon: Icons.inventory_2_outlined,
        title: _t(fr: 'Le lot', en: 'The lot'),
        subtitle: _t(
          fr: 'Les dimensions et la valeur déterminent le prix du transport.',
          en: 'Dimensions and value drive the transport price.',
        ),
        children: [
          DSTextField(
            controller: _description,
            label: _t(fr: 'Description du lot *', en: 'Lot description *'),
            hintText: _t(
              fr: 'Commode Louis XV, marbre, fragile',
              en: 'Louis XV chest of drawers, marble, fragile',
            ),
            maxLines: 3,
            minLines: 2,
            validator: _required,
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DSTextField(
                  controller: _length,
                  label: _t(fr: 'Longueur (cm)', en: 'Length (cm)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  mono: true,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DSTextField(
                  controller: _width,
                  label: _t(fr: 'Largeur (cm)', en: 'Width (cm)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  mono: true,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DSTextField(
                  controller: _height,
                  label: _t(fr: 'Hauteur (cm)', en: 'Height (cm)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  mono: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DSTextField(
                  controller: _weight,
                  label: _t(fr: 'Poids (kg) *', en: 'Weight (kg) *'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  mono: true,
                  validator: _weightRequired,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DSTextField(
                  controller: _declaredValue,
                  label: _t(
                      fr: 'Valeur déclarée (€) *', en: 'Declared value (€) *'),
                  helperText: _t(
                    fr: "Sert à calculer l'assurance ad valorem.",
                    en: 'Used to size the ad valorem cover.',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  mono: true,
                  validator: (value) {
                    final missing = _required(value);
                    if (missing != null) return missing;
                    return _euroTextToCents(value!) == null
                        ? _t(fr: 'Montant invalide', en: 'Invalid amount')
                        : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _packingPicker(theme),
          const SizedBox(height: 16.0),
          _photoPicker(theme),
        ],
      );

  Widget _packingPicker(FlutterFlowTheme theme) {
    const labels = {
      _Packing.unpacked: (fr: 'Non emballé', en: 'Unpacked'),
      _Packing.protected: (fr: 'Protégé', en: 'Protected'),
      _Packing.packed: (fr: 'Emballé', en: 'Packed'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(fr: 'État du lot', en: 'Lot condition'),
          style: theme.labelMedium.override(color: theme.primaryText),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _Packing.values.map((packing) {
            final selected = _packing == packing;
            return ChoiceChip(
              label: Text(
                _t(fr: labels[packing]!.fr, en: labels[packing]!.en),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _packing = packing),
              backgroundColor: theme.secondaryBackground,
              selectedColor: theme.primary,
              side: BorderSide(
                color: selected ? theme.primary : theme.alternate,
              ),
              labelStyle: theme.bodySmall.override(
                color: selected ? Colors.white : theme.primaryText,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _photoPicker(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSButton(
          label: _photoUrls.isEmpty
              ? _t(fr: 'Ajouter des photos', en: 'Add photos')
              : _t(
                  fr: '${_photoUrls.length} photo(s) ajoutée(s)',
                  en: '${_photoUrls.length} photo(s) added',
                ),
          icon: Icons.photo_camera_outlined,
          variant: DSButtonVariant.outline,
          expand: true,
          onPressed: _uploadingPhotos ? null : _pickPhotos,
        ),
        if (_photoUrls.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(_photoUrls.clear),
              child: Text(
                _t(fr: 'Tout retirer', en: 'Remove all'),
                style: theme.bodySmall.override(color: theme.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bordereauSection(FlutterFlowTheme theme) => _section(
        theme,
        icon: Icons.receipt_long_outlined,
        title: _t(fr: 'Bordereau', en: 'Purchase slip'),
        subtitle: _t(
          fr: "Facultatif, mais il accélère la validation du retrait.",
          en: 'Optional, but it speeds up clearing the collection.',
        ),
        children: [
          DSTextField(
            controller: _bordereauNumber,
            label: _t(fr: 'N° de bordereau', en: 'Slip number'),
            mono: true,
          ),
          const SizedBox(height: 12.0),
          DSButton(
            label: _bordereauFile == null
                ? _t(fr: 'Joindre le bordereau', en: 'Attach the slip')
                : (_bordereauFile!.name ??
                    _t(fr: 'Bordereau joint', en: 'Slip attached')),
            icon: _bordereauFile == null
                ? Icons.upload_file_outlined
                : Icons.description_outlined,
            variant: DSButtonVariant.outline,
            expand: true,
            onPressed: _uploadingBordereau ? null : _pickBordereau,
          ),
          if (_uploadingBordereau) ...[
            const SizedBox(height: 8.0),
            Text(
              _t(fr: 'Envoi en cours…', en: 'Uploading…'),
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ],
          const SizedBox(height: 8.0),
          SwitchListTile.adaptive(
            value: _bordereauPaid,
            onChanged: (value) => setState(() => _bordereauPaid = value),
            contentPadding: EdgeInsets.zero,
            title: Text(
              _t(fr: 'Bordereau acquitté', en: 'Slip already paid'),
              style: theme.bodyMedium.override(color: theme.primaryText),
            ),
            subtitle: Text(
              _t(
                fr: 'La maison de ventes a bien reçu votre règlement.',
                en: 'The auction house has received your payment.',
              ),
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
            activeThumbColor: theme.primary,
          ),
        ],
      );

  Widget _deliverySection(FlutterFlowTheme theme) => _section(
        theme,
        icon: Icons.local_shipping_outlined,
        title: _t(fr: 'Livraison', en: 'Delivery'),
        subtitle: _t(
          fr: 'Où le lot doit être livré.',
          en: 'Where the lot is delivered to.',
        ),
        children: [
          DSAddressAutocomplete(
            controller: _deliveryAddress,
            label: _t(fr: 'Adresse de livraison *', en: 'Delivery address *'),
            helperText: _t(
              fr: 'Commencez à taper pour choisir une adresse reconnue.',
              en: 'Start typing to pick a recognised address.',
            ),
            validator: _required,
            onSelected: (suggestion) => setState(() {
              _deliveryPosition = suggestion;
              if (suggestion.postalCode.isNotEmpty) {
                _deliveryPostalCode.text = suggestion.postalCode;
              }
              if (suggestion.city.isNotEmpty) {
                _deliveryCity.text = suggestion.city;
              }
            }),
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DSTextField(
                  controller: _deliveryPostalCode,
                  label: _t(fr: 'Code postal *', en: 'Postcode *'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  mono: true,
                  validator: _postalCode,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                flex: 2,
                child: DSTextField(
                  controller: _deliveryCity,
                  label: _t(fr: 'Ville *', en: 'City *'),
                  validator: _required,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          DSPositionConfirmedChip(suggestion: _deliveryPosition),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DSTextField(
                  controller: _recipientName,
                  label: _t(fr: 'Nom du destinataire', en: "Recipient's name"),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DSTextField(
                  controller: _deliveryPhone,
                  label: _t(fr: 'Téléphone sur place', en: 'Phone on site'),
                  keyboardType: TextInputType.phone,
                  mono: true,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _notesSection(FlutterFlowTheme theme) => _section(
        theme,
        icon: Icons.chat_bubble_outline_rounded,
        title: _t(fr: 'Précisions', en: 'Notes'),
        subtitle: _t(
          fr: 'Accès, étage, ascenseur, créneaux — tout ce qui aide le '
              'transporteur.',
          en: 'Access, floor, lift, time slots — anything that helps the '
              'carrier.',
        ),
        children: [
          DSTextField(
            controller: _comment,
            label: _t(fr: 'Commentaire', en: 'Comment'),
            maxLines: 4,
            minLines: 3,
          ),
        ],
      );
}
