import '/app_shell.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/expedion_api/quote_repository.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/quote_draft.dart';
import '/backend/quote_form_draft.dart';
import '/backend/quote_form_rules.dart';
import '/design_system/ds_button.dart';
import '/design_system/ds_card.dart';
import '/design_system/ds_l10n.dart';
import '/design_system/ds_location_picker.dart';
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
/// ## What is required, and why
///
/// The line between required and optional is not a matter of taste here. A
/// quote that reaches Expeditoo missing any of the first group cannot be
/// escalated to a carrier: `escalationBlockers`
/// (`expeditoo-ship/src/server/services/expedion-escalation.service.ts`)
/// refuses the job and it sits in the operator queue until a human chases the
/// client for the answer. Asking here costs one field; asking later costs a
/// phone call and a day.
///
/// | Field                        | Rule                              | Why |
/// |------------------------------|-----------------------------------|-----|
/// | Auction house                | 2+ characters                     | the crew has to announce themselves to someone |
/// | Collection address           | not empty                         | blocker: `pickup address` |
/// | Collection postcode          | exactly 5 digits                  | blocker: `pickup postal code` (`normalisePostalCode`) |
/// | Collection town              | not empty                         | blocker: `pickup city` |
/// | Collection position          | geocoded, pinned, or accepted     | blocker: `pickup coordinates` |
/// | Lot description              | 5+ characters                     | `buildTitle` falls back to "Retrait enchères" below that |
/// | Weight                       | > 0, ≤ 5 000 kg                   | blocker: `weight`; the cap catches "1200" typed for "12,00" |
/// | Declared value               | > 0, ≤ 5 000 000 €                | sizes the ad valorem cover |
/// | Delivery address / postcode / town / position | as collection    | the four delivery blockers |
///
/// Everything else is optional — but optional means *may be left empty*, never
/// *may be wrong*: a filled optional field is held to its own rule before the
/// form will submit.
///
/// | Field              | Rule when filled                                |
/// |--------------------|-------------------------------------------------|
/// | L / W / H          | all three or none, each 1–1000 cm (`buildDescription` prints them only as a set) |
/// | Recipient          | 2+ characters                                    |
/// | Phone on site      | a French number (`06…`, `+33 6…`)                |
/// | Slip number        | ≤ 30 characters                                  |
/// | Comment            | ≤ 1000 characters                                |
///
/// Submit stays disabled until every one of those holds and no upload is in
/// flight; the panel above the buttons lists whatever is still missing, so the
/// disabled button is never a mystery. Save draft has no conditions at all —
/// it keeps whatever has been typed so far on this device
/// ([QuoteFormDraft]), because half a form is worth keeping and Expeditoo has
/// no server-side draft state to put it in.
///
/// A few operational details the server has no column for (how the lot is
/// packed, a collection deadline) are folded into `comment` rather than
/// dropped, which is what the bordereau form does with its own extras.
class FormulaireDemandeDeDevisRetraitAuxEncheresWidget extends StatefulWidget {
  const FormulaireDemandeDeDevisRetraitAuxEncheresWidget({super.key});

  static String routeName = 'Formulaire-demande-de-devis-retrait-aux-encheres';
  static String routePath = '/formulaireDemandeDeDevisRetraitAuxEncheres';

  @override
  State<FormulaireDemandeDeDevisRetraitAuxEncheresWidget> createState() =>
      _FormulaireDemandeDeDevisRetraitAuxEncheresWidgetState();
}

/// How the lot is presented for collection. `isProtected` on the quote is the
/// boolean the carrier-facing listing reads; the three-way distinction rides
/// along in the comment, where the ops team reads it.
enum _Packing { unpacked, protected, packed }

/// One unmet requirement, for the checklist that explains a disabled Submit.
enum _Gap {
  auctionHouse,
  pickupAddress,
  pickupPostalCode,
  pickupCity,
  pickupPosition,
  description,
  weight,
  declaredValue,
  dimensions,
  deliveryAddress,
  deliveryPostalCode,
  deliveryCity,
  deliveryPosition,
  recipientName,
  deliveryPhone,
}

