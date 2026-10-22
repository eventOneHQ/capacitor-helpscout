package io.event1.plugins.helpscout

import android.app.Activity
import android.app.Application
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.util.Base64
import com.helpscout.beacon.Beacon
import com.helpscout.beacon.model.BeaconConfigOverrides
import com.helpscout.beacon.model.BeaconScreens
import com.helpscout.beacon.model.ContactFormConfig
import com.helpscout.beacon.model.FocusMode
import com.helpscout.beacon.model.PreFilledForm
import com.helpscout.beacon.model.SuggestedArticle
import com.helpscout.beacon.ui.BeaconActivity
import com.helpscout.beacon.ui.BeaconEventLifecycleHandler
import com.helpscout.beacon.ui.BeaconOnClosedListener
import com.helpscout.beacon.ui.BeaconOnOpenedListener
import com.helpscout.beacon.ui.BeaconPushNotificationsProcessor
import java.io.File
import java.lang.ref.WeakReference
import java.util.UUID

class HelpScoutException(message: String) : Exception(message)

/** Screens that map onto a Beacon route without any arguments. */
enum class HelpScoutScreen(val jsName: String, val beaconScreen: BeaconScreens) {
    HOME("home", BeaconScreens.DEFAULT),
    ASK("ask", BeaconScreens.ASK),
    ASK_MESSAGE("askMessage", BeaconScreens.CONTACT_FORM_SCREEN),
    ASK_CHAT("askChat", BeaconScreens.CHAT),
    ANSWERS("answers", BeaconScreens.ANSWERS),
    AI_ANSWERS("aiAnswers", BeaconScreens.AI_ANSWERS),
    PREVIOUS_MESSAGES("previousMessages", BeaconScreens.PREVIOUS_MESSAGES);

    companion object {
        fun fromJsName(name: String): HelpScoutScreen? = values().firstOrNull { it.jsName == name }
    }
}

data class HelpScoutAttachment(val filename: String, val data: String?, val uri: String?)

data class HelpScoutPrefill(
    val name: String?,
    val email: String?,
    val subject: String?,
    val message: String?,
    val customFields: Map<Int, String>,
    val attachments: List<HelpScoutAttachment>
)

sealed class HelpScoutSuggestion {
    data class Article(val articleId: String) : HelpScoutSuggestion()
    data class Link(val url: String, val text: String) : HelpScoutSuggestion()
}

class HelpScout(private val context: Context) {
    private var beaconId: String? = null
    private var logsEnabled = false
    private var signature: String? = null

    // Config override state. Beacon applies overrides as a single object, so every field is remembered here.
    private var docsEnabled: Boolean? = null
    private var messagingEnabled: Boolean? = null
    private var chatEnabled: Boolean? = null
    private var enablePreviousMessages = true
    private var color: String? = null
    private var focusMode: FocusMode? = null
    private var contactForm: ContactFormConfig? = null

    private var currentBeaconActivity: WeakReference<Activity>? = null

    val isInitialized: Boolean
        get() = beaconId != null

    // region Setup

    fun initialize(beaconId: String, logsEnabled: Boolean) {
        this.beaconId = beaconId
        this.logsEnabled = logsEnabled
        build()
    }

    private fun build() {
        val id = beaconId ?: throw HelpScoutException(NOT_INITIALIZED)
        Beacon.Builder()
            .withBeaconId(id)
            .withLogsEnabled(logsEnabled)
            .withContext(context)
            .build()
    }

    private fun requireInitialized() {
        if (beaconId == null) throw HelpScoutException(NOT_INITIALIZED)
    }

