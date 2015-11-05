//
//  AppDelegate.swift
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        var url: NSURL?
        
        url = launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL
        
        
        //Start Vim!
        performSelectorOnMainThread("VimStarter:", withObject: url, waitUntilDone: false)
        return true
        
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if(url.fileURL) {
            let file = "Inbox/"+url.lastPathComponent!
            do_cmdline_cmd("tabedit \(file)".char)
            do_cmdline_cmd("redraw!".char)
            return true
        }
        return false
    }
    
    
    func VimStarter(url: NSURL?) {
        guard let vimPath = NSBundle.mainBundle().resourcePath else {return}
        let runtimePath = vimPath + "/runtime"
        vim_setenv("VIM".char, vimPath.char)
        vim_setenv("VIMRUNTIME".char, runtimePath.char)
        //            print("VimPath: \(vimPath)")
        //            print("VimRuntime: \(runtimePath)")
        
        
        
        let workingDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        //print("WorkingDir: \(workingDir)")
        
        vim_setenv("HOME".char, workingDir.char)
        NSFileManager.defaultManager().changeCurrentDirectoryPath(workingDir)
        
        var numberOfArguments = 0
        var file: String?

        if let url = url where url.fileURL {
            if let filename=url.lastPathComponent {
                file = "Inbox/"+filename
                numberOfArguments++
            }
        }
        
        vimHelper(Int32(numberOfArguments),file)
    }
    
}




extension String {
    var char: UnsafeMutablePointer<char_u> {
        return UnsafeMutablePointer<char_u>((self as NSString).UTF8String)
    }
    
    func each(closure: (String) -> Void ) {
        for digit in self.characters
        {
            closure(String(digit))
        }
    }
    
}