import 'dart:math' as math;

import '/app_settings/app_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/utils/download_text_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_page_model.dart';
export 'chat_page_model.dart';

class ChatPageWidget extends StatefulWidget {
  const ChatPageWidget({
    super.key,
    this.chatid,
  });

  final DocumentReference? chatid;

  static String routeName = 'ChatPage';
  static String routePath = '/chatPage';

  @override
  State<ChatPageWidget> createState() => _ChatPageWidgetState();
}

class _ChatPageWidgetState extends State<ChatPageWidget> {
  static const _maxContinuationRounds = 3;
  static const _minDrawerWidth = 304.0;
  static const _continuationPrompt =
      'Continue exactly from where you stopped. Do not restart, summarize, or repeat prior text. Resume the answer directly from the cutoff point.';
  late ChatPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _messagesScrollController = ScrollController();
  final TextEditingController _chatSearchController = TextEditingController();
  DocumentReference? _activeChatRef;
  bool _isSending = false;
  int _lastMessageCount = 0;
  String _chatSearchQuery = '';
  bool _showArchived = false;
  String _customInstructions = '';
  String _responseStyle = 'Balanced';
  List<String> _savedPrompts =
      List<String>.from(AppPreferences.defaultSavedPrompts);
  String _workspaceAlias = '';
  String _assistantName = AppPreferences.defaultAssistantName;
  String _personalizationFocus = '';
  double? _drawerWidth;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatPageModel());
    _activeChatRef = widget.chatid;
    _model.textController ??= TextEditingController(text: _model.myTextValue);
    _model.textFieldFocusNode ??= FocusNode();
    _loadAssistantPrefs();
    _chatSearchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _chatSearchQuery = _chatSearchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadAssistantPrefs() async {
    final prefs = await AppPreferences.loadAssistantPreferences();
    if (!mounted) {
      return;
    }
    setState(() {
      _customInstructions = prefs.customInstructions;
      _responseStyle = prefs.responseStyle;
      _savedPrompts = prefs.savedPrompts;
      _workspaceAlias = prefs.workspaceAlias;
      _assistantName = prefs.assistantName;
      _personalizationFocus = prefs.personalizationFocus;
    });
  }

  Future<void> _saveAssistantPrefs() async {
    await AppPreferences.saveAssistantPreferences(
      customInstructions: _customInstructions,
      responseStyle: _responseStyle,
      savedPrompts: _savedPrompts,
      workspaceAlias: _workspaceAlias,
      assistantName: _assistantName,
      personalizationFocus: _personalizationFocus,
    );
  }

  String _buildChatPreview(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.length <= 90
        ? normalized
        : '${normalized.substring(0, 90).trim()}...';
  }

  String _buildTranscript(
    List<MessagesRecord> messages, {
    required bool markdown,
  }) {
    return messages.map((message) {
      if (markdown) {
        final output = StringBuffer()
          ..writeln('## You')
          ..writeln(message.text);
        if (message.response.isNotEmpty) {
          output
            ..writeln()
            ..writeln('## $_assistantDisplayName')
            ..write(message.response);
        }
        return output.toString().trim();
      }

      final output = StringBuffer('You: ${message.text}');
      if (message.response.isNotEmpty) {
        output
          ..writeln()
          ..write('$_assistantDisplayName: ${message.response}');
      }
      return output.toString();
    }).join('\n\n');
  }

  String _suggestTitleFromConversation({
    required String prompt,
    required String reply,
  }) {
    final headingMatch =
        RegExp(r'^\s{0,3}#{1,3}\s+(.+)$', multiLine: true).firstMatch(reply);
    if (headingMatch != null) {
      final heading = headingMatch.group(1)?.trim() ?? '';
      if (heading.isNotEmpty) {
        return heading.length <= 42
            ? heading
            : '${heading.substring(0, 42).trim()}...';
      }
    }

    final firstSentence = reply
        .replaceAll(RegExp(r'[`*_#>-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'[.!?]'))
        .first
        .trim();
    if (firstSentence.split(' ').length >= 3) {
      final words = firstSentence.split(' ').take(6).join(' ');
      return words.length <= 42 ? words : '${words.substring(0, 42).trim()}...';
    }

    return _smartTitleFromPrompt(prompt);
  }

  String _smartTitleFromPrompt(String prompt) {
    var normalized = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceFirst(
      RegExp(
        r'^(can you|could you|please|help me|i need you to|write|create|generate|tell me|explain|summarize)\s+',
        caseSensitive: false,
      ),
      '',
    );
    normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    if (normalized.isEmpty) {
      return 'New Chat';
    }

    final words =
        normalized.split(' ').where((word) => word.isNotEmpty).toList();
    final selected = words.take(6).map((word) {
      if (word.length <= 2) {
        return word.toLowerCase();
      }
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');

    return selected.length <= 42
        ? selected
        : '${selected.substring(0, 42).trim()}...';
  }

  String get _systemInstruction {
    final styleInstruction = switch (_responseStyle) {
      'Concise' =>
        'Keep answers concise, direct, and compact unless the user asks for detail.',
      'Detailed' =>
        'Give detailed, well-structured answers with examples when useful.',
      'Step-by-step' =>
        'Prefer step-by-step explanations and clearly separated action items.',
      _ => 'Give balanced answers that are clear, helpful, and structured.',
    };

    final userInstruction = _customInstructions.trim();
    final personalizationInstruction = _personalizationFocus.trim();
    return [
      styleInstruction,
      if (personalizationInstruction.isNotEmpty)
        'Optimize responses for this workflow focus: $personalizationInstruction.',
      if (userInstruction.isNotEmpty) userInstruction,
    ].join('\n\n');
  }

  String get _workspaceDisplayName {
    if (_workspaceAlias.trim().isNotEmpty) {
      return _workspaceAlias.trim();
    }
    if (currentUserDisplayName.isNotEmpty) {
      return currentUserDisplayName;
    }
    return 'Your Workspace';
  }

  String get _assistantDisplayName {
    final trimmed = _assistantName.trim();
    return trimmed.isEmpty ? AppPreferences.defaultAssistantName : trimmed;
  }

  double _drawerMinWidth(double screenWidth) {
    return math.min(_minDrawerWidth, screenWidth * 0.92);
  }

  double _drawerMaxWidth(double screenWidth) {
    return math.max(_drawerMinWidth(screenWidth), screenWidth * 0.5);
  }

  double _resolvedDrawerWidth(double screenWidth) {
    final minWidth = _drawerMinWidth(screenWidth);
    final maxWidth = _drawerMaxWidth(screenWidth);
    return (_drawerWidth ?? minWidth).clamp(minWidth, maxWidth).toDouble();
  }

  @override
  void dispose() {
    _messagesScrollController.dispose();
    _chatSearchController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_messagesScrollController.hasClients) {
      return;
    }
    final position = _messagesScrollController.position.maxScrollExtent;
    if (animated) {
      _messagesScrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }
    _messagesScrollController.jumpTo(position);
  }

  void _scheduleScrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToBottom(animated: animated);
    });
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textColor == null ? null : TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buildConversationHistory(
    DocumentReference chatReference,
  ) async {
    final snapshot = await queryMessagesRecordOnce(
      parent: chatReference,
      queryBuilder: (messagesRecord) => messagesRecord.orderBy('createdAt'),
    );

    final history = <Map<String, dynamic>>[];
    for (final message in snapshot.take(12)) {
      if (message.text.isNotEmpty) {
        history.add({
          'role': 'user',
          'parts': [
            {'text': message.text}
          ],
        });
      }

      final response = message.response.trim();
      if (response.isNotEmpty &&
          response != 'Thinking...' &&
          !response.startsWith('Error:')) {
        history.add({
          'role': 'model',
          'parts': [
            {'text': response}
          ],
        });
      }
    }
    return history;
  }

  Future<ApiCallResponse> _runGeminiCall({
    required String prompt,
    required List<Map<String, dynamic>> history,
  }) async {
    return GeminiGenerateCall.call(
      textValue: prompt,
      history: history,
      systemInstruction: _systemInstruction,
    );
  }

  Future<(String?, ApiCallResponse?)> _generateCompleteReply({
    required String prompt,
    required DocumentReference chatReference,
  }) async {
    var history = await _buildConversationHistory(chatReference);
    var latestResponse = await _runGeminiCall(
      prompt: prompt,
      history: history,
    );

    if (!(latestResponse.succeeded)) {
      return (null, latestResponse);
    }

    var fullReply =
        GeminiGenerateCall.geminiReplyText(latestResponse.jsonBody) ?? '';
    var finishReason = GeminiGenerateCall.finishReason(latestResponse.jsonBody);
    var continuationRound = 0;

    while (finishReason == 'MAX_TOKENS' &&
        continuationRound < _maxContinuationRounds) {
      continuationRound += 1;
      history = [
        ...history,
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        },
        {
          'role': 'model',
          'parts': [
            {'text': fullReply}
          ],
        },
      ];

      latestResponse = await _runGeminiCall(
        prompt: _continuationPrompt,
        history: history,
      );

      if (!latestResponse.succeeded) {
        break;
      }

      final continuationText =
          GeminiGenerateCall.geminiReplyText(latestResponse.jsonBody) ?? '';
      if (continuationText.isEmpty) {
        break;
      }

      fullReply = fullReply.isEmpty
          ? continuationText
          : '$fullReply\n\n$continuationText';
      finishReason = GeminiGenerateCall.finishReason(latestResponse.jsonBody);
    }

    return (fullReply.trim(), latestResponse);
  }

  Future<(String?, ApiCallResponse?, bool)> _generateReplyWithStatus({
    required String prompt,
    required DocumentReference chatReference,
  }) async {
    final (reply, response) = await _generateCompleteReply(
      prompt: prompt,
      chatReference: chatReference,
    );
    final isTruncated =
        GeminiGenerateCall.finishReason(response?.jsonBody) == 'MAX_TOKENS';
    return (reply, response, isTruncated);
  }

  void _applyPrompt(String prompt) {
    _model.textController?.text = prompt;
    _model.textController?.selection = TextSelection.collapsed(
      offset: _model.textController?.text.length ?? 0,
    );
    _model.textFieldFocusNode?.requestFocus();
    setState(() {});
  }

  Future<void> _saveCurrentPrompt() async {
    final prompt = _model.textController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    setState(() {
      _savedPrompts = [
        prompt,
        ..._savedPrompts.where((item) => item != prompt),
      ].take(12).toList();
    });
    await _saveAssistantPrefs();
    _showSnackBar('Prompt saved');
  }

  Future<void> _openPromptLibrary() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = FlutterFlowTheme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Prompts',
                  style: theme.headlineSmall,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Tap a prompt to use it in the composer.',
                  style: theme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _savedPrompts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                    itemBuilder: (context, index) {
                      final prompt = _savedPrompts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(color: theme.alternate),
                        ),
                        child: ListTile(
                          title: Text(
                            prompt,
                            style: theme.bodyMedium,
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _applyPrompt(prompt);
                          },
                          trailing: IconButton(
                            onPressed: () async {
                              setState(() {
                                _savedPrompts = _savedPrompts
                                    .where((item) => item != prompt)
                                    .toList();
                                if (_savedPrompts.isEmpty) {
                                  _savedPrompts = List<String>.from(
                                    AppPreferences.defaultSavedPrompts,
                                  );
                                }
                              });
                              await _saveAssistantPrefs();
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.error,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAssistantSettings() async {
    final instructionsController = TextEditingController(
      text: _customInstructions,
    );
    var selectedStyle = _responseStyle;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = FlutterFlowTheme.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20.0,
                  18.0,
                  20.0,
                  24.0 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Assistant Settings',
                        style: theme.headlineSmall,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Personalize how Gemini responds without changing your API setup.',
                        style: theme.bodyMedium,
                      ),
                      const SizedBox(height: 18.0),
                      Text(
                        'Response style',
                        style: theme.titleMedium,
                      ),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: [
                          'Balanced',
                          'Concise',
                          'Detailed',
                          'Step-by-step',
                        ]
                            .map(
                              (style) => ChoiceChip(
                                label: Text(style),
                                selected: selectedStyle == style,
                                onSelected: (_) {
                                  setSheetState(() {
                                    selectedStyle = style;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18.0),
                      Text(
                        'Custom instructions',
                        style: theme.titleMedium,
                      ),
                      const SizedBox(height: 10.0),
                      TextField(
                        controller: instructionsController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText:
                              'Example: Prefer practical answers, use clean formatting, and explain code clearly.',
                          filled: true,
                          fillColor: theme.primaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            borderSide: BorderSide(color: theme.alternate),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            borderSide: BorderSide(color: theme.alternate),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            borderSide: BorderSide(color: theme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                instructionsController.clear();
                                setSheetState(() {
                                  selectedStyle = 'Balanced';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                setState(() {
                                  _customInstructions =
                                      instructionsController.text.trim();
                                  _responseStyle = selectedStyle;
                                });
                                await _saveAssistantPrefs();
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    instructionsController.dispose();
  }

  Future<void> _regenerateResponse(MessagesRecord message) async {
    final prompt = message.text.trim();
    if (prompt.isEmpty || _isSending) {
      return;
    }

    _model.textController?.text = prompt;
    _model.textController?.selection = TextSelection.collapsed(
      offset: prompt.length,
    );
    await _sendMessage();
  }

  Future<void> _continueGenerating(MessagesRecord message) async {
    if (_isSending) {
      return;
    }

    final currentResponse = message.response.trim();
    if (currentResponse.isEmpty || currentResponse.startsWith('Error:')) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final history = await _buildConversationHistory(message.parentReference);
      final apiResponse = await _runGeminiCall(
        prompt: _continuationPrompt,
        history: [
          ...history,
          {
            'role': 'user',
            'parts': [
              {'text': message.text}
            ],
          },
          {
            'role': 'model',
            'parts': [
              {'text': currentResponse}
            ],
          },
        ],
      );

      if (!(apiResponse.succeeded)) {
        return;
      }

      final continuation =
          GeminiGenerateCall.geminiReplyText(apiResponse.jsonBody);
      if (continuation == null || continuation.trim().isEmpty) {
        return;
      }

      final mergedResponse =
          '$currentResponse\n\n${continuation.trim()}'.trim();
      final stillNeedsContinuation =
          GeminiGenerateCall.finishReason(apiResponse.jsonBody) == 'MAX_TOKENS';

      await message.reference.update(createMessagesRecordData(
        response: mergedResponse,
        needsContinuation: stillNeedsContinuation,
      ));
      await message.parentReference.update(createChatsRecordData(
        updatedAt: getCurrentTimestamp,
        lastMessagePreview: _buildChatPreview(mergedResponse),
      ));
      _scheduleScrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _setMessageFeedback(
      MessagesRecord message, String feedback) async {
    final nextFeedback = message.feedback == feedback ? '' : feedback;
    await message.reference.update(createMessagesRecordData(
      feedback: nextFeedback,
    ));
  }

  Future<void> _renameChat(ChatsRecord chat) async {
    final controller = TextEditingController(text: chat.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = FlutterFlowTheme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.secondaryBackground,
          title: Text(
            'Rename Chat',
            style: theme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter a chat title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newTitle == null || newTitle.isEmpty) {
      return;
    }

    await chat.reference.update(createChatsRecordData(
      title: newTitle,
      updatedAt: getCurrentTimestamp,
    ));
  }

  Future<void> _deleteChat(ChatsRecord chat) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final theme = FlutterFlowTheme.of(dialogContext);
            return AlertDialog(
              backgroundColor: theme.secondaryBackground,
              title: Text(
                'Delete Chat?',
                style: theme.titleLarge,
              ),
              content: Text(
                'This will remove the chat and all messages inside it.',
                style: theme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.error,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final messages = await queryMessagesRecordOnce(parent: chat.reference);
    final batch = FirebaseFirestore.instance.batch();
    for (final message in messages) {
      batch.delete(message.reference);
    }
    batch.delete(chat.reference);
    await batch.commit();

    if (_activeChatRef?.path == chat.reference.path) {
      _activeChatRef = null;
      if (!mounted) {
        return;
      }
      context.goNamed(ChatPageWidget.routeName);
    }
  }

  Future<void> _toggleChatPinned(ChatsRecord chat) async {
    await chat.reference.update(createChatsRecordData(
      pinned: !chat.pinned,
      updatedAt: getCurrentTimestamp,
    ));
  }

  Future<void> _toggleChatArchived(ChatsRecord chat) async {
    await chat.reference.update(createChatsRecordData(
      archived: !chat.archived,
      updatedAt: getCurrentTimestamp,
    ));

    if (_activeChatRef?.path == chat.reference.path && !chat.archived) {
      _activeChatRef = null;
      if (!mounted) {
        return;
      }
      context.goNamed(ChatPageWidget.routeName);
    }
  }

  Future<void> _exportCurrentChat() async {
    if (_activeChatRef == null) {
      return;
    }

    final messages = await queryMessagesRecordOnce(
      parent: _activeChatRef,
      queryBuilder: (messagesRecord) => messagesRecord.orderBy('createdAt'),
    );

    if (messages.isEmpty) {
      return;
    }

    final chatTitle = _activeChatRef != null
        ? await ChatsRecord.getDocumentOnce(_activeChatRef!)
            .then((chat) => chat.title)
            .catchError((_) => 'conversation')
        : 'conversation';
    final safeTitle = chatTitle
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    if (!mounted) {
      return;
    }
    final theme = FlutterFlowTheme.of(context);

    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.secondaryBackground,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Download TXT'),
                onTap: () => Navigator.of(sheetContext).pop('txt'),
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text('Download Markdown'),
                onTap: () => Navigator.of(sheetContext).pop('md'),
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Transcript'),
                onTap: () => Navigator.of(sheetContext).pop('copy'),
              ),
            ],
          ),
        ),
      ),
    );

    if (format == null) {
      return;
    }

    final transcript = _buildTranscript(
      messages,
      markdown: format == 'md',
    );

    bool downloaded = false;
    if (format == 'txt' || format == 'md') {
      downloaded = await downloadTextFile(
        filename:
            '${safeTitle.isEmpty ? 'conversation' : safeTitle}.${format == 'md' ? 'md' : 'txt'}',
        text: transcript,
      );
    }

    if (!downloaded || format == 'copy') {
      await Clipboard.setData(ClipboardData(text: transcript));
    }
    _showSnackBar(
      downloaded && format != 'copy'
          ? 'Conversation downloaded'
          : 'Conversation copied to clipboard',
      duration: const Duration(milliseconds: 1400),
    );
  }

  Future<DocumentReference> _ensureChatReference(String prompt) async {
    if (_activeChatRef != null) {
      await _activeChatRef!.update(createChatsRecordData(
        updatedAt: getCurrentTimestamp,
        archived: false,
      ));
      return _activeChatRef!;
    }

    final chatReference = ChatsRecord.collection.doc();
    final title = _chatTitleFromPrompt(prompt);
    await chatReference.set(createChatsRecordData(
      userId: currentUserReference,
      title: title,
      createdAt: getCurrentTimestamp,
      updatedAt: getCurrentTimestamp,
      lastMessagePreview: '',
      pinned: false,
      archived: false,
    ));

    _activeChatRef = chatReference;
    if (!mounted) {
      return chatReference;
    }
    context.goNamed(
      ChatPageWidget.routeName,
      queryParameters: {
        'chatid': serializeParam(
          chatReference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );

    return chatReference;
  }

  String _chatTitleFromPrompt(String prompt) {
    return _smartTitleFromPrompt(prompt);
  }

  Future<void> _createNewChat() async {
    final chatsRecordReference = ChatsRecord.collection.doc();
    await chatsRecordReference.set(createChatsRecordData(
      userId: currentUserReference,
      title: 'New Chat',
      createdAt: getCurrentTimestamp,
      updatedAt: getCurrentTimestamp,
      lastMessagePreview: '',
      pinned: false,
      archived: false,
    ));
    _model.newChatItem = ChatsRecord.getDocumentFromData(
      createChatsRecordData(
        userId: currentUserReference,
        title: 'New Chat',
        createdAt: getCurrentTimestamp,
        updatedAt: getCurrentTimestamp,
        lastMessagePreview: '',
        pinned: false,
        archived: false,
      ),
      chatsRecordReference,
    );

    if (!mounted) {
      return;
    }

    context.pushNamed(
      ChatPageWidget.routeName,
      queryParameters: {
        'chatid': serializeParam(
          chatsRecordReference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _sendMessage() async {
    final prompt = _model.textController.text.trim();
    if (prompt.isEmpty || _isSending) {
      return;
    }

    final theme = FlutterFlowTheme.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _model.myTextValue = prompt;
    });

    try {
      final chatReference = await _ensureChatReference(prompt);
      final messageReference = MessagesRecord.createDoc(chatReference);
      final placeholder = createMessagesRecordData(
        createdAt: getCurrentTimestamp,
        senderId: currentUserReference?.id,
        text: prompt,
        role: 'user',
        response: 'Thinking...',
        needsContinuation: false,
      );

      await messageReference.set(placeholder);
      await chatReference.update(createChatsRecordData(
        updatedAt: getCurrentTimestamp,
        archived: false,
        lastMessagePreview: _buildChatPreview(prompt),
      ));
      _model.newMessageRef = MessagesRecord.getDocumentFromData(
        placeholder,
        messageReference,
      );

      _model.textController!.clear();
      _scheduleScrollToBottom();

      final (reply, apiResponse, needsContinuation) =
          await _generateReplyWithStatus(
        prompt: prompt,
        chatReference: chatReference,
      );
      _model.apiResultszi = apiResponse;

      if (_model.apiResultszi?.succeeded ?? false) {
        final finalReply = (reply?.isNotEmpty ?? false)
            ? reply!
            : 'I could not generate a response.';
        final existingChat = await ChatsRecord.getDocumentOnce(chatReference);
        final suggestedTitle = _suggestTitleFromConversation(
          prompt: prompt,
          reply: finalReply,
        );
        await messageReference.update(createMessagesRecordData(
          response: finalReply,
          needsContinuation: needsContinuation,
        ));
        await chatReference.update(createChatsRecordData(
          updatedAt: getCurrentTimestamp,
          lastMessagePreview: _buildChatPreview(finalReply),
          title: existingChat.title == 'New Chat' ||
                  existingChat.title == _smartTitleFromPrompt(prompt)
              ? suggestedTitle
              : null,
        ));
        _scheduleScrollToBottom();
      } else {
        final errorText = GeminiGenerateCall.errorText(
              _model.apiResultszi?.jsonBody,
            ) ??
            (_model.apiResultszi?.bodyText.isNotEmpty ?? false
                ? _model.apiResultszi?.bodyText
                : null) ??
            (_model.apiResultszi?.statusCode != null
                ? 'Request failed with status ${_model.apiResultszi!.statusCode}.'
                : null) ??
            (_model.apiResultszi?.exceptionMessage.isNotEmpty ?? false
                ? _model.apiResultszi?.exceptionMessage
                : null) ??
            'Unable to reach the Gemini service right now.';

        await messageReference.update(createMessagesRecordData(
          response: 'Error: $errorText',
          needsContinuation: false,
        ));
        await chatReference.update(createChatsRecordData(
          updatedAt: getCurrentTimestamp,
          lastMessagePreview: _buildChatPreview('Error: $errorText'),
        ));
        _scheduleScrollToBottom();
        _showSnackBar(
          errorText,
          backgroundColor: theme.error,
          textColor: theme.info,
          duration: const Duration(milliseconds: 2400),
        );
      }
    } catch (error) {
      _showSnackBar(
        'Something went wrong while sending your message.',
        backgroundColor: theme.error,
        textColor: theme.info,
        duration: const Duration(milliseconds: 2200),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final minDrawerWidth = _drawerMinWidth(screenWidth);
    final maxDrawerWidth = _drawerMaxWidth(screenWidth);
    final drawerWidth = _resolvedDrawerWidth(screenWidth);
    return Drawer(
      width: drawerWidth,
      backgroundColor: theme.secondaryBackground,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: theme.alternate,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52.0,
                          height: 52.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.primary, theme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: ClipOval(
                            child: currentUserPhoto.isNotEmpty
                                ? Image.network(
                                    currentUserPhoto,
                                    width: 52.0,
                                    height: 52.0,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildAvatarFallback(theme),
                                  )
                                : _buildAvatarFallback(theme),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _workspaceDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.titleMedium.override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontStyle: theme.titleMedium.fontStyle,
                                  ),
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                currentUserEmail.isNotEmpty
                                    ? currentUserEmail
                                    : 'Signed in',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.labelMedium.override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: theme.labelMedium.fontStyle,
                                  ),
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Text(
                        'Recent Chats',
                        style: theme.titleMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontStyle: theme.titleMedium.fontStyle,
                          ),
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      FlutterFlowIconButton(
                        borderRadius: 14.0,
                        buttonSize: 40.0,
                        fillColor: theme.primaryBackground,
                        icon: Icon(
                          Icons.settings_outlined,
                          color: theme.primaryText,
                          size: 20.0,
                        ),
                        onPressed: () {
                          context.pushNamed(SettingsPageWidget.routeName);
                        },
                      ),
                      const Spacer(),
                      FlutterFlowIconButton(
                        borderRadius: 14.0,
                        buttonSize: 40.0,
                        fillColor: theme.primaryBackground,
                        icon: Icon(
                          Icons.add_comment_rounded,
                          color: theme.primaryText,
                          size: 20.0,
                        ),
                        onPressed: _createNewChat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _chatSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search chats',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.primaryBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        borderSide: BorderSide(color: theme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: !_showArchived,
                        onSelected: (_) {
                          setState(() {
                            _showArchived = false;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Archived'),
                        selected: _showArchived,
                        onSelected: (_) {
                          setState(() {
                            _showArchived = true;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Expanded(
                    child: StreamBuilder<List<ChatsRecord>>(
                      stream: queryChatsRecord(
                        queryBuilder: (chatsRecord) => chatsRecord
                            .where('userId', isEqualTo: currentUserReference)
                            .orderBy('updatedAt', descending: true),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final chats = snapshot.data!;
                        final visibleChats = chats
                            .where((chat) => chat.archived == _showArchived)
                            .toList()
                          ..sort((a, b) {
                            if (a.pinned != b.pinned) {
                              return a.pinned ? -1 : 1;
                            }
                            final aTime =
                                a.updatedAt ?? a.createdAt ?? DateTime(1970);
                            final bTime =
                                b.updatedAt ?? b.createdAt ?? DateTime(1970);
                            return bTime.compareTo(aTime);
                          });
                        final filteredChats = _chatSearchQuery.isEmpty
                            ? visibleChats
                            : chats
                                .where(
                                  (chat) => chat.title
                                      .toLowerCase()
                                      .contains(_chatSearchQuery),
                                )
                                .where((chat) => chat.archived == _showArchived)
                                .toList()
                          ..sort((a, b) {
                            if (a.pinned != b.pinned) {
                              return a.pinned ? -1 : 1;
                            }
                            final aTime =
                                a.updatedAt ?? a.createdAt ?? DateTime(1970);
                            final bTime =
                                b.updatedAt ?? b.createdAt ?? DateTime(1970);
                            return bTime.compareTo(aTime);
                          });
                        if (filteredChats.isEmpty) {
                          return Center(
                            child: Text(
                              _chatSearchQuery.isEmpty
                                  ? (_showArchived
                                      ? 'No archived chats yet.'
                                      : 'Start a new chat to see it here.')
                                  : 'No chats match your search.',
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500,
                                  fontStyle: theme.bodyMedium.fontStyle,
                                ),
                                color: theme.secondaryText,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filteredChats.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10.0),
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            final isSelected =
                                _activeChatRef?.path == chat.reference.path;
                            return InkWell(
                              borderRadius: BorderRadius.circular(20.0),
                              onTap: () {
                                context.pushNamed(
                                  ChatPageWidget.routeName,
                                  queryParameters: {
                                    'chatid': serializeParam(
                                      chat.reference,
                                      ParamType.DocumentReference,
                                    ),
                                  }.withoutNulls,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.accent1.withValues(alpha: 0.25)
                                      : theme.primaryBackground,
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.primary
                                        : theme.alternate,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (chat.pinned)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0, top: 2.0),
                                            child: Icon(
                                              Icons.push_pin_rounded,
                                              size: 16.0,
                                              color: theme.primary,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            valueOrDefault<String>(
                                                chat.title, 'New Chat'),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.bodyLarge.override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                fontStyle:
                                                    theme.bodyLarge.fontStyle,
                                              ),
                                              color: theme.primaryText,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_horiz_rounded,
                                            color: theme.secondaryText,
                                          ),
                                          onSelected: (value) async {
                                            if (value == 'rename') {
                                              await _renameChat(chat);
                                            }
                                            if (value == 'pin') {
                                              await _toggleChatPinned(chat);
                                            }
                                            if (value == 'archive') {
                                              await _toggleChatArchived(chat);
                                            }
                                            if (value == 'delete') {
                                              await _deleteChat(chat);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'rename',
                                              child: Text('Rename'),
                                            ),
                                            PopupMenuItem(
                                              value: 'pin',
                                              child: Text(chat.pinned
                                                  ? 'Unpin'
                                                  : 'Pin'),
                                            ),
                                            PopupMenuItem(
                                              value: 'archive',
                                              child: Text(chat.archived
                                                  ? 'Unarchive'
                                                  : 'Archive'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (chat.lastMessagePreview.isNotEmpty) ...[
                                      const SizedBox(height: 8.0),
                                      Text(
                                        chat.lastMessagePreview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.bodySmall.override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                theme.bodySmall.fontStyle,
                                          ),
                                          color: theme.secondaryText,
                                          lineHeight: 1.45,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6.0),
                                    Text(
                                      dateTimeFormat(
                                        "MMM d, h:mm a",
                                        chat.updatedAt ?? chat.createdAt,
                                      ),
                                      style: theme.labelMedium.override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              theme.labelMedium.fontStyle,
                                        ),
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        router.prepareAuthEvent();
                        await authManager.signOut();
                        router.clearRedirectLocation();

                        if (!mounted) {
                          return;
                        }
                        if (!router.shouldRedirect(false)) {
                          router.goNamed(OnBoardingWidget.routeName);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.info,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 16.0,
                        ),
                        side: BorderSide(color: theme.alternate),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  setState(() {
                    _drawerWidth = minDrawerWidth;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _drawerWidth =
                        (_drawerWidth ?? minDrawerWidth) + details.delta.dx;
                    _drawerWidth = _drawerWidth!
                        .clamp(minDrawerWidth, maxDrawerWidth)
                        .toDouble();
                  });
                },
                child: Container(
                  width: 18.0,
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      color: theme.alternate.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(FlutterFlowTheme theme) {
    final letterSource = currentUserDisplayName.isNotEmpty
        ? currentUserDisplayName
        : currentUserEmail;
    final letter = letterSource.isNotEmpty
        ? letterSource.substring(0, 1).toUpperCase()
        : 'A';
    return Container(
      color: theme.primary,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: theme.titleLarge.override(
          font: GoogleFonts.urbanist(
            fontWeight: FontWeight.w700,
            fontStyle: theme.titleLarge.fontStyle,
          ),
          color: theme.info,
        ),
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (_activeChatRef == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88.0,
                height: 88.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28.0),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.info,
                  size: 40.0,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Ask anything',
                style: theme.headlineMedium.override(
                  font: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w700,
                    fontStyle: theme.headlineMedium.fontStyle,
                  ),
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                '$_assistantDisplayName is ready to help inside $_workspaceDisplayName with clearer contrast, readable bubbles, and room for longer messages.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontStyle: theme.bodyMedium.fontStyle,
                  ),
                  color: theme.secondaryText,
                  lineHeight: 1.5,
                ),
              ),
              const SizedBox(height: 24.0),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                alignment: WrapAlignment.center,
                children: _savedPrompts
                    .take(4)
                    .map(
                      (prompt) => ActionChip(
                        label: Text(prompt),
                        onPressed: () => _applyPrompt(prompt),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<MessagesRecord>>(
      stream: queryMessagesRecord(
        parent: _activeChatRef,
        queryBuilder: (messagesRecord) => messagesRecord.orderBy('createdAt'),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'Send your first prompt to start the conversation.',
              style: theme.bodyMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: theme.secondaryText,
              ),
            ),
          );
        }

        if (_lastMessageCount != messages.length) {
          _lastMessageCount = messages.length;
          _scheduleScrollToBottom(
            animated: messages.length > 1,
          );
        }

        return ListView.separated(
          controller: _messagesScrollController,
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
          itemCount: messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18.0),
          itemBuilder: (context, index) {
            final message = messages[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MessageBubble(
                  alignment: Alignment.centerRight,
                  label: 'You',
                  text: message.text,
                  isUser: true,
                  timestamp: message.createdAt,
                ),
                if (message.response.isNotEmpty) ...[
                  const SizedBox(height: 10.0),
                  _MessageBubble(
                    alignment: Alignment.centerLeft,
                    label: _assistantDisplayName,
                    text: message.response,
                    isThinking: message.response == 'Thinking...',
                    timestamp: message.createdAt,
                    feedback: message.feedback,
                    showContinue: message.needsContinuation,
                    onCopy: message.response == 'Thinking...'
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: message.response),
                            );
                            _showSnackBar('Response copied');
                          },
                    onRegenerate: message.response == 'Thinking...'
                        ? null
                        : () => _regenerateResponse(message),
                    onContinue: message.response == 'Thinking...' ||
                            !message.needsContinuation
                        ? null
                        : () => _continueGenerating(message),
                    onThumbUp: message.response == 'Thinking...'
                        ? null
                        : () => _setMessageFeedback(message, 'up'),
                    onThumbDown: message.response == 'Thinking...'
                        ? null
                        : () => _setMessageFeedback(message, 'down'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(color: theme.alternate),
            boxShadow: [
              BoxShadow(
                blurRadius: 18.0,
                color: Colors.black.withValues(alpha: 0.22),
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _model.textController,
                  focusNode: _model.textFieldFocusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask $_assistantDisplayName anything',
                    hintStyle: theme.labelMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        fontStyle: theme.labelMedium.fontStyle,
                      ),
                      color: theme.secondaryText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                  ),
                  style: theme.bodyLarge.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontStyle: theme.bodyLarge.fontStyle,
                    ),
                    color: theme.primaryText,
                    lineHeight: 1.5,
                  ),
                  cursorColor: theme.primary,
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                tooltip: 'Save prompt',
                onPressed: _saveCurrentPrompt,
                icon: Icon(
                  Icons.bookmark_add_outlined,
                  color: theme.secondaryText,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSending
                        ? [theme.alternate, theme.alternate]
                        : [theme.primary, theme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(theme.info),
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          color: theme.info,
                          size: 22.0,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        drawer: _buildDrawer(context),
        appBar: AppBar(
          backgroundColor: theme.primaryBackground,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          leading: FlutterFlowIconButton(
            borderRadius: 18.0,
            buttonSize: 48.0,
            fillColor: theme.secondaryBackground,
            icon: Icon(
              Icons.menu_rounded,
              color: theme.primaryText,
              size: 24.0,
            ),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'How can $_assistantDisplayName help?',
                style: theme.headlineMedium.override(
                  font: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w700,
                    fontStyle: theme.headlineMedium.fontStyle,
                  ),
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                'Gemini-powered assistant for $_workspaceDisplayName',
                style: theme.labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontStyle: theme.labelMedium.fontStyle,
                  ),
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            FlutterFlowIconButton(
              borderRadius: 18.0,
              buttonSize: 48.0,
              fillColor: theme.secondaryBackground,
              icon: Icon(
                Icons.ios_share_rounded,
                color: theme.primaryText,
                size: 20.0,
              ),
              onPressed: _exportCurrentChat,
            ),
            const SizedBox(width: 8.0),
            FlutterFlowIconButton(
              borderRadius: 18.0,
              buttonSize: 48.0,
              fillColor: theme.secondaryBackground,
              icon: Icon(
                Icons.tune_rounded,
                color: theme.primaryText,
                size: 22.0,
              ),
              onPressed: _openAssistantSettings,
            ),
            const SizedBox(width: 8.0),
            FlutterFlowIconButton(
              borderRadius: 18.0,
              buttonSize: 48.0,
              fillColor: theme.secondaryBackground,
              icon: Icon(
                Icons.library_books_rounded,
                color: theme.primaryText,
                size: 22.0,
              ),
              onPressed: _openPromptLibrary,
            ),
            const SizedBox(width: 8.0),
            FlutterFlowIconButton(
              borderRadius: 18.0,
              buttonSize: 48.0,
              fillColor: theme.secondaryBackground,
              icon: Icon(
                Icons.add_rounded,
                color: theme.primaryText,
                size: 22.0,
              ),
              onPressed: _createNewChat,
            ),
            const SizedBox(width: 12.0),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryBackground,
                theme.secondaryBackground,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _buildMessages(context)),
              _buildComposer(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.alignment,
    required this.label,
    required this.text,
    this.timestamp,
    this.isUser = false,
    this.isThinking = false,
    this.feedback = '',
    this.showContinue = false,
    this.onCopy,
    this.onRegenerate,
    this.onContinue,
    this.onThumbUp,
    this.onThumbDown,
  });

  final Alignment alignment;
  final String label;
  final String text;
  final DateTime? timestamp;
  final bool isUser;
  final bool isThinking;
  final String feedback;
  final bool showContinue;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onContinue;
  final VoidCallback? onThumbUp;
  final VoidCallback? onThumbDown;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bubbleColor = isUser ? theme.primary : theme.secondaryBackground;
    final borderColor = isUser ? theme.primary : theme.alternate;
    final textColor = isUser ? theme.info : theme.primaryText;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width > 700.0
              ? 520.0
              : MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                blurRadius: 16.0,
                color: Colors.black.withValues(alpha: 0.12),
                offset: const Offset(0.0, 8.0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.labelSmall.override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontStyle: theme.labelSmall.fontStyle,
                  ),
                  color: textColor.withValues(alpha: 0.78),
                  letterSpacing: 0.4,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  dateTimeFormat('h:mm a', timestamp),
                  style: theme.labelSmall.override(
                    font: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontStyle: theme.labelSmall.fontStyle,
                    ),
                    color: textColor.withValues(alpha: 0.68),
                  ),
                ),
              ],
              const SizedBox(height: 8.0),
              isUser || isThinking
                  ? SelectableText(
                      text,
                      style: theme.bodyLarge.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight:
                              isThinking ? FontWeight.w500 : FontWeight.w600,
                          fontStyle:
                              isThinking ? FontStyle.italic : FontStyle.normal,
                        ),
                        color: textColor,
                        lineHeight: 1.55,
                      ),
                    )
                  : MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.bodyLarge.override(
                          font: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                          ),
                          color: textColor,
                          lineHeight: 1.6,
                        ),
                        h1: theme.headlineMedium.override(
                          color: textColor,
                        ),
                        h2: theme.titleLarge.override(
                          color: textColor,
                        ),
                        h3: theme.titleMedium.override(
                          color: textColor,
                        ),
                        code: TextStyle(
                          color: theme.primaryText,
                          backgroundColor: theme.primaryBackground,
                          fontFamily: 'monospace',
                          fontSize: 13.0,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: theme.alternate),
                        ),
                        blockquote: theme.bodyMedium.override(
                          color: textColor.withValues(alpha: 0.88),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: theme.primaryBackground.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border(
                            left: BorderSide(
                              color: theme.primary,
                              width: 4.0,
                            ),
                          ),
                        ),
                        listBullet: theme.bodyLarge.override(
                          color: textColor,
                        ),
                      ),
                    ),
              if (!isThinking &&
                  !isUser &&
                  (onCopy != null ||
                      onRegenerate != null ||
                      onContinue != null ||
                      onThumbUp != null ||
                      onThumbDown != null))
                Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      if (onThumbUp != null)
                        IconButton.filledTonal(
                          onPressed: onThumbUp,
                          style: IconButton.styleFrom(
                            backgroundColor: feedback == 'up'
                                ? theme.accent1.withValues(alpha: 0.35)
                                : theme.primaryBackground,
                          ),
                          icon: Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 18.0,
                            color: feedback == 'up'
                                ? theme.primary
                                : theme.secondaryText,
                          ),
                        ),
                      if (onThumbDown != null)
                        IconButton.filledTonal(
                          onPressed: onThumbDown,
                          style: IconButton.styleFrom(
                            backgroundColor: feedback == 'down'
                                ? theme.accent1.withValues(alpha: 0.35)
                                : theme.primaryBackground,
                          ),
                          icon: Icon(
                            Icons.thumb_down_alt_outlined,
                            size: 18.0,
                            color: feedback == 'down'
                                ? theme.primary
                                : theme.secondaryText,
                          ),
                        ),
                      if (onCopy != null)
                        OutlinedButton.icon(
                          onPressed: onCopy,
                          icon: const Icon(Icons.copy_rounded, size: 16.0),
                          label: const Text('Copy'),
                        ),
                      if (onRegenerate != null)
                        OutlinedButton.icon(
                          onPressed: onRegenerate,
                          icon: const Icon(Icons.refresh_rounded, size: 16.0),
                          label: const Text('Regenerate'),
                        ),
                      if (showContinue && onContinue != null)
                        OutlinedButton.icon(
                          onPressed: onContinue,
                          icon:
                              const Icon(Icons.more_horiz_rounded, size: 16.0),
                          label: const Text('Continue'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
