import '/app_settings/app_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  static String routeName = 'SettingsPage';
  static String routePath = '/settingsPage';

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  late TextEditingController _instructionsController;
  late TextEditingController _workspaceAliasController;
  late TextEditingController _assistantNameController;
  late TextEditingController _focusController;
  String _responseStyle = 'Balanced';
  List<String> _savedPrompts =
      List<String>.from(AppPreferences.defaultSavedPrompts);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController();
    _workspaceAliasController = TextEditingController();
    _assistantNameController = TextEditingController();
    _focusController = TextEditingController();
    _loadPreferences();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _workspaceAliasController.dispose();
    _assistantNameController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await AppPreferences.loadAssistantPreferences();
    if (!mounted) {
      return;
    }
    setState(() {
      _instructionsController.text = prefs.customInstructions;
      _responseStyle = prefs.responseStyle;
      _savedPrompts = prefs.savedPrompts;
      _workspaceAliasController.text = prefs.workspaceAlias;
      _assistantNameController.text = prefs.assistantName;
      _focusController.text = prefs.personalizationFocus;
      _loading = false;
    });
  }

  Future<void> _savePreferences() async {
    await AppPreferences.saveAssistantPreferences(
      customInstructions: _instructionsController.text.trim(),
      responseStyle: _responseStyle,
      savedPrompts: _savedPrompts,
      workspaceAlias: _workspaceAliasController.text.trim(),
      assistantName: _assistantNameController.text.trim().isEmpty
          ? AppPreferences.defaultAssistantName
          : _assistantNameController.text.trim(),
      personalizationFocus: _focusController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _addPrompt() async {
    final controller = TextEditingController();
    final prompt = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Prompt'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter a reusable prompt',
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
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (prompt == null || prompt.isEmpty) {
      return;
    }

    setState(() {
      _savedPrompts = [
        prompt,
        ..._savedPrompts.where((item) => item != prompt),
      ].take(20).toList();
    });
    await _savePreferences();
  }

  Future<void> _removePrompt(String prompt) async {
    setState(() {
      _savedPrompts = _savedPrompts.where((item) => item != prompt).toList();
      if (_savedPrompts.isEmpty) {
        _savedPrompts = List<String>.from(AppPreferences.defaultSavedPrompts);
      }
    });
    await _savePreferences();
  }

  Future<void> _signOut() async {
    final router = GoRouter.of(context);
    router.prepareAuthEvent();
    await authManager.signOut();
    router.clearRedirectLocation();

    if (!mounted) {
      return;
    }
    context.goNamedAuth(
      OnBoardingWidget.routeName,
      context.mounted,
    );
  }

  Widget _buildMetricCard({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.primary,
            size: 22.0,
          ),
          const SizedBox(height: 12.0),
          Text(
            value,
            style: theme.headlineSmall.override(
              font: GoogleFonts.urbanist(
                fontWeight: FontWeight.w700,
                fontStyle: theme.headlineSmall.fontStyle,
              ),
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  int _activityStreak(List<DateTime> activityDates) {
    final uniqueDays = activityDates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (uniqueDays.isEmpty) {
      return 0;
    }

    var streak = 1;
    for (var i = 1; i < uniqueDays.length; i++) {
      final expectedPrevious =
          uniqueDays[i - 1].subtract(const Duration(days: 1));
      if (uniqueDays[i] == expectedPrevious) {
        streak += 1;
        continue;
      }
      break;
    }
    return streak;
  }

  String _workspaceDisplayName() {
    final alias = _workspaceAliasController.text.trim();
    if (alias.isNotEmpty) {
      return alias;
    }
    if (currentUserDisplayName.isNotEmpty) {
      return currentUserDisplayName;
    }
    return 'Your Workspace';
  }

  String _assistantDisplayName() {
    final assistantName = _assistantNameController.text.trim();
    return assistantName.isEmpty
        ? AppPreferences.defaultAssistantName
        : assistantName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.titleLarge.override(
            font: GoogleFonts.urbanist(
              fontWeight: FontWeight.w700,
              fontStyle: theme.titleLarge.fontStyle,
            ),
            color: theme.primaryText,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _savePreferences,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28.0,
                          backgroundColor: theme.primary,
                          backgroundImage: currentUserPhoto.isNotEmpty
                              ? NetworkImage(currentUserPhoto)
                              : null,
                          child: currentUserPhoto.isEmpty
                              ? Text(
                                  currentUserDisplayName.isNotEmpty
                                      ? currentUserDisplayName
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : 'U',
                                  style: theme.titleLarge.override(
                                    color: theme.info,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _workspaceDisplayName(),
                                style: theme.titleMedium,
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                currentUserEmail,
                                style: theme.bodyMedium.override(
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
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: StreamBuilder<List<ChatsRecord>>(
                      stream: queryChatsRecord(
                        queryBuilder: (chatsRecord) => chatsRecord.where(
                          'userId',
                          isEqualTo: currentUserReference,
                        ),
                      ),
                      builder: (context, snapshot) {
                        final chats = snapshot.data ?? const <ChatsRecord>[];
                        final activeChats =
                            chats.where((chat) => !chat.archived).length;
                        final archivedChats =
                            chats.where((chat) => chat.archived).length;
                        final pinnedChats =
                            chats.where((chat) => chat.pinned).length;
                        final latestChatDate = chats
                            .map((chat) => chat.updatedAt ?? chat.createdAt)
                            .whereType<DateTime>()
                            .fold<DateTime?>(
                              null,
                              (current, next) =>
                                  current == null || next.isAfter(current)
                                      ? next
                                      : current,
                            );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Workspace Overview',
                                style: theme.titleMedium),
                            const SizedBox(height: 6.0),
                            Text(
                              'A quick view of your assistant setup and conversation library.',
                              style: theme.bodyMedium.override(
                                color: theme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            GridView.count(
                              shrinkWrap: true,
                              crossAxisCount:
                                  MediaQuery.sizeOf(context).width > 700
                                      ? 4
                                      : 2,
                              mainAxisSpacing: 12.0,
                              crossAxisSpacing: 12.0,
                              childAspectRatio: 1.35,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: 'Active chats',
                                  value: activeChats.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.archive_outlined,
                                  label: 'Archived chats',
                                  value: archivedChats.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.push_pin_outlined,
                                  label: 'Pinned chats',
                                  value: pinnedChats.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.bolt_rounded,
                                  label: 'Saved prompts',
                                  value: _savedPrompts.length.toString(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14.0),
                            Container(
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: theme.primaryBackground,
                                borderRadius: BorderRadius.circular(18.0),
                                border: Border.all(color: theme.alternate),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Text(
                                      latestChatDate != null
                                          ? 'Last active ${dateTimeFormat("MMM d, h:mm a", latestChatDate)}'
                                          : 'No recent chat activity yet',
                                      style: theme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  StreamBuilder<List<MessagesRecord>>(
                    stream: queryMessagesRecord(
                      queryBuilder: (messagesRecord) => messagesRecord.where(
                        'senderId',
                        isEqualTo: currentUserReference?.id ?? '__guest__',
                      ),
                    ),
                    builder: (context, snapshot) {
                      final messages =
                          snapshot.data ?? const <MessagesRecord>[];
                      final activityDates = messages
                          .map((message) => message.createdAt)
                          .whereType<DateTime>()
                          .toList();
                      final successfulReplies = messages
                          .where(
                            (message) =>
                                message.response.isNotEmpty &&
                                message.response != 'Thinking...' &&
                                !message.response.startsWith('Error:'),
                          )
                          .length;
                      final likedReplies = messages
                          .where((message) => message.feedback == 'up')
                          .length;
                      final continuationReplies = messages
                          .where((message) => message.needsContinuation)
                          .length;
                      final likedMessages = messages
                          .where((message) => message.feedback == 'up')
                          .toList();
                      final successRate = messages.isEmpty
                          ? 0
                          : ((successfulReplies / messages.length) * 100)
                              .round();
                      final activityStreak = _activityStreak(activityDates);

                      return Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(color: theme.alternate),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Usage Insights', style: theme.titleMedium),
                            const SizedBox(height: 8.0),
                            Text(
                              'A lightweight view of how you are using the assistant right now.',
                              style: theme.bodyMedium.override(
                                color: theme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            GridView.count(
                              shrinkWrap: true,
                              crossAxisCount:
                                  MediaQuery.sizeOf(context).width > 700
                                      ? 3
                                      : 2,
                              mainAxisSpacing: 12.0,
                              crossAxisSpacing: 12.0,
                              childAspectRatio: 1.45,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.forum_outlined,
                                  label: 'Prompts sent',
                                  value: messages.length.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.auto_awesome_outlined,
                                  label: 'Successful replies',
                                  value: successfulReplies.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.thumb_up_alt_outlined,
                                  label: 'Liked replies',
                                  value: likedReplies.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.more_horiz_rounded,
                                  label: 'Continued replies',
                                  value: continuationReplies.toString(),
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.local_fire_department_outlined,
                                  label: 'Active streak',
                                  value: '$activityStreak days',
                                ),
                                _buildMetricCard(
                                  theme: theme,
                                  icon: Icons.insights_outlined,
                                  label: 'Success rate',
                                  value: '$successRate%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14.0),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: theme.primaryBackground,
                                borderRadius: BorderRadius.circular(18.0),
                                border: Border.all(color: theme.alternate),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Favorite interactions',
                                    style: theme.titleSmall,
                                  ),
                                  const SizedBox(height: 8.0),
                                  if (likedMessages.isEmpty)
                                    Text(
                                      'Thumbs-up a few replies and your favorite conversations will start surfacing here.',
                                      style: theme.bodyMedium.override(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ...likedMessages.take(3).map(
                                        (message) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: theme.warning,
                                                size: 18.0,
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                  message.text,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme', style: theme.titleMedium),
                        const SizedBox(height: 12.0),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: [
                            ChoiceChip(
                              label: const Text('Dark'),
                              selected:
                                  FlutterFlowTheme.themeMode == ThemeMode.dark,
                              onSelected: (_) => MyApp.of(context)
                                  .setThemeMode(ThemeMode.dark),
                            ),
                            ChoiceChip(
                              label: const Text('Light'),
                              selected:
                                  FlutterFlowTheme.themeMode == ThemeMode.light,
                              onSelected: (_) => MyApp.of(context)
                                  .setThemeMode(ThemeMode.light),
                            ),
                            ChoiceChip(
                              label: const Text('System'),
                              selected: FlutterFlowTheme.themeMode ==
                                  ThemeMode.system,
                              onSelected: (_) => MyApp.of(context)
                                  .setThemeMode(ThemeMode.system),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personalization', style: theme.titleMedium),
                        const SizedBox(height: 8.0),
                        Text(
                          'Shape the product language so the app feels more like your own workspace.',
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _workspaceDisplayName(),
                            _assistantDisplayName(),
                            if (_focusController.text.trim().isNotEmpty)
                              _focusController.text.trim(),
                          ]
                              .map(
                                (item) => Chip(
                                  label: Text(item),
                                  backgroundColor: theme.primaryBackground,
                                  side: BorderSide(color: theme.alternate),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _workspaceAliasController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Workspace alias',
                            hintText: 'Example: Mayank Lab',
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
                        const SizedBox(height: 14.0),
                        TextField(
                          controller: _assistantNameController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Assistant display name',
                            hintText: 'Example: Nova',
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
                        const SizedBox(height: 14.0),
                        TextField(
                          controller: _focusController,
                          onChanged: (_) => setState(() {}),
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Workflow focus',
                            hintText:
                                'Example: product design, mobile coding, interview prep',
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
                        const SizedBox(height: 14.0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: theme.primaryBackground,
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(color: theme.alternate),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: theme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'Preview: ',
                                  style: theme.bodyMedium.override(
                                    color: theme.secondaryText,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${_assistantDisplayName()} supports ${_workspaceDisplayName()}',
                                  style: theme.bodyMedium.override(
                                    color: theme.primaryText,
                                  ),
                                ),
                                if (_focusController.text.trim().isNotEmpty)
                                  TextSpan(
                                    text:
                                        ' with a focus on ${_focusController.text.trim()}.',
                                    style: theme.bodyMedium.override(
                                      color: theme.primaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _workspaceAliasController.clear();
                                _assistantNameController.text =
                                    AppPreferences.defaultAssistantName;
                                _focusController.clear();
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset personalization'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assistant', style: theme.titleMedium),
                        const SizedBox(height: 12.0),
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
                                  selected: _responseStyle == style,
                                  onSelected: (_) {
                                    setState(() {
                                      _responseStyle = style;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _instructionsController,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText:
                                'Add persistent instructions for the assistant.',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Saved Prompts', style: theme.titleMedium),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: _addPrompt,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        ..._savedPrompts.map(
                          (prompt) => Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
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
                              trailing: IconButton(
                                onPressed: () => _removePrompt(prompt),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: theme.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account', style: theme.titleMedium),
                        const SizedBox(height: 8.0),
                        Text(
                          'Your Gemini setup stays in the app run configuration. Settings here only control the chat experience.',
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 42.0,
                            height: 42.0,
                            decoration: BoxDecoration(
                              color: theme.primaryBackground,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: theme.alternate),
                            ),
                            child: Icon(
                              Icons.mark_chat_read_outlined,
                              color: theme.primary,
                            ),
                          ),
                          title: Text(
                            'Model integration',
                            style: theme.bodyLarge,
                          ),
                          subtitle: Text(
                            'Gemini API remains unchanged and is configured through `--dart-define=GEMINI_API_KEY`.',
                            style: theme.bodySmall.override(
                              color: theme.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign Out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
