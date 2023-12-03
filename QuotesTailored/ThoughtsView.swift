//
//  ThoughtsView.swift
//  QuotesTailored
//
//  Created by Limeng Ye on 2023/11/19.
//

import SwiftUI
import WidgetKit
import StoreKit
import os

let appGroup = "group.tonyc.QuotesTailored"

let udkey_wish = "wish"
let udkey_refresh = "refresh"
let udkey_wishUpdateCount = "wishUpdateCount"
let udkey_lastReviewVer = "lastReviewVer"

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum RefreshTime: String, CaseIterable, Identifiable {
    case hour1 = "1 hour"
    case hour3 = "3 hours"
    case hour24 = "24 hours"
    var id: RefreshTime { self }
}
// string to enum
extension RefreshTime: RawRepresentable {
    public init(rawValue: String) {
        switch rawValue {
        case "1 hour":
            self = .hour1
        case "3 hours":
            self = .hour3
        case "24 hours":
            self = .hour24
        default:
            self = .hour3
        }
    }

    // get global user default value
    static public func getUserDefault() -> RefreshTime {
        return RefreshTime(rawValue: (UserDefaults(suiteName: appGroup)!.string(forKey: udkey_refresh) ?? ""))
    }

    // to Int
    public var intValue: Int {
        switch self {
        case .hour1:
            return 1
        case .hour3:
            return 3
        case .hour24:
            return 24
        }
    }
}


struct ThoughtsView: View {
    @State private var selectedTime: RefreshTime = RefreshTime.getUserDefault()
    
    @State private var wish: String = (UserDefaults(suiteName: appGroup)!.string(forKey: udkey_wish) ?? "")
    
    @State private var showRating = false
    @State private var showFeedback = false
    @State private var feedbackStr: String = ""
    
    @Binding var showModal: Bool
    @Binding var disableCancel: Bool
    @Binding var newThought: Bool
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "thoughtsview")
    
    var body: some View {
        NavigationStack {
            innerView
                .toolbar {
                    if !disableCancel {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                self.showModal.toggle()
                            }
                            .foregroundColor(.white)
                            .bold()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            let oldWishStr = UserDefaults(suiteName: appGroup)?.string(forKey: udkey_wish) ?? ""
                            let newWishStr = self.$wish.wrappedValue
                            if oldWishStr != newWishStr {
                                UserDefaults(suiteName: appGroup)!.set(newWishStr, forKey: udkey_wish)
                                ReportUtils.shared.sendRequest(key: "enteredThoughts", value: newWishStr)
                                WidgetCenter.shared.reloadAllTimelines()
                                RequestQuotes.shared.requestQuotes()
                                ratingCheck()
                                newThought = true
                                print("[ThoughtsView] wishStr changed")
                            }
                            self.showModal.toggle()
                        }
                        .foregroundColor(.white)
                        .bold()
                    }
                }
        }
    }
    
    var innerView: some View {
        ZStack {
            Image("default_bg")
                .resizable()
//                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .opacity(0.4)
            VStack {
                Text("What's on your mind?")
                    .foregroundColor(.white)
                    .font(.title)
                    .bold()
               
                HStack(alignment: .center) {
                    Spacer()
                    
                    TextField("Enter here", text: $wish/*, axis: .vertical*/) {
                        UIApplication.shared.endEditing()
                    }
                        .font(.title3)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(4...10)
                        .inputBox()
                    
                    Spacer()
                }
                
                HStack() {
                    Text("Quotes will be recommended based on your thoughts.\nHere are some input examples: \n  I'm stressed in my new job. \n  I wanna become a successful entrepreneur. \n  Wisdom from Maya Angelou.")
                        .foregroundColor(.white)
                        .padding([.horizontal], 28)
                        .font(.footnote)
                }
                .offset(y:20)
                
                Group {
                    HStack {
//                        Label("Refresh time", systemImage: "arrow.clockwise.circle")
                        Group {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(.blue)
                            Picker("Refresh time", selection: $selectedTime) {
                                ForEach(RefreshTime.allCases) { v in
                                    Text(v.rawValue).tag(v)
                                }
                            }
                            .onChange(of:selectedTime) { value in
                                UserDefaults(suiteName: appGroup)!.set(selectedTime.rawValue, forKey: udkey_refresh)
                                WidgetCenter.shared.reloadAllTimelines()
                                print("[ThoughtsView] refresh time changed to \(selectedTime.rawValue)")
                            }
                            .offset(x:-10)
                        }
                        .foregroundColor(.white)
                    }
                    Button(action: {
                        showFeedback = true
                    }) {
                        Label("Feedback", systemImage: "square.and.pencil")
                    }
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal], 40)
                .offset(y:200)
            }
            .offset(y: -80)
        }
        .onAppear {
            // set default values
            // if udkey_refresh is not set, set it to 3 hours
            if UserDefaults(suiteName: appGroup)!.string(forKey: udkey_refresh) == nil {
                UserDefaults(suiteName: appGroup)!.set("3 hours", forKey: udkey_refresh)
            }
            checkStatus()
        }
        .alert("We'd love to hear your feedback and will keep improving the app.", isPresented: $showFeedback, actions: {
            TextField("Feedback", text: $feedbackStr)
            
            Button("Send", action: {
                sendFeedback(feedback:feedbackStr)
            })
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel, action: {})
        })
        .alert("Do you find this app helpful?", isPresented: $showRating, actions: {
            Button("Yes", action: {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let infoDictionaryKey = kCFBundleVersionKey as String
                    if let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String {
                        SKStoreReviewController.requestReview(in: windowScene)
                        UserDefaults.standard.set(currentVersion, forKey: udkey_lastReviewVer)
                    }
               }
            })
            .keyboardShortcut(.defaultAction)
            Button("No", role: .cancel, action: {
                showFeedback = true
            })
        })
    }
    
    func sendFeedback(feedback:String) {
        ReportUtils.shared.sendRequest(key: "feedback", value: feedback)
    }
    
    func checkStatus() {
        WidgetCenter.shared.getCurrentConfigurations { results in
            guard let widgets = try? results.get() else { return }
            var widgetStatus = ""
            for wid in widgets {
                widgetStatus += "\(wid.family), "
            }
            ReportUtils.shared.sendRequest(key: "widgetStatus", value: widgetStatus)
        }
    }
    
    func ratingCheck() {
        // If the app doesn't store the count, this returns 0.
        var count = UserDefaults.standard.integer(forKey: udkey_wishUpdateCount)
        count += 1
        UserDefaults.standard.set(count, forKey: udkey_wishUpdateCount)
        print("[ThoughtsView][ratingCheck] Process completed \(count) time(s).")
        
        // Keep track of the most recent app version that prompts the user for a review.
        let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: udkey_lastReviewVer)

        // Get the current bundle version for the app.
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary.") }
         // Verify the user completes the process several times and doesn’t receive a prompt for this app version.
         if count >= 4 && currentVersion != lastVersionPromptedForReview {
             Task {
                 // Delay for two seconds to avoid interrupting the person using the app.
                 // Use the equation n * 10^9 to convert seconds to nanoseconds.
                 try? await Task.sleep(nanoseconds: UInt64(2e9))
                 showRating = true
             }
         }
    }
}

#Preview {
    ThoughtsView(showModal: .constant(true), disableCancel: .constant(false), newThought: .constant(false))
}
