import Foundation
import UIKit
import Capacitor
import Beacon

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(HelpScoutPlugin)
public class HelpScoutPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "HelpScoutPlugin"
    public let jsName = "HelpScout"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "navigate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "search", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openArticle", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "askQuestion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "identify", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "logout", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reset", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clear", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "addAttribute", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeAttribute", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearAttributes", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setSessionAttributes", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getSessionAttributes", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPrefilledForm", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearPrefilledForm", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setSuggestions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resetSuggestions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "initializePushNotifications", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPushToken", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "failedToRegisterForPushNotifications", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isBeaconPushNotification", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "handlePushNotification", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = HelpScout()

    override public func load() {
        implementation.onEvent = { [weak self] name, data in
            self?.notifyListeners(name, data: data)
        }
    }

    /// Runs `body` on the main thread and rejects the call if it throws.
    private func onMain(_ call: CAPPluginCall, _ body: @escaping () throws -> Void) {
        DispatchQueue.main.async {
            do {
                try body()
                call.resolve()
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    private func requiredString(_ call: CAPPluginCall, _ key: String) -> String? {
        guard let value = call.getString(key) else {
            call.reject("\(key) must be provided.")
            return nil
        }
        return value
    }

    private func stringMap(_ object: JSObject?) -> [String: String] {
        var result: [String: String] = [:]
        object?.forEach { key, value in
            if let string = value as? String {
                result[key] = string
            }
        }
        return result
    }

    // MARK: - Setup

    @objc func initialize(_ call: CAPPluginCall) {
        guard let beaconId = requiredString(call, "beaconId") else { return }
        implementation.initialize(beaconId: beaconId)
        call.resolve()
    }

    @objc func configure(_ call: CAPPluginCall) {
        var contactForm: [String: Bool] = [:]
        if let form = call.getObject("contactForm") {
            for key in ["customFieldsEnabled", "showName", "showSubject", "allowAttachments", "showPrefilledCustomFields"] {
                if let value = form[key] as? Bool {
                    contactForm[key] = value
                }
            }
        }
        let config = HelpScoutConfig(
            messagingEnabled: call.getBool("messagingEnabled"),
            docsEnabled: call.getBool("docsEnabled"),
            chatEnabled: call.getBool("chatEnabled"),
            enablePreviousMessages: call.getBool("enablePreviousMessages"),
            color: call.getString("color"),
            focusMode: call.getString("focusMode"),
            contactForm: contactForm,
            localizationOverrides: call.getObject("localizationOverrides").map { stringMap($0) },
            useLocalTranslationOverrides: call.getBool("useLocalTranslationOverrides")
        )
        onMain(call) {
            try self.implementation.configure(config)
        }
    }

    // MARK: - Presenting

    @objc func open(_ call: CAPPluginCall) {
        onMain(call) {
            try self.implementation.open(signature: call.getString("signature"), from: self.bridge?.viewController)
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.implementation.close(from: self.bridge?.viewController) { call.resolve() }
        }
    }

    @objc func navigate(_ call: CAPPluginCall) {
        guard let name = requiredString(call, "screen") else { return }
        guard let screen = HelpScoutScreen(rawValue: name) else {
            call.reject("Unknown screen '\(name)'.")
            return
        }
        onMain(call) {
            try self.implementation.navigate(screen: screen, signature: call.getString("signature"), from: self.bridge?.viewController)
        }
    }

    @objc func search(_ call: CAPPluginCall) {
        guard let query = requiredString(call, "query") else { return }
        onMain(call) {
            try self.implementation.search(query: query, signature: call.getString("signature"), from: self.bridge?.viewController)
        }
    }

    @objc func openArticle(_ call: CAPPluginCall) {
        guard let articleId = requiredString(call, "articleId") else { return }
        onMain(call) {
            try self.implementation.openArticle(articleId: articleId, signature: call.getString("signature"), from: self.bridge?.viewController)
        }
    }

    @objc func askQuestion(_ call: CAPPluginCall) {
        guard let question = requiredString(call, "question") else { return }
        onMain(call) {
            try self.implementation.askQuestion(question: question, signature: call.getString("signature"), from: self.bridge?.viewController)
        }
    }

    // MARK: - Identity

    @objc func identify(_ call: CAPPluginCall) {
        guard let email = requiredString(call, "email") else { return }
        let attributes = stringMap(call.getObject("attributes"))
        let identity = HelpScoutUser(
            email: email,
            name: call.getString("name"),
            company: call.getString("company"),
            jobTitle: call.getString("jobTitle"),
            avatar: call.getString("avatar"),
            signature: call.getString("signature"),
            attributes: attributes
        )
        onMain(call) {
            self.implementation.identify(identity)
        }
    }

    @objc func logout(_ call: CAPPluginCall) {
        let endActiveChat = call.getBool("endActiveChat") ?? false
        onMain(call) {
            self.implementation.logout(endActiveChat: endActiveChat)
        }
    }

    @objc func reset(_ call: CAPPluginCall) {
        onMain(call) {
            self.implementation.reset()
        }
    }

    @objc func clear(_ call: CAPPluginCall) {
        onMain(call) {
            self.implementation.clear()
        }
    }

    @objc func addAttribute(_ call: CAPPluginCall) {
        guard let key = requiredString(call, "key"), let value = requiredString(call, "value") else { return }
        DispatchQueue.main.async {
            call.resolve(["added": self.implementation.addAttribute(key: key, value: value)])
        }
    }

    @objc func removeAttribute(_ call: CAPPluginCall) {
        guard let key = requiredString(call, "key") else { return }
        onMain(call) {
            self.implementation.removeAttribute(key: key)
        }
    }

    @objc func clearAttributes(_ call: CAPPluginCall) {
        onMain(call) {
            self.implementation.clearAttributes()
        }
    }

    // MARK: - Session attributes and prefill

    @objc func setSessionAttributes(_ call: CAPPluginCall) {
        guard let attributes = call.getObject("attributes") else {
            call.reject("attributes must be provided.")
            return
        }
        call.resolve(["success": implementation.setSessionAttributes(stringMap(attributes))])
    }

    @objc func getSessionAttributes(_ call: CAPPluginCall) {
        call.resolve(["attributes": implementation.getSessionAttributes()])
    }

    @objc func setPrefilledForm(_ call: CAPPluginCall) {
        var prefill = HelpScoutPrefill()
        prefill.name = call.getString("name")
        prefill.email = call.getString("email")
        prefill.subject = call.getString("subject")
        prefill.message = call.getString("message")

        call.getObject("customFields")?.forEach { key, value in
            if let fieldId = Int(key), let text = value as? String {
                prefill.customFields[fieldId] = text
            }
        }

        for case let item as JSObject in call.getArray("attachments") ?? [] {
            guard let filename = item["filename"] as? String else {
                call.reject("Each attachment needs a filename.")
                return
            }
            if let encoded = item["data"] as? String, let data = Data(base64Encoded: encoded) {
                prefill.attachments.append(HelpScoutAttachment(filename: filename, data: data))
            } else if let uri = item["uri"] as? String,
                      let url = URL(string: uri),
                      let data = try? Data(contentsOf: url) {
                prefill.attachments.append(HelpScoutAttachment(filename: filename, data: data))
            } else {
                call.reject("Attachment '\(filename)' needs valid base64 data or a readable file uri.")
                return
            }
        }

        implementation.setPrefill(prefill)
        call.resolve()
    }

    @objc func clearPrefilledForm(_ call: CAPPluginCall) {
        implementation.setPrefill(nil)
        call.resolve()
    }

}

extension HelpScoutPlugin {
    // MARK: - Suggestions

    @objc func setSuggestions(_ call: CAPPluginCall) {
        var items: [HSBeaconSuggestionItem] = []
        for case let item as JSObject in call.getArray("suggestions") ?? [] {
            switch item["type"] as? String {
            case "article":
                guard let articleId = item["articleId"] as? String else {
                    call.reject("Article suggestions need an articleId.")
                    return
                }
                items.append(HSBeaconArticleSuggestion(id: articleId))
            case "link":
                guard let text = item["text"] as? String,
                      let urlString = item["url"] as? String,
                      let url = URL(string: urlString) else {
                    call.reject("Link suggestions need a valid url and text.")
                    return
                }
                items.append(HSBeaconLinkSuggestion(url: url, text: text))
            default:
                call.reject("Unknown suggestion type.")
                return
            }
        }
        onMain(call) {
            self.implementation.setSuggestions(items)
        }
    }

    @objc func resetSuggestions(_ call: CAPPluginCall) {
        onMain(call) {
            self.implementation.resetSuggestions()
        }
    }

    // MARK: - Push notifications

    @objc func initializePushNotifications(_ call: CAPPluginCall) {
        onMain(call) {
            self.implementation.initializePushNotifications(
                methodSwizzling: call.getBool("methodSwizzling") ?? true,
                overrideUserNotificationCenterDelegate: call.getBool("overrideUserNotificationCenterDelegate") ?? true,
                forwardCapacitorRegistration: call.getBool("forwardCapacitorRegistration") ?? true
            )
        }
    }

    @objc func setPushToken(_ call: CAPPluginCall) {
        guard let token = requiredString(call, "token") else { return }
        onMain(call) {
            try self.implementation.setPushToken(hex: token)
        }
    }

    @objc func failedToRegisterForPushNotifications(_ call: CAPPluginCall) {
        guard let message = requiredString(call, "message") else { return }
        onMain(call) {
            self.implementation.failedToRegisterForPushNotifications(message: message)
        }
    }

    @objc func isBeaconPushNotification(_ call: CAPPluginCall) {
        guard let data = call.getObject("data") else {
            call.reject("data must be provided.")
            return
        }
        call.resolve(["value": implementation.isBeaconPushNotification(data)])
    }

    @objc func handlePushNotification(_ call: CAPPluginCall) {
        guard let data = call.getObject("data") else {
            call.reject("data must be provided.")
            return
        }
        DispatchQueue.main.async {
            do {
                let handled = try self.implementation.handlePushNotification(
                    userInfo: data,
                    signature: call.getString("signature"),
                    from: self.bridge?.viewController
                )
                call.resolve(["handled": handled])
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    // MARK: - Status

    @objc func getStatus(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            call.resolve(self.implementation.status())
        }
    }
}
