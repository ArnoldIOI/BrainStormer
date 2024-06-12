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


    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("BrainStormer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .black.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(10)
                    .shadow(color: .black, radius: 10, x: 5, y: 5)
                    .opacity((!showTextField && ideas.isEmpty) ? 1 : 0)

                Spacer()

                // What's on your mind
                if ideas.isEmpty {
                    if showTextField {
                        TextField("What's on your mind?", text: $idea, onCommit: {
                            if !idea.isEmpty {
                                generateIdeas(basedOn: idea)
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
                        Text("What's on your mind?")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                            .shadow(color: .black, radius: 10, x: 5, y: 5)
                            .padding(.horizontal, 40)
                            .onTapGesture {
                                withAnimation {
                                    showTextField.toggle()
                                }
                            }
                    }
                } else {
                    // Top idea text
                    Text(idea)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .shadow(color: .black, radius: 10, x: 5, y: 5)
                        .padding(.horizontal, 40)

                    // Swipable Card
                    SwipableCard(ideas: $ideas, activeIdeaIndex: $activeIdeaIndex, idea: $idea, generateIdeas: generateIdeas)
                    
                    // Bottom index and count
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
            
            // ProgressView for loading state
            if isLoading {
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
        .animation(.easeInOut(duration: 0.5), value: ideas)
    }

    private func generateIdeas(basedOn idea: String) {
        guard let url = URL(string: "http://localhost:5000/api/generate") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["idea": idea]
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
               let newIdeas = jsonResponse["ideas"] as? [[String: String]] {
                DispatchQueue.main.async {
                    self.ideas.append(contentsOf: newIdeas.compactMap { $0["description"] })
                }
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
}

struct SwipableCard: View {
    @Binding var ideas: [String]
    @Binding var activeIdeaIndex: Int?
    @Binding var idea: String
    let generateIdeas: (String) -> Void

    @State private var dragState = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            if let activeIndex = activeIdeaIndex {
                CardView(text: ideas[activeIndex])
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
                                        }else {
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
    let text: String

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