class _FormulaireDemandeDeDevisRetraitAuxEncheresWidgetState
    extends State<FormulaireDemandeDeDevisRetraitAuxEncheresWidget> {
  final _formKey = GlobalKey<FormState>();

  /// Bumped by [Form.onChanged] and by either address block. Only the review
  /// panel and the buttons listen, so a keystroke does not rebuild two maps.
  final _revision = ValueNotifier<int>(0);

  // Pickup.
  final _auctionHouse = TextEditingController();
  final _pickup = DSAddressValue();

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
  final _delivery = DSAddressValue();
  final _recipientName = TextEditingController();
  final _deliveryPhone = TextEditingController();

  final _comment = TextEditingController();

  _Packing _packing = _Packing.unpacked;

  // Attachments.
  FFUploadedFile? _bordereauFile;

  /// Survives a draft restore, where the bytes cannot: the file is already in
  /// storage, so its name and URL are all that is needed.
  String _bordereauName = '';
  String _bordereauUrl = '';
  bool _uploadingBordereau = false;

  final _photoUrls = <String>[];
  bool _uploadingPhotos = false;

  /// Retired whenever the gallery is emptied, so a batch still uploading when
  /// the visitor taps "Tout retirer" cannot put its photos back afterwards.
  int _photoGeneration = 0;

  /// The express-card bordereau's upload while it is in flight. Submit awaits
  /// it, so saving early cannot silently drop the file.
  Future<void>? _draftBordereauUpload;

  bool _saving = false;
  bool _savingDraft = false;

  /// The draft found on this device, and whether the visitor has already dealt
  /// with it (restored it, deleted it, or written over it with a fresh save).
  QuoteFormDraft? _storedDraft;
  bool _draftHandled = false;

  @override
  void initState() {
    super.initState();

    for (final value in [_pickup, _delivery]) {
      value.addListener(_bumpRevision);
    }

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
    _delivery.restore(
      postalCode: delivery?.postcode ?? '',
      city: delivery?.city ?? '',
    );

    // The collection deadline has no field of its own — it belongs with the
    // other notes rather than being dropped.
    if ((draft?.deadline ?? '').isNotEmpty) {
      _comment.text = 'Deadline de retrait : ${draft!.deadline}';
    }

    _stageDraftBordereau(draft?.bordereau);
    _loadStoredDraft();
  }

  void _bumpRevision() => _revision.value++;

  Future<void> _loadStoredDraft() async {
    final stored = await QuoteFormDraft.load(currentUserUid);
    if (!mounted || stored == null) return;
    setState(() => _storedDraft = stored);
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
    _bordereauName = staged.name ?? '';

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
        final stillOurs = identical(_bordereauFile, staged);
        setState(() {
          _uploadingBordereau = false;
          // Only claim the slot if it is still the staged file: while this was
          // in flight the visitor may have picked their own bordereau (or
          // removed this one), and that choice wins.
          if (url != null && stillOurs) _bordereauUrl = url;
          // A failed upload leaves the file named on the button with no URL
          // behind it, which reads as "attached". Drop the name with it, and
          // say so — the same thing `_pickBordereau` does — rather than
          // letting the visitor submit believing the slip went with it.
          if (url == null && stillOurs) {
            _bordereauFile = null;
            _bordereauName = '';
          }
        });
        if (url == null && stillOurs) {
          _say(
            frText: "L'envoi du bordereau a échoué. Joignez-le à nouveau.",
            enText: 'Uploading the slip failed. Attach it again.',
          );
        }
      }
      uploadDone.complete();
    });
  }

  @override
  void dispose() {
    for (final value in [_pickup, _delivery]) {
      value.removeListener(_bumpRevision);
      value.dispose();
    }
    for (final c in [
      _auctionHouse,
      _description,
      _length,
      _width,
      _height,
      _weight,
      _declaredValue,
      _bordereauNumber,
      _recipientName,
      _deliveryPhone,
      _comment,
    ]) {
      c.dispose();
    }
    _revision.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Rules
  // ==========================================================================
  // One predicate per rule, read by both the field's validator (which says
  // what is wrong, under the field) and by [_gaps] (which says what is
  // missing, above the buttons). They cannot drift apart because there is only
  // one of each.

  static bool _isFilled(TextEditingController c) => c.text.trim().isNotEmpty;

  bool get _isAuctionHouseOk =>
      QuoteFormRules.isAuctionHouse(_auctionHouse.text);

  bool get _isDescriptionOk => QuoteFormRules.isDescription(_description.text);

  bool get _isWeightOk => QuoteFormRules.isWeight(_weight.text);

  bool get _isDeclaredValueOk =>
      QuoteFormRules.isDeclaredValue(_declaredValue.text);

  /// All three or none: `buildDescription` only prints dimensions when it has
  /// the full set, so two of them tell the carrier nothing.
  bool get _areDimensionsOk => QuoteFormRules.areDimensions(
        _length.text,
        _width.text,
        _height.text,
      );

  bool get _isRecipientOk => QuoteFormRules.isRecipient(_recipientName.text);

  bool get _isDeliveryPhoneOk => QuoteFormRules.isPhone(_deliveryPhone.text);

  /// Everything standing between this form and a submittable quote.
  List<_Gap> get _gaps => [
        if (!_isAuctionHouseOk) _Gap.auctionHouse,
        for (final gap in _pickup.gaps)
          switch (gap) {
            DSAddressGap.address => _Gap.pickupAddress,
            DSAddressGap.postalCode => _Gap.pickupPostalCode,
            DSAddressGap.city => _Gap.pickupCity,
            DSAddressGap.position => _Gap.pickupPosition,
          },
        if (!_isDescriptionOk) _Gap.description,
        if (!_isWeightOk) _Gap.weight,
        if (!_isDeclaredValueOk) _Gap.declaredValue,
        if (!_areDimensionsOk) _Gap.dimensions,
        for (final gap in _delivery.gaps)
          switch (gap) {
            DSAddressGap.address => _Gap.deliveryAddress,
            DSAddressGap.postalCode => _Gap.deliveryPostalCode,
            DSAddressGap.city => _Gap.deliveryCity,
            DSAddressGap.position => _Gap.deliveryPosition,
          },
        if (!_isRecipientOk) _Gap.recipientName,
        if (!_isDeliveryPhoneOk) _Gap.deliveryPhone,
      ];

  bool get _busy =>
      _saving || _savingDraft || _uploadingBordereau || _uploadingPhotos;

  bool get _canSubmit => !_busy && _gaps.isEmpty;

  /// A draft is worth saving as soon as anything at all has been typed.
  bool get _hasAnythingToSave =>
      !_pickup.isEmpty ||
      !_delivery.isEmpty ||
      _photoUrls.isNotEmpty ||
      _bordereauUrl.isNotEmpty ||
      [
        _auctionHouse,
        _description,
        _length,
        _width,
        _height,
        _weight,
        _declaredValue,
        _bordereauNumber,
        _recipientName,
        _deliveryPhone,
        _comment,
      ].any(_isFilled);

  String _gapLabel(_Gap gap) => switch (gap) {
        _Gap.auctionHouse => _t(fr: 'Maison de ventes', en: 'Auction house'),
        _Gap.pickupAddress =>
          _t(fr: 'Adresse de retrait', en: 'Collection address'),
        _Gap.pickupPostalCode => _t(
            fr: 'Code postal de retrait (5 chiffres)',
            en: 'Collection postcode (5 digits)',
          ),
        _Gap.pickupCity => _t(fr: 'Ville de retrait', en: 'Collection town'),
        _Gap.pickupPosition => _t(
            fr: 'Position de retrait à confirmer sur la carte',
            en: 'Collection position to confirm on the map',
          ),
        _Gap.description => _t(fr: 'Description du lot', en: 'Lot description'),
        _Gap.weight => _t(fr: 'Poids du lot', en: 'Lot weight'),
        _Gap.declaredValue => _t(fr: 'Valeur déclarée', en: 'Declared value'),
        _Gap.dimensions => _t(
            fr: 'Dimensions : les trois, ou aucune',
            en: 'Dimensions: all three, or none',
          ),
        _Gap.deliveryAddress =>
          _t(fr: 'Adresse de livraison', en: 'Delivery address'),
        _Gap.deliveryPostalCode => _t(
            fr: 'Code postal de livraison (5 chiffres)',
            en: 'Delivery postcode (5 digits)',
          ),
        _Gap.deliveryCity => _t(fr: 'Ville de livraison', en: 'Delivery town'),
        _Gap.deliveryPosition => _t(
            fr: 'Position de livraison à confirmer sur la carte',
            en: 'Delivery position to confirm on the map',
          ),
        _Gap.recipientName => _t(
            fr: 'Nom du destinataire trop court',
            en: "Recipient's name too short"),
        _Gap.deliveryPhone => _t(
            fr: 'Téléphone sur place invalide',
            en: 'Phone on site is not valid',
          ),
      };

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
      _bordereauName = local.name ?? '';
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

    final stillOurs = identical(_bordereauFile, local);
    setState(() {
      _uploadingBordereau = false;
      if (url != null && stillOurs) _bordereauUrl = url;
      // Otherwise the button keeps the file's name with no URL behind it,
      // which reads as attached — and `_snapshot` would persist that name
      // into the draft, so the lie survives a reload.
      if (url == null && stillOurs) {
        _bordereauFile = null;
        _bordereauName = '';
      }
    });

    if (url == null && stillOurs) {
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
    if (!mounted) return;
    if (!media.every((m) => validateFileFormat(m.storagePath, context))) return;

    final generation = _photoGeneration;
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
    final abandoned = generation != _photoGeneration;
    setState(() {
      _uploadingPhotos = false;
      if (!abandoned) _photoUrls.addAll(urls);
    });
    if (abandoned) return;

    if (urls.length != media.length && mounted) {
      _say(
        frText: "Certaines photos n'ont pas pu être envoyées.",
        enText: 'Some photos could not be uploaded.',
      );
    }
  }

  // ==========================================================================
  // Draft
  // ==========================================================================

  /// Every answer on the form, flat, for [QuoteFormDraft]. Files are kept as
  /// the URLs they already uploaded to, not as bytes.
  Map<String, dynamic> _snapshot() => {
        'auctionHouse': _auctionHouse.text,
        'pickupAddress': _pickup.address.text,
        'pickupPostalCode': _pickup.postalCode.text,
        'pickupCity': _pickup.city.text,
        'pickupLat': _pickup.point?.latitude,
        'pickupLng': _pickup.point?.longitude,
        'pickupAccepted': _pickup.status == DSAddressStatus.accepted,
        'description': _description.text,
        'length': _length.text,
        'width': _width.text,
        'height': _height.text,
        'weight': _weight.text,
        'declaredValue': _declaredValue.text,
        'packing': _packing.name,
        'bordereauNumber': _bordereauNumber.text,
        'bordereauPaid': _bordereauPaid,
        'bordereauUrl': _bordereauUrl,
        'bordereauName': _bordereauName,
        'photoUrls': _photoUrls,
        'deliveryAddress': _delivery.address.text,
        'deliveryPostalCode': _delivery.postalCode.text,
        'deliveryCity': _delivery.city.text,
        'deliveryLat': _delivery.point?.latitude,
        'deliveryLng': _delivery.point?.longitude,
        'deliveryAccepted': _delivery.status == DSAddressStatus.accepted,
        'recipientName': _recipientName.text,
        'deliveryPhone': _deliveryPhone.text,
        'comment': _comment.text,
      };

  Future<void> _saveDraft() async {
    setState(() => _savingDraft = true);
    final snapshot = _snapshot();
    final stored = await QuoteFormDraft.save(currentUserUid, snapshot);
    if (!mounted) return;

    setState(() {
      _savingDraft = false;
      if (stored) {
        _storedDraft =
            QuoteFormDraft(values: snapshot, savedAt: DateTime.now());
        _draftHandled = true;
      }
    });

    _say(
      frText: stored
          ? 'Brouillon enregistré sur cet appareil.'
          : "Ce navigateur n'autorise pas l'enregistrement local.",
      enText: stored
          ? 'Draft saved on this device.'
          : 'This browser will not allow a local save.',
    );
  }

  void _restoreDraft() {
    final draft = _storedDraft;
    if (draft == null) return;

    _auctionHouse.text = draft.text('auctionHouse');
    _pickup.restore(
      address: draft.text('pickupAddress'),
      postalCode: draft.text('pickupPostalCode'),
      city: draft.text('pickupCity'),
      lat: draft.number('pickupLat'),
      lng: draft.number('pickupLng'),
      accepted: draft.flag('pickupAccepted'),
    );
    _description.text = draft.text('description');
    _length.text = draft.text('length');
    _width.text = draft.text('width');
    _height.text = draft.text('height');
    _weight.text = draft.text('weight');
    _declaredValue.text = draft.text('declaredValue');
    _bordereauNumber.text = draft.text('bordereauNumber');
    _delivery.restore(
      address: draft.text('deliveryAddress'),
      postalCode: draft.text('deliveryPostalCode'),
      city: draft.text('deliveryCity'),
      lat: draft.number('deliveryLat'),
      lng: draft.number('deliveryLng'),
      accepted: draft.flag('deliveryAccepted'),
    );
    _recipientName.text = draft.text('recipientName');
    _deliveryPhone.text = draft.text('deliveryPhone');
    _comment.text = draft.text('comment');

    setState(() {
      _packing = _Packing.values.firstWhere(
        (packing) => packing.name == draft.text('packing'),
        orElse: () => _Packing.unpacked,
      );
      _bordereauPaid = draft.flag('bordereauPaid');
      // Dropped, so the express-card upload staged in `initState` cannot claim
      // the slot after this: it only writes `_bordereauUrl` while
      // `_bordereauFile` is still identically the file it staged.
      _bordereauFile = null;
      _bordereauUrl = draft.text('bordereauUrl');
      _bordereauName = draft.text('bordereauName');
      _photoGeneration++;
      _photoUrls
        ..clear()
        ..addAll(draft.strings('photoUrls'));
      _draftHandled = true;
    });
    _bumpRevision();

    _say(frText: 'Brouillon restauré.', enText: 'Draft restored.');
  }

  Future<void> _discardDraft() async {
    await QuoteFormDraft.clear(currentUserUid);
    if (!mounted) return;
    setState(() {
      _storedDraft = null;
      _draftHandled = true;
    });
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
    ].where((line) => line.isNotEmpty).join('\n');
  }

  Future<void> _save() async {
    // The button is disabled until this holds; the check stays because a
    // pending geocode can land between the tap and this line.
    if (!_canSubmit) {
      _formKey.currentState?.validate();
      _say(
        frText: 'Complétez les champs obligatoires.',
        enText: 'Fill in the required fields.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    // The express-card bordereau may still be in flight; wait for it so the
    // attachment is not dropped from the quote.
    await _draftBordereauUpload;

    final result = await QuoteRepository.create({
      'auctionHouseName': _auctionHouse.text.trim(),
      'pickupAddress': _pickup.address.text.trim(),
      'pickupPostalCode': _pickup.postalCode.text.trim(),
      'pickupCity': _pickup.city.text.trim(),
      'description': _description.text.trim(),
      'lengthCm': QuoteFormRules.number(_length.text),
      'widthCm': QuoteFormRules.number(_width.text),
      'heightCm': QuoteFormRules.number(_height.text),
      'weightKg': QuoteFormRules.number(_weight.text),
      // The column the carrier-facing listing reads ("Objet emballé." in
      // `buildDescription`); the three-way distinction stays in the comment.
      'isProtected': _packing != _Packing.unpacked,
      'declaredValueCents': QuoteFormRules.euroToCents(_declaredValue.text),
      'bordereauNumber': _bordereauNumber.text.trim(),
      'bordereauPaid': _bordereauPaid,
      if (_bordereauUrl.isNotEmpty) 'bordereauDocUrl': _bordereauUrl,
      if (_photoUrls.isNotEmpty) 'photoUrls': _photoUrls,
      'deliveryAddress': _delivery.address.text.trim(),
      'deliveryPostalCode': _delivery.postalCode.text.trim(),
      'deliveryCity': _delivery.city.text.trim(),
      'recipientName': _recipientName.text.trim(),
      'deliveryPhone': _deliveryPhone.text.trim(),
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

    // The quote is filed; the local copy has nothing left to protect. The
    // `anon` slot goes too: a draft saved before signing in stays there, and
    // it is shared with everyone else who uses this browser signed out.
    await QuoteFormDraft.clear(currentUserUid);
    if (currentUserUid.isNotEmpty) await QuoteFormDraft.clear('');
    if (!mounted) return;

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
                onChanged: _bumpRevision,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 40.0),
                  children: [
                    Text(
                      _t(
                        fr: 'Ces informations nous permettent de chiffrer le '
                            'retrait et la livraison de votre lot. Les champs '
                            'marqués * sont indispensables pour confier le lot '
                            'à un transporteur.',
                        en: 'These details let us price the collection and '
                            'delivery of your lot. The fields marked * are '
                            'what a carrier needs before the lot can be '
                            'handed over.',
                      ),
                      style:
                          theme.bodyMedium.override(color: theme.secondaryText),
                    ),
                    if (_storedDraft != null && !_draftHandled) ...[
                      const SizedBox(height: 16.0),
                      _draftBanner(theme),
                    ],
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
                    ValueListenableBuilder<int>(
                      valueListenable: _revision,
                      builder: (context, _, __) => _footer(theme),
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

  // --------------------------------------------------------------------------
  // Footer: what is left, then the two ways out of this page
  // --------------------------------------------------------------------------

  Widget _footer(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _reviewPanel(theme),
        const SizedBox(height: 16.0),
        LayoutBuilder(
          builder: (context, constraints) {
            final draftButton = DSButton(
              label: _t(
                fr: 'Enregistrer le brouillon',
                en: 'Save draft',
              ),
              icon: Icons.bookmark_border_rounded,
              variant: DSButtonVariant.outline,
              size: DSButtonSize.lg,
              expand: true,
              onPressed: _busy || !_hasAnythingToSave ? null : _saveDraft,
            );
            final submitButton = DSButton(
              label: _t(fr: 'Envoyer la demande', en: 'Send the request'),
              icon: Icons.send_rounded,
              size: DSButtonSize.lg,
              expand: true,
              onPressed: _canSubmit ? _save : null,
            );

            // Below ~420px two 48px buttons side by side truncate their
            // labels, so they stack, primary action first.
            if (constraints.maxWidth < 420.0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  submitButton,
                  const SizedBox(height: 12.0),
                  draftButton,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: draftButton),
                const SizedBox(width: 12.0),
                Expanded(flex: 2, child: submitButton),
              ],
            );
          },
        ),
        if (_storedDraft != null && _draftHandled) ...[
          const SizedBox(height: 10.0),
          Text(
            _t(
              fr: 'Brouillon enregistré ${_age(_storedDraft!.savedAt)} sur cet '
                  'appareil.',
              en: 'Draft saved ${_age(_storedDraft!.savedAt)} on this device.',
            ),
            textAlign: TextAlign.center,
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ],
      ],
    );
  }

  /// The checklist that makes a disabled Submit legible. Never a wall of red:
  /// it is a neutral list of what is still outstanding, and turns into a
  /// single green line the moment the form is complete.
  Widget _reviewPanel(FlutterFlowTheme theme) {
    final gaps = _gaps;

    if (gaps.isEmpty) {
      return DSCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 20.0, color: theme.success),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                _busy
                    ? _t(
                        fr: 'Envoi des pièces jointes en cours…',
                        en: 'Attachments still uploading…',
                      )
                    : _t(
                        fr: 'Tout y est. Vous pouvez envoyer votre demande.',
                        en: 'All set. You can send your request.',
                      ),
                style: theme.bodySmall.override(color: theme.primaryText),
              ),
            ),
          ],
        ),
      );
    }

    // A dozen bullets is a wall, not a list; the rest are counted instead.
    const shown = 6;
    final visible = gaps.take(shown).toList(growable: false);
    final hidden = gaps.length - visible.length;

    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded,
                  size: 20.0, color: theme.secondaryText),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  _t(
                    fr: 'Il reste ${gaps.length} élément(s) à compléter avant '
                        "l'envoi :",
                    en: '${gaps.length} thing(s) left before you can send:',
                  ),
                  style: theme.bodySmall.override(color: theme.primaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          for (final gap in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(Icons.radio_button_unchecked,
                        size: 12.0, color: theme.secondaryText),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      _gapLabel(gap),
                      style:
                          theme.labelSmall.override(color: theme.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
          if (hidden > 0)
            Text(
              _t(fr: '+ $hidden autre(s)', en: '+ $hidden more'),
              style: theme.labelSmall.override(color: theme.secondaryText),
            ),
        ],
      ),
    );
  }

  Widget _draftBanner(FlutterFlowTheme theme) {
    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 20.0, color: theme.primary),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  _t(
                    fr: 'Un brouillon de demande a été enregistré '
                        '${_age(_storedDraft!.savedAt)} sur cet appareil.',
                    en: 'A saved draft from ${_age(_storedDraft!.savedAt)} is '
                        'waiting on this device.',
                  ),
                  style: theme.bodySmall.override(color: theme.primaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: DSButton(
                  label: _t(fr: 'Reprendre', en: 'Restore'),
                  icon: Icons.restore_rounded,
                  size: DSButtonSize.sm,
                  expand: true,
                  onPressed: _restoreDraft,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: DSButton(
                  label: _t(fr: 'Supprimer', en: 'Delete'),
                  icon: Icons.delete_outline_rounded,
                  variant: DSButtonVariant.outline,
                  size: DSButtonSize.sm,
                  expand: true,
                  onPressed: _discardDraft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "il y a 2 h" without pulling a locale table in for four cases.
  String _age(DateTime when) {
    final elapsed = DateTime.now().difference(when);
    if (elapsed.inMinutes < 1) {
      return _t(fr: "à l'instant", en: 'just now');
    }
    if (elapsed.inMinutes < 60) {
      return _t(
        fr: 'il y a ${elapsed.inMinutes} min',
        en: '${elapsed.inMinutes} min ago',
      );
    }
    if (elapsed.inHours < 24) {
      return _t(
          fr: 'il y a ${elapsed.inHours} h', en: '${elapsed.inHours} h ago');
    }
    return _t(fr: 'il y a ${elapsed.inDays} j', en: '${elapsed.inDays} d ago');
  }

  // --------------------------------------------------------------------------
  // Sections
  // --------------------------------------------------------------------------

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
            validator: (value) {
              final missing = _required(value);
              if (missing != null) return missing;
              return _isAuctionHouseOk
                  ? null
                  : _t(fr: 'Nom trop court', en: 'Name is too short');
            },
          ),
          const SizedBox(height: 12.0),
          DSAddressPicker(
            value: _pickup,
            addressLabel:
                _t(fr: 'Adresse de retrait *', en: 'Collection address *'),
            postalCodeLabel: _t(fr: 'Code postal *', en: 'Postcode *'),
            cityLabel: _t(fr: 'Ville *', en: 'City *'),
            addressHint: '9 rue Drouot',
          ),
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
            validator: (value) {
              final missing = _required(value);
              if (missing != null) return missing;
              return _isDescriptionOk
                  ? null
                  : _t(
                      fr: 'Décrivez le lot en quelques mots',
                      en: 'Describe the lot in a few words',
                    );
            },
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dimensionField(
                  controller: _length,
                  label: _t(fr: 'Longueur (cm)', en: 'Length (cm)'),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _dimensionField(
                  controller: _width,
                  label: _t(fr: 'Largeur (cm)', en: 'Width (cm)'),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _dimensionField(
                  controller: _height,
                  label: _t(fr: 'Hauteur (cm)', en: 'Height (cm)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            _t(
              fr: 'Facultatif — mais renseignez les trois, ou aucune : le '
                  'transporteur ne peut rien faire de deux dimensions sur '
                  'trois.',
              en: 'Optional — but fill all three or none: two out of three '
                  'tells the carrier nothing.',
            ),
            style: theme.labelSmall.override(color: theme.secondaryText),
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
                  validator: (value) {
                    final missing = _required(value);
                    if (missing != null) return missing;
                    if (QuoteFormRules.number(value!) == null) {
                      return _t(fr: 'Poids invalide', en: 'Invalid weight');
                    }
                    return _isWeightOk
                        ? null
                        : _t(
                            fr: 'Entre 0 et ${QuoteFormRules.maxWeightKg.toInt()} kg',
                            en: 'Between 0 and ${QuoteFormRules.maxWeightKg.toInt()} kg',
                          );
                  },
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
                    final cents = QuoteFormRules.euroToCents(value!);
                    if (cents == null) {
                      return _t(fr: 'Montant invalide', en: 'Invalid amount');
                    }
                    if (cents <= 0) {
                      return _t(
                        fr: 'Indiquez la valeur du lot',
                        en: "Enter the lot's value",
                      );
                    }
                    return cents <= QuoteFormRules.maxDeclaredValueCents
                        ? null
                        : _t(
                            fr: 'Au-delà de 5 M€, contactez-nous directement',
                            en: 'Above €5M, contact us directly',
                          );
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

  Widget _dimensionField({
    required TextEditingController controller,
    required String label,
  }) {
    return DSTextField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      mono: true,
      validator: (value) {
        // Empty is fine on its own — it is only wrong next to a filled sibling.
        if ((value ?? '').trim().isEmpty) {
          return _areDimensionsOk
              ? null
              : _t(fr: 'Les trois, ou aucune', en: 'All three, or none');
        }
        final parsed = QuoteFormRules.number(value!);
        if (parsed == null || parsed <= 0) {
          return _t(fr: 'Dimension invalide', en: 'Invalid dimension');
        }
        return parsed <= QuoteFormRules.maxDimensionCm
            ? null
            : _t(
                fr: 'Maximum ${QuoteFormRules.maxDimensionCm.toInt()} cm',
                en: 'At most ${QuoteFormRules.maxDimensionCm.toInt()} cm',
              );
      },
    );
  }

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
        const SizedBox(height: 6.0),
        Text(
          _t(
            fr: 'Facultatif. Une photo par angle encombrant évite un devis '
                'révisé sur place.',
            en: 'Optional. A photo of each awkward angle saves a revised '
                'quote on the doorstep.',
          ),
          style: theme.labelSmall.override(color: theme.secondaryText),
        ),
        if (_photoUrls.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _photoGeneration++;
                _photoUrls.clear();
              }),
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
            maxLength: QuoteFormRules.maxSlipNumberChars,
          ),
          const SizedBox(height: 12.0),
          DSButton(
            label: _bordereauName.isEmpty
                ? _t(fr: 'Joindre le bordereau', en: 'Attach the slip')
                : _bordereauName,
            icon: _bordereauName.isEmpty
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
          DSAddressPicker(
            value: _delivery,
            addressLabel:
                _t(fr: 'Adresse de livraison *', en: 'Delivery address *'),
            postalCodeLabel: _t(fr: 'Code postal *', en: 'Postcode *'),
            cityLabel: _t(fr: 'Ville *', en: 'City *'),
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DSTextField(
                  controller: _recipientName,
                  label: _t(fr: 'Nom du destinataire', en: "Recipient's name"),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return null;
                    return _isRecipientOk
                        ? null
                        : _t(fr: 'Nom trop court', en: 'Name is too short');
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: DSTextField(
                  controller: _deliveryPhone,
                  label: _t(fr: 'Téléphone sur place', en: 'Phone on site'),
                  hintText: '06 12 34 56 78',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ .\-]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  mono: true,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return null;
                    return _isDeliveryPhoneOk
                        ? null
                        : _t(
                            fr: 'Numéro français attendu (06…, +33…)',
                            en: 'A French number is expected (06…, +33…)',
                          );
                  },
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
            maxLength: QuoteFormRules.maxCommentChars,
            helperText: _t(
              fr: 'Facultatif · ${QuoteFormRules.maxCommentChars} caractères maximum',
              en: 'Optional · ${QuoteFormRules.maxCommentChars} characters max',
            ),
          ),
        ],
      );
}
