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
        
        //dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { self.VimStarter(url)}
//        dispatch_async(dispatch_get_main_queue()) { self.VimStarter(url)}
        performSelectorOnMainThread("VimStarter:", withObject: url, waitUntilDone: false)
       // VimStarter(url)
        return true
        
    }
    
    
    
    func VimStarter(url: NSURL?) {
        if let vimPath = NSBundle.mainBundle().resourcePath {
            let runtimePath = vimPath + "/runtime"
            vim_setenv("VIM".char, vimPath.char)
            vim_setenv("VIMRUNTIME".char, runtimePath.char)
//            print("VimPath: \(vimPath)")
//            print("VimRuntime: \(runtimePath)")
            
            
            let workingDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            //print("WorkingDir: \(workingDir)")
            
            vim_setenv("HOME".char, workingDir.char)
            NSFileManager.defaultManager().changeCurrentDirectoryPath(workingDir)
            
            var numberOfArguments = 1
            var arguments = CStringArray(["vim"]).pointers
            VimMain(Int32(numberOfArguments),&arguments)
        }
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