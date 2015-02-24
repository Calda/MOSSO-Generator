//
//  OverrideVideoController.swift
//  MOSSO
//
//  Created by DFA Film 11: Brian on 2/24/15.
//  Copyright (c) 2015 Dog Pound Productions. All rights reserved.
//

import Foundation
import AppKit
import AVFoundation

class OverrideVideoController : NSViewController {
    
    var mosso : ViewController?
    @IBOutlet weak var radio: NSMatrix!
    @IBOutlet weak var selectionLabel: NSTextField!
    
    @IBAction func browsePressed(sender: AnyObject) {
        let open = NSOpenPanel()
        open.canChooseFiles = true
        open.canChooseDirectories = false
        open.allowsMultipleSelection = false
        open.allowedFileTypes = ["mov","MOV"]
        
        let clicked = open.runModal()
        
        if clicked == NSOKButton {
            if let url = open.URL {
                if let mosso = self.mosso {
                    let overrideAsset = AVAsset.assetWithURL(url) as AVAsset
                    mosso.showOpenOverride = overrideAsset
                    if let fileName = url.lastPathComponent {
                        let display = (fileName as NSString).substringToIndex(countElements(fileName) - 4)
                        selectionLabel.stringValue = display
                    }
                }
            }
        }
    }
    
    @IBAction func radioChanged(sender: NSMatrix) {
        if let mosso = mosso {
            switch(sender.selectedTag()) {
                case 2: mosso.overrideSetting = .First30
                case 3: mosso.overrideSetting = .All
                default: mosso.overrideSetting = .Random30
            }
        }
    }
    
}