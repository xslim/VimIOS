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
    
    var controller = UIDocumentInteractionController()
    
    override var keyCommands: [UIKeyCommand]? {
        return keyCommandArray
    }
   // override var keyCommands:[UIKeyCommand]? { print("Show me the commands!"); return [UIKeyCommand(input:"[", modifierFlags:.Control, action:"keyPressed:")] }
    
    
    
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name:UIKeyboardWillShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name:UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name:UIKeyboardWillHideNotification, object:nil)
    }
    
    override func viewDidLoad() {
        //print("Bounds \(UIScreen.mainScreen().bounds)")
        vimView = VimView(frame: UIScreen.mainScreen().bounds)
        vimView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view.addSubview(vimView!)
        
        registerHotkeys()
        
        vimView?.addGestureRecognizer(UITapGestureRecognizer(target:self,action:"click:"))
        vimView?.addGestureRecognizer(UILongPressGestureRecognizer(target:self,action:"longPress:"))
        
        let scrollRecognizer = UIPanGestureRecognizer(target:self, action:"scroll:")
        scrollRecognizer.minimumNumberOfTouches=1
        scrollRecognizer.maximumNumberOfTouches=1
        
        vimView?.addGestureRecognizer(scrollRecognizer)
        
        inputAssistantItem.leadingBarButtonGroups=[]
        inputAssistantItem.trailingBarButtonGroups=[]
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        #if  FEAT_GUI
        //print("Hallo!")
        #endif
    }
    
    func click(sender: UITapGestureRecognizer) {
        becomeFirstResponder()
        let clickLocation = sender.locationInView(sender.view)
        gui_send_mouse_event(0, Int32(clickLocation.x), Int32(clickLocation.y), 1,0)
    }
    func longPress(sender: UILongPressGestureRecognizer) {
        if(sender.state == .Began) {
        becomeFirstResponder()
        toggleKeyboardBar()
        }
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
            //print("Enter!")
            escapeString = String(UnicodeScalar(Int(keyCAR))).char
        }
        
        becomeFirstResponder()
        let length = text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        add_to_input_buf(escapeString, Int32(length))

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
    
    
    func toggleKeyboardBar() {
        if(inputAssistantItem.leadingBarButtonGroups.count == 0){
            let escButton = UIBarButtonItem(title: "ESC", style: .Plain, target: self, action: "handleBarButton:")
            let tabButton = UIBarButtonItem(title: "TAB", style: .Plain, target: self, action: "handleBarButton:")
            inputAssistantItem.leadingBarButtonGroups += [UIBarButtonItemGroup(barButtonItems: [escButton, tabButton], representativeItem: nil)]
        }
        else {
            inputAssistantItem.leadingBarButtonGroups=[]
            inputAssistantItem.trailingBarButtonGroups=[]
        }
        resignFirstResponder()
        becomeFirstResponder()
    }
    
    
    
    //MARK: OnScreen Keyboard Handling
    func keyboardWillShow(notification: NSNotification) {
        guard let vView = vimView else { return}
        let keyboardRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue
        let keyboardRectInViewCoordinates = view!.window!.convertRect(keyboardRect!, toView: vimView)
        print(keyboardRectInViewCoordinates)
        
        vView.frame = CGRectMake(vView.frame.origin.x, vView.frame.origin.y, vView.frame.size.width, keyboardRectInViewCoordinates.origin.y)
        print("Did show!")
        
    
    }
    
    func keyboardDidShow(notification: NSNotification) {
    
    }
    func keyboardWillHide(notification: NSNotification) {
        keyboardWillShow(notification)
        print("Will Hide!")
    }
    
    func handleBarButton(sender: UIBarButtonItem) {
        switch sender.title! {
        case "ESC":
            insertText(String(UnicodeScalar(Int(keyESC))))
        case "TAB":
            insertText(String(UnicodeScalar(Int(keyTAB))))
        default: break
        }
    }

    
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
        //print("Number of Hotkeys \(keyCommands?.count)")
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
        //print("Passed \(passed)")
        
        if(passed < 1000) {
            wait = 10
        } else if(wtime < 0 ){
            wait = 4000
        }
        
     
     //print("Wait2 \(wait)")
     
     let expirationDate = NSDate(timeIntervalSinceNow: Double(wait)/1000.0)
        NSRunLoop.currentRunLoop().acceptInputForMode(NSDefaultRunLoopMode, beforeDate: expirationDate)
     let delay = expirationDate.timeIntervalSinceNow
     return delay < 0 ? 0 : 1
    
    }
    
    
    func showShareSheetForURL(url: NSURL) {
        controller.URL = url
        let height = view.bounds.size.height
        controller.presentOptionsMenuFromRect(CGRectMake(0,height-10,10,10), inView:view, animated: true)
    }
    
    
    func scroll(sender: UIPanGestureRecognizer) {
        let clickLocation = sender.locationInView(vimView!)
        let translation = sender.translationInView(vimView!)
    
        var diffY = translation.y/(vimView!.char_height)
        
//        print("Vorher \(diffY): \(ceil(diffY))")
        
        if(diffY <= -1) {
            sender.setTranslation(CGPoint(x: 0, y: translation.y-ceil(diffY)*vimView!.char_height), inView: vimView!)
        }
        if(diffY >= 1) {
            sender.setTranslation(CGPoint(x:0,y: translation.y-floor(diffY)*vimView!.char_height), inView: vimView!)
        }
        while(diffY <= -1){
         //   gui_send_mouse_event(MOUSE_5, Int32(clickLocation.x), Int32(clickLocation.y), 0, 0);
            insertText(String(UnicodeScalar(Int(getCTRLKeyCode("E")))))
            diffY++
        }
        while(diffY >= 1) {
            insertText(String(UnicodeScalar(Int(getCTRLKeyCode("Y")))))
            //gui_send_mouse_event(MOUSE_4, Int32(clickLocation.x), Int32(clickLocation.y), 0, 0);
            diffY--
        }
        
        print("Nachher \(diffY)")
    }
    
    

    
}

