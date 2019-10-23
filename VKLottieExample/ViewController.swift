//
//  ViewController.swift
//  VKLottieExample
//
//  Created by Антон Сергеев on 15.10.2019.
//

import UIKit
import VKLottie

class ViewController: UIViewController {

    @IBOutlet weak var vklView: VKLView?
    @IBOutlet weak var vklView1: VKLView?
    @IBOutlet weak var vklView2: VKLView?
    @IBOutlet weak var vklView3: VKLView?
    var player: VKLPlayer?
    var player1: VKLPlayer?
    var player2: VKLPlayer?
    var player3: VKLPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async { [weak self] in
            guard let self = self,
                let path = Bundle.main.path(forResource: "acrobatics", ofType: "json"),
                let data = FileManager.default.contents(atPath: path) else {
                return
            }
            let player = VKLPlayer(animationData: data, cacheKey: "acrobatics", size: CGSize(width: 288 / 3, height: 360 / 3), scale: 3)
            let player1 = VKLPlayer(animationData: data, cacheKey: "acrobatics", size: CGSize(width: 288 / 3, height: 360 / 3), scale: 3)
            let player2 = VKLPlayer(animationData: data, cacheKey: "acrobatics", size: CGSize(width: 288 / 3, height: 360 / 3), scale: 3)
            let player3 = VKLPlayer(animationData: data, cacheKey: "acrobatics", size: CGSize(width: 288 / 3, height: 360 / 3), scale: 3)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.player = player
                self.vklView?.player = player
                self.vklView?.isPlaying = true

                self.player1 = player1
                self.vklView1?.player = player1
                self.vklView1?.isPlaying = true

                self.player2 = player2
                self.vklView2?.player = player2
                self.vklView3?.isPlaying = true

                self.player3 = player3
                self.vklView3?.player = player3
                self.vklView3?.isPlaying = true
            }
        }
    }


}

