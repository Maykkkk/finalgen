# AI App Roadmap

This roadmap turns the current Gemini-powered Flutter chat app into a fuller assistant product while keeping the current API integration path intact.

Current rule:
- Keep `GeminiGenerateCall` as the active LLM integration.
- Build new features around UI, Firestore data, local app behavior, and reusable presentation components.
- Avoid backend changes unless explicitly needed later.

## Current App Snapshot

Working now:
- Auth and onboarding
- Chat list and single chat screen
- Gemini direct API call
- Firestore chat/message persistence
- Basic responsive dark UI

Known gaps:
- No markdown or code rendering
- No structured message actions beyond copy/regenerate
- No truncated-answer continuation flow
- No chat rename/delete/search UX
- No saved prompts or custom instructions
- No settings page or assistant preferences
- No file/image workflow
- No product-level organization or memory controls

## Build Strategy

Implementation order:
1. Stabilize and harden the current chat flow
2. Add must-have assistant UX
3. Add content rendering and response tooling
4. Add chat organization and settings
5. Add productivity features
6. Add deeper polish and scale-readiness

Reason for this order:
- It protects the working Gemini path
- It fixes high-friction issues first
- It avoids building advanced features on unstable message behavior

## Phase 1: Stability and Reliability

Goal:
- Make the current chat experience dependable before adding more product features

User-facing outcomes:
- Full responses display reliably
- Better handling for long answers
- Fewer broken sends or confusing loading states
- Cleaner recovery from API errors

Tasks:
- Add auto-continue flow when Gemini returns `finishReason == MAX_TOKENS`
- Normalize and store richer API metadata per message if useful
- Prevent duplicate sends from rapid taps or repeated enter presses
- Improve loading state messaging in the chat thread
- Make response updates robust when network/API calls fail
- Improve scroll behavior during new messages and regenerated replies
- Tighten null/error parsing in chat response handling

Likely files:
- `lib/backend/api_requests/api_calls.dart`
- `lib/chat_page/chat_page_widget.dart`
- `lib/chat_page/chat_page_model.dart`
- `lib/backend/schema/messages_record.dart`

Definition of done:
- Long answers no longer silently stop without a way to continue
- Retry/regenerate works consistently
- Errors are human-readable
- Message ordering and scrolling feel solid on web and mobile

## Phase 2: Core Assistant UX

Goal:
- Add the features users expect from a serious AI assistant app

User-facing outcomes:
- Chat feels closer to ChatGPT/Gemini
- Common actions are accessible directly from messages and chats

Tasks:
- Rename chat
- Delete chat
- Search chats
- Pin/star chats
- Better empty states and starter prompts
- Edit-and-resend prompt flow
- Continue generating button
- Improve regenerate flow so it can reuse the last prompt intentionally
- Add quick action chips under the composer
- Add clearer “AI is thinking” and error cards

Likely files:
- `lib/chat_page/chat_page_widget.dart`
- `lib/backend/schema/chats_record.dart`
- `lib/backend/backend.dart`

Data model additions:
- `ChatsRecord.pinned`
- `ChatsRecord.archived`
- `ChatsRecord.lastMessagePreview`
- `ChatsRecord.lastUsedPrompt`

Definition of done:
- Users can manage chats without touching Firestore manually
- Core chat actions are available in the main UI

## Phase 3: Rich Response Rendering

Goal:
- Make model output look polished and useful

User-facing outcomes:
- Headings, bullets, code, and structured text render properly
- Responses are easier to scan and copy

Tasks:
- Add markdown-style rendering
- Render fenced code blocks with a styled container
- Add copy-code action per code block
- Style ordered and unordered lists
- Style inline code and emphasis
- Render tables gracefully or fall back well
- Add response section spacing and better typography

Likely files:
- `lib/chat_page/chat_page_widget.dart`
- `pubspec.yaml`

Possible dependencies:
- `flutter_markdown`
- or a lighter markdown renderer depending on fit

Definition of done:
- Technical or structured answers look meaningfully better than plain text

## Phase 4: Prompting and Personalization

Goal:
- Make the assistant more useful for repeated real-world workflows

User-facing outcomes:
- Users can save useful prompts
- Users can steer assistant tone and style

