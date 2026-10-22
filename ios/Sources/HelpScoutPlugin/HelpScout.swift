import Foundation
import UIKit
import UserNotifications
import Beacon

@objc public class HelpScout: NSObject, HSBeaconDelegate {
    /// Called with an event name and payload when Beacon opens or closes.
    var onEvent: ((String, [String: Any]) -> Void)?

    private var settings: HSBeaconSettings?
    private var user: HSBeaconUser?
    private var identified = false
    private var signature: String?
    private var sessionAttributesStore: [String: String] = [:]
    private var prefill: HelpScoutPrefill?
    private var registrationObservers: [NSObjectProtocol] = []
    private var closeEventCount = 0

    // MARK: - Setup

    func initialize(beaconId: String) {
        let newSettings = HSBeaconSettings(beaconId: beaconId)
        newSettings.delegate = self
        settings = newSettings
    }

    private func requireSettings() throws -> HSBeaconSettings {
        guard let settings = settings else {
            throw HelpScoutError.notInitialized
        }
        return settings
    }

    func configure(_ config: HelpScoutConfig) throws {
        try config.apply(to: requireSettings())
    }

    // MARK: - Presenting

    private func effectiveSignature(_ explicit: String?) -> String? {
        return explicit ?? signature
    }

    func open(signature: String?, from viewController: UIViewController?) throws {
        let settings = try requireSettings()
        let signature = effectiveSignature(signature)
        switch (viewController, signature) {
        case let (viewController?, signature?):
            HSBeacon.open(settings, from: viewController, signature: signature)
        case let (viewController?, nil):
            HSBeacon.open(settings, from: viewController)
        case let (nil, signature?):
            HSBeacon.open(settings, signature: signature)
        case (nil, nil):
            HSBeacon.open(settings)
        }
    }

    /// Dismisses Beacon by dismissing whatever the host view controller is presenting.
    /// `HSBeacon.dismiss` is not used because it never completes in Beacon 4.1.0.
    func close(from viewController: UIViewController?, completion: @escaping () -> Void) {
        guard let presented = viewController?.presentedViewController else {
            completion()
            return
        }
        let closeEventsBefore = closeEventCount
        presented.dismiss(animated: true) { [weak self] in
            // Beacon only reports closing when its own close button was used, so report it here otherwise.
            if let self = self, self.closeEventCount == closeEventsBefore {
                self.onEvent?("beaconClosed", ["initial": false])
            }
            completion()
        }
    }

    func navigate(screen: HelpScoutScreen, signature: String?, from viewController: UIViewController?) throws {
        try navigate(route: screen.route, signature: signature, from: viewController)
    }

    private func navigate(route: BeaconRoute, signature: String?, from viewController: UIViewController?) throws {
        let settings = try requireSettings()
        HSBeacon.navigate(route, settings: settings, viewController: viewController, signature: effectiveSignature(signature))
    }

    func search(query: String, signature: String?, from viewController: UIViewController?) throws {
        let settings = try requireSettings()
        let signature = effectiveSignature(signature)
        if let viewController = viewController {
            HSBeacon.search(query, beaconSettings: settings, viewController: viewController, signature: signature)
        } else {
            HSBeacon.search(query, beaconSettings: settings, signature: signature)
        }
    }

    func openArticle(articleId: String, signature: String?, from viewController: UIViewController?) throws {
        let settings = try requireSettings()
        let signature = effectiveSignature(signature)
        if let viewController = viewController {
            HSBeacon.openArticle(articleId, beaconSettings: settings, viewController: viewController, signature: signature)
        } else {
            HSBeacon.openArticle(articleId, beaconSettings: settings, signature: signature)
        }
    }

    func askQuestion(question: String, signature: String?, from viewController: UIViewController?) throws {
        let settings = try requireSettings()
        let signature = effectiveSignature(signature)
        if let viewController = viewController {
            HSBeacon.askQuestion(question, beaconSettings: settings, viewController: viewController, signature: signature)
        } else {
            HSBeacon.askQuestion(question, beaconSettings: settings, signature: signature)
        }
    }

    // MARK: - Identity

    func identify(_ identity: HelpScoutUser) {
        let beaconUser = user ?? HSBeaconUser()
        beaconUser.email = identity.email
        beaconUser.name = identity.name
        beaconUser.company = identity.company
        beaconUser.jobTitle = identity.jobTitle
        beaconUser.avatar = identity.avatar.flatMap { URL(string: $0) }
        beaconUser.signature = identity.signature
        for (key, value) in identity.attributes {
            _ = beaconUser.addAttribute(withKey: key, value: value)
        }
        user = beaconUser
        identified = true
        signature = identity.signature
        HSBeacon.identify(beaconUser)
    }

    func logout(endActiveChat: Bool) {
        HSBeacon.logout(endActiveChat)
        user = nil
        identified = false
        signature = nil
    }

    /// Clears the draft contact form without touching the identified user.
    func reset() {
        HSBeacon.reset()
    }

    /// Clears everything, including the identified user and attributes.
    func clear() {
        HSBeacon.logout(true)
        HSBeacon.reset()
        user = nil
        identified = false
        signature = nil
        prefill = nil
        sessionAttributesStore = [:]
        HSBeacon.suggest([])
    }

