import 'package:flutter/foundation.dart';

import 'expedion_api.dart';

/// Longest first or last name Expeditoo accepts (`NAME_PART_MAX` in
/// expeditoo-ship `src/lib/person-name.ts`).
const int kNamePartMax = 80;

/// The country a blank country field means. Expedion only moves lots within
/// France, and the server validates phones as French numbers.
const String kDefaultCountry = 'France';

/// A postal address as `/api/expedion/me/profile` reads and writes it.
@immutable
class ExpedionAddress {
  const ExpedionAddress({
    required this.line1,
    this.line2,
    required this.zip,
    required this.city,
    required this.country,
  });

  factory ExpedionAddress.fromJson(Map<String, dynamic> json) =>
      ExpedionAddress(
        line1: json['line1']?.toString() ?? '',
        line2: _blankToNull(json['line2']?.toString()),
        zip: json['zip']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
      );

  /// Reads an address out of form fields.
  ///
  /// Null unless the street, postcode and city are all filled in, because the
  /// server refuses an address missing any of them. A blank country becomes
  /// [kDefaultCountry].
  static ExpedionAddress? fromForm({
    required String line1,
    String line2 = '',
    required String zip,
    required String city,
    String country = '',
  }) {
    if (line1.trim().isEmpty || zip.trim().isEmpty || city.trim().isEmpty) {
      return null;
    }
    return ExpedionAddress(
      line1: line1.trim(),
      line2: _blankToNull(line2),
      zip: zip.trim(),
      city: city.trim(),
      country: country.trim().isEmpty ? kDefaultCountry : country.trim(),
    );
  }

  /// Whether the visitor typed nothing at all into the address fields. The
  /// country is left out: the edit form prefills it.
  static bool isBlankForm({
    required String line1,
    String line2 = '',
    required String zip,
    required String city,
  }) =>
      [line1, line2, zip, city].every((part) => part.trim().isEmpty);

  final String line1;
  final String? line2;
  final String zip;
  final String city;
  final String country;

  /// "12 rue X, Bât B, 75011 Paris".
  String get oneLine => [
        line1,
        line2 ?? '',
        '$zip $city'.trim(),
      ].where((part) => part.trim().isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {
        'line1': line1,
        'line2': line2 ?? '',
        'zip': zip,
        'city': city,
        'country': country,
      };
}

/// The signed-in client's contact details on Expeditoo.
@immutable
class ExpedionProfile {
  const ExpedionProfile({
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
  });

  factory ExpedionProfile.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    return ExpedionProfile(
      email: json['email']?.toString() ?? '',
      firstName: _blankToNull(json['firstName']?.toString()),
      lastName: _blankToNull(json['lastName']?.toString()),
      phone: _blankToNull(json['phone']?.toString()),
      address: address is Map
          ? ExpedionAddress.fromJson(address.cast<String, dynamic>())
          : null,
    );
  }

  final String email;
  final String? firstName;
  final String? lastName;

  /// E.164, e.g. `+33612345678`. See [formatFrenchPhone] for display.
  final String? phone;
  final ExpedionAddress? address;

  /// Last name first, the order the personal space has always used. Null when
  /// neither part is set.
  String? get displayName {
    final parts = [lastName, firstName].whereType<String>();
    return parts.isEmpty ? null : parts.join(' ');
  }
}

/// A change to the profile. Only the non-null fields are sent, and the server
/// leaves everything it is not sent as it was.
@immutable
class ExpedionProfileUpdate {
  const ExpedionProfileUpdate({
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
  });

  factory ExpedionProfileUpdate.fromJson(Map<String, dynamic> json) {
    String? read(String key) =>
        json[key] is String ? json[key] as String : null;
    final address = json['address'];
    return ExpedionProfileUpdate(
      firstName: read('firstName'),
      lastName: read('lastName'),
      phone: read('phone'),
      address: address is Map
          ? ExpedionAddress.fromJson(address.cast<String, dynamic>())
          : null,
    );
  }

  final String? firstName;
  final String? lastName;

  /// National or E.164; an empty string clears the stored number.
  final String? phone;
  final ExpedionAddress? address;

  bool get isEmpty => toJson().isEmpty;

  Map<String, dynamic> toJson() => {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address!.toJson(),
      };

  /// The same update with the named top-level fields dropped.
  ExpedionProfileUpdate without(Set<String> fields) => ExpedionProfileUpdate(
        firstName: fields.contains('firstName') ? null : firstName,
        lastName: fields.contains('lastName') ? null : lastName,
        phone: fields.contains('phone') ? null : phone,
        address: fields.contains('address') ? null : address,
      );
}

/// A first or last name as typed, or null when there is nothing the server
/// would accept: blank, or longer than [kNamePartMax].
String? namePartOrNull(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty || trimmed.length > kNamePartMax ? null : trimmed;
}

/// `+33612345678` → `06 12 34 56 78`. Anything else is returned unchanged.
String formatFrenchPhone(String phone) {
  final match = RegExp(r'^\+33(\d{9})$').firstMatch(phone.trim());
  if (match == null) return phone;
  final digits = '0${match.group(1)}';
  return [
    for (var i = 0; i < digits.length; i += 2) digits.substring(i, i + 2),
  ].join(' ');
}

String? _blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();

/// The outcome of reading or saving the profile.
@immutable
class ProfileResult {
  const ProfileResult._({
    this.profile,
    this.statusCode = 0,
    this.code,
    this.message,
    this.details = const {},
  });

  final ExpedionProfile? profile;

  /// HTTP status, or 0 when no response arrived.
  final int statusCode;
  final String? code;
  final String? message;

  /// Per-field reasons from a `VALIDATION_ERROR`, flattened to text.
  final Map<String, String> details;

  bool get succeeded => profile != null;

  /// A Firebase-era session: signed in, but with no Expeditoo account behind
  /// it, so there is no profile to read or write.
  bool get needsAccount => code == 'PROFILE_NEEDS_ACCOUNT';

  bool get isValidationError => code == 'VALIDATION_ERROR';

  /// No session, or one the server no longer accepts.
  bool get isUnauthenticated =>
      statusCode == 401 || code == 'UNAUTHENTICATED';

  /// The top-level fields [details] names; `address.zip` counts as `address`.
  Set<String> get invalidFields =>
      {for (final key in details.keys) key.split('.').first};

  factory ProfileResult.fromApi(ExpedionApiResult result) {
    if (result.success) {
      return ProfileResult._(profile: ExpedionProfile.fromJson(result.map));
    }
    return ProfileResult._(
      statusCode: result.statusCode,
      code: result.code,
      message: result.message,
      details: _flattenDetails(result.details),
    );
  }

  static Map<String, String> _flattenDetails(Map<String, dynamic>? raw) {
    if (raw == null) return const {};
    final fields = raw['fieldErrors'] is Map
        ? (raw['fieldErrors'] as Map).cast<String, dynamic>()
        : raw;
    final flat = <String, String>{};
    fields.forEach((key, value) {
      final text = switch (value) {
        String s => s,
        List l => l.whereType<String>().join(' '),
        _ => '',
      };
      flat[key] = text;
    });
    return flat;
  }
}

/// Where screens read and save the client's profile.
class ProfileRepository {
  const ProfileRepository._();

  static Future<ProfileResult> load() async =>
      ProfileResult.fromApi(await ExpedionApi.getProfile());

  static Future<ProfileResult> save(ExpedionProfileUpdate update) async =>
      ProfileResult.fromApi(await ExpedionApi.updateProfile(update.toJson()));
}
