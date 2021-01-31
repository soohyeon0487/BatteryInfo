//
//  ContentView.swift
//  BatteryInfo
//
//  Created by Soohyeon Lee on 2021/01/31.
//

import SwiftUI
import NotificationCenter

struct ContentView: View {
    
    @ObservedObject var manager = DeviceInfoManager()
    
    @State var timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        BatteyInfoView(deviceList: self.manager.deviceList)
            .frame(width: 300, height: 300, alignment: .center)
            .padding()
            .onAppear(perform: {
                print(#file, #function)
            })
            .onDisappear(perform: {
                print(#file, #function)
            })
            .onReceive(timer) { _ in
                print(#file, #function)
            }
    }
}

struct BatteyInfoView: View {
    
    @State var deviceList: [String: DeviceInfo]
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            HStack(spacing: 0) {
                
                ForEach(Array(self.deviceList.keys).sorted(), id: \.self) { product in
                    
                    VStack(spacing: 0) {
                        
                        Image(systemName: self.deviceList[product]!.symbol)
                            .font(.largeTitle)
                            .frame(width: 50, height: 40, alignment: .center)
                        
                        Text("\(product)")
                            .font(.headline)
                            .padding(10)
                        
                        Text("\(self.deviceList[product]!.transport)")
                            .font(.body)
                            .padding(.bottom, 10)
                        
                        ProgressBar(currentValue: CGFloat(self.deviceList[product]!.batteryPercent)/100)
                            .padding()
                        
                        Text("\(self.deviceList[product]! .serialNumber)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(5)
                        
                    }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
