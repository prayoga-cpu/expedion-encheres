/// Where an attached bordereau or lot photo goes.
///
/// It is not Firebase Storage any more, despite the folder this file still
/// sits in — the path is kept so the six generated call sites that import
/// `/backend/firebase_storage/storage.dart` do not all have to move at once.
///
/// ## Why this moved
///
/// [uploadData] used to `putData` into `users/$currentUserUid/uploads/…`,
/// which the deployed Storage rule guards with:
///
/// ```
/// allow write: if request.auth != null && request.auth.uid == userId;
/// ```
///
/// `request.auth` is a *Firebase* session. The app authenticates through
/// Better Auth now, and a Better Auth user has no Firebase session at all —
/// so `request.auth` was null and **every upload by an account created since
/// the migration was denied**. The bordereau form hard-gates its submit button
/// on a non-empty URL (`_canSubmit`), so the primary quote-creation flow was
/// simply unusable for those accounts; the retrait form dropped the document
/// and filed the quote without it.
///
/// The fix is not a different Storage rule — there is no Firebase identity
/// left to write a rule about. The bytes go to Expeditoo's ship instead, over
/// the same credential every other call in this app already carries, and land
/// in a private R2 bucket that is only ever read back through
/// `/api/expedion/files/<id>` by the file's owner or an admin. That last part
/// matters: a bordereau names the buyer, their address and phone, the lot and
/// what they paid for it. The Firebase download URLs this replaces are public
/// to anyone holding the string, and that is the exposure this deliberately
/// does not recreate.
///
/// Rows already holding a `firebasestorage.googleapis.com` URL keep working
/// untouched — those links carry a download token the Storage service checks
/// itself, independently of Security Rules — so nothing has to be migrated
/// before this ships.
library;

import 'dart:convert';
import 'dart:typed_data';

import '/backend/bordereau_check.dart'
    show bordereauMimeType, kBordereauMaxBytes;
import '/backend/expedion_api/expedion_api.dart';

/// What one upload came back with.
///
/// [uploadData]'s `String?` cannot say *why* an upload failed, and "why" is
/// most of the value: a 3 MB ceiling and a rejected file format are both things
/// the person who picked the file can act on, while "l'envoi a échoué" is not.
/// Screens that can show a message read this; the generated call sites that
/// only want a URL keep using [uploadData].
class UploadOutcome {
  const UploadOutcome._({this.url, this.code});

  const UploadOutcome.success(String url) : this._(url: url);

  const UploadOutcome.failure(String code) : this._(code: code);

  /// The permanent ship URL to persist into `bordereauDocUrl` / `photoUrls`.
  /// Null when the upload was refused.
  ///
  /// Safe to keep for weeks — it is a stable route on the ship, not a
  /// presigned link — which is what lets the retrait form park it in its
  /// 30-day `QuoteFormDraft`.
  final String? url;

  /// The failure's API code, for `xpdApiErrorMessage` to turn into copy in the
  /// reader's language. Null on success.
  final String? code;

  bool get succeeded => url != null;
}

/// Sends [data] to the ship and returns the URL it was stored under.
///
/// [path] is only read for its basename: the extension feeds the MIME sniff's
/// fallback and the filename travels along for diagnostics. It no longer
/// decides *where* the bytes go — the server derives the object key from the
/// authenticated caller, so the client has nothing left to assert about whose
/// folder this is.
///
/// [kind] is `'bordereau'` for a slip and `'photo'` for a lot picture. It
/// defaults to the stricter of the two on purpose: a mislabelled photo is
/// merely stored more privately than it needed to be, whereas a mislabelled
/// bordereau would be the leak all over again.
///
/// The size and format checks below are the client half of a pair — the server
/// enforces both again — and exist so a 20 MB scan is refused before it is
/// base64-encoded and pushed over the network to be refused there.
Future<UploadOutcome> uploadToShip(
  String path,
  Uint8List data, {
  String kind = 'bordereau',
}) async {
  if (data.isEmpty) return const UploadOutcome.failure('INVALID_FILE');
  if (data.length > kBordereauMaxBytes) {
    return const UploadOutcome.failure('FILE_TOO_LARGE');
  }

  final filename = path.split('/').last;
  // Magic bytes first, extension only as a fallback — the same reading
  // `BordereauCheck` does, so a slip the check accepted cannot be one the
  // upload turns around and calls unsupported.
  final mimeType = bordereauMimeType(data, filename);
  if (mimeType == null) {
    return const UploadOutcome.failure('UNSUPPORTED_MEDIA_TYPE');
  }

  final result = await ExpedionApi.uploadFile(
    data: base64Encode(data),
    mimeType: mimeType,
    filename: filename.isEmpty ? null : filename,
    kind: kind,
  );

  if (!result.success) {
    return UploadOutcome.failure(result.code ?? 'UPLOAD_FAILED');
  }

  // A 200 without a URL is the server failing in a shape we have no reading of.
  // Treating it as success would hand an empty string to the submit payload,
  // which is the silent failure this whole change exists to remove.
  final url = result.map['url'];
  if (url is! String || url.isEmpty) {
    return const UploadOutcome.failure('UPLOAD_FAILED');
  }
  return UploadOutcome.success(url);
}

/// The `String?` shape the generated call sites were written against: the URL
/// on success, null on any refusal.
///
/// Prefer [uploadToShip] anywhere the outcome can be explained to the person
/// who picked the file.
Future<String?> uploadData(
  String path,
  Uint8List data, {
  String kind = 'bordereau',
}) async =>
    (await uploadToShip(path, data, kind: kind)).url;
