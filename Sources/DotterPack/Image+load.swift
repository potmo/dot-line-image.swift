import SwiftUI
import Foundation

extension Image {
    init(packageResource name: String, ofType type: String) {
#if canImport(UIKit)
        guard let path = Bundle.module.path(forResource: name, ofType: type) else {
            print("UIKit could not find path for resource: \(name) of type: \(type)")
            self.init(name)
            return
        }

        guard let image = UIImage(contentsOfFile: path) else {
            print("UIKit could not create image for path: \(path)")
            self.init(name)
            return
        }

        self.init(uiImage: image)
#elseif canImport(AppKit)

        guard let path = Bundle.module.path(forResource: name, ofType: type) else {
            print("Appkit could not find path for resource: \(name) of type: \(type)")
            self.init(name)
            return
        }

        guard let image = NSImage(contentsOfFile: path) else {
            print("Appkit could not create image for path: \(path)")
            self.init(name)
            return
        }
        self.init(nsImage: image)
#else
        fatalError("This extension can only be used in contexts where UIKit or AppKit can be imported")
#endif
    }
}


