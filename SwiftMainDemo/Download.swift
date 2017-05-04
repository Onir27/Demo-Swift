//
//  Download.swift
//  SwiftMainDemo
//
//  Created by Nirmalya on 25/04/17.
//  Copyright © 2017 Nirmalya. All rights reserved.
//

import Foundation

class Download: NSObject {
    
    var url: String
    var isDownloading = false
    var isCompleted = false
    var progress: Float = 0.0
    
    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?
    
    init(url: String) {
        self.url = url
    }
}
