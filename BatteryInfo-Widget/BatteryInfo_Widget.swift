//
//  BatteryInfo_Widget.swift
//  BatteryInfo-Widget
//
//  Created by Soohyeon Lee on 2021/01/31.
//

import IOKit
import SwiftUI
import WidgetKit
import UserNotifications

struct DeviceInfo {
    var serialNumber: String
    var transport: String
    var batteryPercent: Int
    var symbol: String
    
    init(_ symbol: String) {
        self.transport = "Not Connected"
        self.serialNumber = ""
        self.batteryPercent = 0
        self.symbol = symbol
    }
    
    func check() -> Bool { // true = 충분
        return self.batteryPercent > 20
    }
}

class DeviceInfoManager: ObservableObject {
    
    @Published var deviceList: [String: DeviceInfo] = [:]
    
    init() {
        self.reloadData()
    }
    
    func reloadData() {
        
        let masterPort: mach_port_t = kIOMasterPortDefault
        let matchingDict : CFDictionary = IOServiceMatching("AppleDeviceManagementHIDEventService")
        
        var serialPortIterator = io_iterator_t()
        var object : io_object_t = 0
        var kernResult: kern_return_t = 0
        
        self.deviceList["Magic Keyboard"] = DeviceInfo("keyboard")
        self.deviceList["Magic Trackpad 2"] = DeviceInfo("rectangle.inset.fill")
        
        // IO 서비스 중 masterPort와 matcingDict과 일치하는 목록을 serialPortIterator에 저장
        kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, &serialPortIterator)
        
        // 매칭되는 서비스 목록이 ?
        if KERN_SUCCESS == kernResult {
            
            repeat {
                object = IOIteratorNext(serialPortIterator)
                
                if object != 0 {
                    
                    // IO 서비스의 배터리 정보 호출 (없으면 nil)
                    guard let product = IORegistryEntryCreateCFProperty(object, "Product" as CFString, kCFAllocatorDefault, 0) else {
                        continue
                    }
                    
                    let productValue = product.takeRetainedValue() as! String
                    
                    if !productValue.contains("Magic") {
                        continue
                    }
                    
                    guard let serialNumber = IORegistryEntryCreateCFProperty(object, "SerialNumber" as CFString, kCFAllocatorDefault, 0) else {
                        continue
                    }
                    
                    let serialNumberValue = serialNumber.takeRetainedValue() as! String
                    
                    self.deviceList[productValue]?.serialNumber = serialNumberValue
                    
                    guard let transport = IORegistryEntryCreateCFProperty(object, "Transport" as CFString, kCFAllocatorDefault, 0) else {
                        continue
                    }
                    
                    let transportValue = transport.takeRetainedValue() as! String
                    
                    self.deviceList[productValue]?.transport = transportValue
                    
                    guard let battery = IORegistryEntryCreateCFProperty(object, "BatteryPercent" as CFString, kCFAllocatorDefault, 0) else {
                        continue
                    }
                    
                    let batteryValue = battery.takeRetainedValue() as! Int
                    
                    self.deviceList[productValue]?.batteryPercent = batteryValue
                }
            } while object != 0
            
            IOObjectRelease(object)
        }
        
        IOObjectRelease(serialPortIterator)
    }
    
    private func checkBattery() {
        Array(self.deviceList.keys).forEach {
            if !(self.deviceList[$0]?.check())! {
                // 배터리 경고
                _ = BatteryNotiManager(title: "Need Charging", subTitle: nil, body: "\($0)'s Battery level is less than 20%")
            }
        }
    }
}

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

struct BatteryInfoEntry: TimelineEntry {
    var date = Date()
    let manager: DeviceInfoManager
}

struct Provider: TimelineProvider {
    
    typealias Entry = BatteryInfoEntry
    
    var manager = DeviceInfoManager()
    
    
    func placeholder(in context: Context) -> Entry {
        
        print(#file, #function)
        
        return Entry(manager: manager)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
        
        print(#file, #function)
        
        let entry = Entry(manager: manager)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        print(#file, #function)
        
        manager.reloadData()
        
        let currentDate = Date()
        
        let refresh = Calendar.current.date(byAdding: .second, value: 3, to: currentDate)!
        
        let entry = Entry(date: currentDate, manager: manager)
        
        let timeline = Timeline(entries: [entry], policy: .after(refresh))
        
        completion(timeline)
    }
}

struct BatteryInfo_WidgetEntryView: View {
    
    @Environment(\.widgetFamily) var family
    
    @State var entry: Provider.Entry
    
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            HStack(spacing: 0) {
                
                ForEach(Array(self.entry.manager.deviceList.keys).sorted(), id: \.self) { product in
                    
                    VStack(spacing: 0) {
                        
                        Image(systemName: self.entry.manager.deviceList[product]!.symbol)
                            .font(.largeTitle)
                            .frame(width: 50, height: 40, alignment: .center)
                        
                        Text("\(product)")
                            .font(.headline)
                            .padding(10)
                        
                        Text("\(self.entry.manager.deviceList[product]!.transport)")
                            .font(.body)
                            .padding(.bottom, 10)
                        
                        if family != .systemMedium {
                            ProgressBar(currentValue: CGFloat(self.entry.manager.deviceList[product]!.batteryPercent)/100)
                                .padding()
                        } else {
                            Text("\(self.entry.manager.deviceList[product]!.batteryPercent)%")
                                .font(.title)
                                .foregroundColor(self.entry.manager.deviceList[product]!.batteryPercent == 0 ? Color.black.opacity(0.5) : (self.entry.manager.deviceList[product]!.batteryPercent > 50 ? Color.green : Color.red))
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                        }
                        
                        Text("\(self.entry.manager.deviceList[product]! .serialNumber)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(5)
                        
                    }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
        .frame(width: (family != .systemMedium ? 300 : 300), height: (family != .systemMedium ? 300 : 150), alignment: .center)
    }
}

struct ProgressBar: View {
    
    var currentValue: CGFloat
    
    var body: some View {
        ZStack {
            
            // Back
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(self.currentValue == 0 ? Color.black : (self.currentValue > 0.5 ? Color.green : Color.red))
            
            // Front
            Circle()
                .trim(from: 0, to: self.currentValue)
                .stroke(lineWidth: 10)
                .foregroundColor(self.currentValue > 0.5 ? Color.green : Color.red)
            
            // Percent
            Text("\(Int(self.currentValue*100))%")
                .font(.title)
                .foregroundColor(self.currentValue == 0 ? Color.black.opacity(0.5) : (self.currentValue > 0.5 ? Color.green : Color.red))
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        }
    }
}

@main
struct BatteryInfo_Widget: Widget {
    let kind: String = "BatteryInfo_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BatteryInfo_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct BatteryInfo_Widget_Previews: PreviewProvider {
    static var previews: some View {
        BatteryInfo_WidgetEntryView(entry: BatteryInfoEntry(manager: DeviceInfoManager()))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
