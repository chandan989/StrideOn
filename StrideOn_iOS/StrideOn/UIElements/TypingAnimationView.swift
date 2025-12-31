import SwiftUI

struct TypingAnimationView: View {
    
    @State private var bounceCircle1 = false
    @State private var bounceCircle2 = false
    @State private var bounceCircle3 = false
    var color: Color
    var size: CGFloat = 12
    var spacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: spacing) {
            Circle()
                .frame(width: size, height: size)
                .offset(y: bounceCircle1 ? -10 : 0)
            Circle()
                .frame(width: size, height: size)
                .offset(y: bounceCircle2 ? -10 : 0)
            Circle()
                .frame(width: size, height: size)
                .offset(y: bounceCircle3 ? -10 : 0)
        }
        .foregroundColor(color)
        .onAppear {
            performBounceAnimation()
        }
    }
    
    func performBounceAnimation() {
        let animationDuration = 0.4
        let delayBetweenCircles = 0.2
        let delayAfterCycle = 0.3
        
        func animateCircle(_ circleNumber: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(circleNumber) * delayBetweenCircles) {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    switch circleNumber {
                    case 0: bounceCircle1.toggle()
                    case 1: bounceCircle2.toggle()
                    case 2: bounceCircle3.toggle()
                    default: break
                    }
                }
                
                // Reset the circle after the animation
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        switch circleNumber {
                        case 0: bounceCircle1.toggle()
                        case 1: bounceCircle2.toggle()
                        case 2: bounceCircle3.toggle()
                        default: break
                        }
                    }
                }
            }
        }
        
        func animateCycle() {
            for i in 0...2 {
                animateCircle(i)
            }
            
            // Schedule the next cycle
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 3 * delayBetweenCircles + delayAfterCycle) {
                animateCycle()
            }
        }
        
        animateCycle()
    }
}

struct TypingAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        TypingAnimationView(color: .black)
    }
}
