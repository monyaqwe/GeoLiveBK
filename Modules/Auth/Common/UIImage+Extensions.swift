import UIKit

extension UIImage {
    
    // Legacy support: delegates to the high-fidelity customizedAvatar method
    func removingWhiteBackground() -> UIImage? {
        return self.customizedAvatar(
            gender: .male,
            skinColor: .clear,
            hair: nil,
            hat: nil,
            glasses: nil,
            beard: nil,
            clothing: nil
        )
    }
    
    func customizedAvatar(
        gender: Gender,
        skinColor: UIColor,
        hair: String?,
        hat: String?,
        glasses: String?,
        beard: String?,
        clothing: String?
    ) -> UIImage? {
        let canvasSize = CGSize(width: 1024, height: 1024)
        
        // We create a transparent context of exactly 1024x1024 pixels
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 1.0)
        
        // Configure current Graphics Context for studio-grade, professional image rendering
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            context.setShouldAntialias(true)
            context.setAllowsAntialiasing(true)
        }
        
        // 1. Draw base character image (will be drawn right-side up)
        self.draw(in: CGRect(origin: .zero, size: canvasSize))
        
        let genderStr = (gender == .male) ? "male" : "female"
        
        // Helper to load and draw a pre-aligned transparent PNG overlay
        func drawOverlay(named name: String) {
            if let overlayImage = CharacterAssets.loadOverlay(name: name) {
                overlayImage.draw(in: CGRect(origin: .zero, size: canvasSize))
            }
        }
        
        // A. Draw Clothing overlay
        if let clothing = clothing {
            if clothing == "👕" || clothing == "cloth_polo" {
                drawOverlay(named: "\(genderStr)_cloth_polo")
            } else if clothing == "👔" || clothing == "cloth_red_polo" {
                drawOverlay(named: "\(genderStr)_cloth_red_polo")
            }
        }
        
        // B. Draw Hair Style overlay
        if let hairType = hair {
            if hairType == "hair_short" || hairType.contains("💇") {
                drawOverlay(named: "\(genderStr)_hair_short")
            } else if hairType == "hair_curly" || hairType.contains("🦱") || hairType.contains("🧑") {
                drawOverlay(named: "\(genderStr)_hair_curly")
            }
        }
        
        // C. Draw Beard overlay (Male only)
        if gender == .male, let beardType = beard {
            if beardType == "beard_mustache" || beardType.contains("👨") || beardType.contains("mustache") {
                drawOverlay(named: "male_beard_mustache")
            } else if beardType == "beard_full" || beardType == "🧔" || beardType.contains("🧔") {
                drawOverlay(named: "male_beard_full")
            }
        }
        
        // D. Draw Glasses overlay
        if let glassesType = glasses {
            if glassesType == "glass_retro" || glassesType.contains("🕶") {
                drawOverlay(named: "\(genderStr)_glass_retro")
            } else if glassesType == "glass_classic" || glassesType.contains("👓") {
                drawOverlay(named: "\(genderStr)_glass_classic")
            }
        }
        
        // E. Draw Hat overlay
        if let hatType = hat {
            if hatType == "👑" || hatType == "hat_crown" {
                drawOverlay(named: "\(genderStr)_hat_crown")
            } else if hatType == "🧢" || hatType == "hat_cap" {
                drawOverlay(named: "\(genderStr)_hat_cap")
            }
        }
        
        let customizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return customizedImage
    }
    
    // Auxiliary helper for channel value bounding
    private func clip(_ val: CGFloat) -> CGFloat {
        return max(0.0, min(255.0, val))
    }
}

