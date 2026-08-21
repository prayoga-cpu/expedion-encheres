import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/expedion_api/support_chat.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_button.dart';
import 'ds_empty_state.dart';
import 'ds_l10n.dart';
import 'ds_loader.dart';
import 'ds_tokens.dart';

/// Live support chat, in place of the contact form.
///
/// The form it replaces posted into Airtable: the visitor got a button that
/// dimmed and no answer, and an operator who wanted to reply had to leave the
/// product and open a mailbox. This writes into the same conversation the
/// Expeditoo admin panel already lists under **Support Chats**, so a question
/// asked here is answered from the same inbox as every other one — and the
/// answer arrives back on this screen.
///
/// Everything about *how* that works lives in [SupportChatController]; this
/// draws four states — signed out, loading, failed, and the thread itself.
class DSSupportChat extends StatefulWidget {
  const DSSupportChat({
    super.key,
    required this.onSignIn,
    this.maxHeight = 420.0,
  });

  /// Where the signed-out state sends the visitor. Passed in rather than
  /// routed from here so `lib/design_system` keeps no opinion about the app's
  /// router.
  final VoidCallback onSignIn;

  /// The thread scrolls inside the card instead of growing the page, so the
  /// composer stays reachable however long the history gets.
  final double maxHeight;

  @override
  State<DSSupportChat> createState() => _DSSupportChatState();
}

