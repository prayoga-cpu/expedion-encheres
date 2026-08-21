import 'dart:async';

import 'package:flutter/foundation.dart';

import 'expedion_api.dart';

/// One line in the support thread.
///
/// Deliberately thinner than the row the database holds: the client draws a
/// bubble and a timestamp, so a message carries no conversation id, no sender
/// id and no participant record. [senderName] is the operator's, and is null
/// for the visitor's own messages — the bubble is already on their side.
@immutable
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isOwn,
    this.readByOther = false,
    this.senderName,
    this.senderImage,
    this.status = SupportMessageStatus.sent,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
        isOwn: json['isOwn'] == true,
        readByOther: json['readByOther'] == true,
        senderName: json['senderName']?.toString(),
        senderImage: json['senderImage']?.toString(),
      );

  final String id;
  final String content;
  final DateTime createdAt;
  final bool isOwn;
  final bool readByOther;
  final String? senderName;
  final String? senderImage;
  final SupportMessageStatus status;

  SupportMessage copyWith({SupportMessageStatus? status}) => SupportMessage(
        id: id,
        content: content,
        createdAt: createdAt,
        isOwn: isOwn,
        readByOther: readByOther,
        senderName: senderName,
        senderImage: senderImage,
        status: status ?? this.status,
      );
}

/// Where a message the visitor typed has got to.
///
/// [sending] and [failed] only ever apply to a bubble this client invented:
/// anything the server returned is [sent] by definition.
enum SupportMessageStatus { sending, sent, failed }

/// Drives the support chat: loads the thread, polls it, and posts into it.
///
/// Polling rather than Ably, which is what the website uses. Adding a realtime
/// SDK, its token endpoint and its own reconnect story to the Flutter app buys
/// a few seconds on a screen a visitor opens to ask one question — and every
/// poll here is a single indexed read. If support chat ever becomes a place
/// people sit, this is the seam to replace.
class SupportChatController extends ChangeNotifier {
  SupportChatController();

  /// Long enough not to hammer the API from an idle tab, short enough that a
  /// reply lands while the visitor is still looking at the screen.
  static const Duration pollInterval = Duration(seconds: 8);

  final List<SupportMessage> _messages = <SupportMessage>[];
  Timer? _poll;
  bool _disposed = false;

  bool _loading = true;
  bool _sending = false;
  String? _errorCode;
  String? _conversationId;

  List<SupportMessage> get messages => List.unmodifiable(_messages);

  /// True only for the first load, so a poll that fails behind a thread the
  /// visitor is already reading does not replace it with a spinner.
  bool get isLoading => _loading;
  bool get isSending => _sending;

  /// Set when the *visible* state is a failure: the first load could not
  /// complete, or a send was refused. A failed background poll leaves this
  /// null — the thread on screen is still the thread.
  String? get errorCode => _errorCode;

  String? get conversationId => _conversationId;

  /// Whether anybody can chat at all. False when nobody is signed in, in which
  /// case the UI offers sign-in instead of a composer.
  bool get isAvailable => ExpedionApi.isConfigured;

  /// First load, then start polling. Safe to call more than once.
  Future<void> start() async {
    await refresh(showSpinner: true);
    // No timer for a signed-out visitor: every tick would return at the
    // `isAvailable` guard, forever, behind a panel offering them sign-in.
    if (_disposed || !isAvailable) return;
    _poll ??= Timer.periodic(pollInterval, (_) => refresh());
  }

  /// Re-reads the thread.
  ///
  /// [showSpinner] is for the first load only; a poll must not blank the
  /// screen, and must not surface its own failure as an error state — a
  /// dropped request between two successful ones is not something to tell the
  /// visitor about.
  Future<void> refresh({bool showSpinner = false}) async {
    if (_disposed) return;
    if (!isAvailable) {
      _loading = false;
      _notify();
      return;
    }
    if (showSpinner) {
      _loading = true;
      _errorCode = null;
      _notify();
    }

    final result = await ExpedionApi.supportThread();
    if (_disposed) return;

    if (!result.success) {
      _loading = false;
      // Only a load the visitor is waiting on gets to report a failure.
      if (showSpinner) _errorCode = result.code ?? 'NETWORK_ERROR';
      _notify();
      return;
    }

    _conversationId = result.map['conversationId']?.toString();
    final incoming = (result.map['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SupportMessage.fromJson)
        .toList();

    // Anything still in flight, or that failed to send, is the client's own
    // and has no server row to be replaced by — keep it pinned to the end so
    // a poll landing mid-send does not make the visitor's message vanish.
    final pending = _messages
        .where((m) => m.status != SupportMessageStatus.sent)
        .toList(growable: false);

    _messages
      ..clear()
      ..addAll(incoming)
      ..addAll(pending);

    _loading = false;
    _errorCode = null;
    _notify();
  }

  /// Posts [text] and returns whether the server took it.
  ///
  /// The bubble appears immediately and is reconciled against the reload that
  /// follows; a refusal leaves it on screen marked [SupportMessageStatus.failed]
  /// rather than deleting what the visitor typed.
  Future<bool> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || _sending || !isAvailable) return false;

    final draft = SupportMessage(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      createdAt: DateTime.now(),
      isOwn: true,
      status: SupportMessageStatus.sending,
    );

    _sending = true;
    _errorCode = null;
    _messages.add(draft);
    _notify();

    final result = await ExpedionApi.sendSupportMessage(content);
    if (_disposed) return result.success;

    _sending = false;

    if (!result.success) {
      final index = _messages.indexWhere((m) => m.id == draft.id);
      if (index != -1) {
        _messages[index] = draft.copyWith(status: SupportMessageStatus.failed);
      }
      _errorCode = result.code ?? 'NETWORK_ERROR';
      _notify();
      return false;
    }

    // Drop the optimistic bubble and take the server's copy, so the timestamp
    // and id on screen are the ones the operator will see.
    _messages.removeWhere((m) => m.id == draft.id);
    final message = result.map['message'];
    if (message is Map<String, dynamic>) {
      _messages.add(SupportMessage.fromJson(message));
    }
    _conversationId =
        result.map['conversationId']?.toString() ?? _conversationId;
    _notify();

    // Picks up anything the operator wrote while this was in flight.
    unawaited(refresh());
    return true;
  }

  /// Clears the failed bubble for [id] so the visitor can retype or dismiss it.
  void discard(String id) {
    _messages.removeWhere(
      (m) => m.id == id && m.status == SupportMessageStatus.failed,
    );
    // The error belonged to that bubble. Left set, dismissing the only message
    // in a brand-new thread would swap a working chat for the "chat
    // unavailable" panel, which is the one state that is not true.
    _errorCode = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _poll = null;
    super.dispose();
  }
}
