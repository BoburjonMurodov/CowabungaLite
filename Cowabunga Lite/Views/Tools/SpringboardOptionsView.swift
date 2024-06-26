//
//  SpringboardOptionsView.swift
//  CowabungaJailed
//
//  Created by lemin on 3/22/23.
//

import Foundation
import SwiftUI

struct SpringboardOptionsView: View {
    @StateObject private var logger = Logger.shared
    @StateObject private var dataSingleton = DataSingleton.shared
    @State private var enableTweak: Bool = false
    @State private var footnoteText = ""
    @State private var animSpeed: Double = 1
    
    struct SBOption: Identifiable {
        var id = UUID()
        var key: String
        var name: String
        var fileLocation: MainUtils.FileLocation
        var value: Bool = false
        var invertValue: Bool = false
        var dividerBelow: Bool = false
    }
    
    @State private var sbOptions: [SBOption] = [
//        .init(key: "kWiFiShowKnownNetworks", name: "Show Known WiFi Networks", fileLocation: .wifi)
//        .init(key: "SBDisableHomeButton", name: "Disable Home Button", imageName: "iphone.homebutton"),
//        .init(key: "SBDontLockEver", name: "Disable Lock Button", imageName: "lock.square"),
//        .init(key: "SBDisableNotificationCenterBlur", name: "Disable Notif Center Blur", fileLocation: .springboard),
//        .init(key: "SBControlCenterDemo", name: "CC AirPlay Radar", fileLocation: .springboard)
    ]
    
