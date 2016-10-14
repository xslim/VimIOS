//
//  VimView.swift
//  VimIOS
//
//  Created by Lars Kindler on 31/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

import UIKit
import CoreText

struct font{
    static let name = "Menlo-Regular"
    static let size =  CGFloat(14)
}

struct FontProperties{
}

class VimView: UIView {
    var dirtyRect = CGRectZero
    var shellLayer : CGLayerRef?
    var shellSize = 1366
    
    var char_ascent=CGFloat(0)
    var char_width=CGFloat(0)
    var char_height=CGFloat(0)
    
    var bgcolor:CGColorRef?
    var fgcolor:CGColorRef?
    var spcolor:CGColorRef?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shellSize = max(Int(UIScreen.mainScreen().bounds.width), Int(UIScreen.mainScreen().bounds.height))
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    override func drawRect(rect: CGRect) {
        guard let layer = shellLayer else {
            let scale = UIScreen.mainScreen().scale
            
            shellLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext()!, CGSizeMake(CGFloat(shellSize)*scale, CGFloat(shellSize)*scale), nil)
            let layerContext = CGLayerGetContext(shellLayer!)
            
            CGContextScaleCTM(layerContext!, scale,scale)
            return
        }
        //print("DrawRect \(rect)")
        
        if( !CGRectEqualToRect(rect, CGRectZero)) {
            let context = UIGraphicsGetCurrentContext()
            CGContextSaveGState(context!)
            CGContextBeginPath(context!)
            CGContextAddRect(context!, rect)
            CGContextClip(context!)
            let bounds = CGRectMake(0,0,CGFloat(shellSize),CGFloat(shellSize))
            CGContextDrawLayerInRect(context!, bounds, layer)
            CGContextRestoreGState(context!)
            dirtyRect=CGRectZero
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeShell()
    }
    
    func resizeShell() {
        print("Resizing to \(frame)")
        gui_resize_shell(CInt(frame.width), CInt(frame.height))
    }
    
    
    
    func CGLayerCopyRectToRect(layer: CGLayerRef? , sourceRect: CGRect , targetRect: CGRect) {
        guard let layer = layer else {return}
        
        let context = CGLayerGetContext(layer)
        
        var destinationRect = targetRect
        destinationRect.size.width = min(targetRect.size.width, sourceRect.size.width)
        destinationRect.size.height = min(targetRect.size.height, sourceRect.size.height)
        
        CGContextSaveGState(context!)
        
        CGContextBeginPath(context!)
        CGContextAddRect(context!, destinationRect)
        CGContextClip(context!)
        let size = CGLayerGetSize(layer)
        
        CGContextDrawLayerInRect(context!, CGRectMake(destinationRect.origin.x - sourceRect.origin.x, destinationRect.origin.y - sourceRect.origin.y, size.width/2, size.height/2),layer);
        //    CGContextDrawLayerAtPoint(context, CGPointMake(destinationRect.origin.x - sourceRect.origin.x, destinationRect.origin.y - sourceRect.origin.y), layer);
        
        
        dirtyRect = CGRectUnion(dirtyRect, destinationRect)
        CGContextRestoreGState(context!)
    }
    func CGLayerCopyRectToRect(sourceRect: CGRect , targetRect: CGRect) {
        CGLayerCopyRectToRect(shellLayer, sourceRect: sourceRect, targetRect: targetRect)
    }

    func flush(){
        CGContextFlush(CGLayerGetContext(shellLayer!)!)
        self.setNeedsDisplayInRect(dirtyRect)
//        if(dirtyRect.height>1) {
//                print(dirtyRect)
//        }
        
        
    }
    
    func clearAll() {
        if let layer = shellLayer {
        let  size = CGLayerGetSize(layer)
        
        fillRectWithColor(CGRectMake(0,0,size.width,size.height), color: bgcolor ?? UIColor.blackColor().CGColor)
        dirtyRect=self.bounds
   //         print("ClearALL \(CGColorGetComponents(bgcolor)), \(size.width), \(size.height), \(self.bounds)")
        self.setNeedsDisplayInRect(dirtyRect)
        }
    }
    