class _DSSupportChatState extends State<DSSupportChat> {
  final SupportChatController _chat = SupportChatController();
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _chat.addListener(_onChatChanged);
    _chat.start();
  }

  @override
  void dispose() {
    _chat.removeListener(_onChatChanged);
    _chat.dispose();
    _composer.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    if (!mounted) return;
    setState(() {});

    // Only follow the thread when it actually grew. Scrolling on every
    // notification would yank the view back down while somebody is reading
    // their way up through the history.
    if (_chat.messages.length > _lastCount) {
      _lastCount = _chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } else {
      _lastCount = _chat.messages.length;
    }
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: DSMotion.duration,
      curve: DSMotion.curve,
    );
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    // Cleared before the round trip: the message is already on screen as an
    // optimistic bubble, and leaving it in the box invites a double send.
    _composer.clear();
    final sent = await _chat.send(text);
    if (!mounted) return;
    if (!sent) {
      // Give it back, so a refusal does not cost the visitor what they wrote.
      _composer.text = text;
    }
    _composerFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(DSShape.card),
        border: Border.all(
          color: theme.alternate,
          width: DSShape.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (!_chat.isAvailable) return _signedOut(context);
    if (_chat.isLoading) {
      return DSPageLoader(
        minHeight: 240.0,
        size: DSLoaderSize.sm,
        message: xpdT(context, 'Ouverture du chat…', 'Opening chat…'),
      );
    }
    if (_chat.messages.isEmpty && _chat.errorCode != null) {
      return _failed(context, _chat.errorCode);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: _chat.messages.isEmpty
              ? _emptyThread(context)
              : _thread(context),
        ),
        _composerRow(context),
      ],
    );
  }

  // --------------------------------------------------------------------
  // States
  // --------------------------------------------------------------------

  Widget _signedOut(BuildContext context) => DSEmptyState(
        icon: Icons.headset_mic_outlined,
        title: xpdT(context, 'Connectez-vous pour discuter',
            'Sign in to start a chat'),
        description: xpdT(
          context,
          "Le chat est rattaché à votre compte, pour que l'équipe retrouve vos "
              'devis et vous réponde ici même.',
          'The chat is tied to your account, so the team can find your quotes '
              'and answer you right here.',
        ),
        action: DSButton(
          label: xpdT(context, 'Se connecter', 'Sign in'),
          icon: Icons.login_rounded,
          onPressed: widget.onSignIn,
        ),
      );

  Widget _failed(BuildContext context, String? code) => DSEmptyState(
        icon: Icons.wifi_off_rounded,
        title: xpdT(context, 'Chat indisponible', 'Chat unavailable'),
        description: xpdApiErrorMessage(
          context,
          code,
          fallbackFr: "Le chat n'a pas pu être ouvert.",
          fallbackEn: 'The chat could not be opened.',
        ),
        action: DSButton(
          label: xpdT(context, 'Réessayer', 'Try again'),
          icon: Icons.refresh_rounded,
          variant: DSButtonVariant.outline,
          onPressed: () => _chat.refresh(showSpinner: true),
        ),
      );

  Widget _emptyThread(BuildContext context) => DSEmptyState(
        icon: Icons.forum_outlined,
        title: xpdT(context, 'Posez votre question', 'Ask us anything'),
        description: xpdT(
          context,
          "L'équipe Expeditoo répond ici, du lundi au vendredi.",
          'The Expeditoo team answers here, Monday to Friday.',
        ),
      );

  // --------------------------------------------------------------------
  // Thread
  // --------------------------------------------------------------------

  Widget _header(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.alternate.withValues(alpha: 0.5),
            width: DSShape.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: theme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              xpdT(context, 'Support Expeditoo', 'Expeditoo support'),
              style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            xpdT(context, 'Réponse sous 24 h', 'Replies within 24 h'),
            style: theme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _thread(BuildContext context) {
    final messages = _chat.messages;
    return ListView.separated(
      controller: _scroll,
      shrinkWrap: true,
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) => _Bubble(
        message: messages[index],
        onDiscard: () => _chat.discard(messages[index].id),
      ),
    );
  }

  Widget _composerRow(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canSend = !_chat.isSending;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(
          top: BorderSide(
            color: theme.alternate.withValues(alpha: 0.5),
            width: DSShape.borderWidth,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Focus(
              // Enter sends, Shift+Enter breaks the line — what every chat
              // does, and the reason the field is multiline rather than a
              // one-line input with a submit action.
              onKeyEvent: (node, event) {
                final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter;
                if (event is! KeyDownEvent || !isEnter) {
                  return KeyEventResult.ignored;
                }
                if (HardwareKeyboard.instance.isShiftPressed) {
                  return KeyEventResult.ignored;
                }
                _send();
                return KeyEventResult.handled;
              },
              child: TextField(
                controller: _composer,
                focusNode: _composerFocus,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: theme.bodyMedium,
                cursorColor: theme.primary,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  hintText: xpdT(
                    context,
                    'Écrivez votre message…',
                    'Write your message…',
                  ),
                  hintStyle: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  border: _composerBorder(theme.alternate),
                  enabledBorder: _composerBorder(theme.alternate),
                  focusedBorder: _composerBorder(theme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          DSButton(
            label: xpdT(context, 'Envoyer', 'Send'),
            icon: Icons.send_rounded,
            size: DSButtonSize.sm,
            onPressed: canSend ? _send : null,
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _composerBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(DSShape.control),
        borderSide: BorderSide(color: color, width: DSShape.borderWidth),
      );
}

/// One message. The visitor's own sit right and carry the brand colour; the
/// operator's sit left on the muted surface, named so it is clear a person
/// answered rather than the form having echoed.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onDiscard});

  final SupportMessage message;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final own = message.isOwn;
    final failed = message.status == SupportMessageStatus.failed;
    final sending = message.status == SupportMessageStatus.sending;

    final background = failed
        ? theme.error.withValues(alpha: 0.10)
        : own
            ? theme.primary
            : theme.primaryBackground;
    final foreground = failed
        ? theme.error
        : own
            ? Colors.white
            : theme.primaryText;

    return Row(
      mainAxisAlignment: own ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment:
                own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!own && (message.senderName?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, left: 4.0),
                  child: Text(message.senderName!, style: theme.labelSmall),
                ),
              Container(
                constraints: const BoxConstraints(maxWidth: 460.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(DSShape.card),
                    topRight: const Radius.circular(DSShape.card),
                    bottomLeft: Radius.circular(own ? DSShape.card : 4.0),
                    bottomRight: Radius.circular(own ? 4.0 : DSShape.card),
                  ),
                  border: own && !failed
                      ? null
                      : Border.all(
                          color: failed
                              ? theme.error.withValues(alpha: 0.20)
                              : theme.alternate,
                          width: DSShape.borderWidth,
                        ),
                ),
                child: Text(
                  message.content,
                  style: theme.bodyMedium.copyWith(color: foreground),
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    failed
                        ? xpdT(context, 'Non envoyé', 'Not sent')
                        : sending
                            ? xpdT(context, 'Envoi…', 'Sending…')
                            : _clock(context, message.createdAt),
                    style: theme.labelSmall.copyWith(
                      color: failed ? theme.error : theme.secondaryText,
                    ),
                  ),
                  if (failed) ...[
                    const SizedBox(width: 8.0),
                    DSButton(
                      label: xpdT(context, 'Retirer', 'Dismiss'),
                      variant: DSButtonVariant.link,
                      size: DSButtonSize.sm,
                      onPressed: onDiscard,
                    ),
                  ] else if (own && message.readByOther) ...[
                    const SizedBox(width: 6.0),
                    Icon(Icons.done_all_rounded,
                        size: 14.0, color: theme.primary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `HH:mm` today, `dd/MM HH:mm` before that — enough to place a reply
  /// without pulling in a date-formatting dependency for one line.
  String _clock(BuildContext context, DateTime at) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(at.hour)}:${two(at.minute)}';
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return sameDay ? time : '${two(at.day)}/${two(at.month)} $time';
  }
}
