//
//  File.swift
//  
//
//  Created by mac on 08.05.2023.
//

import UIKit

private struct NotificationItem: Codable {
    let id: Int
    let title: String
    let body: String
    let image: String
}

@objcMembers
public class Notifications: NSObject {
    
    private let notificationItems: [NotificationItem]
    
    private let date: Date
    
    private let id: String
    
    public init?(userInfo: [AnyHashable : Any]) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let id = userInfo["id"] as? String,
              let executeTime = userInfo["executeTime"] as? String,
              let date = dateFormatter.date(from: executeTime),
//              let frequency = userInfo["frequency"] as? String,
              let data = userInfo["notifications"] as? String,
              let jsonData = data.data(using: .utf8),
              let notificationItems = try? JSONDecoder().decode([NotificationItem].self,
                                                                from: jsonData) else {
            
            print("/n/n/n/n        Looks like userInfo is wrong...      /n/n/n/n")
            
            return nil
        }
    
        
        self.notificationItems = notificationItems
        self.date = date
        self.id = id
        
    }
    
    
    public func schedule() {
        notificationItems.forEach { self.scheduleNotification(from: $0) }
    }
    
    
    private func scheduleNotification(from notificationItem: NotificationItem) {
        let content = UNMutableNotificationContent()
        content.title = notificationItem.title
        content.body = notificationItem.body
        
        if let imageURL = URL(string: notificationItem.image) {
            let session = URLSession.shared
            
            let task = session.dataTask(with: imageURL) { (data, response, error) in
                guard let imageData = data, error == nil else {
                    print("Failed to download image: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                do {
                    let fileManager = FileManager.default
                    let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileURL = documentsURL.appendingPathComponent("image.jpg")
                    try imageData.write(to: fileURL)
                    let attachment = try UNNotificationAttachment(identifier: "image", url: fileURL, options: nil)
                    content.attachments = [attachment]
                } catch {
                    print("Failed to create notification attachment: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
        
        let triggerDateComponents = Calendar.current.dateComponents([.hour, .minute],
                                                                    from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: id,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("error schedule notification failed: \(error.localizedDescription)")
            }
            
        }
    }
    
    // MARK: - Not used.
//    func cancelAllNotifications() {
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//    }
    
}
