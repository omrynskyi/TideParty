//
//  CodeInputView.swift
//  TideParty
//
//  Reusable 4-digit code input component with purple squares
//

import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    @FocusState private var focusedIndex: Int?
    
    private let boxCount = 4
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<boxCount, id: \.self) { index in
                CodeDigitBox(
                    digit: digitAt(index: index),
                    isFocused: focusedIndex == index,
                    index: index
                )
                .onTapGesture {
                    focusedIndex = index
                }
            }
        }
        .background(
            // Hidden TextField for keyboard input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($focusedIndex, equals: 0)
                .opacity(0)
                .frame(width: 1, height: 1)
        )
        .onChange(of: code) { oldValue, newValue in
            // Limit to 4 digits
            if newValue.count > boxCount {
                code = String(newValue.prefix(boxCount))
            }
            
            // Filter non-numeric characters
            code = code.filter { $0.isNumber }
            
            // Haptic feedback when complete
            if code.count == boxCount {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .onAppear {
            // Auto-focus first box
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedIndex = 0
            }
        }
    }
    
    private func digitAt(index: Int) -> String {
        guard code.count > index else { return "" }
        let digitIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[digitIndex])
    }
}

struct CodeDigitBox: View {
    let digit: String
    let isFocused: Bool
    let index: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.45, green: 0.3, blue: 0.9)) // Purple
                .frame(width: 60, height: 70)
            
            Text(digit)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            // Blinking cursor when focused and empty
            if isFocused && digit.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 2, height: 40)
                    .opacity(cursorOpacity)
            }
        }
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isFocused)
    }
    
    @State private var cursorOpacity: Double = 1.0
    
    private var cursorAnimation: Animation {
        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)
    }
    
    init(digit: String, isFocused: Bool, index: Int) {
        self.digit = digit
        self.isFocused = isFocused
        self.index = index
        
        if isFocused {
            withAnimation(cursorAnimation) {
                _cursorOpacity = State(initialValue: 0.3)
            }
        }
    }
}

#Preview {
    VStack {
        CodeInputView(code: .constant("12"))
        CodeInputView(code: .constant("5423"))
    }
    .padding()
    .background(Color("MainBlue"))
}
