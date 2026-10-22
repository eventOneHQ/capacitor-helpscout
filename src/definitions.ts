import type { PluginListenerHandle } from '@capacitor/core';

/**
 * Screens that can be opened with {@link HelpScoutPlugin.navigate}.
 *
 * - `home`: the default Beacon home screen (iOS `BeaconRoute.home`, Android `BeaconScreens.DEFAULT`).
 * - `ask`: the "Ask" screen (requires Docs and Messaging).
 * - `askMessage`: the contact form (requires Messaging).
 * - `askChat`: the chat screen (requires Chat; falls back to the contact form).
 * - `answers`: the Docs answers screen (requires Docs).
 * - `aiAnswers`: the AI Answers screen (requires AI Answers).
 * - `previousMessages`: the previous messages screen (requires Messaging).
 */
export type BeaconScreen = 'home' | 'ask' | 'askMessage' | 'askChat' | 'answers' | 'aiAnswers' | 'previousMessages';

/**
 * Controls whether help articles or contact options are shown first.
 * Requires Docs and Messaging to be enabled.
 */
export type BeaconFocusMode = 'neutral' | 'selfService' | 'askFirst';

export interface InitOptions {
  /**
   * The ID of your Beacon, found in Beacon Builder.
   */
  beaconId: string;
  /**
   * Print developer logs to the native console (LogCat on Android).
   *
   * Android only.
   *
   * @default false
   */
  logsEnabled?: boolean;
}

export interface BeaconContactFormConfig {
  /**
   * Show custom fields in the contact form.
   *
   * On Android the four contact form options are applied together: any option you leave out is treated as enabled.
   */
  customFieldsEnabled?: boolean;
  /**
   * Show an editable name field.
   */
  showName?: boolean;
  /**
   * Show an editable subject field.
   */
  showSubject?: boolean;
  /**
   * Allow attachments to be added to the contact form.
   */
  allowAttachments?: boolean;
  /**
   * Show prefilled custom fields as editable. A saved draft takes precedence over prefilled values.
   */
  showPrefilledCustomFields?: boolean;
}

export interface BeaconConfig {
  /**
   * Enable or disable contact options. Cannot enable them if they are disabled in Beacon Builder.
   */
  messagingEnabled?: boolean;
  /**
   * Enable or disable Docs. Cannot enable it if it is disabled in Beacon Builder.
   */
  docsEnabled?: boolean;
  /**
   * Enable or disable Chat. Cannot enable it if it is disabled in Beacon Builder.
   */
  chatEnabled?: boolean;
  /**
   * Enable or disable the previous messages screen.
   */
  enablePreviousMessages?: boolean;
  /**
   * Primary brand color as a hex string, e.g. `#617DEC`.
   */
  color?: string;
  /**
   * Override the focus mode configured in Beacon Builder.
   */
  focusMode?: BeaconFocusMode;
  /**
   * Contact form overrides.
   */
  contactForm?: BeaconContactFormConfig;
  /**
   * Override Beacon labels. Values are limited to 160 characters. Keys match the JavaScript API translate keys.
   *
   * iOS only. On Android, override the `hs_beacon_*` string resources instead.
   */
  localizationOverrides?: Record<string, string>;
  /**
   * Load overrides from a `BeaconLocalizable.strings` file in the app bundle.
   *
   * iOS only.
   */
  useLocalTranslationOverrides?: boolean;
}

export interface OpenOptions {
  /**
   * Secure Mode signature, computed by your backend from the identified user's email.
   * Falls back to the signature passed to {@link HelpScoutPlugin.identify}.
   */
  signature?: string;
}

export interface NavigateOptions extends OpenOptions {
  /**
   * The screen to open.
   */
  screen: BeaconScreen;
}

export interface SearchOptions extends OpenOptions {
  /**
   * The Docs search term.
   */
  query: string;
}

export interface OpenArticleOptions extends OpenOptions {
  /**
   * The Docs article ID.
   */
  articleId: string;
}

