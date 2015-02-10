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
    let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidDisappear() {
        NSApplication.sharedApplication().terminate(self)
    }
    
    
    @IBAction func generateButtonClicked(sender: AnyObject) {
        
        dispatch_async(backgroundQueue, {
            self.generateVideo()
        })
    }
    
    
    func generateVideo() {
        //delete previous file
        let desktopPath = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] as String
        let fileURL = NSURL.fileURLWithPath(desktopPath.stringByAppendingPathComponent("/Generated MOSSO.mov"))
        var error:NSError?
        NSFileManager.defaultManager().removeItemAtPath(fileURL!.path!, error: &error)
        
        //generate new file
        let (titleClipOpt, titleStartTime, clipQueue) = generateClipQueue()
        let mixComposition = AVMutableComposition()
        var nextClipStart = kCMTimeZero
        var layerInstructions : [AVMutableVideoCompositionLayerInstruction] = []
        var mixLength : CMTime = kCMTimeZero
        
        showMessage("Creating Fades")
        progressBar.doubleValue = 0.2
        
        if let titleClip = titleClipOpt {
            println(titleClip)
            let titleTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: 1)
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: titleTrack)
            instruction.setOpacity(1.0, atTime: titleStartTime)
            layerInstructions.append(instruction)
            titleTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, titleClip.duration), ofTrack: titleClip.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack, atTime: titleStartTime, error: nil)
        }
        
        for queuePath in clipQueue {
            let isFirstClip = (queuePath == clipQueue.first!)
            let isLastClip = (queuePath == clipQueue.last!)
            
            let queueClip = MSClip(asset: queuePath, startTime: nextClipStart, fadeIn: !isLastClip, includeSound: isFirstClip || isLastClip)
            nextClipStart = queueClip.nextClipStart
            let layerInstruction = queueClip.buildInstruction(mixComposition)
            layerInstructions.append(layerInstruction)
            
            if isLastClip {
                mixLength = queueClip.fadeOutEnd
            }
        }
        
        showMessage("Exporting File")
        progressBar.doubleValue = 0.4
        
        //decoration delay
        delay(2) {
            self.showMessage("Working.")
            self.progressBar.doubleValue = 0.5
        }
        delay(2.25) {
            self.showMessage("Working..")
            self.progressBar.doubleValue = 0.55
        }
        delay(2.5) {
            self.showMessage("Working...")
            self.progressBar.doubleValue = 0.6
        }
        
        delay(5) {
            self.showMessage("This is gonna be a sec...")
            self.progressBar.doubleValue = 0.7
        }
        
        delay(9) {
            self.showMessage("Almost there...")
            self.progressBar.doubleValue = 0.85
        }
        
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
                self.delay(2.5) { //close when done
                    NSApplication.sharedApplication().terminate(self)
                }
            })
        })
        
    }
    
    
    func generateClipQueue() -> (titleClip: AVAsset?, titleStart: CMTime, queue: [AVAsset]) {
        var clips : [String] = []
        
        //get all clips from folder
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .AllDomainsMask, true) as? [String]
        let path = dirs![0].stringByAppendingPathComponent("/MH Instruction/MOSSO")
        if let enumerator = fileManager.enumeratorAtPath(path) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".mov") && !file.hasSuffix("SHOW OPEN.mov") && !file.hasSuffix("TEXT WITH ALPHA.mov") && !file.hasSuffix("COUNTDOWN.mov") {
                    clips.append(path + "/" + file)
                }
            }
        }
        
        if clips.count == 0 {
            let pathLength = path.pathComponents.count
            let pathDisplay = "\(path.pathComponents[pathLength - 2])/\(path.pathComponents[pathLength - 1])"
            showMessage("No clips in folder (\(pathDisplay))")
        }
        
        //create Clip Queue that adds up to 32s (<37s)
        var clipQueue : [AVAsset] = []
        var currentDuration : CMTime = kCMTimeZero
        
        while currentDuration < CMTimeMake(32,1) {
            let clipIndex = Int(random(min: 0, max: CGFloat(clips.count - 1)))
            let clipPath = clips[clipIndex]
            let clipAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: clipPath)) as AVAsset
            let possibleNewDuration = CMTimeAdd(currentDuration, clipAsset.duration)
            if possibleNewDuration < CMTimeMake(37, 1) { //will not go over 37s
                clipQueue.append(clipAsset)
                currentDuration = possibleNewDuration
                println(currentDuration)
            }
            clips.removeAtIndex(clipIndex)
            if possibleNewDuration > CMTimeMake(32, 1) || clips.count == 0 { //video is 32s or out of clips
                break;
            }
        }
        
        let requiredPath = path.stringByAppendingPathComponent("/ REQUIRED")
        let countdownPath = requiredPath.stringByAppendingPathComponent("/COUNTDOWN.mov")
        var countdownLength = kCMTimeZero
        if let countdownAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: countdownPath)) as? AVAsset {
            clipQueue.insert(countdownAsset, atIndex: 0)
            countdownLength = countdownAsset.duration
        }
        
        let showOpenPath = requiredPath.stringByAppendingPathComponent("/SHOW OPEN.mov")
        if let showOpenAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: showOpenPath)) as? AVAsset {
            clipQueue.append(showOpenAsset)
        } else {
            error("SHOW OPEN NOT FOUND.")
        }
        
        let titlePath = requiredPath.stringByAppendingPathComponent("/TEXT WITH ALPHA.mov")
        let titleClip = AVAsset.assetWithURL(NSURL(fileURLWithPath: titlePath)) as? AVAsset
        
        return (titleClip, countdownLength, clipQueue)
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

    func delay(delay:Double, closure:()->()) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), closure)
    }
    
}

