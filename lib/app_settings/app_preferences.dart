import 'package:shared_preferences/shared_preferences.dart';

class AssistantPreferences {
  const AssistantPreferences({
    required this.customInstructions,
    required this.responseStyle,
    required this.savedPrompts,
    required this.workspaceAlias,
    required this.assistantName,
    required this.personalizationFocus,
  });

  final String customInstructions;
  final String responseStyle;
  final List<String> savedPrompts;
  final String workspaceAlias;
  final String assistantName;
  final String personalizationFocus;
}

class AppPreferences {
  static const customInstructionsKey = 'chat_custom_instructions';
  static const responseStyleKey = 'chat_response_style';
  static const savedPromptsKey = 'chat_saved_prompts';
  static const workspaceAliasKey = 'chat_workspace_alias';
  static const assistantNameKey = 'chat_assistant_name';
  static const personalizationFocusKey = 'chat_personalization_focus';

  static const defaultAssistantName = 'Gemini';

  static const defaultSavedPrompts = [
    'Summarize this clearly with key takeaways.',
    'Write this in a professional tone.',
    'Explain this like I am a beginner.',
    'Turn this into a step-by-step plan.',
  ];

  static Future<AssistantPreferences> loadAssistantPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return AssistantPreferences(
      customInstructions: prefs.getString(customInstructionsKey) ?? '',
      responseStyle: prefs.getString(responseStyleKey) ?? 'Balanced',
      savedPrompts: prefs.getStringList(savedPromptsKey) ??
          List<String>.from(defaultSavedPrompts),
      workspaceAlias: prefs.getString(workspaceAliasKey) ?? '',
      assistantName: prefs.getString(assistantNameKey) ?? defaultAssistantName,
      personalizationFocus: prefs.getString(personalizationFocusKey) ?? '',
    );
  }

  static Future<void> saveAssistantPreferences({
    required String customInstructions,
    required String responseStyle,
    required List<String> savedPrompts,
    String workspaceAlias = '',
    String assistantName = defaultAssistantName,
    String personalizationFocus = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(customInstructionsKey, customInstructions);
    await prefs.setString(responseStyleKey, responseStyle);
    await prefs.setStringList(savedPromptsKey, savedPrompts);
    await prefs.setString(workspaceAliasKey, workspaceAlias);
    await prefs.setString(assistantNameKey, assistantName);
    await prefs.setString(personalizationFocusKey, personalizationFocus);
  }
}
