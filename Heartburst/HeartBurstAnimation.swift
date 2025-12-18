import SwiftUI

// MARK: - Heart Shape from your SVG
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        let scaleX = width / 20
        let scaleY = height / 20
        
        var path = Path()
        
        path.move(to: CGPoint(x: 16.6274 * scaleX, y: 11.2038 * scaleY))
        path.addLine(to: CGPoint(x: 11.4111 * scaleX, y: 16.553 * scaleY))
        path.addCurve(
            to: CGPoint(x: 8.58894 * scaleX, y: 16.553 * scaleY),
            control1: CGPoint(x: 10.6376 * scaleX, y: 17.3462 * scaleY),
            control2: CGPoint(x: 9.36244 * scaleX, y: 17.3462 * scaleY)
        )
        path.addLine(to: CGPoint(x: 3.37258 * scaleX, y: 11.2038 * scaleY))
        path.addCurve(
            to: CGPoint(x: 3.37258 * scaleX, y: 4.40754 * scaleY),
            control1: CGPoint(x: 1.54247 * scaleX, y: 9.32705 * scaleY),
            control2: CGPoint(x: 1.54247 * scaleX, y: 6.28427 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 10 * scaleX, y: 4.40754 * scaleY),
            control1: CGPoint(x: 5.20269 * scaleX, y: 2.53082 * scaleY),
            control2: CGPoint(x: 8.16989 * scaleX, y: 2.53082 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 16.6274 * scaleX, y: 4.40754 * scaleY),
            control1: CGPoint(x: 11.8301 * scaleX, y: 2.53082 * scaleY),
            control2: CGPoint(x: 14.7973 * scaleX, y: 2.53082 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 16.6274 * scaleX, y: 11.2038 * scaleY),
            control1: CGPoint(x: 18.4575 * scaleX, y: 6.28427 * scaleY),
            control2: CGPoint(x: 18.4575 * scaleX, y: 9.32705 * scaleY)
        )
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Sparkle Data
struct SparkleData: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let delay: Double
    let size: CGFloat
    let fadeDelay: Double  // How long before this sparkle starts fading
}

// MARK: - Heart Burst Button
struct HeartBurstButton: View {
    @State private var isLiked = false
    @State private var isPressed = false
    @State private var heartScale: CGFloat = 1.0
    @State private var heartFlip: Double = 0  // For backflip (3D rotation on X-axis)
    @State private var heartOffsetY: CGFloat = 0  // For jump effect
    @State private var pressScale: CGFloat = 1.0  // Shrinks while holding
    @State private var pressStartTime: Date? = nil
    @State private var ringScale: CGFloat = 0
    @State private var ringOpacity: Double = 0
    @State private var ringLineWidth: CGFloat = 24
    @State private var sparkleProgress: CGFloat = 0
    @State private var sparkleAnimating: Bool = false
    @State private var sparkleScale: CGFloat = 1.0
    
    let heartColor = Color(red: 1, green: 0.455, blue: 0.604) // #FF749A
    let outlineColor = Color(red: 0.416, green: 0.447, blue: 0.471) // #6A7278
    
    // Haptic feedback generator
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Regenerate sparkles with randomization on each tap
    @State private var sparkles: [SparkleData] = []
    
