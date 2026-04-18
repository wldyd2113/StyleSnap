import SwiftUI

// MARK: - Color Harmony Engine
final class ColorHarmonyEngine {
    static let shared = ColorHarmonyEngine()
    private init() {}
    
    func getHarmoniousColors(for color: Color) -> [Color] {
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // 1. 톤온톤 (유사 색상, 낮은 채도)
        let toneOnTone = Color(hue: h, saturation: s * 0.4, brightness: b > 0.5 ? b - 0.1 : b + 0.1)
        
        // 2. 보색 (색상 반전)
        let complementary = Color(hue: fmod(h + 0.5, 1.0), saturation: s, brightness: b)
        
        // 3. 유사색 1 (색상 +30도 회전) - 흰색 대신 계산된 색상 사용
        let analogous1 = Color(hue: fmod(h + 0.08, 1.0), saturation: s * 0.8, brightness: b)
        
        // 4. 유사색 2 (색상 -30도 회전) - 검은색 대신 계산된 색상 사용
        let analogous2 = Color(hue: fmod(h + 0.92, 1.0), saturation: s * 0.8, brightness: b)
        
        return [toneOnTone, complementary, analogous1, analogous2]
    }
}