    func addAttribute(key: String, value: String) -> Bool {
        let beaconUser = user ?? HSBeaconUser()
        user = beaconUser
        let added = beaconUser.addAttribute(withKey: key, value: value)
        if identified && added {
            HSBeacon.identify(beaconUser)
        }
        return added
    }

    func removeAttribute(key: String) {
        guard let beaconUser = user else { return }
        beaconUser.removeAttribute(withKey: key)
        if identified {
            HSBeacon.identify(beaconUser)
        }
    }

    func clearAttributes() {
        guard let beaconUser = user else { return }
        beaconUser.clearAttributes()
        if identified {
            HSBeacon.identify(beaconUser)
        }
    }

    // MARK: - Session attributes and prefill

    func setSessionAttributes(_ attributes: [String: String]) -> Bool {
        guard attributes.count <= 20 else { return false }
        sessionAttributesStore = attributes
        return true
    }

    func getSessionAttributes() -> [String: String] {
        return sessionAttributesStore
    }

    func setPrefill(_ prefill: HelpScoutPrefill?) {
        self.prefill = prefill
    }

    // MARK: - Suggestions

    func setSuggestions(_ items: [HSBeaconSuggestionItem]) {
        HSBeacon.suggest(with: items)
    }

    func resetSuggestions() {
        HSBeacon.suggest([])
    }

}

extension HelpScout {
    // MARK: - Push notifications

    func initializePushNotifications(
        methodSwizzling: Bool,
        overrideUserNotificationCenterDelegate: Bool,
        forwardCapacitorRegistration: Bool
    ) {
        HSBeacon.initializeAutomaticPushNotificationHandling(
            withMethodSwizzling: methodSwizzling,
            overrideUserNotificationCenterDelegate: overrideUserNotificationCenterDelegate
        )
        HSBeacon.initializeBeaconPushNotificationSupport()

        registrationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        registrationObservers = []
        guard forwardCapacitorRegistration else { return }

        registrationObservers.append(
            NotificationCenter.default.addObserver(
                forName: .capacitorDidRegisterForRemoteNotifications,
                object: nil,
                queue: .main
            ) { notification in
                if let token = notification.object as? Data {
                    HSBeacon.setDeviceToken(token)
                }
            }
        )
        registrationObservers.append(
            NotificationCenter.default.addObserver(
                forName: .capacitorDidFailToRegisterForRemoteNotifications,
                object: nil,
                queue: .main
            ) { notification in
                if let error = notification.object as? NSError {
                    HSBeacon.failedToRegisterForRemoteNotificationsWithError(error)
                }
            }
        )
    }

    func setPushToken(hex: String) throws {
        guard let data = Data(hexString: hex) else {
            throw HelpScoutError.invalidArgument("token must be a hex encoded APNs device token.")
        }
        HSBeacon.setDeviceToken(data)
    }

    func failedToRegisterForPushNotifications(message: String) {
        let error = NSError(domain: "io.event1.plugins.helpscout", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
        HSBeacon.failedToRegisterForRemoteNotificationsWithError(error)
    }

    func isBeaconPushNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        return HSBeacon.isBeaconPushNotification(userInfo)
    }

    func handlePushNotification(
        userInfo: [AnyHashable: Any],
        signature: String?,
        from viewController: UIViewController?
    ) throws -> Bool {
        let settings = try requireSettings()
        guard HSBeacon.isBeaconPushNotification(userInfo) else { return false }
        let signature = effectiveSignature(signature)
        if let viewController = viewController {
            HSBeacon.handlePushNotification(userInfo, beaconSettings: settings, viewController: viewController, signature: signature)
        } else {
            HSBeacon.handlePushNotification(userInfo, beaconSettings: settings, signature: signature)
        }
        return true
    }

    // MARK: - Status

    func status() -> [String: Any] {
        var result: [String: Any] = ["initialized": settings != nil]
        if let settings = settings {
            result["beaconId"] = settings.beaconId
        }
        if let version = Bundle(identifier: "net.helpscout.beacon")?.infoDictionary?["CFBundleShortVersionString"] as? String {
            result["version"] = version
        }
        if let email = (HSBeacon.currentUser() ?? user)?.email, !email.isEmpty {
            result["email"] = email
        }
        return result
    }

    // MARK: - HSBeaconDelegate

    public func prefill(_ form: HSBeaconContactForm) {
        guard let prefill = prefill else { return }
        if let email = prefill.email { form.email = email }
        form.name = prefill.name
        form.subject = prefill.subject
        form.text = prefill.message
        for (fieldId, value) in prefill.customFields {
            form.addCustomFieldValue(value, forId: Int32(fieldId))
        }
        for attachment in prefill.attachments {
            _ = form.addAttachment(attachment.filename, data: attachment.data)
        }
    }

    public func sessionAttributes() -> [String: String] {
        return sessionAttributesStore
    }

    public func onBeaconInitialOpen(_ beaconSettings: HSBeaconSettings) {
        onEvent?("beaconOpened", ["initial": true])
    }

    public func onBeaconOpen(_ beaconSettings: HSBeaconSettings) {
        onEvent?("beaconOpened", ["initial": false])
    }

    public func onBeaconInitialClose(_ beaconSettings: HSBeaconSettings) {
        closeEventCount += 1
        onEvent?("beaconClosed", ["initial": true])
    }

    public func onBeaconClose(_ beaconSettings: HSBeaconSettings) {
        closeEventCount += 1
        onEvent?("beaconClosed", ["initial": false])
    }
}
