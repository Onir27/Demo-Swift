//
//  BGDownloadTableViewCell.swift
//  SwiftMainDemo
//
//  Created by Nirmalya on 24/04/17.
//  Copyright © 2017 Nirmalya. All rights reserved.
//

import UIKit

protocol BGDownloadTableViewCellDelegate {
    func performed(action:BGTableCellAction, cell: BGDownloadTableViewCell)
}

enum BGTableCellAction {
    case Download, Pause, Resume, Cancel
}
class BGDownloadTableViewCell: UITableViewCell {

    @IBOutlet weak var fileNamelbl: UILabel!
    @IBOutlet weak var artistNamelbl: UILabel!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var pauseResumeBtn:UIButton!
    @IBOutlet weak var cancelBtn:UIButton!
    @IBOutlet weak var downloadProgressbar: UIProgressView!
    @IBOutlet weak var downloadProgressLbl:UILabel!
    
    var delegate: BGDownloadTableViewCellDelegate?
    var track:Track?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.pauseResumeBtn.isHidden = true
        self.cancelBtn.isHidden = true
        self.downloadProgressbar.progress = 0.0
        self.downloadProgressbar.isHidden = true
        self.downloadProgressLbl.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func layOutConstraints(){
        
    }
    
    func setUpCellFor(track: Track){
        self.track = track
        self.fileNamelbl.text = track.name
        self.artistNamelbl.text = track.artist
        var shouldHideDownloadControls = true
        if let download = track.download {
            if download.isDownloading {
                shouldHideDownloadControls = false
            }
            self.downloadProgressbar.progress = download.progress
            self.pauseResumeBtn.titleLabel?.text = download.isDownloading ? "Pause" : "Resume"
            self.downloadBtn.titleLabel?.text = download.isCompleted ? "Play" :"Download"
        }
        self.downloadProgressbar.isHidden = shouldHideDownloadControls
        self.downloadProgressLbl.isHidden = shouldHideDownloadControls
        self.pauseResumeBtn.isHidden = shouldHideDownloadControls
        self.cancelBtn.isHidden = shouldHideDownloadControls
        self.downloadBtn.isHidden = !shouldHideDownloadControls
    }
    

    @IBAction func downloadTapped(_ sender: Any) {
        if !((self.track?.islocalFileExistsForTrack())!) {
            self.downloadProgressbar.isHidden = false
            self.downloadProgressLbl.isHidden = false
            self.delegate?.performed(action: .Download, cell: self)
        }
        
    }
    
    
    @IBAction func pauseResumeTapped(_ sender: Any) {
        if let download = self.track?.download {
            if download.isDownloading {
                self.delegate?.performed(action: .Pause, cell: self)
            } else{
                self.delegate?.performed(action: .Resume, cell: self)
            }
        }
        
    }
    
    
    @IBAction func canceltapped(_ sender: Any) {
        self.delegate?.performed(action: .Cancel, cell: self)
    }
    
}