    func fillRectWithColor(rect: CGRect, color: CGColorRef?) {
            //print("In fillRectWithColor \(rect), \(color)")
        if let layer = shellLayer, let color = color {
            let context = CGLayerGetContext(layer)
            CGContextSetFillColorWithColor(context!, color)
            CGContextFillRect(context!, rect)
            dirtyRect = CGRectUnion(dirtyRect, rect)
            self.setNeedsDisplayInRect(dirtyRect)
            }
    }
    
    func drawString(s:NSAttributedString,
        font: CTFontRef,
        pos_x:CGFloat,
        pos_y: CGFloat,
        rect:CGRect,
        p_antialias: Bool,
        transparent: Bool,
        cursor: Bool) {
            
            guard let context = CGLayerGetContext(shellLayer!) else{ return}
            CGContextSetShouldAntialias(context, p_antialias);
            CGContextSetAllowsAntialiasing(context, p_antialias);
            CGContextSetShouldSmoothFonts(context, p_antialias);
            
            CGContextSetCharacterSpacing(context, 0);
            CGContextSetTextDrawingMode(context, .Fill)
            
            
            if(transparent) {
                CGContextSetFillColorWithColor(context, bgcolor!)
                CGContextFillRect(context, rect)
            }
            
            
            CGContextSetFillColorWithColor(context, fgcolor!);
//            let attributes : [String:AnyObject] = ([NSFontAttributeName:font, (kCTForegroundColorFromContextAttributeName as String):true])
//            
//            let attributesNeu = NSDictionary(dictionaryLiteral: (NSFontAttributeName, font) (kCTForegroundColorFromContextAttributeName, true))
//            
//            let attString = NSAttributedString(string: s as String, attributes: attributes)
            
            
            let line = CTLineCreateWithAttributedString(s)
            CGContextSetTextPosition(context, pos_x, pos_y)
            CTLineDraw(line, context)
            
            if(cursor) {
                CGContextSaveGState(context);
                CGContextSetBlendMode(context, .Difference)
                CGContextFillRect(context, rect)
                CGContextRestoreGState(context)
            }
            
            
            
            
            dirtyRect = CGRectUnion(dirtyRect, rect);
          //  print("Draw String \(s) at \(pos_x), \(pos_y) and \(dirtyRect)")
            
    }
    
    func initFont() -> CTFontRef {
        let rawFont = CTFontCreateWithName(font.name as CFStringRef, font.size, nil)
        
        var boundingRect = CGRectZero;
        var glyph = CTFontGetGlyphWithName(rawFont, "0" as CFStringRef)
       
        let glyphPointer = withUnsafePointer(&glyph) {(pointer: UnsafePointer<CGGlyph>) -> UnsafePointer<CGGlyph> in return pointer}
        
        withUnsafeMutablePointer(&boundingRect) { (pointer:UnsafeMutablePointer<CGRect>) in
        CTFontGetBoundingRectsForGlyphs(rawFont, .Horizontal, glyphPointer, pointer, 1)
        }
        
        
        char_ascent = CTFontGetAscent(rawFont)
        char_width = boundingRect.width
        char_height = boundingRect.height+3


        var advances = CGSizeZero
        withUnsafeMutablePointer(&advances, {(pointer: UnsafeMutablePointer<CGSize>) in
            CTFontGetAdvancesForGlyphs(rawFont, .Horizontal, glyphPointer, pointer, 1)});
        
        var transform = CGAffineTransformMakeScale(boundingRect.width/advances.width, -1)
        
        return withUnsafePointer(&transform, {
            (t:UnsafePointer<CGAffineTransform>) -> CTFont in
            return CTFontCreateCopyWithAttributes(rawFont, font.size,t , nil)})
    
    }

    
    
    
}
