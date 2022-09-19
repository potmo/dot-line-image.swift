import Foundation
import AppKit
import Cocoa

struct Pixel {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
    init(a:UInt8, r: UInt8, g: UInt8, b: UInt8) {
        self.a = a
        self.r = r
        self.g = g
        self.b = b
    }

    init(value: UInt32) {
        let r = UInt8(value & 0xFF)
        let g = UInt8((value >> 8) & 0xFF)
        let b = UInt8((value >> 16) & 0xFF)
        let a = UInt8((value >> 24) & 0xFF)
        self.init(a: a, r: r, g: g, b: b)
    }

    var int: UInt32 {
        return UInt32(a) << 24 | UInt32(b) << 16 | UInt32(g) << 8 | UInt32(r)
    }

}

struct MonochromePixelImage {
    let width: Int
    let height: Int
    var pixels: [Bool]

    subscript(x: Int, y: Int) -> Bool {
        get {
            let index = getIndex(x,y)
            return pixels[index]
        }
        set(newValue) {
            let index = getIndex(x,y)
            pixels[index] = newValue
        }
    }

    private func getIndex(_ x: Int, _ y: Int) -> Int {
        guard self.contains(x, y) else {
            fatalError("\(x), \(y) is outside \(width), \(height)")
        }

        return y * width + x
    }

    func contains(_ x: Int, _ y: Int) -> Bool {
        return (0 ..< width).contains(x) && (0 ..< height).contains(y)
    }
}

struct PixelImage {
    let width: Int
    let height: Int
    var pixels: [Pixel]

    subscript(x: Int, y: Int) -> Pixel {
        get {
            let index = getIndex(x,y)
            return pixels[index]
        }
        set(newValue) {
            let index = getIndex(x,y)
            pixels[index] = newValue
        }
    }

    var matrix: [[Pixel]] {
        return stride(from: 0, to: width, by: 1).map{ x in
            return stride(from: 0, to: height, by: 1).map{ y in
                return self[x, y]
            }
        }
    }

    private func getIndex(_ x: Int, _ y: Int) -> Int {
        guard  self.contains(x, y) else {
            fatalError("\(x), \(y) is outside \(width), \(height)")
        }

        return y * width + x
    }

    func contains(_ x: Int, _ y: Int) -> Bool {
        return (0 ..< width).contains(x) && (0 ..< height).contains(y)
    }
}

extension PixelImage {
    func monochromed() -> MonochromePixelImage {
        let pixels = self.pixels.map{ $0.r == 0}
        return MonochromePixelImage(width: width, height: height, pixels: pixels)
    }
}

extension MonochromePixelImage {
    func fullColored() -> PixelImage {
        let pixels = self.pixels.map{ Pixel(a: 255, r: $0 ? 255 : 0, g: $0 ? 255 : 0, b: $0 ? 255 : 0)}
        return PixelImage(width: width, height: height, pixels: pixels)
    }
}


extension PixelImage {
    func rotatedCCW() -> PixelImage{

        let n = width
        let x = Int(floor(Double(n) / 2))
        let y = n - 1

        var pixels = self.pixels

        for i in 0 ..< x {
            for j in i ..< (y - i) {
                let k = pixels[getIndex(i,j)];
                pixels[getIndex(i,j)] = pixels[getIndex(y-j,i)]
                pixels[getIndex(y-j,i)] = pixels[getIndex(y-i,y-j)]
                pixels[getIndex(y-i,y-j)] = pixels[getIndex(j,y - i)]
                pixels[getIndex(j,y-i)] = k
            }
        }

        return PixelImage(width: width, height: height, pixels: pixels)

    }
}

extension NSImage {
    func pixelImage() -> PixelImage {

        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("could not get CGImage")
        }

        // Redraw image for correct pixel format
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let bytesPerRow = width * 4

        let imageData = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)

        guard let imageContext = CGContext(
            data: imageData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            fatalError("could not create CGContext")
        }

        imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let rawPixels = UnsafeMutableBufferPointer<UInt32>(start: imageData, count: width * height)

        let pixels = rawPixels.map(Pixel.init)

        return PixelImage(width: width, height: height, pixels: pixels)

    }
}

extension PixelImage {
    func toImage() -> NSImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue

        let imageData = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
        let dataPixels = UnsafeMutableBufferPointer<UInt32>(start: imageData, count: width * height)

        pixels.map(\.int).enumerated().forEach{ index, value in
            dataPixels[index] = value
        }

        let bytesPerRow = width * 4

        guard let context = CGContext(
            data: dataPixels.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            releaseCallback: nil,
            releaseInfo: nil
        ) else {
            fatalError("could not create CGContext")
        }

        guard let cgImage = context.makeImage() else {
            fatalError("could not create CGImage")
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}