    @Suppress("LongParameterList")
    fun configure(
        messagingEnabled: Boolean?,
        docsEnabled: Boolean?,
        chatEnabled: Boolean?,
        enablePreviousMessages: Boolean?,
        color: String?,
        focusMode: String?,
        contactForm: Map<String, Boolean>
    ) {
        requireInitialized()

        messagingEnabled?.let { this.messagingEnabled = it }
        docsEnabled?.let { this.docsEnabled = it }
        chatEnabled?.let { this.chatEnabled = it }
        enablePreviousMessages?.let { this.enablePreviousMessages = it }
        color?.let {
            try {
                Color.parseColor(it)
            } catch (e: IllegalArgumentException) {
                throw HelpScoutException("Invalid color '$it'. Use a hex string such as #617DEC.")
            }
            this.color = it
        }
        focusMode?.let {
            this.focusMode = when (it) {
                "neutral" -> FocusMode.NEUTRAL
                "selfService" -> FocusMode.SELF_SERVICE
                "askFirst" -> FocusMode.ASK_FIRST
                else -> throw HelpScoutException("Invalid focusMode '$it'.")
            }
        }

        val formKeys = listOf("showName", "showSubject", "allowAttachments", "customFieldsEnabled")
        if (formKeys.any { contactForm.containsKey(it) }) {
            val previous = this.contactForm
            this.contactForm = ContactFormConfig(
                contactForm["showName"] ?: previous?.showName ?: true,
                contactForm["showSubject"] ?: previous?.showSubject ?: true,
                contactForm["allowAttachments"] ?: previous?.allowAttachments ?: true,
                contactForm["customFieldsEnabled"] ?: previous?.customFieldsEnabled ?: true
            )
        }

        Beacon.setConfigOverrides(
            BeaconConfigOverrides(
                this.docsEnabled,
                this.messagingEnabled,
                this.chatEnabled,
                this.contactForm,
                this.color,
                this.focusMode,
                this.enablePreviousMessages
            )
        )

        contactForm["showPrefilledCustomFields"]?.let { Beacon.showPrefilledCustomFields(it) }
    }

    // endregion

    // region Presenting

    fun open(activity: Activity, signature: String?) {
        present(activity, signature, BeaconScreens.DEFAULT, null)
    }

    fun navigate(activity: Activity, screen: HelpScoutScreen, signature: String?) {
        present(activity, signature, screen.beaconScreen, null)
    }

    fun search(activity: Activity, query: String, signature: String?) {
        present(activity, signature, BeaconScreens.SEARCH_SCREEN, arrayListOf(query))
    }

    fun openArticle(activity: Activity, articleId: String, signature: String?) {
        present(activity, signature, BeaconScreens.ARTICLE_SCREEN, arrayListOf(articleId))
    }

    fun askQuestion(activity: Activity, question: String, signature: String?) {
        present(activity, signature, BeaconScreens.ASK_QUESTION, arrayListOf(question))
    }

    private fun present(activity: Activity, signature: String?, screen: BeaconScreens, args: ArrayList<String>?) {
        requireInitialized()
        val effectiveSignature = signature ?: this.signature
        val arguments = args ?: arrayListOf()
        if (effectiveSignature != null) {
            BeaconActivity.openInSecureMode(activity, effectiveSignature, screen, arguments)
        } else {
            BeaconActivity.open(activity, screen, arguments)
        }
    }

    /** Beacon has no close API, so the BeaconActivity is tracked through activity lifecycle callbacks. */
    fun close() {
        currentBeaconActivity?.get()?.finish()
        currentBeaconActivity = null
    }

    /**
     * Registers lifecycle callbacks that report when Beacon opens and closes and keep track of the Beacon activity.
     */
    fun registerLifecycleCallbacks(application: Application, onOpened: () -> Unit, onClosed: () -> Unit) {
        application.registerActivityLifecycleCallbacks(
            BeaconEventLifecycleHandler(
                object : BeaconOnOpenedListener {
                    override fun onOpened() = onOpened()
                },
                object : BeaconOnClosedListener {
                    override fun onClosed() = onClosed()
                }
            )
        )
        application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                if (activity is BeaconActivity) currentBeaconActivity = WeakReference(activity)
            }

            override fun onActivityDestroyed(activity: Activity) {
                if (currentBeaconActivity?.get() === activity) currentBeaconActivity = null
            }

