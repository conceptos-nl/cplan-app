import UserNotifications
import Intents

/// Turns a push into a communication notification showing the organisation's
/// logo as the sender avatar. Runs for any APNs/FCM payload with
/// `mutable-content: 1`; reads `sender_name`, `sender_logo` and `id` from the
/// payload (FCM `data` keys land at the top level of userInfo).
class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            deliver(request.content)
            return
        }

        let userInfo = bestAttemptContent.userInfo
        guard let logoUrlString = userInfo["sender_logo"] as? String,
              let senderName = userInfo["sender_name"] as? String,
              let logoUrl = URL(string: logoUrlString) else {
            deliver(bestAttemptContent)
            return
        }

        URLSession.shared.downloadTask(with: logoUrl) { (location, response, error) in
            guard let location = location else {
                self.deliver(bestAttemptContent)
                return
            }

            let tmpDirectory = NSTemporaryDirectory()
            let tmpFile = "file://".appending(tmpDirectory).appending(logoUrl.lastPathComponent)
            let tmpUrl = URL(string: tmpFile)!

            try? FileManager.default.moveItem(at: location, to: tmpUrl)

            let avatar = INImage(url: tmpUrl)
            let handle = INPersonHandle(value: senderName, type: .unknown)
            let sender = INPerson(personHandle: handle, nameComponents: nil, displayName: senderName, image: avatar, contactIdentifier: nil, customIdentifier: nil)

            let intent = INSendMessageIntent(recipients: nil, outgoingMessageType: .outgoingMessageText, content: bestAttemptContent.body, speakableGroupName: nil, conversationIdentifier: userInfo["id"] as? String, serviceName: nil, sender: sender, attachments: nil)

            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            interaction.donate { _ in
                do {
                    let updatedContent = try bestAttemptContent.updating(from: intent)
                    self.deliver(updatedContent)
                } catch {
                    self.deliver(bestAttemptContent)
                }
            }
        }.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        if let bestAttemptContent = bestAttemptContent {
            deliver(bestAttemptContent)
        }
    }

    /// Hands the content to the system at most once (the download callback
    /// and the timeout can both get here).
    private func deliver(_ content: UNNotificationContent) {
        guard let handler = contentHandler else { return }
        contentHandler = nil
        handler(content)
    }
}
