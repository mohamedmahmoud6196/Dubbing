//
//  ViewController.swift
//  Dubbing
//
//  Created by Mohamed Mahmoud on 11/04/2022.
//

import UIKit
import AVKit
class ViewController: UIViewController {
    
    // Movie name with extension
    @IBOutlet weak var playerView: UIView!
    let movie: (name: String, ext: String) = ("Ocean", "mov")
    let voidoverAudio1: (name: String, ext: String) = ("VoisOverAudio1", "m4a")
    let voidoverAudio2: (name: String, ext: String) = ("VoisOverAudio2", "m4a")
    var player: AVPlayer!
    
    lazy var movieURL: URL = {
        return Bundle.main.url(forResource: movie.name, withExtension: movie.ext)!
    }()
     
    lazy var voisoverAudio1URL: URL = {
        return Bundle.main.url(forResource: voidoverAudio1.name, withExtension: voidoverAudio1.ext)!
    }()
    
    lazy var voisoverAudio2URL: URL = {
        return Bundle.main.url(forResource: voidoverAudio2.name, withExtension: voidoverAudio2.ext)!
    }()
    var playerViewController: AVPlayerViewController!
    //"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8"
    
    let remoteVideoURl = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!
    var videoTime:CMTime!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
            let movie = AVMutableComposition()
           let videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
           let audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])

            let beachMovie = AVURLAsset(url: movieURL) //1
          
         
        mergeVideoAndAudio(videoUrl: remoteVideoURl, audioUrl: voisoverAudio1URL) { (error, successTyple) in
            
            let (url, mergeedAsset) = successTyple
          let mergedAsset =   successTyple.mergedAsset!
            self.setupPlayer(with: url ?? self.movieURL, asset: mergedAsset, startPlay: true)
            
        }
    }
    func setupPlayer(with url: URL,startPlay: Bool = false) {
        if let player = player, let playerViewController = playerViewController {
            player.pause()
            playerViewController.player = nil
        }
        let asset = AVURLAsset(url: url, options: nil)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerViewController = AVPlayerViewController()
        playerViewController.view.frame = self.playerView.bounds
        playerViewController.player = player

        DispatchQueue.main.async {
            self.addChild(self.playerViewController)
            self.view.addSubview(self.playerViewController.view)
            self.playerViewController.didMove(toParent: self)
            
        }
      
        if startPlay {
            player.play()
        }
    }

    func setupPlayer(with url: URL, asset:AVAsset,startPlay: Bool = false) {
        DispatchQueue.main.async {
            if let player = self.player, let playerViewController = self.playerViewController {
                player.pause()
                playerViewController.player = nil
            }
            self.player = .init(playerItem: .init(asset: asset))
            self.playerViewController = AVPlayerViewController()
            self.playerViewController.view.frame = self.playerView.bounds
            self.playerViewController.player = self.player

          
                self.addChild(self.playerViewController)
                self.view.addSubview(self.playerViewController.view)
                self.play  }
           // self.player.isMuted = true
            if startPlay {
                self.player.play()
            }
        }
      
    }
    func mergeVideoAndAudio(videoUrl: URL,
                            audioUrl: URL,
                            shouldFlipHorizontally: Bool = false,
                            completion: @escaping (_ error: Error?,( URL?,mergedAsset:AVMutableComposition?)) -> Void) {
      
       


        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()

        //start merge

        let aVideoAsset = AVAsset(url: videoUrl)
        
        let aAudioAsset = AVAsset(url: audioUrl)

        let compositionAddVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudio = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid)

        let compositionAddAudioOfVideo = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                            preferredTrackID: kCMPersistentTrackID_Invalid)

        let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let aAudioOfVideoAssetTrack: AVAssetTrack? = aVideoAsset.tracks(withMediaType: AVMediaType.audio).first
        let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]

        // Default must have tranformation
        compositionAddVideo?.preferredTransform = aVideoAssetTrack.preferredTransform

        if shouldFlipHorizontally {
            // Flip video horizontally
            var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
            frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
            compositionAddVideo?.preferredTransform = frontalTransform
        }

        mutableCompositionVideoTrack.append(compositionAddVideo!)
        mutableCompositionAudioTrack.append(compositionAddAudio!)
        mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo!)

        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aVideoAssetTrack,
                                                                at: CMTime.zero)

        
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero,
                                                                                duration: aVideoAssetTrack.timeRange.duration),
                                                                of: aAudioAssetTrack,
                                                                at: CMTime.zero)

         
        } catch {
            print(error.localizedDescription)
        }

        // Exporting
        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        do { // delete old video
            try FileManager.default.removeItem(at: savePathUrl)
        } catch { print(error.localizedDescription) }
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)!
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true

        completion(nil, (savePathUrl,mixComposition))

    /*    assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case AVAssetExportSession.Status.completed:
                print("success")
                completion(nil, (savePathUrl,mixComposition))
            case AVAssetExportSession.Status.failed:
                print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, (nil,nil))
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(assetExport.error, (nil,nil))
            default:
                print("complete")
                completion(assetExport.error, (nil,nil))
            }
        }*/

    }

}

