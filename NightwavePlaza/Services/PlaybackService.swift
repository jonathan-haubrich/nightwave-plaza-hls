//
//  PlaybackService.swift
//  NightwavePlaza
//
//  Created by Aleksey Garbarev on 24.05.2020.
//  Copyright © 2020 Aleksey Garbarev. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import RxSwift
import RxCocoa
import Reachability
import BugfenderSDK

enum PlaybackQuality: Int {
    case High = 0
    case Eco = 1
}

class PlaybackService {
    
    var qualityStorage = CCUserDefaultsStorage(with: NSNumber.self, key: "quality")
    
    var quality: PlaybackQuality {
        set {
            qualityStorage?.save(NSNumber(integerLiteral: newValue.rawValue))
            replacePlayerForQuality()
        }
        get {
            if let storedQuality = qualityStorage?.getObject() as? NSNumber, let quality = PlaybackQuality.init(rawValue: storedQuality.intValue) {
                return quality;
            } else {
                return .High
            }
        }
    }
    
    var playbackRate$ = BehaviorSubject<Float>(value: 0)
    
    var player = AVPlayer(url: URL(string: "https://radio.plaza.one/hls")!)
    
    let reachability = try! Reachability()
    
    private var lastPlayTime: CMTime?

    init() {
        setupPlaybackSession()
        setupRemoteTransportControls()

        replacePlayerForQuality()
        resumePlaybackWhenBecomeReachable()

        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    

    func resumePlaybackWhenBecomeReachable() {
        
        reachability.whenReachable = { [unowned self] reachability in
            replacePlayerForQuality()
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            Bugfender.error("Unable to start Reachability Notifier")
        }
        
    }
    
    func play() {
        if let lastTime = lastPlayTime, CMTimeCompare(player.currentTime(), lastTime) == 0 {
            // If player stalled, reload player
            replacePlayerForQuality()
        }
        
        player.play()
        playbackRate$.onNext(player.rate)
        lastPlayTime = player.currentTime()
    }
    
    func pause() {
        player.pause()
        playbackRate$.onNext(player.rate)
        lastPlayTime = player.currentTime()
    }
    
    var paused: Bool {
        get {
            return player.timeControlStatus == AVPlayer.TimeControlStatus.paused
        }
    }
    
    func replacePlayerForQuality() {
        let item = AVPlayerItem(url: urlForQuality())
        player.replaceCurrentItem(with: item)
    }
    
    private func urlForQuality() -> URL {
        let streamUrl: String
        if quality == .High {
            streamUrl = "https://radio.plaza.one/hls"
        } else {
            streamUrl = "https://radio.plaza.one/aac_lofi.m3u8"
        }

        return URL(string: streamUrl)!
    }
    
    @objc private func handleInterruption(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
            let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue) else {
                print("Unable to parse interruptionType")
                pause()
                return
        }
    
        switch interruptionType {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            } else {
                print("Should NOT resume a playback")
                // Interruption ended. Playback should not resume.
            }
        @unknown default:
            Bugfender.warning("New interruption type is unhandled: \(interruptionType)")
        }
        
    }
    
    private func setupPlaybackSession() {
       
        let session = AVAudioSession.sharedInstance()
        
        do {
            if #available(iOS 13.0, *) {
                try session.setCategory(AVAudioSession.Category.playback,
                                        mode: .default,
                                        policy: .longFormAudio,
                                        options: [])
            } else {
                try session.setCategory(AVAudioSession.Category.playback, options: [])
            }
        } catch let error {
            fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
        do {
            try session.setActive(true)
        } catch let error {
            fatalError("Unable to active audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupRemoteTransportControls() {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            if player.rate == 0.0 {
                play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if player.rate == 1.0 {
                pause()
                return .success
            }
            return .commandFailed
        }
    }
}
