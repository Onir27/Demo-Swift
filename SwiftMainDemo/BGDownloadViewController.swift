//
//  BGDownloadViewController.swift
//  SwiftMainDemo
//
//  Created by Nirmalya on 24/04/17.
//  Copyright © 2017 Nirmalya. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class BGDownloadViewController: UIViewController {

    @IBOutlet weak var documentsTableView: UITableView!
    @IBOutlet weak var searchbar: UISearchBar!
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    var searchResults = [Track]()
    var datatask:URLSessionDataTask?
    var searchTimer:Timer?
    
    lazy var downloadSession:URLSession = {
        let session =  URLSession(configuration:URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        return session
    }()
    // MARK: View controller methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchbar.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyBoard(){
        searchbar.resignFirstResponder()
    }
    
    // MARK: Prase search results
    func updateSearchResults(_ data:Data?){
        searchResults.removeAll()
        //TODO - How does it work?
        do {
            if let data = data, let parsedResults = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject] {
                if let tracksArray = parsedResults["results"] {
                    for trackDictionary  in tracksArray as! [AnyObject] {
                        if let trackDictonary = trackDictionary as? [String: AnyObject], let previewUrl = trackDictonary["previewUrl"] as? String {
                            // Parse the search result
                            let name = trackDictonary["trackName"] as? String
                            let artist = trackDictonary["artistName"] as? String
                            searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
                        }else{
                            print("Not a dictionary")
                        }
                    }
                } else{
                    print("Results key not found")
                }
            } else{
                print("INCORRECT JSON")
            }
            
        } catch let error as NSError {
            print("Error parsing results: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.documentsTableView.reloadData()
            self.documentsTableView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    
    func trackIndexForDownloadTask(downloadTask: URLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            for (index, track) in searchResults.enumerated() {
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        return nil
    }
    
    func trackForDownloadTask(downloadTask: URLSessionDownloadTask) -> Track? {
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            for (_, track) in searchResults.enumerated() {
                if url == track.previewUrl! {
                    return track
                }
            }
        }
        return nil
    }
    // This method attempts to play the local file (if it exists) when the cell is tapped
    func playDownload(_ track: Track) {
        if let url = track.localFilePathForTrack() {
            let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
            presentMoviePlayerViewControllerAnimated(moviePlayer)
//            let player = AVPlayer(url: url)
//            let playerController = AVPlayerViewController()
//            
//            playerController.player = player
//            self.addChildViewController(playerController)
//            self.view.addSubview(playerController.view)
//            playerController.view.frame = self.view.frame
//            
//            player.play()
        }
    }
    // MARK: Download methods
    func startDownload(_ track:Track){
        guard let urlString = track.previewUrl,  let url = URL(string: urlString) else {
            return
        }
        let download = Download(url: urlString)
        download.downloadTask = downloadSession.downloadTask(with: url)
        download.downloadTask?.resume()
        download.isDownloading = true
        download.isCompleted = false
        track.download = download
        //activeDownloads[download.url] = download
    }
    
    // Called when the Pause button for a track is tapped
    func pauseDownload(_ track: Track) {
        guard let download = track.download else {
            return
        }
        if download.isDownloading {
            download.downloadTask?.cancel(byProducingResumeData: {
                data in
                if data != nil{
                    download.resumeData = data
                }
            })
            download.isDownloading = false
            download.isCompleted = false
        }
    }
    
    // Called when the Cancel button for a track is tapped
    func cancelDownload(_ track: Track) {
        guard let download = track.download else {
            return
        }
        download.downloadTask?.cancel()
        track.download = nil
    }
    
    // Called when the Resume button for a track is tapped
    func resumeDownload(_ track: Track) {
        guard let download = track.download else {
            return
        }
        if let resumeData = download.resumeData {
            download.downloadTask = downloadSession.downloadTask(withResumeData: resumeData)
            download.downloadTask?.resume()
            download.isDownloading = true
            download.isCompleted = false
        } else if let url = URL(string: download.url){
            download.downloadTask = downloadSession.downloadTask(with: url)
            download.downloadTask?.resume()
            download.isDownloading = true
            download.isCompleted = false
        }
    }

}

// MARK: - Tableview Delgates
extension BGDownloadViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = searchResults[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! BGDownloadTableViewCell
        cell.delegate = self
        cell.setUpCellFor(track: track)
        return cell

    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = searchResults[indexPath.row]
        if track.islocalFileExistsForTrack() {
            playDownload(track)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: - Customcell Delgates
extension BGDownloadViewController:BGDownloadTableViewCellDelegate{
    func performed(action: BGTableCellAction, cell: BGDownloadTableViewCell) {
        if let indexPath = self.documentsTableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            switch action {
            case .Download:
                startDownload(track)
            case .Pause:
                pauseDownload(track)
            case .Resume:
                resumeDownload(track)
            case .Cancel:
                cancelDownload(track)
            }
            self.documentsTableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
        
    }
}
// MARK: - Searchbar Delgates
extension BGDownloadViewController:UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.search), object: searchBar.text as NSString?)
        self.perform(#selector(self.search), with: searchBar.text as NSString?, afterDelay: 0.5)
    }
    
    func search(text:NSString?){
        //start search
        if datatask != nil {
            datatask?.cancel()
        }
        
        let expectedCharSet = NSCharacterSet.urlQueryAllowed
        if  let searchText = text!.addingPercentEncoding(withAllowedCharacters: expectedCharSet) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let url = URL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchText)")
            datatask = defaultSession.dataTask(with: url!){
                data, response, error in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                if let error = error {
                    print(error.localizedDescription)
                }
                else if let httpresponse = response as? HTTPURLResponse{
                    if httpresponse.statusCode == 200 {
                        // parse data here
                        self.updateSearchResults(data)
                    }
                }
            }
        }
        datatask?.resume()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {}
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {}
    
}


extension BGDownloadViewController:URLSessionDelegate,URLSessionDownloadDelegate{
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let track = trackForDownloadTask(downloadTask: downloadTask), let download = track.download else {
            return
        }
        download.isCompleted = true
        download.isDownloading = false
        
        if let destinaltionURL = track.localFilePathForTrack(){
            print(destinaltionURL)
            
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: destinaltionURL)
            } catch  {
                //
            }
            do {
                try fileManager.copyItem(at: location, to: destinaltionURL)
            } catch let error {
                print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }
        
        if let trackIndex = trackIndexForDownloadTask(downloadTask: downloadTask) {
            DispatchQueue.main.async {
                self.documentsTableView.reloadRows(at: [IndexPath(row: trackIndex, section: 0)], with: .none)
            }
        }
        
    
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let track = self.trackForDownloadTask(downloadTask: downloadTask) {
            if let download = track.download {
                download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: ByteCountFormatter.CountStyle.binary)
                
                if let trackIndex = self.trackIndexForDownloadTask(downloadTask: downloadTask), let trackCell = documentsTableView.cellForRow(at: IndexPath(row: trackIndex, section: 0)) as? BGDownloadTableViewCell{
                    DispatchQueue.main.async {
                        trackCell.downloadProgressbar.progress = download.progress
                        trackCell.downloadProgressLbl.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
                    }
                }
            }
            
        }
    }
}