Tasks:
- Saved prompt library
- Prompt categories like writing, coding, planning, study
- Custom instructions
- Tone selector: concise, balanced, detailed
- Output mode selector: plain text, bullets, step-by-step
- Creative vs factual slider or preset
- Starter workspace cards on empty/new chat screens

Likely files:
- new settings/prompt widgets under `lib/`
- `lib/chat_page/chat_page_widget.dart`
- `lib/backend/schema/users_record.dart`

Data model additions:
- user custom instructions
- saved prompts collection or embedded list
- preferred assistant style

Definition of done:
- Users can personalize assistant behavior without changing the model integration

## Phase 5: Chat Organization and Productivity

Goal:
- Turn the app into a practical AI workspace

User-facing outcomes:
- Easier management of many chats
- Faster reuse of assistant output

Tasks:
- Archive chats
- Favorites/starred messages
- Export conversation
- Share conversation view
- Auto-generated chat titles
- Better recent chat previews
- Project/folder grouping
- Tagging chats
- Search within message history

Likely files:
- `lib/chat_page/chat_page_widget.dart`
- new widgets under `lib/chat_page/`
- `lib/backend/schema/chats_record.dart`
- `lib/backend/schema/messages_record.dart`

Definition of done:
- Users can keep many conversations organized without the app feeling cluttered

## Phase 6: Attachments and Rich Inputs

Goal:
- Expand beyond plain text input

User-facing outcomes:
- More flexible assistant use cases

Tasks:
- Attach file button UX
- Image upload or preview flow
- Paste large text modal
- Summarize/import pasted notes
- Multi-input composer layout

Important note:
- Gemini support for files/images can be layered later, but the UI and local flow can be built first without disrupting the current text integration.

Likely files:
- `lib/chat_page/chat_page_widget.dart`
- `pubspec.yaml`
- potentially new utility files

Definition of done:
- The app UI supports richer input workflows cleanly

## Phase 7: Settings, Profile, and App Shell

Goal:
- Make the product feel complete beyond the chat screen

User-facing outcomes:
- Users can control app behavior and preferences

Tasks:
- Settings page
- Profile page
- Theme preferences
- Assistant preferences
- Data/privacy guidance
- Keyboard shortcuts help
- Better onboarding guidance

Likely files:
- new pages under `lib/`
- router updates
- `lib/main.dart`
- `lib/flutter_flow/nav/nav.dart`

Definition of done:
- The app feels like a full product, not just a single screen

## Phase 8: Polish and Quality

Goal:
- Prepare for a more production-like experience

Tasks:
- Accessibility pass
- Empty/loading/error state consistency
- Keyboard navigation on web
- Better animation timing
- Performance cleanup
- Firestore read/write optimization
- More focused tests for core chat flows

Definition of done:
- The app feels polished and resilient across devices

## Recommended Immediate Sprint

This is the best next build batch for the current repo:

1. Add auto-continue for truncated Gemini responses
2. Add markdown and code block rendering
3. Add rename/delete/search chat features
4. Add saved prompts and custom instructions
5. Add a basic settings page

Why this sprint:
- It solves current pain first
- It adds high-value assistant features quickly
- It keeps work concentrated in the existing chat architecture

## File-by-File Ownership Map

Primary chat surface:
- `lib/chat_page/chat_page_widget.dart`
- `lib/chat_page/chat_page_model.dart`

LLM call layer:
- `lib/backend/api_requests/api_calls.dart`
- `lib/backend/api_requests/api_manager.dart`

Theme/app shell:
- `lib/flutter_flow/flutter_flow_theme.dart`
- `lib/main.dart`

Firestore models:
- `lib/backend/schema/chats_record.dart`
- `lib/backend/schema/messages_record.dart`
- `lib/backend/schema/users_record.dart`

Auth and onboarding:
- `lib/on_boarding/on_boarding_widget.dart`
- `lib/login_page/login_page_widget.dart`
- `lib/creat_account/creat_account_widget.dart`

## Guardrails

Do not change unless explicitly needed:
- The active Gemini API mechanism
- The `--dart-define=GEMINI_API_KEY=...` flow
- The current chat persistence pattern

Prefer to improve through:
- Better message formatting
- Better state handling
- Better Firestore data shape
- Reusable widgets and helper methods

## Success Criteria

The app should eventually feel like:
- a polished AI chat product
- easy to use on web and mobile
- able to handle longer conversations
- good enough for writing, coding, planning, and study
- structured to support future model options later without rewriting the app