    func generateSparkles(pressDuration: Double) -> [SparkleData] {
        var result: [SparkleData] = []
        let nGroups = 7
        let nSparklesPerGroup = 2
        let groupBaseAngle = 360.0 / Double(nGroups)
        let sparkleBaseAngle = 360.0 / Double(nSparklesPerGroup)
        let sparkleOffAngle = 60.0
        
        let bubbleRadius: CGFloat = 24
        let sparkleDistance: CGFloat = 5
        
        // Distance multiplier scales same as heart: 3s=200%, 4s=300%, 5s+=400%
        let distanceMultiplier: CGFloat
        if pressDuration < 3 {
            distanceMultiplier = 1.0 + (0.1 * pressDuration)  // Subtle under 3s
        } else if pressDuration < 5 {
            distanceMultiplier = 2.0 + ((pressDuration - 3) * 1.0)  // 3s=2x, 4s=3x
        } else {
            distanceMultiplier = 4.0  // Max at 4x
        }
        
        for i in 0..<nGroups {
            // Add slight random angle variation (-8 to +8 degrees)
            let angleVariation = Double.random(in: -8...8)
            let groupAngle = Double(i) * groupBaseAngle - 90 + angleVariation
            
            // Randomize start and end radius slightly
            let startGroupR = bubbleRadius + CGFloat.random(in: -2...2)
            let baseEndMultiplier = CGFloat.random(in: 1.1...1.2)
            let endGroupR = bubbleRadius * baseEndMultiplier * distanceMultiplier
            
            for j in 0..<nSparklesPerGroup {
                let sparkleAngle = groupAngle + sparkleOffAngle + Double(j) * sparkleBaseAngle
                
                let startGroupX = startGroupR * CGFloat(cos(groupAngle * .pi / 180))
                let startGroupY = startGroupR * CGFloat(sin(groupAngle * .pi / 180))
                let startX = startGroupX + sparkleDistance * CGFloat(cos(sparkleAngle * .pi / 180))
                let startY = startGroupY + sparkleDistance * CGFloat(sin(sparkleAngle * .pi / 180))
                
                let endGroupX = endGroupR * CGFloat(cos(groupAngle * .pi / 180))
                let endGroupY = endGroupR * CGFloat(sin(groupAngle * .pi / 180))
                let endX = endGroupX + sparkleDistance * CGFloat(cos(sparkleAngle * .pi / 180))
                let endY = endGroupY + sparkleDistance * CGFloat(sin(sparkleAngle * .pi / 180))
                
                // Randomize delay slightly
                let delay = Double(i) * 0.015 + Double.random(in: 0...0.02)
                
                // Randomize size
                let size = CGFloat.random(in: 3...5)
                
                // First dot (j=0) fades faster, second dot (j=1) lingers longer
                let fadeDelay = Double(j) * 0.12 + Double.random(in: 0...0.03)
                
                result.append(SparkleData(
                    color: heartColor,
                    startX: startX,
                    startY: startY,
                    endX: endX,
                    endY: endY,
                    delay: delay,
                    size: size,
                    fadeDelay: fadeDelay
                ))
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            // Ring burst effect
            Circle()
                .stroke(heartColor, lineWidth: ringLineWidth)
                .frame(width: 48, height: 48)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            
            // Sparkles with individual delays
            ForEach(sparkles) { sparkle in
                SparkleView(
                    sparkle: sparkle,
                    progress: sparkleProgress,
                    scale: sparkleScale,
                    isAnimating: sparkleAnimating
                )
            }
            
            // Heart
            HeartShape()
                .fill(isLiked ? heartColor : .clear)
                .overlay(
                    HeartShape()
                        .stroke(isLiked ? heartColor : outlineColor, lineWidth: 1.5)
                )
                .frame(width: 24, height: 24)
                .scaleEffect(heartScale * pressScale)
                .rotation3DEffect(.degrees(heartFlip), axis: (x: 0, y: 1, z: 0))
                .offset(y: heartOffsetY)
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        pressStartTime = Date()
                        lightFeedback.impactOccurred()
                        
                        // Normal press down feel
                        withAnimation(.easeOut(duration: 0.1)) {
                            pressScale = 0.9
                        }
                    }
                }
                .onEnded { _ in
                    let pressDuration = pressStartTime.map { Date().timeIntervalSince($0) } ?? 0
                    isPressed = false
                    pressStartTime = nil
                    
                    // Reset press scale
                    withAnimation(.easeOut(duration: 0.1)) {
                        pressScale = 1.0
                    }
                    
                    toggleLike(pressDuration: pressDuration)
                }
        )
        .onAppear {
            impactFeedback.prepare()
            lightFeedback.prepare()
            sparkles = generateSparkles(pressDuration: 0)
        }
    }
    
    private func toggleLike(pressDuration: Double) {
        if isLiked {
            // Unlike
            lightFeedback.impactOccurred()
            withAnimation(.easeOut(duration: 0.15)) {
                isLiked = false
            }
        } else {
            // Like with burst animation
            impactFeedback.impactOccurred()
            isLiked = true
            
            // Intensity scales with hold duration
            let seconds = pressDuration
            let isSpecialFlip = seconds >= 5
            
            // Generate sparkles (distance scales only for 5s+ special flip)
            sparkles = generateSparkles(pressDuration: isSpecialFlip ? seconds : 0)
            
            // Reset states
            ringScale = 0
            ringOpacity = 0.25
            ringLineWidth = 24
            sparkleProgress = 0
            sparkleAnimating = false
            sparkleScale = 1.0
            heartFlip = 0
            heartOffsetY = 0
            
            // 1. Heart shrinks
            withAnimation(.easeIn(duration: 0.1)) {
                heartScale = 0
            }
            
            // 2. Ring expands and thins
            withAnimation(.easeOut(duration: 0.35)) {
                ringScale = 1
            }
            withAnimation(.easeOut(duration: 0.35)) {
                ringLineWidth = 0
            }
            withAnimation(.easeOut(duration: 0.15).delay(0.25)) {
                ringOpacity = 0
            }
            
            // 3. Heart pops back
            if isSpecialFlip {
                // 5s+ SURPRISE: Hop and flip!
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0).delay(0.1)) {
                    heartScale = 1.0
                }
                
                // Hop and flip - smooth with hang time at top
                let easeOutExpo = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.35)
                let easeInExpo = Animation.timingCurve(0.7, 0, 0.84, 0, duration: 0.3)
                
                // Up movement
                withAnimation(easeOutExpo) {
                    heartOffsetY = -15
                }
                // Pause at top, then down
                withAnimation(easeInExpo.delay(0.5)) {
                    heartOffsetY = 0
                }
                
                // Single 180° flip - slow for longer, speeds up at the very end
                let flipCurve = Animation.timingCurve(0.5, 0.05, 0.9, 0.3, duration: 0.8)
                
                withAnimation(flipCurve) {
                    heartFlip = 180
                }
                // Reset flip after landing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                    heartFlip = 0
                }
            } else {
                // Normal tap: simple bouncy pop
                withAnimation(.spring(response: 0.35, dampingFraction: 0.4, blendDuration: 0).delay(0.1)) {
                    heartScale = 1.0
                }
            }
            
            // 4. Sparkles appear and animate out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                sparkleAnimating = true
                sparkleScale = 1.0
                
                // Move outward
                withAnimation(.easeOut(duration: 0.5)) {
                    sparkleProgress = 1
                }
                
                // Scale down as they fade
                withAnimation(.easeIn(duration: 0.4).delay(0.1)) {
                    sparkleScale = 0
                }
            }
        }
    }
}

// MARK: - Individual Sparkle View
struct SparkleView: View {
    let sparkle: SparkleData
    let progress: CGFloat
    let scale: CGFloat
    let isAnimating: Bool
    
    @State private var opacity: Double = 0
    
    var body: some View {
        let currentX = sparkle.startX + (sparkle.endX - sparkle.startX) * progress
        let currentY = sparkle.startY + (sparkle.endY - sparkle.startY) * progress
        
        Circle()
            .fill(sparkle.color)
            .frame(width: sparkle.size, height: sparkle.size)
            .scaleEffect(scale)
            .offset(x: currentX, y: currentY)
            .opacity(opacity)
            .onChange(of: isAnimating) { _, animating in
                if animating {
                    // Fade in immediately
                    opacity = 1
                    // Fade out after individual delay
                    withAnimation(.easeOut(duration: 0.18).delay(sparkle.fadeDelay)) {
                        opacity = 0
                    }
                } else {
                    opacity = 0
                }
            }
    }
}

// MARK: - Demo View
struct HeartBurstDemo: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Tap the heart")
                    .foregroundColor(.black.opacity(0.5))
                    .font(.system(size: 14))
                
                HeartBurstButton()
            }
        }
    }
}

#Preview {
    HeartBurstDemo()
}
