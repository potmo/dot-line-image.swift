import Foundation

extension PixelImage where T == Pixel {

    func luminances() -> [UInt8] {
        return pixels.map{ pixel in
            let r = Double(pixel.r) * 0.299
            let g = Double(pixel.g) * 0.587
            let b = Double(pixel.b) * 0.114
            let luminance = UInt8(r + g + b)
            return luminance
        }
    }

    func grayscaled() -> PixelImage {
        let newPixels = luminances().map{ luminance in
            return Pixel(a: 255, r: luminance, g: luminance, b: luminance)
        }

        return PixelImage<Pixel>(width: width, height: height, pixels: newPixels)
    }
}

extension PixelImage where T == Pixel {
    func thresholded(with threshold: UInt8) -> PixelImage {

        let pixels = self.luminances().map{ luminence in
            let value: UInt8 = luminence < threshold ? 0 : 255;
            return Pixel(a: 255, r: value, g: value, b: value)
        }

        return PixelImage(width: width, height: height, pixels: pixels)

    }
}

extension PixelImage where T == Pixel {
    func bayerDithered(with threshold: UInt8) -> PixelImage {
        let thresholdMap: [[UInt8]] = [
            [15, 135, 45, 165],
            [195, 75, 225, 105],
            [60, 180, 30, 150],
            [240, 120, 210, 90],
        ]

        let pixels = self.luminances().enumerated().map{ index, luminence in
            let x = index % width
            let y = index / width
            let map = UInt8((Int(luminence) + Int(thresholdMap[x % 4][y % 4])) / 2)
            let value: UInt8 = map < threshold ? 0 : 255;
            return Pixel(a: 255, r: value, g: value, b: value)
        }

        return PixelImage(width: width, height: height, pixels: pixels)
    }
}

extension PixelImage where T == Pixel{
    func floydSteinbergDithered() -> PixelImage {
        var luminances = self.luminances().map(Double.init)

        let pixels = stride(from: 0, to: luminances.count, by: 1).map{ index in

            let luminance = luminances[index]
            let value: Double = luminance < 129 ? 0 : 255
            let error = floor( (luminance - value) / 16 )

            if index + 1 < luminances.count  {luminances[index + 1] += error * 7 }
            if index + width - 1 < luminances.count  {luminances[index + width - 1] += error * 3 }
            if index + width < luminances.count  {luminances[index + width] += error * 5 }
            if index + width + 1 < luminances.count  {luminances[index + width + 1] += error * 1 }

            return UInt8(value)
        }.map{ value in
            return Pixel(a: 255, r: value, g: value, b: value)
        }

        return PixelImage(width: width, height: height, pixels: pixels)
    }
}

extension PixelImage where T == Pixel {
    func atkinsonDithered() -> PixelImage {
        var luminances = self.luminances().map(Double.init)

        let pixels = stride(from: 0, to: luminances.count, by: 1).map{ index in

            let luminance = luminances[index]
            let value: Double = luminance < 129 ? 0 : 255
            let error = floor( (luminance - value) / 8 )

            if index + 1 < luminances.count {luminances[index + 1] += error }
            if index + 2 < luminances.count {luminances[index + 2] += error }
            if index + width - 1 < luminances.count { luminances[index + width - 1] += error }
            if index + width < luminances.count {luminances[index + width] += error }
            if index + width + 1 < luminances.count {luminances[index + width + 1] += error }
            if index + 2 * width < luminances.count {luminances[index + 2 * width] += error }

            return UInt8(value)
        }.map{ value in
            return Pixel(a: 255, r: value, g: value, b: value)
        }

        return PixelImage(width: width, height: height, pixels: pixels)
    }
}
