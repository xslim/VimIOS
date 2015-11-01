//
//  ViewController.swift
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

import UIKit

enum blink_state {
    case NONE     /* not blinking at all */
    case OFF     /* blinking, cursor is not shown */
    case ON        /* blinking, cursor is shown */
}



class VimViewController: UIViewController {
    var hasBeenFlushedOnce = false
    var lastKeyPress = NSDate()
    
    var blink_wait:CLong = 1000
    var blink_on:CLong = 1000
    var blink_off:CLong = 1000
    var state:blink_state = .NONE
    
    
    var blinkTimer : NSTimer?
        
        
        
    override func viewDidAppear(animated: Bool) {
//        gui_ios.shellView = self.
//        gui_ios.shellView = self.view as VimView
        
        #if  FEAT_GUI
        print("Hallo!")
        #endif
        //(view as! VimView).clearAll()
        //view.setNeedsDisplay()
        
        
    }
    
    
    func flush() {
        if(!hasBeenFlushedOnce) {
            hasBeenFlushedOnce = true
            self.becomeFirstResponder()
        }
        (view as! VimView).flush()
    }
    
    func blinkCursorTimer() {
        blinkTimer?.invalidate()
        
        if(state == .ON) {
            gui_undraw_cursor()
            state = .OFF
            
            let off_time = Double(blink_off)/1000.0
            blinkTimer = NSTimer.scheduledTimerWithTimeInterval(off_time, target:self, selector:"blinkCursorTimer", userInfo:nil, repeats:false)
        }
        else if (state == .OFF) {
            gui_update_cursor(1, 0)
            state = .ON
            let on_time = Double(blink_on)/1000.0
            blinkTimer = NSTimer.scheduledTimerWithTimeInterval(on_time, target:self, selector:"blinkCursorTimer", userInfo:nil, repeats:false)
        }
        view.setNeedsDisplayInRect((view as! VimView).dirtyRect)
        
        
        
    }
    
    func startBlink() {
        blinkTimer?.invalidate()
        
        
        blinkTimer = NSTimer.scheduledTimerWithTimeInterval(Double(blink_wait)/1000.0, target: self,  selector: "blinkCursorTimer", userInfo: nil, repeats: false)
        state = .ON
        gui_update_cursor(1,0)
        
        
        
    }
    
    func stopBlink() {
        blinkTimer?.invalidate()
        state = .NONE
        blinkTimer=nil
    }

}