export interface AskQuestionOptions extends OpenOptions {
  /**
   * A question that is automatically submitted to AI Answers.
   */
  question: string;
}

export interface IdentifyOptions {
  /**
   * The user's email address.
   */
  email: string;
  /**
   * The user's name (max 80 characters).
   */
  name?: string;
  /**
   * The user's company (max 60 characters).
   */
  company?: string;
  /**
   * The user's job title (max 60 characters).
   */
  jobTitle?: string;
  /**
   * URL of the user's avatar (max 200 characters).
   */
  avatar?: string;
  /**
   * Secure Mode signature, remembered and used for subsequent opens, searches, navigation and push handling.
   */
  signature?: string;
  /**
   * User attributes to set at the same time as identifying (max 30).
   */
  attributes?: Record<string, string>;
}

export interface LogoutOptions {
  /**
   * End any active chat when logging out.
   *
   * @default false
   */
  endActiveChat?: boolean;
}

export interface AttributeOptions {
  /**
   * Attribute key (max 100 characters). Letters, numbers, hyphens and underscores.
   * On Android it must match a Customer Property ID. `name` and `email` are reserved.
   */
  key: string;
  /**
   * Attribute value (max 255 characters).
   */
  value: string;
}

export interface RemoveAttributeOptions {
  /**
   * The key of the attribute to remove.
   */
  key: string;
}

export interface SessionAttributesOptions {
  /**
   * Up to 20 label/value pairs (label max 100 characters, value max 10,000). Not synced to the customer profile.
   */
  attributes: Record<string, string>;
}

export interface PrefilledAttachment {
  /**
   * File name shown in the contact form. Required on iOS.
   */
  filename: string;
  /**
   * Base64 encoded file contents. Preferred on iOS.
   * On Android the data is written to a temporary file and passed to Beacon as a `file://` URI.
   */
  data?: string;
  /**
   * URI of the file. On Android typically a `content://` URI. On iOS a `file://` URL.
   */
  uri?: string;
}

export interface PrefilledForm {
  /**
   * Prefilled name.
   */
  name?: string;
  /**
   * Prefilled email.
   */
  email?: string;
  /**
   * Prefilled subject.
   */
  subject?: string;
  /**
   * Prefilled message body.
   */
  message?: string;
  /**
   * Prefilled custom field values, keyed by custom field ID.
   */
  customFields?: Record<number, string>;
  /**
   * Prefilled attachments (max 3, each up to 10 MB).
   */
  attachments?: PrefilledAttachment[];
}

export interface ArticleSuggestion {
  type: 'article';
  /**
   * The Docs article ID.
   */
  articleId: string;
}

export interface LinkSuggestion {
  type: 'link';
  /**
   * The link URL.
   */
  url: string;
  /**
   * The label shown for the link.
   */
  text: string;
}

export type BeaconSuggestion = ArticleSuggestion | LinkSuggestion;

export interface SuggestionsOptions {
  /**
   * Up to 10 suggestions. Extra items are ignored. An empty list reverts to the Beacon Builder defaults.
   */
  suggestions: BeaconSuggestion[];
}

export interface PushTokenOptions {
  /**
   * On iOS the APNs device token as a hex string. On Android the Firebase Cloud Messaging token.
   */
  token: string;
}

export interface InitializePushOptions {
  /**
   * Let Beacon swizzle the app delegate to handle push registration and taps automatically.
   * Not supported with Secure Mode.
   *
   * iOS only.
   *
   * @default true
   */
  methodSwizzling?: boolean;
  /**
   * Let Beacon take over the `UNUserNotificationCenter` delegate.
   *
   * iOS only.
   *
   * @default true
   */
  overrideUserNotificationCenterDelegate?: boolean;
  /**
   * Forward the device token and registration errors that Capacitor receives to Beacon automatically.
   * Use this together with `@capacitor/push-notifications`.
   *
   * iOS only.
   *
   * @default true
   */
  forwardCapacitorRegistration?: boolean;
}

