package io.event1.plugins.helpscout

import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.json.JSONObject

@CapacitorPlugin(name = "HelpScout")
class HelpScoutPlugin : Plugin() {

    private lateinit var implementation: HelpScout

    override fun load() {
        implementation = HelpScout(context)
        implementation.registerLifecycleCallbacks(
            activity.application,
            onOpened = { notifyListeners("beaconOpened", JSObject()) },
            onClosed = { notifyListeners("beaconClosed", JSObject()) }
        )
    }

    /** Runs [block], resolving the call afterwards (with [block]'s result, if any) or rejecting on failure. */
    private fun run(call: PluginCall, block: () -> JSObject?) {
        try {
            val result = block()
            if (result != null) call.resolve(result) else call.resolve()
        } catch (e: HelpScoutException) {
            call.reject(e.message)
        } catch (e: Exception) {
            call.reject(e.message ?: e.javaClass.simpleName, e)
        }
    }

    /** Like [run], but executes [block] on the UI thread, as required for anything that shows an activity. */
    private fun runOnUi(call: PluginCall, block: () -> JSObject?) {
        activity.runOnUiThread { run(call, block) }
    }

    private fun requiredString(call: PluginCall, key: String): String? {
        val value = call.getString(key)
        if (value == null) call.reject("$key must be provided.")
        return value
    }

    private fun JSONObject?.toStringMap(): Map<String, String> {
        val result = mutableMapOf<String, String>()
        this?.keys()?.forEach { key ->
            val value = opt(key)
            if (value is String) result[key] = value
        }
        return result
    }

    private fun JSONObject?.toBooleanMap(keys: List<String>): Map<String, Boolean> {
        val result = mutableMapOf<String, Boolean>()
        if (this == null) return result
        keys.forEach { key ->
            val value = opt(key)
            if (value is Boolean) result[key] = value
        }
        return result
    }

    private fun Map<String, Any?>.toJSObject(): JSObject {
        val result = JSObject()
        forEach { (key, value) -> if (value != null) result.put(key, value) }
        return result
    }

    // region Setup

    @PluginMethod
    fun initialize(call: PluginCall) {
        val beaconId = requiredString(call, "beaconId") ?: return
        run(call) {
            implementation.initialize(beaconId, call.getBoolean("logsEnabled", false) ?: false)
            null
        }
    }

    @PluginMethod
    fun configure(call: PluginCall) {
        val contactForm = call.getObject("contactForm").toBooleanMap(
            listOf("customFieldsEnabled", "showName", "showSubject", "allowAttachments", "showPrefilledCustomFields")
        )
        run(call) {
            implementation.configure(
                messagingEnabled = call.getBoolean("messagingEnabled"),
                docsEnabled = call.getBoolean("docsEnabled"),
                chatEnabled = call.getBoolean("chatEnabled"),
                enablePreviousMessages = call.getBoolean("enablePreviousMessages"),
                color = call.getString("color"),
                focusMode = call.getString("focusMode"),
                contactForm = contactForm
            )
            null
        }
    }

    // endregion

    // region Presenting

    @PluginMethod
    fun open(call: PluginCall) {
        runOnUi(call) {
            implementation.open(activity, call.getString("signature"))
            null
        }
    }

    @PluginMethod
    fun close(call: PluginCall) {
        runOnUi(call) {
            implementation.close()
            null
        }
    }

    @PluginMethod
    fun navigate(call: PluginCall) {
        val name = requiredString(call, "screen") ?: return
        val screen = HelpScoutScreen.fromJsName(name)
        if (screen == null) {
            call.reject("Unknown screen '$name'.")
            return
        }
        runOnUi(call) {
            implementation.navigate(activity, screen, call.getString("signature"))
            null
        }
    }

    @PluginMethod
    fun search(call: PluginCall) {
        val query = requiredString(call, "query") ?: return
        runOnUi(call) {
            implementation.search(activity, query, call.getString("signature"))
            null
        }
    }

    @PluginMethod
    fun openArticle(call: PluginCall) {
        val articleId = requiredString(call, "articleId") ?: return
        runOnUi(call) {
            implementation.openArticle(activity, articleId, call.getString("signature"))
            null
        }
    }

    @PluginMethod
    fun askQuestion(call: PluginCall) {
        val question = requiredString(call, "question") ?: return
        runOnUi(call) {
            implementation.askQuestion(activity, question, call.getString("signature"))
            null
        }
    }

    // endregion

    // region Identity

    @PluginMethod
    fun identify(call: PluginCall) {
        val email = requiredString(call, "email") ?: return
        val attributes = call.getObject("attributes").toStringMap()
        run(call) {
            implementation.identify(
                email = email,
                name = call.getString("name"),
                company = call.getString("company"),
                jobTitle = call.getString("jobTitle"),
                avatar = call.getString("avatar"),
                signature = call.getString("signature"),
                attributes = attributes
            )
            null
        }
    }

    @PluginMethod
    fun logout(call: PluginCall) {
        runOnUi(call) {
            implementation.logout(call.getBoolean("endActiveChat", false) ?: false)
            null
        }
    }

    @PluginMethod
    fun reset(call: PluginCall) {
        runOnUi(call) {
            implementation.reset()
            null
        }
    }

    @PluginMethod
    fun clear(call: PluginCall) {
        runOnUi(call) {
            implementation.clear()
            null
        }
    }

