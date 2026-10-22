import Foundation
import UIKit
import Beacon

enum HelpScoutError: LocalizedError {
    case notInitialized
    case invalidArgument(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Beacon is not initialized. Call initialize() first."
        case .invalidArgument(let message):
            return message
        }
    }
}

enum HelpScoutScreen: String {
    case home, ask, askMessage, askChat, answers, aiAnswers, previousMessages

    var route: BeaconRoute {
        switch self {
        case .home: return .home
        case .ask: return .ask
        case .askMessage: return .askMessage
        case .askChat: return .askChat
        case .answers: return .answers
        case .aiAnswers: return .aiAnswers
        case .previousMessages: return .previousMessages
        }
    }
}

struct HelpScoutAttachment {
    let filename: String
    let data: Data
}

struct HelpScoutPrefill {
    var name: String?
    var email: String?
    var subject: String?
    var message: String?
    var customFields: [Int: String] = [:]
    var attachments: [HelpScoutAttachment] = []
}

struct HelpScoutUser {
    var email: String
    var name: String?
    var company: String?
    var jobTitle: String?
    var avatar: String?
    var signature: String?
    var attributes: [String: String] = [:]
}

struct HelpScoutConfig {
    var messagingEnabled: Bool?
    var docsEnabled: Bool?
    var chatEnabled: Bool?
    var enablePreviousMessages: Bool?
    var color: String?
    var focusMode: String?
    var contactForm: [String: Bool] = [:]
    var localizationOverrides: [String: String]?
    var useLocalTranslationOverrides: Bool?

    /// Applies only the values that were provided to `settings`.
    func apply(to settings: HSBeaconSettings) throws {
        applyFeatures(to: settings)
        try applyAppearance(to: settings)
        applyContactForm(to: settings.messagingSettings)
        applyLocalization(to: settings)
    }

    private func applyFeatures(to settings: HSBeaconSettings) {
        if let messagingEnabled = messagingEnabled { settings.messagingEnabled = messagingEnabled }
        if let docsEnabled = docsEnabled { settings.docsEnabled = docsEnabled }
        if let chatEnabled = chatEnabled { settings.chatEnabled = chatEnabled }
        if let enablePreviousMessages = enablePreviousMessages { settings.enablePreviousMessages = enablePreviousMessages }
    }

    private func applyAppearance(to settings: HSBeaconSettings) throws {
        if let color = color {
            guard let parsed = UIColor(hexString: color) else {
                throw HelpScoutError.invalidArgument("Invalid color '\(color)'. Use a hex string such as #617DEC.")
            }
            settings.color = parsed
        }

        if let focusMode = focusMode {
            switch focusMode {
            case "neutral": settings.focusModeOverride = .neutral
            case "selfService": settings.focusModeOverride = .selfService
            case "askFirst": settings.focusModeOverride = .askFirst
            default:
                throw HelpScoutError.invalidArgument("Invalid focusMode '\(focusMode)'.")
            }
        }
    }

    private func applyContactForm(to messaging: HSBeaconMessagingSettings) {
        if let value = contactForm["customFieldsEnabled"] { messaging.contactFormCustomFieldsEnabled = value }
        if let value = contactForm["showName"] { messaging.contactFormShowNameField = value }
        if let value = contactForm["showSubject"] { messaging.contactFormShowSubjectField = value }
        if let value = contactForm["allowAttachments"] { messaging.contactFormAllowAttachments = value }
        if let value = contactForm["showPrefilledCustomFields"] { messaging.showPrefilledCustomFields = value }
    }

    private func applyLocalization(to settings: HSBeaconSettings) {
        if let localizationOverrides = localizationOverrides { settings.localizationOverrides = localizationOverrides }
        if let useLocalTranslationOverrides = useLocalTranslationOverrides {
            settings.useLocalTranslationOverrides = useLocalTranslationOverrides
        }
    }
}

// MARK: - Helpers

extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }
        let hasAlpha = hex.count == 8
        let red = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Data {
    init?(hexString: String) {
        let hex = hexString.filter { !$0.isWhitespace && $0 != "<" && $0 != ">" }
        guard hex.count % 2 == 0 else { return nil }
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        self = data
    }
}