export interface FailedPushRegistrationOptions {
  /**
   * The registration error message.
   */
  message: string;
}

export interface PushPayloadOptions {
  /**
   * The push notification payload (the `userInfo` on iOS, the FCM message `data` on Android).
   */
  data: Record<string, any>;
}

export interface HandlePushOptions extends PushPayloadOptions {
  /**
   * Secure Mode signature. Falls back to the signature passed to {@link HelpScoutPlugin.identify}.
   */
  signature?: string;
}

export interface BeaconStatus {
  /**
   * Whether {@link HelpScoutPlugin.initialize} has been called.
   */
  initialized: boolean;
  /**
   * The Beacon ID, if initialized.
   */
  beaconId?: string;
  /**
   * The native Beacon SDK version.
   */
  version?: string;
  /**
   * Whether the Beacon SDK is enabled. Android only.
   */
  enabled?: boolean;
  /**
   * The identified user's email, if any.
   */
  email?: string;
  /**
   * Whether the current user has an email. Android only.
   */
  userHasEmail?: boolean;
  /**
   * Whether developer logs are enabled. Android only.
   */
  logsEnabled?: boolean;
  /**
   * Effective Docs setting, if known. Android only.
   */
  docsEnabled?: boolean;
  /**
   * Effective Chat setting, if known. Android only.
   */
  chatEnabled?: boolean;
  /**
   * Effective Messaging setting, if known. Android only.
   */
  messagingEnabled?: boolean;
  /**
   * Effective previous messages setting, if known. Android only.
   */
  previousMessagesEnabled?: boolean;
}

export interface BeaconOpenedEvent {
  /**
   * `true` the first time Beacon opens in an app session. iOS only.
   */
  initial?: boolean;
}

export interface BeaconClosedEvent {
  /**
   * `true` the first time Beacon closes in an app session. iOS only.
   */
  initial?: boolean;
}

export interface HelpScoutPlugin {
  /**
   * Initialize Beacon. Must be called before any other method.
   *
   * @since 0.0.1
   */
  initialize(options: InitOptions): Promise<void>;

  /**
   * Configure Beacon: feature toggles, color, focus mode, contact form and localization overrides.
   * Only the provided values are changed.
   *
   * @since 0.0.1
   */
  configure(options: BeaconConfig): Promise<void>;

  /**
   * Open Beacon on its default screen.
   *
   * @since 0.0.1
   */
  open(options?: OpenOptions): Promise<void>;

  /**
   * Close Beacon if it is currently displayed.
   *
   * @since 0.0.1
   */
  close(): Promise<void>;

  /**
   * Open Beacon on a specific screen.
   *
   * @since 0.0.1
   */
  navigate(options: NavigateOptions): Promise<void>;

  /**
   * Open Beacon and search Docs. Requires Docs.
   *
   * @since 0.0.1
   */
  search(options: SearchOptions): Promise<void>;

  /**
   * Open Beacon on a Docs article. Requires Docs.
   *
   * @since 0.0.1
   */
  openArticle(options: OpenArticleOptions): Promise<void>;

  /**
   * Open Beacon and submit a question to AI Answers. Requires AI Answers.
   *
   * @since 0.0.1
   */
  askQuestion(options: AskQuestionOptions): Promise<void>;

  /**
   * Associate subsequent Beacon sessions with a user.
   *
   * @since 0.0.1
   */
  identify(options: IdentifyOptions): Promise<void>;

  /**
   * Clear the identified user. The Beacon ID and configuration are kept.
   *
   * @since 0.0.1
   */
  logout(options?: LogoutOptions): Promise<void>;

  /**
   * Clear the draft contact form. Does not clear the identified name or email, use {@link HelpScoutPlugin.logout}
   * for that. Maps to `HSBeacon.reset()` on iOS and `Beacon.contactFormReset()` on Android.
   *
   * @since 0.0.1
   */
  reset(): Promise<void>;

