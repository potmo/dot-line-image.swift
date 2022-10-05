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

struct PixelImage<T> {
    let width: Int
    let height: Int
    var pixels: [T]

    subscript(x: Int, y: Int) -> T {
        get {
            let index = getIndex(x,y)
            return pixels[index]
        }
        set(newValue) {
            let index = getIndex(x,y)
            pixels[index] = newValue
        }
    }

    var matrix: [[T]] {
        return stride(from: 0, to: width, by: 1).map{ x in
            return stride(from: 0, to: height, by: 1).map{ y in
                let index = y * width + x
                return pixels[index]
            }
        }
    }

    var diagonals: [[T]] {
        var diagonals: [[T]] = []
        diagonals.reserveCapacity(width + height - 2)
        let matrix = self.matrix

        for k in 0 ... (width + height - 2) {
            var diagonal:[T] = []
            diagonal.reserveCapacity(k)
            for j in 0 ... k {
                let i = k - j;
                if( i < height && j < width ) {
                    diagonal.append(matrix[j][i])
                }
            }

            diagonals.append(diagonal)
        }

        return diagonals
    }

    private func getIndex(_ x: Int, _ y: Int) -> Int {
        guard  self.contains(x, y) else {
            fatalError("\(x), \(y) is outside \(width), \(height)")
        }

        return y * width + x
    }

    private func getCoordinate(from index: Int) -> (x: Int, y: Int) {
        let x = index % width
        let y = index / width
        return (x: x, y: y)
    }

    func contains(_ x: Int, _ y: Int) -> Bool {
        return (0 ..< width).contains(x) && (0 ..< height).contains(y)
    }
}

extension PixelImage where T == Pixel {
    func monochromed() -> PixelImage<Bool> {
        let pixels = self.pixels.map{ $0.r == 0}
        return PixelImage<Bool>(width: width, height: height, pixels: pixels)
    }
}

extension PixelImage where T == Bool {
    func labeled() -> PixelImage<LabeledBool> {
        /*
        let pixels = self.pixels.enumerated().map{ index, value in
            let (x, y) = self.getCoordinate(from: index)
            return LabeledBool(x: x, y: y, value: value)
        }
        return PixelImage<LabeledBool>(width: width, height: height, pixels: pixels)
         */

        var output: [LabeledBool] = Array(repeating: LabeledBool(x: 0, y: 0, value: false), count: pixels.count)

        for x in 0 ..< width {
            for y in 0 ..< height {
                let index = y * width + x
                let value = pixels[index]
                output[index] = LabeledBool(x: x, y: y, value: value)
            }
        }

        return PixelImage<LabeledBool>(width: width, height: height, pixels: output)

    }
}

extension PixelImage where T == Bool {

}

struct LabeledBool: Equatable, Alignable {

    let x: Int
    let y: Int
    let value: Bool

    /*static func == (lhs: LabeledBool, rhs: LabeledBool) -> Bool {
        return lhs.value == rhs.value
    }*/

    func alignsWith(_ other: LabeledBool) -> Bool {
        return self.value && other.value
    }

    func alignmentScore(_ other: LabeledBool) -> Double {
        switch (self.value, other.value) {
            case (true, true):
                return 1.0
            case (false, false):
                return 0.8
            default:
                return 0.5
        }
    }

    func printValue() -> String {
        return value ? "■" : "□"
    }
}

extension Array where Element == LabeledBool {
    var string: String {
        return self.map{ pixel in
            let x = "\(pixel.x)"
            let y = "\(pixel.y)"
            return "\(pixel.printValue())" + "(\(x), \(y))".leftPad(toLength: 8)
        }.joined(separator: " ")
    }
}


extension PixelImage {
    func rotatedCCW() -> PixelImage<T>{

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
    func pixelImage() -> PixelImage<Pixel> {

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

        return PixelImage<Pixel>(width: width, height: height, pixels: pixels)

    }
}

extension PixelImage where T == Pixel {
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


