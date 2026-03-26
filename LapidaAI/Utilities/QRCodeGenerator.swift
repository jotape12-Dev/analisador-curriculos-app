import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - QR Code Generator
struct QRCodeGenerator {
    static func generate(from string: String, size: CGFloat = 200) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - QR Code SwiftUI View
struct QRCodeView: View {
    let payload: String
    let size: CGFloat
    
    init(payload: String, size: CGFloat = 200) {
        self.payload = payload
        self.size = size
    }
    
    var body: some View {
        if let uiImage = QRCodeGenerator.generate(from: payload, size: size) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        } else {
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.surfaceLight)
                .frame(width: size, height: size)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.textTertiary)
                        Text("Erro ao gerar QR Code")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                )
        }
    }
}
