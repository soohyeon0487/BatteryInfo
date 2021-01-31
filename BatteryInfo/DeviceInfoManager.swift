//
//  DeviceInfoManager.swift
//  BatteryInfo
//
//  Created by Soohyeon Lee on 2021/01/31.
//

import Foundation
import IOKit

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

