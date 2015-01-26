//
//  ViewController.swift
//  MOSSO
//
//  Created by DFA Film 9: K-9 on 12/9/14.
//  Copyright (c) 2014 Dog Pound Productions. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation
import AppKit
import QuartzCore

class ViewController: NSViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screens = NSScreen.screens()!
        var smallScreen: NSScreen = screens[0] as NSScreen
        for anyScreen in screens {
            let screen = anyScreen as NSScreen
            if smallScreen.frame.width > screen.frame.width {
                smallScreen = screen
            }
        }
        let aspectRatio = smallScreen.frame.width / smallScreen.frame.height
        if aspectRatio == (16/9) { //smallest monitor was main iMac monitor
            error("External monitor not found.")
            return
        }
        
        var clips : [String] = []
        
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .AllDomainsMask, true) as? [String]
        let path = dirs![0].stringByAppendingPathComponent("/MH Instruction/Moment of Silence")
        let fileManager = NSFileManager.defaultManager()
        if let enumerator = fileManager.enumeratorAtPath(path) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".mov") {
                    clips.append(path + "/" + file)
                }
            }
        } else {
            println("Folder not found.")
        }
        
        if clips.count > 0 {
            NSThread.sleepForTimeInterval(NSTimeInterval(5.0))
            
            var clipQueue : [String] = []
            while clips.count > 0 {
                let clipIndex = Int(random(min: 0, max: CGFloat(clips.count - 1)))
                clipQueue.append(clips[clipIndex])
                clips.removeAtIndex(clipIndex)
            }
            
        }

    }
    
    func error(error : String){
        println("CRITIAL ERROR:::\(error)")
    }

    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }

}

