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
                        selectionLabel.textColor = NSColor(calibratedRed: 0.1, green: 0.5, blue: 0.1, alpha: 1)
                    }
                }
            }
        }
    }
    
    
    @IBAction func radioChanged(sender: NSMatrix) {
        if let mosso = mosso {
            switch(sender.selectedTag()) {
                case 2: mosso.overrideSetting = .Random40Consecutive
                case 3: mosso.overrideSetting = .First40
                case 4: mosso.overrideSetting = .All
                case 5: mosso.overrideSetting = .None
                default: mosso.overrideSetting = .Random40Cuts
            }
        }
    }
    
    //reset view to already existing settings
    override func viewWillAppear() {
        
        if let mosso = mosso {
            var id : Int
            switch(mosso.overrideSetting) {
                case .Random40Consecutive: id = 2
                case .First40: id = 3
                case .All: id = 4
                case .None: id = 5
                default: id = 1
            }
            radio.selectCellWithTag(id)
            
            if let selectedOverride = mosso.showOpenOverride as? AVURLAsset {
                let URL = selectedOverride.URL.path!.lastPathComponent
                let display = (URL as NSString).substringToIndex(countElements(URL) - 4)
                selectionLabel.stringValue = display
                selectionLabel.textColor = NSColor(calibratedRed: 0.1, green: 0.5, blue: 0.1, alpha: 1)
            }
            
        }
    }
    
}