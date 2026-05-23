import Cocoa

let femalePath = "/Users/makarmonko/Downloads/geocity-main 2/Modules/Auth/Assets/avatar_male.png"
guard let image = NSImage(contentsOfFile: femalePath),
      let tiff = image.tiffRepresentation,
      let imageRep = NSBitmapImageRep(data: tiff) else {
    print("Failed to load image")
    exit(1)
}

let width = imageRep.pixelsWide
let height = imageRep.pixelsHigh
print("Loaded female image: \(width)x\(height)")
if let color = imageRep.colorAt(x: 0, y: 0) {
    let r = Int(color.redComponent * 255)
    let g = Int(color.greenComponent * 255)
    let b = Int(color.blueComponent * 255)
    print("Female 0,0 RGB: (\(r),\(g),\(b))")
}


var bgCount = 0
var bodyHighlightCount = 0

// First, let's run a BFS from the edges using a very safe background check (RGB >= 228)
// to identify the true background pixels.
var isBackground = [Bool](repeating: false, count: width * height)
var queue = [Int]()

// Initialize from all four edges
for x in 0..<width {
    queue.append(x)
    isBackground[x] = true
    let bottomIdx = (height - 1) * width + x
    queue.append(bottomIdx)
    isBackground[bottomIdx] = true
}
for y in 0..<height {
    let leftIdx = y * width
    queue.append(leftIdx)
    isBackground[leftIdx] = true
    let rightIdx = y * width + (width - 1)
    queue.append(rightIdx)
    isBackground[rightIdx] = true
}

var head = 0
while head < queue.count {
    let currIdx = queue[head]
    head += 1
    
    let cx = currIdx % width
    let cy = currIdx / width
    
    let dx = [0, 0, -1, 1]
    let dy = [-1, 1, 0, 0]
    for i in 0..<4 {
        let nx = cx + dx[i]
        let ny = cy + dy[i]
        if nx >= 0 && nx < width && ny >= 0 && ny < height {
            let nIdx = ny * width + nx
            if !isBackground[nIdx] {
                if let color = imageRep.colorAt(x: nx, y: ny) {
                    let r = Int(color.redComponent * 255)
                    let g = Int(color.greenComponent * 255)
                    let b = Int(color.blueComponent * 255)
                    // If it is light colored like the background
                    if r >= 228 && g >= 228 && b >= 228 {
                        isBackground[nIdx] = true
                        queue.append(nIdx)
                    }
                }
            }
        }
    }
}

// Now let's group all unvisited pixels with RGB >= 228 into connected components
var visitedIsolated = [Bool](repeating: false, count: width * height)
var componentSizes = [Int]()

for y in 0..<height {
    for x in 0..<width {
        let index = y * width + x
        if isBackground[index] || visitedIsolated[index] { continue }
        
        if let color = imageRep.colorAt(x: x, y: y) {
            let r = Int(color.redComponent * 255)
            let g = Int(color.greenComponent * 255)
            let b = Int(color.blueComponent * 255)
            
            if r >= 228 && g >= 228 && b >= 228 {
                // Found a new isolated component, let's run BFS to find its size
                var compQueue = [index]
                visitedIsolated[index] = true
                var headIdx = 0
                
                while headIdx < compQueue.count {
                    let currIdx = compQueue[headIdx]
                    headIdx += 1
                    
                    let cx = currIdx % width
                    let cy = currIdx / width
                    
                    let dx = [0, 0, -1, 1]
                    let dy = [-1, 1, 0, 0]
                    for i in 0..<4 {
                        let nx = cx + dx[i]
                        let ny = cy + dy[i]
                        if nx >= 0 && nx < width && ny >= 0 && ny < height {
                            let nIdx = ny * width + nx
                            if !isBackground[nIdx] && !visitedIsolated[nIdx] {
                                if let nColor = imageRep.colorAt(x: nx, y: ny) {
                                    let nr = Int(nColor.redComponent * 255)
                                    let ng = Int(nColor.greenComponent * 255)
                                    let nb = Int(nColor.blueComponent * 255)
                                    if nr >= 228 && ng >= 228 && nb >= 228 {
                                        visitedIsolated[nIdx] = true
                                        compQueue.append(nIdx)
                                    }
                                }
                            }
                        }
                    }
                }
                
                componentSizes.append(compQueue.count)
                if compQueue.count > 10 {
                    print("Found isolated component of size \(compQueue.count) starting at \(x),\(y)")
                }
            }
        }
    }
}

let sortedSizes = componentSizes.sorted(by: >)
print("Sorted component sizes: \(sortedSizes.prefix(20))")
print("Total isolated pixels: \(sortedSizes.reduce(0, +))")

