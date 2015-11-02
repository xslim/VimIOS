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


//let hotkeys = "1234567890[]{}()!@#$%^&*/.,;"
let hotkeys = "1234567890!@#$%^&*()_={}\\/.,<>?:|`~[]"
let shiftableHotkeys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


class VimViewController: UIViewController, UIKeyInput, UITextInputTraits {
    var vimView: VimView?
    var hasBeenFlushedOnce = false
    var lastKeyPress = NSDate()
    
    var blink_wait:CLong = 1000
    var blink_on:CLong = 1000
    var blink_off:CLong = 1000
    var state:blink_state = .NONE
    var blinkTimer : NSTimer?
    
    var keyCommandArray: [UIKeyCommand]?
    
    override var keyCommands: [UIKeyCommand]? {
        print("Show me the KeyCommands! \(keyCommandArray?.count)");return keyCommandArray }
   // override var keyCommands:[UIKeyCommand]? { print("Show me the commands!"); return [UIKeyCommand(input:"[", modifierFlags:.Control, action:"keyPressed:")] }
    
    
    func test(sender: UIKeyCommand) {
        print("Huhc!?")
    }
        
    
    override func viewDidLoad() {
        //print("Bounds \(UIScreen.mainScreen().bounds)")
        vimView = VimView(frame: UIScreen.mainScreen().bounds)
        self.view.addSubview(vimView!)
        registerHotkeys()
        
        
        inputAssistantItem.leadingBarButtonGroups=[]
        inputAssistantItem.trailingBarButtonGroups=[]
    }
    
    override func viewDidAppear(animated: Bool) {
        #if  FEAT_GUI
        //print("Hallo!")
        #endif
    }
    
    
    func flush() {
        if(!hasBeenFlushedOnce) {
            hasBeenFlushedOnce = true
            dispatch_async(dispatch_get_main_queue()){ self.becomeFirstResponder()}
        }
        vimView?.flush()
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
        vimView?.setNeedsDisplayInRect((vimView?.dirtyRect)!)
        
        
        
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

    
   override func canBecomeFirstResponder() -> Bool {
        return hasBeenFlushedOnce
    }
    
    override func canResignFirstResponder() -> Bool {
        return true
    }
    
    
   // MARK: UIKeyInput
    func hasText() -> Bool {
        return false
    }
    
    func insertText(text: String) {
        var escapeString = text.char
        if(text=="\n") {
            print("Enter!")
            escapeString = String(UnicodeScalar(Int(keyCAR))).char
        }
        
        becomeFirstResponder()
        let length = text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        add_to_input_buf(escapeString, Int32(length))
        print("Miep")

        flush()
        vimView?.setNeedsDisplayInRect((vimView?.dirtyRect)!)
    }
    func deleteBackward() {
            insertText(String(UnicodeScalar(Int(keyBS))))
        
    }
    
    // Mark: UITextInputTraits
    
    var autocapitalizationType = UITextAutocapitalizationType.None
    var keyboardType = UIKeyboardType.Default
    var autocorrectionType = UITextAutocorrectionType.No
    

    
    func registerHotkeys(){
        keyCommandArray = []
        hotkeys.each { letter in
            [[], [.Control], [.Command]].map( {
            self.keyCommandArray! += [UIKeyCommand(input:  letter, modifierFlags:$0, action: "keyPressed:")]
            })
        }
        shiftableHotkeys.each{ letter in
            [[],[.Control], [.Shift], [.Command]].map( {
            self.keyCommandArray! += [UIKeyCommand(input:  letter, modifierFlags: $0 , action: "keyPressed:")]
            })
        }
        self.keyCommandArray! += [UIKeyCommand(input:UIKeyInputEscape, modifierFlags: [], action: "keyPressed:")]
        print("Number of Hotkeys \(keyCommands?.count)")
    }
    
    func keyPressed(sender: UIKeyCommand) {
        lastKeyPress = NSDate()
        
        print("Input \(sender.input), Modifier \(sender.modifierFlags)")
        var key:String {
            switch sender.modifierFlags.rawValue {
            case 0:
                if(sender.input == UIKeyInputEscape){
                    return String(UnicodeScalar(Int(keyESC)))
                }
                else {
                    return sender.input.lowercaseString
                }
            case UIKeyModifierFlags.Shift.rawValue:
                return sender.input
            case UIKeyModifierFlags.Control.rawValue:
                return String(UnicodeScalar(Int(getCTRLKeyCode(sender.input))))
            default: return ""
            }
        }
       insertText(key)
       
    }
    
    func waitForChars(wtime: Int) -> Int {
     //   //print("Wait \(wtime)")
        let passed = NSDate().timeIntervalSinceDate(lastKeyPress)*1000
        var wait = wtime
        print("Passed \(passed)")
        
        if(passed < 1000) {
            wait = 10
        } else if(wtime < 0 ){
            wait = 4000
        }
        
     
     print("Wait2 \(wait)")
     
     let expirationDate = NSDate(timeIntervalSinceNow: Double(wait)/1000.0)
        NSRunLoop.currentRunLoop().acceptInputForMode(NSDefaultRunLoopMode, beforeDate: expirationDate)
     let delay = expirationDate.timeIntervalSinceNow
        print("Delay \(delay)")
     return delay < 0 ? 0 : 1
    
    }

    
}

