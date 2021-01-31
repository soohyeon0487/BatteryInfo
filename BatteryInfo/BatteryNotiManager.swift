//
//  LocalNotification.swift
//  BatteryInfo
//
//  Created by Soohyeon Lee on 2021/01/31.
//

import Foundation
import UserNotifications

class BatteryNotiManager {
    
    init(title: String?, subTitle: String?, body: String?) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])  {
            success, error in
            if success {
                print("authorization granted")
            } else {
                print(error?.localizedDescription)
            }
        }
        
        let content = UNMutableNotificationContent()
        
        if let value = title {
            content.title = value
        }
        
        if let value = subTitle {
            content.subtitle = value
        }
        
        if let value = body {
            content.body = value
        }
        
        //content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "BatteryInfo.Noti.Waring", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
    }
    
}
