//
//  ReflectiveGradientView.swift
//  Internet Archive Player
//
//  Created by Hunter Lee Brown on 12/14/24.
//

import SwiftUI

struct ReflectiveGradientView: View {
    let image: UIImage
    let gradient: Gradient

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // The gradient behind the image
                LinearGradient(
                    gradient: gradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )

                // The image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
            }
        }
    }
}

extension UIImage {
    func gradientFromTopToBottom() -> Gradient? {
        guard let inputImage = CIImage(image: self) else { return nil }

        // Extract top region's dominant color
        let topColor = dominantColor(for: inputImage, in: CGRect(x: 0, y: 0, width: inputImage.extent.width, height: inputImage.extent.height / 2))

        // Extract bottom region's dominant color
        let bottomColor = dominantColor(for: inputImage, in: CGRect(x: 0, y: inputImage.extent.height / 2, width: inputImage.extent.width, height: inputImage.extent.height / 2))

        // Create gradient if both colors exist
        if let top = topColor, let bottom = bottomColor {
            return Gradient(colors: [Color(top), Color(bottom)])
        }

        return nil
    }

    private func dominantColor(for ciImage: CIImage, in rect: CGRect) -> UIColor? {
        let extentVector = CIVector(x: rect.origin.x, y: rect.origin.y, z: rect.size.width, w: rect.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]),
              let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: CGFloat(bitmap[3]) / 255.0
        )
    }
}
