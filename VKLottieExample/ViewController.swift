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
    var player: VKLPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async { [weak self] in
            guard let self = self,
                let path = Bundle.main.path(forResource: "acrobatics", ofType: "json"),
                let data = FileManager.default.contents(atPath: path) else {
                return
            }
            let player = VKLPlayer(animationData: data, cacheKey: "acrobatics", size: CGSize(width: 256, height: 256), scale: 3)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.player = player
                self.vklView?.player = player
                self.vklView?.isPlaying = true
            }
        }
    }


}

