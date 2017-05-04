//
//  Track.swift
//  SwiftMainDemo
//
//  Created by Nirmalya on 24/04/17.
//  Copyright © 2017 Nirmalya. All rights reserved.
//

import UIKit

class Track {
    var name: String?
    var artist: String?
    var previewUrl: String?
    var download:Download?
    
    init(name: String?, artist: String?, previewUrl: String?) {
        self.name = name
        self.artist = artist
        self.previewUrl = previewUrl
        self.download = nil
    }
    
    func islocalFileExistsForTrack() -> Bool {
        if let localUrl = self.localFilePathForTrack() {
            var isDir : ObjCBool = false
            let path = localUrl.path
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        }
        return false
    }
    
    func localFilePathForTrack() -> URL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        if let urlString = self.previewUrl, let url = URL(string: urlString) {
            let lastPathComponent = url.lastPathComponent
            let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
            return URL(fileURLWithPath:fullPath)
        }
        return nil
    }

}

