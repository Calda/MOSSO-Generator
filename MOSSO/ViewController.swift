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

class ViewController: NSViewController {

    let fileManager = NSFileManager.defaultManager()
    let editor = AVMutableVideoComposition()
    @IBOutlet weak var outputText: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func generateButtonClicked(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.generateVideo()
        })
    }
    
    
    func generateVideo() {
        //delete previous file
        let desktopPath = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] as String
        let fileURL = NSURL.fileURLWithPath(desktopPath.stringByAppendingPathComponent("/Generated Moment of Silence.mov"))
        var error:NSError?
        NSFileManager.defaultManager().removeItemAtPath(fileURL!.path!, error: &error)
        
        //generate new file
        let clipQueue : [AVAsset] = generateClipQueue()
        let mixComposition = AVMutableComposition()
        var nextClipStart = kCMTimeZero
        var layerInstructions : [AVMutableVideoCompositionLayerInstruction] = []
        var mixLength : CMTime = kCMTimeZero
        
        showMessage("Creating Fades")
        progressBar.doubleValue = 0.2
        
        for queuePath in clipQueue {
            let isLastClip = (queuePath == clipQueue.last!)
            
            let queueClip = MSClip(asset: queuePath, startTime: nextClipStart, fadeIn: !isLastClip)
            nextClipStart = queueClip.nextClipStart
            let layerInstruction = queueClip.buildInstruction(mixComposition)
            layerInstructions.append(layerInstruction)
            
            if isLastClip {
                mixLength = queueClip.fadeOutEnd
            }
        }
        
        showMessage("Exporting File")
        progressBar.doubleValue = 0.4
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixLength)
        mainInstruction.layerInstructions = layerInstructions
        
        let mainCompositionInst = AVMutableVideoComposition(propertiesOfAsset: mixComposition)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTimeMake(1, 30)
        mainCompositionInst.renderSize = CGSizeMake(640, 480)
        
        let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPreset640x480)
        exporter.outputURL = fileURL
        exporter.videoComposition = mainCompositionInst
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                self.showMessage("Export Complete")
                self.progressBar.doubleValue = 1
            })
        })
        
    }
    
    
    func generateClipQueue() -> [AVAsset] {
        var clips : [String] = []
        
        //get all clips from folder
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .AllDomainsMask, true) as? [String]
        let path = dirs![0].stringByAppendingPathComponent("/MH Instruction/Moment of Silence")
        if let enumerator = fileManager.enumeratorAtPath(path) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".mov") {
                    clips.append(path + "/" + file)
                }
            }
        }
        
        if clips.count == 0 {
            let pathLength = path.pathComponents.count
            let pathDisplay = "\(path.pathComponents[pathLength - 2])/\(path.pathComponents[pathLength - 1])"
            showMessage("No clips in folder (\(pathDisplay))")
        }
        
        //create Clip Queue that adds up to 30s (<35s)
        var clipQueue : [AVAsset] = []
        let currentDuration : CMTime = kCMTimeZero
        
        while currentDuration < CMTimeMake(30,1) {
            let clipIndex = Int(random(min: 0, max: CGFloat(clips.count - 1)))
            let clipPath = clips[clipIndex]
            let clipAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: clipPath)) as AVAsset
            let possibleNewDuration = CMTimeAdd(currentDuration, clipAsset.duration)
            if possibleNewDuration < CMTimeMake(35, 1) { //will not go over 35s
                clipQueue.append(clipAsset)
            }
            clips.removeAtIndex(clipIndex)
            if possibleNewDuration > CMTimeMake(30, 1) || clips.count == 0 { //video is 30s or out of clips
                break;
            }
        }
        return clipQueue
    }
    
    
    func showMessage(message : String){
        dispatch_async(dispatch_get_main_queue(), {
            self.outputText.stringValue = message
        })
    }
    
    
    func error(error : String){
        showMessage("CRITIAL ERROR:::\(error)")
    }

    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }

}

