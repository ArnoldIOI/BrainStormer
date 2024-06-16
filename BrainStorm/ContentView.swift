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
    @State private var showTextField = false
    @State private var isEditing = false
    @State private var activeIdeaIndex: Int? = nil
    @State private var isLoading = false
    @State private var typingText: String = ""
    private let fullText: String = "What's on your mind?"
    private let typingSpeed: Double = 0.1
    private let pauseDuration: Double = 1.0
    @State private var timer: Timer?
    @State private var holdOn = false
    @State private var collectedIdeaIndex: Set<Int> = Set<Int>()
    
    private func resetStates() {
        idea = ""
        ideas.removeAll()
        showTextField = false
        isEditing = false
        activeIdeaIndex = nil
        isLoading = false
        typingText = ""
        collectedIdeaIndex.removeAll()
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                HeaderView(showTextField: $showTextField,  ideas: $ideas, resetAll: resetStates)

                Spacer()

                if ideas.isEmpty {
                    IdeaInputView(
                        showTextField: $showTextField,
                        isEditing: $isEditing,
                        idea: $idea,
                        typingText: $typingText,
                        startTyping: startTyping,
                        stopTyping: stopTyping,
                        generateIdeas: generateIdeas
                    )
                } else {
                    IdeaListView(
                        ideas: $ideas,
                        activeIdeaIndex: $activeIdeaIndex,
                        idea: $idea,
                        collectedIdeaIndex: $collectedIdeaIndex,
                        generateIdeas: generateIdeas
                    )
                }

                Spacer()
                Spacer()
            }
            .padding()
            .onTapGesture {
                if !isEditing {
                    withAnimation {
                        showTextField.toggle()
                    }
                }
            }

            if isLoading {
                LoadingView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: ideas)
    }

    private func startTyping() {
        timer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { _ in
            updateText()
        }
    }

    private func stopTyping() {
        timer?.invalidate()
        timer = nil
    }

    private func updateText() {
        if holdOn {
            return
        }
        if typingText.count < fullText.count {
            typingText.append(fullText[fullText.index(fullText.startIndex, offsetBy: typingText.count)])
        } else {
            holdOn.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
                typingText = ""
                holdOn.toggle()
            }
        }
    }

    private func generateIdeas(basedOn idea: String) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer OPENAI_API_KEY", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are now a genius full of clever ideas. I will give you a topic, please help me brainstorm. Your main task is to expand ideas based on the topic and provide a short idea in one sentence. Output format should be JSON with content divided into 'topic' and 'description'. Just need the JSON, nothing else."],
                ["role": "user", "content": idea]
            ],
            "n": 5
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // Show loading indicator
        isLoading = true

        URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {
                // Hide loading indicator
                self.isLoading = false
            }

            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.ideas.append(contentsOf: choices.compactMap {
                        if let message = $0["message"] as? [String: Any],
                           let content = message["content"] as? String,
                           let jsonData = content.data(using: .utf8),
                           let idea = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                            return idea["description"]
                        }
                        return nil
                    })
                }
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
}

struct HeaderView: View {
    @Binding var showTextField: Bool
    @Binding var ideas: [String]
    let resetAll: () -> Void
    
    var body: some View {
        Text("BrainStormer")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .black.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(10)
            .shadow(color: .black, radius: 10, x: 5, y: 5)
            .onTapGesture {
                resetAll()
            }
    }
}

struct IdeaInputView: View {
    @Binding var showTextField: Bool
    @Binding var isEditing: Bool
    @Binding var idea: String
    @Binding var typingText: String
    let startTyping: () -> Void
    let stopTyping: () -> Void
    let generateIdeas: (String) -> Void

    var body: some View {
        if showTextField {
            TextField("What's on your mind?", text: $idea, onCommit: {
                if !idea.isEmpty {
                    generateIdeas(idea)
                    idea = ""
                    showTextField = false
                    isEditing = false
                }
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .shadow(color: .black, radius: 10, x: 5, y: 5)
            .padding(.horizontal, 40)
            .onTapGesture {
                isEditing = true
            }
        } else {
            Text(typingText)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .shadow(color: .black, radius: 10, x: 5, y: 5)
                .padding(.horizontal, 40)
                .onAppear(perform: startTyping)
                .onDisappear(perform: stopTyping)
        }
    }
}

struct IdeaListView: View {
    @Binding var ideas: [String]
    @Binding var activeIdeaIndex: Int?
    @Binding var idea: String
    @Binding var collectedIdeaIndex: Set<Int>
    let generateIdeas: (String) -> Void

    var body: some View {
        VStack {
            Text(idea)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .shadow(color: .black, radius: 10, x: 5, y: 5)
                .padding(.horizontal, 40)

            SwipableCard(collectedIdeaIndex: $collectedIdeaIndex,
                ideas: $ideas, activeIdeaIndex: $activeIdeaIndex, idea: $idea, generateIdeas: generateIdeas)

            if let activeIndex = activeIdeaIndex {
                Text("Idea \(activeIndex + 1) of \(ideas.count)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .shadow(color: .black, radius: 10, x: 5, y: 5)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)

            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding(.bottom, 10)

                Text("Generating Ideas...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.9)
            )
            .cornerRadius(10)
            .shadow(color: .black, radius: 10, x: 5, y: 5)
        }
    }
}

struct SwipableCard: View {
    @Binding var collectedIdeaIndex: Set<Int>
    @Binding var ideas: [String]
    @Binding var activeIdeaIndex: Int?
    @Binding var idea: String
    let generateIdeas: (String) -> Void

    @State private var dragState = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            if let activeIndex = activeIdeaIndex {
                CardView(collectedIdeaIndex: $collectedIdeaIndex,
                    text: ideas[activeIndex],
                         index: activeIndex)
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .padding()
                    .offset(x: dragState.width, y: dragState.height)
                    .rotationEffect(.degrees(Double(dragState.width / 10)))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                self.dragState = gesture.translation
                                self.isDragging = true
                            }
                            .onEnded { gesture in
                                if gesture.translation.width > 100 {
                                    withAnimation {
                                        if activeIndex == ideas.count - 1 {
                                            generateIdeas(idea)
                                        } else {
                                            activeIdeaIndex = activeIndex + 1
                                        }
                                    }
                                } else if gesture.translation.width < -100 {
                                    withAnimation {
                                        if activeIndex > 0 {
                                            activeIdeaIndex = activeIndex - 1
                                        }
                                    }
                                }
                                withAnimation {
                                    self.dragState = .zero
                                }
                                self.isDragging = false
                            }
                    )
                    .animation(.spring())
            }
        }
        .onAppear {
            if activeIdeaIndex == nil && !ideas.isEmpty {
                activeIdeaIndex = 0
            }
        }
    }
}

struct CardView: View {
    @Binding var collectedIdeaIndex: Set<Int>
    let text: String
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Idea")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(5)
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: collectedIdeaIndex.contains(index) ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            if collectedIdeaIndex.contains(index){
                                collectedIdeaIndex.remove(index)
                            }else{
                                collectedIdeaIndex.insert(index)
                            }
                        }
                }
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(.black)
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.white, .gray.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
