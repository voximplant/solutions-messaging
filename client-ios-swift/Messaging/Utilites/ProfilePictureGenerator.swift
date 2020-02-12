/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

let UIScreenScale = UIScreen.main.scale
func floorToScreenPixels(_ value: CGFloat) -> CGFloat {
    return floor(value * UIScreenScale) / UIScreenScale
}


import Foundation
import UIKit

public final class ProfilePictureGenerator {
    
    static func generatePicture(with imageName: String?, and title: String, for bounds: CGRect) -> UIImage {
        if let imageName = imageName,
            let image = UIImage(named: imageName)
        { return image }
        else { return generateImage(bounds, with: title) }
    }
    
    static var randomColor: UIColor {
        let colors = [#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1),  #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),  #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1),  #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1),  #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1),  #colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1),  #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)]
        let random = Int(arc4random_uniform(UInt32(colors.count)))
        return colors[random]
    }
    
    private static func font(with bounds: CGRect) -> UIFont {
        return UIFont.systemFont(ofSize: bounds.height / 2, weight: .bold)
    }
    
    public static func generateImage(_ bounds: CGRect, with letters: String, color: UIColor? = nil) -> UIImage {
        let originalBounds = bounds
        
        let bounds = CGRect(x: 0,
                                 y: 0,
                                 width: originalBounds.width * UIScreenScale,
                                 height: originalBounds.height * UIScreenScale)
        UIGraphicsBeginImageContext(bounds.size)
        let context = UIGraphicsGetCurrentContext()!
        
        let color = color ?? randomColor
        
        context.beginPath()
        context.addEllipse(in: CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height:
            bounds.size.height))
        context.clip()
        
        let colorsArray: NSArray = [color.cgColor, color.withAlphaComponent(0.55).cgColor]
        
        var locations: [CGFloat] = [1.0, 0.0]
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colorsArray, locations: &locations)!
        
        context.drawLinearGradient(gradient, start: CGPoint(), end: CGPoint(x: 0.0, y: bounds.size.height), options: CGGradientDrawingOptions())
        
        context.setBlendMode(.normal)
        
        let string: String = {
            let componenst = letters.components(separatedBy: " ")
                .prefix(2)
                .filter { $0.isLetter }
                .map { $0.prefix(1).uppercased() }

            return componenst.joined()
        }()
        let attributedString = NSAttributedString(string: string, attributes: [NSAttributedString.Key.font: font(with: bounds), NSAttributedString.Key.foregroundColor: UIColor.white])
        
        let line = CTLineCreateWithAttributedString(attributedString)
        let lineBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        let lineOffset = CGPoint(x: string == "B" ? 1.0 : 0.0, y: 0.0)
        let lineOrigin = CGPoint(x: floorToScreenPixels(-lineBounds.origin.x + (bounds.size.width - lineBounds.size.width) / 2.0) + lineOffset.x, y: floorToScreenPixels(-lineBounds.origin.y + (bounds.size.height - lineBounds.size.height) / 2.0))
        
        context.translateBy(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -bounds.size.width / 2.0, y: -bounds.size.height / 2.0)

        context.translateBy(x: lineOrigin.x, y: lineOrigin.y)
        CTLineDraw(line, context)
        context.translateBy(x: -lineOrigin.x, y: -lineOrigin.y)
        
        let image = UIImage(cgImage: context.makeImage()!)
        UIGraphicsEndImageContext()
        
        return image
    }
    
    public static func generateSolidImage(of color: UIColor, with size: CGSize) -> UIImage {
        
        let bounds = CGRect(x: 0,
                            y: 0,
                            width: size.width * UIScreenScale,
                            height: size.height * UIScreenScale)
        UIGraphicsBeginImageContext(bounds.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.beginPath()
        context.addEllipse(in: CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height:
            bounds.size.height))
        context.clip()
        
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        let strokeRect = bounds
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(5 * UIScreenScale)
        context.strokeEllipse(in: strokeRect)
        
        context.setBlendMode(.normal)
        
        let image = UIImage(cgImage: context.makeImage()!)
        UIGraphicsEndImageContext()
        
        return image
    }
}



extension String  {
    var isLetter : Bool {
        get{
            return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.letters) != nil
        }
    }
}


extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}
extension Substring {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }
    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }
    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }
    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }
}
