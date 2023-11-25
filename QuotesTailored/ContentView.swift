////
////  ContentView.swift
////  QuotesTailored
////
////  Created by Yangming Chong on 2023/11/1.
////
//
//import SwiftUI
//import WidgetKit
//import StoreKit
//import os
//
////let appGroup = "group.tonyc.QuotesTailored"
////
////let udkey_wish = "wish"
////let udkey_refresh = "refresh"
////let udkey_wishUpdateCount = "wishUpdateCount"
////let udkey_lastReviewVer = "lastReviewVer"
//
//struct ContentView: View {
//    
//    enum RefreshTime: String, CaseIterable, Identifiable {
//        case hour1 = "1 hour"
//        case hour3 = "3 hours"
//        case hour24 = "24 hours"
//        var id: RefreshTime { self }
//    }
//    @State private var selectedTime: RefreshTime = .hour3
//    
//    @State private var wish: String = (UserDefaults(suiteName: appGroup)!.string(forKey: udkey_wish) ?? "")
//    
//    @State private var showReminder = false
//    @State private var showRating = false
//    @State private var showFeedback = false
//    @State private var feedbackStr: String = ""
//
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                Section() {
//                    Text("Hi! Quotes will be recommended based on your thoughts.")
//                }
//                .listRowBackground(Color(.systemGroupedBackground))
//                Section(header: Text("What's on your mind?"), footer: Text("You can be specific, e.g. I'm stressed in my new job which I don't like. Or, I want to become a successful entrepreneur like Steve Jobs and Elon Musk. ")) {
//                    HStack {
//                        TextField("", text: $wish)
//                            .submitLabel(.done)
//                            .onSubmit {
//                                UserDefaults(suiteName: appGroup)!.set(self.$wish.wrappedValue, forKey: udkey_wish)
//                                WidgetCenter.shared.reloadAllTimelines()
//                                ratingCheck()
//                                showReminder = true
//                                let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")
//                                logger.log("tctc wishStr changed")
//                            }
//                            .alert("To get daily quotes on your home screen:\n 1.Long press home screen.\n2.Tap '+' top left.\n3.Add our widget. Enjoy!", isPresented: $showReminder) {
//                                Button("Got it", role: .cancel) { }
//                            }
//                    }
//                }
//                Section(header: Text("Widget settings")) {
//                    Picker("Refresh time", selection: $selectedTime) {
//                        ForEach(RefreshTime.allCases) { v in
//                            Text(v.rawValue).tag(v)
//                        }
//                    }
//                    .onChange(of:selectedTime) { value in
////                        print("selectedTime set = ", selectedTime)
//                        UserDefaults(suiteName: appGroup)!.set(selectedTime.rawValue, forKey: udkey_refresh)
//                        WidgetCenter.shared.reloadAllTimelines()
//                        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")
//                        logger.log("tctc refresh time changed")
//                    }
//                }
//                Section() {
//                    HStack {
//                        Spacer()
//                        Button("Feedback", action: {
//                            showFeedback = true
//                        })
//                        Spacer()
//                    }
//                }
//                .listRowBackground(Color(.systemGroupedBackground))
//                
//            }
//            .navigationTitle("Quotes")
//            .onAppear {
//                // set default values
//                UserDefaults(suiteName: appGroup)!.set("e.g. I want to get motivated", forKey: udkey_wish)
//                UserDefaults(suiteName: appGroup)!.set("3 hours", forKey: udkey_refresh)
//                checkStatus()
//            }
//            .alert("We'd love to hear your feedback and will keep improving the app.", isPresented: $showFeedback, actions: {
//                TextField("Feedback", text: $feedbackStr)
//                
//                Button("Send", action: {
//                    sendFeedback(feedback:feedbackStr)
//                })
//                .keyboardShortcut(.defaultAction)
//                Button("Cancel", role: .cancel, action: {})
//            })
//            .alert("Do you find this app helpful?", isPresented: $showRating, actions: {
//                Button("Yes", action: {
//                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//                        let infoDictionaryKey = kCFBundleVersionKey as String
//                        if let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String {
//                            SKStoreReviewController.requestReview(in: windowScene)
//                            UserDefaults.standard.set(currentVersion, forKey: udkey_lastReviewVer)
//                        }
//                   }
//                })
//                .keyboardShortcut(.defaultAction)
//                Button("No", role: .cancel, action: {
//                    showFeedback = true
//                })
//            })
//            .buttonStyle(.borderless)
//        }
//    }
//    
//    func sendRequest(key:String, value: String) {
//        let udid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_udid"
//        let payloadStr = "{\"" + key + "\": \"" + value + "\", " + "\"udid\": \"" + udid + "\"" + "}"
////        print("payloadStr = ", payloadStr)
//        
//        let urlStr = "https://ailisteners.com/v1"
//        guard let url = URL(string: urlStr),
//            let payload = payloadStr.data(using: .utf8) else { return }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer cf-Kl814QbGR7tn050enmJdT3BlbkFJH4VX9XwQ6V3HmZo6hUq4", forHTTPHeaderField: "Authorization") // cloudflare
//        request.httpBody = payload
//
//        URLSession.shared.dataTask(with: request) { (data, response, error) in
//        }.resume()
//    }
//    
//    func sendFeedback(feedback:String) {
//        sendRequest(key: "feedback", value: feedback)
//    }
//    
//    func checkStatus() {
//        WidgetCenter.shared.getCurrentConfigurations { results in
//            guard let widgets = try? results.get() else { return }
//            var widgetStatus = ""
//            for wid in widgets {
//                widgetStatus += "\(wid.family), "
//            }
//            sendRequest(key: "widgetStatus", value: widgetStatus)
//        }
//    }
//    
//    func ratingCheck() {
//        // If the app doesn't store the count, this returns 0.
//        var count = UserDefaults.standard.integer(forKey: udkey_wishUpdateCount)
//        count += 4
//        UserDefaults.standard.set(count, forKey: udkey_wishUpdateCount)
//        print("Process completed \(count) time(s).")
//        
//        // Keep track of the most recent app version that prompts the user for a review.
//        let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: udkey_lastReviewVer)
//
//        // Get the current bundle version for the app.
//        let infoDictionaryKey = kCFBundleVersionKey as String
//        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
//            else { fatalError("Expected to find a bundle version in the info dictionary.") }
//         // Verify the user completes the process several times and doesn’t receive a prompt for this app version.
//         if count >= 4 && currentVersion != lastVersionPromptedForReview {
//             Task {
//                 // Delay for two seconds to avoid interrupting the person using the app.
//                 // Use the equation n * 10^9 to convert seconds to nanoseconds.
//                 try? await Task.sleep(nanoseconds: UInt64(2e9))
//                 showRating = true
//             }
//         }
//    }
//}
//
//#Preview {
//    ContentView()
//}