    var body: some View {
        List {
            Group {
                HStack {
                    Image(systemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                    VStack {
                        HStack {
                            Text("Springboard Options")
                                .bold()
                            Spacer()
                        }
                        HStack {
                            Toggle("Modify", isOn: $enableTweak).onChange(of: enableTweak, perform: {nv in
                                DataSingleton.shared.setTweakEnabled(.springboardOptions, isEnabled: nv)
                            }).onAppear(perform: {
                                enableTweak = DataSingleton.shared.isTweakEnabled(.springboardOptions)
                            })
                            Spacer()
                        }
                    }
                }
                Divider()
                if dataSingleton.deviceAvailable {
                    Group {
                        // MARK: UI Animation Speed
                        Text("UI Animation Speed")
                        VStack {
                            Slider(value: $animSpeed, in: 0.1...2, step: 0.01)
                                .onChange(of: animSpeed, perform: { nv in
                                    guard let plistURL = DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent(MainUtils.FileLocation.uikit.rawValue) else {
                                        Logger.shared.logMe("Error finding uikit plist")
                                        return
                                    }
                                    do {
                                        try PlistManager.setPlistValues(url: plistURL, values: [
                                            "UIAnimationDragCoefficient": nv
                                        ])
                                    } catch {
                                        Logger.shared.logMe(error.localizedDescription)
                                    }
                                })
                            Text("\(animSpeed, specifier: "%.2f") (\(animSpeed == 1 ? "Default" : (animSpeed < 1 ? "Fast" : "Slow")))")
                        }.onAppear {
                            guard let plistURL = DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent(MainUtils.FileLocation.uikit.rawValue) else {
                                Logger.shared.logMe("Error finding uikit plist")
                                return
                            }
                            do {
                                animSpeed = try PlistManager.getPlistValues(url: plistURL, key: "UIAnimationDragCoefficient") as? Double ?? 1
                            } catch {
                                return
                            }
                        }
                        
                        // MARK: Lock Screen Footnote
                        Text("Lock Screen Footnote Text")
                        TextField("Footnote Text", text: $footnoteText).onChange(of: footnoteText, perform: { nv in
                            guard let plistURL = DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent(MainUtils.FileLocation.footnote.rawValue) else {
                                Logger.shared.logMe("Error finding footnote plist")
                                return
                            }
                            do {
                                try PlistManager.setPlistValues(url: plistURL, values: [
                                    "LockScreenFootnote": footnoteText
                                ])
                            } catch {
                                Logger.shared.logMe(error.localizedDescription)
                            }
                        }).onAppear(perform: {
                            guard let plistURL = DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent(MainUtils.FileLocation.footnote.rawValue) else {
                                Logger.shared.logMe("Error finding footnote plist")
                                return
                            }
                            do {
                                footnoteText = try PlistManager.getPlistValues(url: plistURL, key: "LockScreenFootnote") as? String ?? ""
                            } catch {
                                return
                            }
                        })
                        
                        Divider()
                        
                        ForEach($sbOptions) { option in
                            Toggle(isOn: option.value) {
                                Text(option.name.wrappedValue)
                                    .minimumScaleFactor(0.5)
                            }.onChange(of: option.value.wrappedValue) { new in
                                do {
                                    guard let plistURL = DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent(option.fileLocation.wrappedValue.rawValue) else {
                                        Logger.shared.logMe("Error finding springboard plist \(option.fileLocation.wrappedValue.rawValue)")
                                        return
                                    }
                                    if option.key.wrappedValue == "WiFiManagerLoggingEnabled" {
                                        try PlistManager.setPlistValues(url: plistURL, values: [
                                            option.key.wrappedValue: option.value.wrappedValue ? "true" : "false"
                                        ])
                                    } else if option.key.wrappedValue == "DiscoverableMode" {
                                        if option.value.wrappedValue == true {
                                            try PropertyListSerialization.data(fromPropertyList: ["DiscoverableMode": "Everyone"], format: .xml, options: 0).write(to: plistURL)
                                        } else {
                                            try PropertyListSerialization.data(fromPropertyList: [:] as [String: Any], format: .xml, options: 0).write(to: plistURL)
                                        }
                                    } else {
                                        try PlistManager.setPlistValues(url: plistURL, values: [
                                            option.key.wrappedValue: !option.invertValue.wrappedValue ? option.value.wrappedValue : !option.value.wrappedValue
                                        ])
                                    }
                                } catch {
                                    Logger.shared.logMe(error.localizedDescription)
                                    return
                                }
                            }
                            .onAppear {
                                do {
                                    guard let plistURL = DataSingleton.shared.getCurrentWorkspace()?.appendingPathComponent(option.fileLocation.wrappedValue.rawValue) else {
                                        Logger.shared.logMe("Error finding springboard plist \(option.fileLocation.wrappedValue.rawValue)")
                                        return
                                    }
                                    if option.key.wrappedValue == "WiFiManagerLoggingEnabled" {
                                        option.value.wrappedValue = (try PlistManager.getPlistValues(url: plistURL, key: option.key.wrappedValue) as? String ?? "false" == "true")
                                    } else if option.key.wrappedValue == "DiscoverableMode" {
                                        option.value.wrappedValue = (try PlistManager.getPlistValues(url: plistURL, key: option.key.wrappedValue) as? String ?? "" == "Everyone")
                                    } else {
                                        let gottenValue = try PlistManager.getPlistValues(url: plistURL, key: option.key.wrappedValue) as? Bool
                                        option.value.wrappedValue = !option.invertValue.wrappedValue ? gottenValue ?? false : !(gottenValue ?? true)
                                    }
                                } catch {
                                    Logger.shared.logMe("Error finding springboard plist \(option.fileLocation.wrappedValue.rawValue)")
                                    return
                                }
                            }
                            if option.dividerBelow.wrappedValue {
                                Divider()
                            }
                        }
                    }.disabled(!enableTweak)
                }
            }.disabled(!dataSingleton.deviceAvailable)
                .hideSeparator()
                .onAppear {
                    if sbOptions.isEmpty {
                        for opt in MainUtils.sbOptions {
                            sbOptions.append(.init(key: opt.key, name: opt.name, fileLocation: opt.fileLocation, invertValue: opt.invertValue, dividerBelow: opt.dividerBelow))
                        }
                    }
                }
        }
    }
}

struct SpringboardOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        SpringboardOptionsView()
    }
}
