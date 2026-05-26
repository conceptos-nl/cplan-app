import UserNotifications
import Intents
import OneSignalExtension

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    var receivedRequest: UNNotificationRequest!

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else { return }
        
        let userInfo = bestAttemptContent.userInfo
        guard let logoUrlString = userInfo["sender_logo"] as? String,
              let senderName = userInfo["sender_name"] as? String,
              let logoUrl = URL(string: logoUrlString) else {
            
            OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler)
            return
        }

        URLSession.shared.downloadTask(with: logoUrl) { (location, response, error) in
            if let location = location {
                let tmpDirectory = NSTemporaryDirectory()
                let tmpFile = "file://".appending(tmpDirectory).appending(logoUrl.lastPathComponent)
                let tmpUrl = URL(string: tmpFile)!
                
                try? FileManager.default.moveItem(at: location, to: tmpUrl)
                
                if #available(iOS 15.0, *) {
                    let avatar = INImage(url: tmpUrl)
                    let handle = INPersonHandle(value: senderName, type: .unknown)
                    let sender = INPerson(personHandle: handle, nameComponents: nil, displayName: senderName, image: avatar, contactIdentifier: nil, customIdentifier: nil)
                    
                    let intent = INSendMessageIntent(recipients: nil, outgoingMessageType: .outgoingMessageText, content: bestAttemptContent.body, speakableGroupName: nil, conversationIdentifier: userInfo["id"] as? String, serviceName: nil, sender: sender, attachments: nil)
                    
                    let interaction = INInteraction(intent: intent, response: nil)
                    interaction.direction = .incoming
                    interaction.donate { _ in
                        do {
                            let updatedContent = try bestAttemptContent.updating(from: intent)
                            guard let mutableUpdatedContent = updatedContent.mutableCopy() as? UNMutableNotificationContent else {
                                OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler)
                                return
                            }
                            OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: mutableUpdatedContent, withContentHandler: self.contentHandler)
                        } catch {
                            OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler)
                        }
                    }
                } else {
                    OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler)
                }
            } else {
                OneSignalExtension.didReceiveNotificationExtensionRequest(self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler)
            }
        }.resume()
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(self.receivedRequest, with: self.bestAttemptContent)
            contentHandler(bestAttemptContent)
        }
    }
}