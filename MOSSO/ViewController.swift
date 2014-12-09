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

class ViewController: NSViewController {

    @IBOutlet weak var playerView: AVPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var clips : [String] = []
        
        let dirs : [String]? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .AllDomainsMask, true) as? [String]
        let path = dirs![0].stringByAppendingPathComponent("/MH Instruction/Moment of Silence")
        let fileManager = NSFileManager.defaultManager()
        if let enumerator = fileManager.enumeratorAtPath(path) {
            while let file = enumerator.nextObject() as? String {
                clips.append(path + "/" + file)
            }
        } else {
            println("Folder not found.")
        }
        
        if clips.count > 0 {
            playVideoQueue(clips)
        }
        
        // Do any additional setup after loading the view.
    }
    
    func playVideoQueue(paths : [String]){
        println(paths[0])
        dispatch_async(dispatch_get_main_queue(), {
            self.playerView.player = AVPlayer(URL: NSURL(fileURLWithPath: paths[0]))
            self.playerView.player!.play()
        })
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

