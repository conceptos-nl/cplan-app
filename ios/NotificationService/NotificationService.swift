import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else { return }
        
        // 1. Extract data from your custom FCM payload
        let userInfo = bestAttemptContent.userInfo
        guard let logoUrlString = userInfo["sender_logo"] as? String,
              let senderName = userInfo["sender_name"] as? String,
              let logoUrl = URL(string: logoUrlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        // 2. Download the Organization Logo
        URLSession.shared.downloadTask(with: logoUrl) { (location, response, error) in
            if let location = location {
                let tmpDirectory = NSTemporaryDirectory()
                let tmpFile = "file://".appending(tmpDirectory).appending(logoUrl.lastPathComponent)
                let tmpUrl = URL(string: tmpFile)!
                
                try? FileManager.default.moveItem(at: location, to: tmpUrl)
                
                // 3. Create the Communication Intent
                if #available(iOS 15.0, *) {
                    let avatar = INImage(url: tmpUrl)
                    let handle = INPersonHandle(value: senderName, type: .unknown)
                    let sender = INPerson(personHandle: handle, nameComponents: nil, displayName: senderName, image: avatar, contactIdentifier: nil, customIdentifier: nil)
                    
                    let intent = INSendMessageIntent(recipients: nil, outgoingMessageType: .outgoingMessageText, content: bestAttemptContent.body, speakableGroupName: nil, conversationIdentifier: userInfo["id"] as? String, serviceName: nil, sender: sender, attachments: nil)
                    
                    // 4. Inject the Intent into the notification
                    let interaction = INInteraction(intent: intent, response: nil)
                    interaction.direction = .incoming
                    interaction.donate { _ in
                        do {
                            let updatedContent = try bestAttemptContent.updating(from: intent)
                            contentHandler(updatedContent)
                        } catch {
                            contentHandler(bestAttemptContent)
                        }
                    }
                } else {
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }.resume()
    }
}