  /**
   * Fully clear all Beacon data, including the identified user and attributes, and re-initialize Beacon
   * with the same Beacon ID.
   *
   * @since 0.0.1
   */
  clear(): Promise<void>;

  /**
   * Add a user attribute (max 30). Resolves with `added: false` when the limit is reached or the value is invalid.
   *
   * On iOS attributes are attached to the user created by {@link HelpScoutPlugin.identify}; attributes added
   * before identifying are kept and applied when you identify.
   *
   * @since 0.0.1
   */
  addAttribute(options: AttributeOptions): Promise<{ added: boolean }>;

  /**
   * Remove a user attribute.
   *
   * @since 0.0.1
   */
  removeAttribute(options: RemoveAttributeOptions): Promise<void>;

  /**
   * Remove all user attributes.
   *
   * @since 0.0.1
   */
  clearAttributes(): Promise<void>;

  /**
   * Set session attributes (max 20). They are sent with each conversation but not synced to the customer profile.
   * Resolves with `success: false` when more than 20 are given.
   *
   * @since 0.0.1
   */
  setSessionAttributes(options: SessionAttributesOptions): Promise<{ success: boolean }>;

  /**
   * Get the current session attributes.
   *
   * @since 0.0.1
   */
  getSessionAttributes(): Promise<{ attributes: Record<string, string> }>;

  /**
   * Prefill the contact form.
   *
   * @since 0.0.1
   */
  setPrefilledForm(options: PrefilledForm): Promise<void>;

  /**
   * Remove any prefilled contact form values.
   *
   * @since 0.0.1
   */
  clearPrefilledForm(): Promise<void>;

  /**
   * Override the suggested articles and links shown in Beacon (max 10). Pass an empty list to revert
   * to the Beacon Builder defaults. Suggestions load when Beacon is displayed.
   *
   * @since 0.0.1
   */
  setSuggestions(options: SuggestionsOptions): Promise<void>;

  /**
   * Revert suggestions to the Beacon Builder defaults.
   *
   * @since 0.0.1
   */
  resetSuggestions(): Promise<void>;

  /**
   * Prepare push notification support.
   *
   * On iOS this initializes automatic push handling. On Android it is a no-op because Beacon registers its
   * Firebase messaging service automatically.
   *
   * @since 0.0.1
   */
  initializePushNotifications(options?: InitializePushOptions): Promise<void>;

  /**
   * Give Beacon the push token: the APNs token (hex) on iOS or the FCM token on Android.
   *
   * @since 0.0.1
   */
  setPushToken(options: PushTokenOptions): Promise<void>;

  /**
   * Tell Beacon that registering for remote notifications failed. iOS only, no-op on Android.
   *
   * @since 0.0.1
   */
  failedToRegisterForPushNotifications(options: FailedPushRegistrationOptions): Promise<void>;

  /**
   * Check whether a push payload belongs to Beacon.
   *
   * @since 0.0.1
   */
  isBeaconPushNotification(options: PushPayloadOptions): Promise<{ value: boolean }>;

  /**
   * Hand a Beacon push payload to Beacon so it opens the right conversation.
   * Resolves with `handled: false` if the payload is not a Beacon notification.
   *
   * @since 0.0.1
   */
  handlePushNotification(options: HandlePushOptions): Promise<{ handled: boolean }>;

  /**
   * Get the current state of the Beacon SDK.
   *
   * @since 0.0.1
   */
  getStatus(): Promise<BeaconStatus>;

  /**
   * Called when Beacon is opened.
   *
   * @since 0.0.1
   */
  addListener(
    eventName: 'beaconOpened',
    listenerFunc: (event: BeaconOpenedEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Called when Beacon is closed.
   *
   * @since 0.0.1
   */
  addListener(
    eventName: 'beaconClosed',
    listenerFunc: (event: BeaconClosedEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Remove all listeners for this plugin.
   *
   * @since 0.0.1
   */
  removeAllListeners(): Promise<void>;
}