            override fun onActivityStarted(activity: Activity) = Unit
            override fun onActivityResumed(activity: Activity) = Unit
            override fun onActivityPaused(activity: Activity) = Unit
            override fun onActivityStopped(activity: Activity) = Unit
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
        })
    }

    // endregion

    // region Identity

    fun identify(
        email: String,
        name: String?,
        company: String?,
        jobTitle: String?,
        avatar: String?,
        signature: String?,
        attributes: Map<String, String>
    ) {
        requireInitialized()
        when {
            company == null && jobTitle == null && avatar == null && name == null -> Beacon.identify(email)
            company == null && jobTitle == null && avatar == null -> Beacon.identify(email, name.orEmpty())
            else -> Beacon.identify(email, name.orEmpty(), company.orEmpty(), jobTitle.orEmpty(), avatar.orEmpty())
        }
        this.signature = signature
        attributes.forEach { (key, value) -> Beacon.addAttributeWithKey(key, value) }
    }

    fun logout(endActiveChat: Boolean) {
        requireInitialized()
        Beacon.logout(endActiveChat)
        signature = null
    }

    fun reset() {
        requireInitialized()
        Beacon.contactFormReset()
    }

    fun clear() {
        requireInitialized()
        Beacon.clear()
        signature = null
        build()
    }

    fun addAttribute(key: String, value: String): Boolean {
        requireInitialized()
        return Beacon.addAttributeWithKey(key, value)
    }

    fun removeAttribute(key: String) {
        requireInitialized()
        Beacon.removeAttribute(key)
    }

    fun clearAttributes() {
        requireInitialized()
        Beacon.clearAttributes()
    }

    // endregion

    // region Session attributes and prefill

    fun setSessionAttributes(attributes: Map<String, String>): Boolean {
        requireInitialized()
        return Beacon.setSessionAttributes(attributes)
    }

    fun getSessionAttributes(): Map<String, String> {
        requireInitialized()
        return Beacon.getSessionAttributes() ?: emptyMap()
    }

    fun setPrefill(prefill: HelpScoutPrefill?) {
        requireInitialized()
        if (prefill == null) {
            Beacon.addPreFilledForm(PreFilledForm())
            return
        }
        val attachmentUris = prefill.attachments.map { attachmentUri(it) }
        Beacon.addPreFilledForm(
            PreFilledForm(
                prefill.name.orEmpty(),
                prefill.subject.orEmpty(),
                prefill.message.orEmpty(),
                prefill.customFields,
                attachmentUris,
                prefill.email.orEmpty()
            )
        )
    }

    /** Beacon wants URIs, so base64 data is written to the cache directory first. */
    private fun attachmentUri(attachment: HelpScoutAttachment): String {
        attachment.uri?.let { return it }
        val encoded = attachment.data ?: throw HelpScoutException("Attachment '${attachment.filename}' needs data or a uri.")
        val directory = File(context.cacheDir, "helpscout-attachments/${UUID.randomUUID()}").apply { mkdirs() }
        val file = File(directory, File(attachment.filename).name)
        file.writeBytes(Base64.decode(encoded, Base64.DEFAULT))
        return android.net.Uri.fromFile(file).toString()
    }

    // endregion

    // region Suggestions

    fun setSuggestions(suggestions: List<HelpScoutSuggestion>) {
        requireInitialized()
        if (suggestions.isEmpty()) {
            Beacon.resetSuggestedArticlesOverrides()
            return
        }
        Beacon.setOverrideSuggestedArticlesOrLinks(
            suggestions.take(MAX_SUGGESTIONS).map {
                when (it) {
                    is HelpScoutSuggestion.Article -> SuggestedArticle.SuggestedArticleWithId(it.articleId)
                    is HelpScoutSuggestion.Link -> SuggestedArticle.SuggestedArticleWithUrl(it.text, it.url)
                }
            }
        )
    }

    fun resetSuggestions() {
        requireInitialized()
        Beacon.resetSuggestedArticlesOverrides()
    }

    // endregion

    // region Push notifications

    fun setPushToken(token: String) {
        requireInitialized()
        Beacon.setFirebaseCloudMessagingToken(context, token)
    }

    fun isBeaconPushNotification(data: Map<String, String>): Boolean {
        return BeaconPushNotificationsProcessor.isBeaconNotification(data) == true
    }

    fun handlePushNotification(data: Map<String, String>): Boolean {
        requireInitialized()
        if (!isBeaconPushNotification(data)) return false
        return BeaconPushNotificationsProcessor().process(context, data)
    }

    // endregion

    // region Status

    fun status(): Map<String, Any?> {
        val id = beaconId ?: return mapOf("initialized" to false, "version" to safely { Beacon.version() })
        return mapOf(
            "initialized" to true,
            "beaconId" to id,
            "version" to safely { Beacon.version() },
            "enabled" to safely { Beacon.isEnabled() },
            "email" to safely { Beacon.email() }?.takeIf { it.isNotEmpty() },
            "userHasEmail" to safely { Beacon.userHasEmail() },
            "logsEnabled" to safely { Beacon.logsEnabled() },
            "docsEnabled" to safely { Beacon.docsEnabled() },
            "chatEnabled" to safely { Beacon.chatEnabled() },
            "messagingEnabled" to safely { Beacon.messagingEnabled() },
            "previousMessagesEnabled" to safely { Beacon.previousMessagesEnabled() }
        )
    }

    private fun <T> safely(block: () -> T): T? = try {
        block()
    } catch (e: Exception) {
        null
    }

    // endregion

    private companion object {
        const val NOT_INITIALIZED = "Beacon is not initialized. Call initialize() first."
        const val MAX_SUGGESTIONS = 10
    }
}