    @PluginMethod
    fun addAttribute(call: PluginCall) {
        val key = requiredString(call, "key") ?: return
        val value = requiredString(call, "value") ?: return
        run(call) { JSObject().put("added", implementation.addAttribute(key, value)) }
    }

    @PluginMethod
    fun removeAttribute(call: PluginCall) {
        val key = requiredString(call, "key") ?: return
        run(call) {
            implementation.removeAttribute(key)
            null
        }
    }

    @PluginMethod
    fun clearAttributes(call: PluginCall) {
        run(call) {
            implementation.clearAttributes()
            null
        }
    }

    // endregion

    // region Session attributes and prefill

    @PluginMethod
    fun setSessionAttributes(call: PluginCall) {
        val attributes = call.getObject("attributes")
        if (attributes == null) {
            call.reject("attributes must be provided.")
            return
        }
        run(call) { JSObject().put("success", implementation.setSessionAttributes(attributes.toStringMap())) }
    }

    @PluginMethod
    fun getSessionAttributes(call: PluginCall) {
        run(call) {
            val attributes = JSObject()
            implementation.getSessionAttributes().forEach { (key, value) -> attributes.put(key, value) }
            JSObject().put("attributes", attributes)
        }
    }

    @PluginMethod
    fun setPrefilledForm(call: PluginCall) {
        val customFields = mutableMapOf<Int, String>()
        val rawFields = call.getObject("customFields")
        rawFields?.keys()?.forEach { key ->
            val fieldId = key.toIntOrNull()
            val value = rawFields.opt(key)
            if (fieldId != null && value is String) customFields[fieldId] = value
        }

        val attachments = mutableListOf<HelpScoutAttachment>()
        val rawAttachments = call.getArray("attachments") ?: JSArray()
        for (index in 0 until rawAttachments.length()) {
            val item = rawAttachments.optJSONObject(index)
            val filename = item?.optString("filename")?.takeIf { it.isNotEmpty() }
            if (item == null || filename == null) {
                call.reject("Each attachment needs a filename.")
                return
            }
            attachments.add(
                HelpScoutAttachment(
                    filename,
                    item.optString("data").takeIf { it.isNotEmpty() },
                    item.optString("uri").takeIf { it.isNotEmpty() }
                )
            )
        }

        run(call) {
            implementation.setPrefill(
                HelpScoutPrefill(
                    name = call.getString("name"),
                    email = call.getString("email"),
                    subject = call.getString("subject"),
                    message = call.getString("message"),
                    customFields = customFields,
                    attachments = attachments
                )
            )
            null
        }
    }

    @PluginMethod
    fun clearPrefilledForm(call: PluginCall) {
        run(call) {
            implementation.setPrefill(null)
            null
        }
    }

    // endregion

    // region Suggestions

    @PluginMethod
    fun setSuggestions(call: PluginCall) {
        val raw = call.getArray("suggestions") ?: JSArray()
        val suggestions = mutableListOf<HelpScoutSuggestion>()
        for (index in 0 until raw.length()) {
            val item = raw.optJSONObject(index)
            when (item?.optString("type")) {
                "article" -> {
                    val articleId = item.optString("articleId").takeIf { it.isNotEmpty() }
                    if (articleId == null) {
                        call.reject("Article suggestions need an articleId.")
                        return
                    }
                    suggestions.add(HelpScoutSuggestion.Article(articleId))
                }
                "link" -> {
                    val url = item.optString("url").takeIf { it.isNotEmpty() }
                    val text = item.optString("text").takeIf { it.isNotEmpty() }
                    if (url == null || text == null) {
                        call.reject("Link suggestions need a url and text.")
                        return
                    }
                    suggestions.add(HelpScoutSuggestion.Link(url, text))
                }
                else -> {
                    call.reject("Unknown suggestion type.")
                    return
                }
            }
        }
        run(call) {
            implementation.setSuggestions(suggestions)
            null
        }
    }

    @PluginMethod
    fun resetSuggestions(call: PluginCall) {
        run(call) {
            implementation.resetSuggestions()
            null
        }
    }

    // endregion

    // region Push notifications

    /** Beacon registers its Firebase messaging service through the manifest, so there is nothing to set up. */
    @PluginMethod
    fun initializePushNotifications(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    fun setPushToken(call: PluginCall) {
        val token = requiredString(call, "token") ?: return
        run(call) {
            implementation.setPushToken(token)
            null
        }
    }

    /** iOS only. */
    @PluginMethod
    fun failedToRegisterForPushNotifications(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    fun isBeaconPushNotification(call: PluginCall) {
        val data = call.getObject("data")
        if (data == null) {
            call.reject("data must be provided.")
            return
        }
        run(call) { JSObject().put("value", implementation.isBeaconPushNotification(data.toStringMap())) }
    }

    @PluginMethod
    fun handlePushNotification(call: PluginCall) {
        val data = call.getObject("data")
        if (data == null) {
            call.reject("data must be provided.")
            return
        }
        runOnUi(call) { JSObject().put("handled", implementation.handlePushNotification(data.toStringMap())) }
    }

    // endregion

    // region Status

    @PluginMethod
    fun getStatus(call: PluginCall) {
        run(call) { implementation.status().toJSObject() }
    }

    // endregion
}
