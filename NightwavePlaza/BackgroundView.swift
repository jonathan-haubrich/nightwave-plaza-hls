//
//  BackgroundView.swift
//  NightwavePlaza
//
//  Created by Aleksey Garbarev on 24.05.2020.
//  Copyright © 2020 Aleksey Garbarev. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

class BackgroundView: UIView {
    
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.addSublayer(playerLayer)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    var disposeBag = DisposeBag()
    
    func setUrl(url: URL) {
        
        let nextPlayer = AVPlayer(url: url)
        nextPlayer.actionAtItemEnd = .none
        
        self.startPlayer(player: nextPlayer) {
            self.replacePlayer(player: nextPlayer)
        }
        
    }
    
    private func startPlayer(player: AVPlayer, completion: @escaping () -> ()) {
        player.play()
       var statusDisposable: Disposable?;
       statusDisposable = player.rx.observe(AVPlayer.TimeControlStatus.self, "timeControlStatus").subscribe { (event) in
           if let status = event.element as? AVPlayer.TimeControlStatus {
               if (status == .playing) {
                   statusDisposable?.dispose()
                   completion()
               }
           }
       };
    }
    
    func replacePlayer(player: AVPlayer) {
        
        let newPlayerLayer = AVPlayerLayer(player: player)
        newPlayerLayer.videoGravity = .resizeAspectFill
        newPlayerLayer.opacity = 1
        newPlayerLayer.frame = self.bounds
        self.layer.addSublayer(newPlayerLayer)
        
        CATransaction.begin()
        
        let fadeIn = CABasicAnimation.init(keyPath: "opacity")
        fadeIn.toValue = 1
        fadeIn.fromValue = 0
        fadeIn.duration = 0.3
        fadeIn.fillMode = .forwards
        fadeIn.isRemovedOnCompletion = true
        
        let fadeOut = CABasicAnimation.init(keyPath: "opacity")
        fadeOut.toValue = 0
        fadeOut.duration = 0.3
        
        self.playerLayer.add(fadeOut, forKey: "opacity")
        newPlayerLayer.add(fadeIn, forKey: "opacity")
        
        CATransaction.setCompletionBlock({
            self.playerLayer.removeFromSuperlayer()
            self.playerLayer = newPlayerLayer
            self.player = player
        })
        CATransaction.commit()
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        self.player.seek(to: CMTime.zero)
    }
    
    @objc func didBecomeForeground(notification: Notification) {
        player.rate = 1.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = self.bounds
    }
    
}
