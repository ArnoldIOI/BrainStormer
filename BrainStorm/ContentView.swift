//
//  ContentView.swift
//  BrainStorm
//
//  Created by Arnold on 10/06/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var idea: String = ""
    @State private var ideas: [String] = []
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Text("BrainStomer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding(.top, 40)

                Spacer()

                if ideas.isEmpty {
                    TextField("What's on your mind?", text: $idea, onCommit: {
                        generateIdeas(basedOn: idea)
                        generateIdeas(basedOn: idea)
                    })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding()
                } else {
                    Text(ideas.first ?? "")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding()

                    TabView(selection: $currentPage) {
                        ForEach(ideas.indices, id: \.self) { index in
                            CardView(text: ideas[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                    .onChange(of: currentPage) { newPage in
                        if newPage == ideas.count - 1 {
                            generateIdeas(basedOn: idea)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.5), value: ideas)
    }

    private func generateIdeas(basedOn idea: String) {
        ideas.append("Example based on \(idea): \(ideas.count)")
    }
}

struct CardView: View {
    let text: String

    var body: some View {
        VStack {
            Text(text)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding()
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

