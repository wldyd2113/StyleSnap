import SwiftUI

// MARK: - Color Harmony Engine
final class ColorHarmonyEngine {
    static let shared = ColorHarmonyEngine()
    private init() {}
    
    func getHarmoniousColors(for color: Color) -> [Color] {
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // 1. 차분한 톤온톤 (채도 낮춤, 밝기 조절)
        let toneOnTone1 = Color(hue: h, saturation: s * 0.3, brightness: b > 0.5 ? b - 0.2 : b + 0.2)
        
        // 2. 밝은 톤온톤 (채도 유지, 밝기 높임)
        let toneOnTone2 = Color(hue: h, saturation: s * 0.5, brightness: min(b + 0.3, 1.0))
        
        // 3. 감각적인 보색 (180도 반전)
        let complementary = Color(hue: fmod(h + 0.5, 1.0), saturation: s, brightness: b)
        
        // 4. 세련된 유사색 (따뜻한 느낌, +30도)
        let analogous1 = Color(hue: fmod(h + 0.08, 1.0), saturation: s * 0.8, brightness: b)
        
        // 5. 시원한 유사색 (차가운 느낌, -30도)
        let analogous2 = Color(hue: fmod(h + 0.92, 1.0), saturation: s * 0.8, brightness: b)
        
        return [toneOnTone1, toneOnTone2, complementary, analogous1, analogous2]
    }
}
