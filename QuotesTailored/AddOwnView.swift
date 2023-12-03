//
//  AddOwnView.swift
//  QuotesTailored
//
//  Created by Limeng Ye on 2023/11/30.
//

import SwiftUI
import os
let udkey_ownList = "ownList"

extension View {
    func inputBox() -> some View {
        self.padding().padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.7))
                    .padding()
            )
    }
}

struct AddOwnView: View {
    @State private var quote: String = ""
    @State private var author: String = ""
    @Binding var showModal: Bool
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "addownview")

    var body: some View {
        NavigationStack {
            innerView
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            self.showModal.toggle()
                        }
                        .foregroundColor(.white)
                        // .bold()
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            addOwnQuote(quote: $quote.wrappedValue, author: $author.wrappedValue)
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
                .edgesIgnoringSafeArea(.all)
                .opacity(0.4)
            VStack {
                Spacer()
                Text("Add my own")
                    .foregroundColor(.white)
                    .font(.title2)
                    .bold()
                TextField("Quote", text: $quote, axis: .vertical)
                    .lineLimit(1...4)
                    .inputBox()
                TextField("Author", text: $author)
                    .inputBox()
                    .offset(y:-20)
                Spacer()
            }
        }
    }
    
    func addOwnQuote(quote: String, author: String) {
        var ownList = UserDefaults.standard.object(forKey: udkey_ownList) as? [Dictionary<String, String>] ?? []
        let new = ["quote": quote, "author": author]
        ownList.append(new)
        UserDefaults.standard.set(ownList, forKey: udkey_ownList)
        ReportUtils.shared.sendRequest(key: "addedOwn", value: self.$quote.wrappedValue)
        print("[AddOwnView] addedOwn")
    }
}

#Preview {
    AddOwnView(showModal: .constant(true))
}
