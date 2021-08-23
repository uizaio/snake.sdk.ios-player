import UIKit

extension UIImage {
	
	open func colorize(with color: UIColor, blendMode: CGBlendMode = .multiply) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
		guard let context = UIGraphicsGetCurrentContext() else { return self }
		
		// flip the image
		context.scaleBy(x: 1.0, y: -1.0)
		context.translateBy(x: 0.0, y: -self.size.height)
		
		// multiply blend mode
		context.setBlendMode(blendMode)
		
		let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
		context.clip(to: rect, mask: self.cgImage!)
		color.setFill()
		context.fill(rect)
		
		// create UIImage
		guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
		UIGraphicsEndImageContext()
		
		return newImage.resizableImage(withCapInsets: self.capInsets, resizingMode: self.resizingMode)
	}
    
    // colorize image with given tint color
    // this is similar to Photoshop's "Color" layer blend mode
    // this is perfect for non-greyscale source images, and images that have both highlights and shadows that should be preserved
    // white will stay white and black will stay black as the lightness of the image is preserved
    func tint(with color: UIColor) -> UIImage {
        
        return modifiedImage { context, rect in
            // draw black background - workaround to preserve color of partially transparent pixels
            context.setBlendMode(.normal)
            UIColor.black.setFill()
            context.fill(rect)
            
            // draw original image
            context.setBlendMode(.normal)
            context.draw(self.cgImage!, in: rect)
            
            // tint image (loosing alpha) - the luminosity of the original image is preserved
            context.setBlendMode(.color)
            color.setFill()
            context.fill(rect)
            
            // mask by alpha values of original image
            context.setBlendMode(.destinationIn)
            context.draw(self.cgImage!, in: rect)
        }
    }
    
    // fills the alpha channel of the source image with the given color
    // any color information except to the alpha channel will be ignored
    func fillAlpha(fillColor: UIColor) -> UIImage {
        
        return modifiedImage { context, rect in
            // draw tint color
            context.setBlendMode(.normal)
            fillColor.setFill()
            context.fill(rect)
//            context.fillCGContextFillRect(context, rect)
            
            // mask by alpha values of original image
            context.setBlendMode(.destinationIn)
            context.draw(self.cgImage!, in: rect)
        }
    }
    
    private func modifiedImage( draw: (CGContext, CGRect) -> Void) -> UIImage {
        
        // using scale correctly preserves retina images
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context: CGContext! = UIGraphicsGetCurrentContext()
        assert(context != nil)
        
        // correctly rotate image
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        
        draw(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
}
