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

    let FADE_LENGTH : Int64 = 15 //(seconds / 30)
    let editor = AVMutableVideoComposition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func generateVideo(sender: NSButton) {
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
        
        if clips.count == 0 {
            let pathLength = path.pathComponents.count
            let pathDisplay = "\(path.pathComponents[pathLength - 2])/\(path.pathComponents[pathLength - 1])"
            showUserMessage("No clips in folder (\(pathDisplay))")
        }
        
        var clipQueue : [String] = []
        while clips.count > 0 {
            let clipIndex = Int(random(min: 0, max: CGFloat(clips.count - 1)))
            clipQueue.append(clips[clipIndex])
            clips.removeAtIndex(clipIndex)
        }
        
        let firstClipAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: clipQueue[0])) as AVAsset
        let firstClipVideoTrack = firstClipAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
        editor.frameDuration = CMTimeMake(1,30)
        editor.renderSize = firstClipVideoTrack.naturalSize
        
        var editorInstructions : [AVMutableVideoCompositionInstruction] = []
        var nextClipStart = kCMTimeZero
        
        for queuePath in clipQueue {
            let clipAsset = AVAsset.assetWithURL(NSURL(fileURLWithPath: queuePath)) as AVAsset
            let clipAssetTrack = clipAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack
            
            let instruction = AVMutableVideoCompositionInstruction()
            let thisClipStart = nextClipStart
            instruction.timeRange = CMTimeRangeMake(thisClipStart, clipAsset.duration)
            nextClipStart = CMTimeMake(nextClipStart.value - (clipAsset.duration.value - FADE_LENGTH), 30)
            
            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipAssetTrack)
            let fadeInRange = CMTimeRangeMake(thisClipStart, CMTimeMake(thisClipStart.value + FADE_LENGTH, 30))
            transformer.setOpacityRampFromStartOpacity(0, toEndOpacity: 1, timeRange: fadeInRange)
            let fadeOutRange = CMTimeRangeMake(nextClipStart, CMTimeMake(nextClipStart.value + FADE_LENGTH, 30))
            transformer.setOpacityRampFromStartOpacity(1, toEndOpacity: 0, timeRange: fadeOutRange)
            
            instruction.layerInstructions = NSArray(object: transformer)
            editorInstructions.append(instruction)
        }
        
        editor.instructions = NSArray(array: editorInstructions)
        
        let desktopPath = NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] as NSString
        let exportURL = NSURL.fileURLWithPath(desktopPath.stringByAppendingPathComponent("/Generated Moment of Silence.mov"))
        
        let exporter = AVAssetExportSession(asset: firstClipAsset, presetName: AVAssetExportPreset640x480)
        exporter.videoComposition = editor
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                self.showUserMessage("done??")
            })
        })
    }
    
    func showUserMessage(message : String){
        println(message)
    }
    
    func error(error : String){
        println("CRITIAL ERROR:::\(error)")
    }

    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }

}

