import UIKit

struct CharacterAssets {
    
    // Centralized relative and absolute paths to the mannequin image files
    static var baseAssetsDir: String {
        return URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Assets").path
    }
    
    /// A robust helper to load resources correctly from the bundle on a physical device,
    /// while falling back to the compile-time absolute path on the simulator.
    static func loadFromBundle(name: String) -> UIImage? {
        let nameLower = name.lowercased()
        
        // 1. Try standard UIImage(named:)
        if let img = UIImage(named: name) {
            return img
        }
        if let img = UIImage(named: nameLower) {
            return img
        }
        
        // 2. Try directly from the Main Bundle (root level)
        if let path = Bundle.main.path(forResource: name, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        if let path = Bundle.main.path(forResource: nameLower, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        
        // 3. Try explicit known paths including the nested Modules folder
        let fileManager = FileManager.default
        if let resourcePath = Bundle.main.resourcePath {
            let possiblePaths = [
                "\(resourcePath)/\(name).png",
                "\(resourcePath)/\(nameLower).png",
                "\(resourcePath)/Assets/\(name).png",
                "\(resourcePath)/Assets/\(nameLower).png",
                "\(resourcePath)/Auth/Assets/\(name).png",
                "\(resourcePath)/Auth/Assets/\(nameLower).png",
                "\(resourcePath)/Modules/Auth/Assets/\(name).png",
                "\(resourcePath)/Modules/Auth/Assets/\(nameLower).png"
            ]
            for p in possiblePaths {
                if fileManager.fileExists(atPath: p) {
                    if let img = UIImage(contentsOfFile: p) {
                        return img
                    }
                }
            }
            
            // 4. Fallback to a recursive directory scan of the entire bundle
            if let enumerator = fileManager.enumerator(atPath: resourcePath) {
                while let subPath = enumerator.nextObject() as? String {
                    let filename = (subPath as NSString).lastPathComponent
                    let filenameWithoutExtension = (filename as NSString).deletingPathExtension.lowercased()
                    let ext = (filename as NSString).pathExtension.lowercased()
                    if filenameWithoutExtension == nameLower && ext == "png" {
                        let fullPath = "\(resourcePath)/\(subPath)"
                        if fileManager.fileExists(atPath: fullPath), let img = UIImage(contentsOfFile: fullPath) {
                            print("DEBUG SUCCESS: Found asset recursively at \(fullPath)")
                            return img
                        }
                    }
                }
            }
        }
        
        // 5. Fallback to compile-time Mac filesystem directory (for Simulator)
        let devPath = "\(baseAssetsDir)/\(name).png"
        if fileManager.fileExists(atPath: devPath) {
            return UIImage(contentsOfFile: devPath)
        }
        let devPathLower = "\(baseAssetsDir)/\(nameLower).png"
        if fileManager.fileExists(atPath: devPathLower) {
            return UIImage(contentsOfFile: devPathLower)
        }
        
        print("DEBUG ERROR: Asset not found: \(name)")
        return nil
    }
    
    /// Loads the male base mannequin image.
    static func maleImage() -> UIImage? {
        return loadFromBundle(name: "avatar_male")
    }
    
    /// Loads the female base mannequin image.
    static func femaleImage() -> UIImage? {
        return loadFromBundle(name: "avatar_female")
    }
    
    /// Resolves the base mannequin image depending on the gender.
    static func baseMannequin(for gender: Gender) -> UIImage? {
        return gender == .male ? maleImage() : femaleImage()
    }
    
    /// Loads a pre-aligned overlay image from the Assets folder.
    static func loadOverlay(name: String) -> UIImage? {
        return loadFromBundle(name: name)
    }
}
