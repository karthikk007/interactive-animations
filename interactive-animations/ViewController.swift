//
//  ViewController.swift
//  interactive-animations
//
//  Created by Karthik on 09/09/19.
//  Copyright © 2019 Karthik. All rights reserved.
//

import UIKit

enum ViewRenderType {
    case fullscreen
    case thumbnail
    
    var opposite: ViewRenderType {
        switch self {
        case .fullscreen:
            return .thumbnail
        case .thumbnail:
            return .fullscreen
        }
    }
}

class ViewController: UIViewController {


    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var currentRenderingType = ViewRenderType.thumbnail
    var animator: UIViewPropertyAnimator!
    var thumbnailFrame: CGRect!
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.blurView.effect = nil
        view.bringSubviewToFront(photoView)
        
        let width: CGFloat = 300.0
        let height: CGFloat = width * (9.0 / 16.0)
        
        let frame = self.view.frame
        photoView.frame = CGRect(x: frame.width - width, y: frame.height - height, width: width, height: height)
        thumbnailFrame = photoView.frame
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.photoView.addGestureRecognizer(tapGestureRecognizer)
        photoView.isUserInteractionEnabled = true
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        self.photoView.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    func handlePan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view.superview)
        
        switch sender.state {
        case .began:
            startPanning()
        case .changed:
            scrub(for: translation)
        case .ended:
            let velocity = sender.velocity(in: self.view.superview)
            endAnimation(at: translation, velocity: velocity)
        default:
            break
        }
    }

    @objc
    func handleTap(sender: UITapGestureRecognizer) {
//        animate(for: currentRenderingType.opposite)
    }
    
    func endAnimation(at point: CGPoint, velocity: CGPoint) {
        guard let animator = self.animator else {
            return
        }
        
        panGestureRecognizer.isEnabled = false
        
        let screenHeight = self.view.frame.height
        
        print("point = \(point)")
        print("velocity = \(velocity)")
        switch currentRenderingType {
        case .thumbnail:
            if point.y <= (-screenHeight / 4) || velocity.y <= -100 {
                animator.isReversed = false
                animator.addCompletion { (position) in
                    self.currentRenderingType = .fullscreen
                    self.panGestureRecognizer.isEnabled = true
                    self.animator = nil
                }
            } else {
                animator.isReversed = true
                animator.addCompletion { (position) in
                    self.currentRenderingType = .thumbnail
                    self.panGestureRecognizer.isEnabled = true
                    self.animator = nil
                }
            }
        case .fullscreen:
            if point.y >= screenHeight / 4 || velocity.y >= 100 {
                animator.isReversed = false
                animator.addCompletion { (position) in
                    self.currentRenderingType = .thumbnail
                    self.panGestureRecognizer.isEnabled = true
                    self.animator = nil
                }
            } else {
                animator.isReversed = true
                animator.addCompletion { (position) in
                    self.currentRenderingType = .fullscreen
                    self.panGestureRecognizer.isEnabled = true
                    self.animator = nil
                }
            }
        }
        
        let vector = CGVector(dx: velocity.x / 100, dy: velocity.y / 100)
        let springParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: vector)
        
        animator.continueAnimation(withTimingParameters: springParameters, durationFactor: 0.5)
    }
    
    func scrub(for point: CGPoint) {
        if let animator = self.animator {
            let yTranslation = self.view.center.y + point.y
            
            var progress: CGFloat = 0
            
            switch currentRenderingType {
            case .thumbnail:
                progress = 1 - (yTranslation / self.view.center.y)
            case .fullscreen:
                progress = (yTranslation / self.view.center.y) - 1
            }
            
            progress = max(0.0001, min(0.9999, progress))
            animator.fractionComplete = progress
        }
    }
    
    func startPanning() {
        var finalFrame = CGRect()
        var blurEffect: UIVisualEffect? = nil
        
        switch currentRenderingType {
        case .fullscreen:
            finalFrame = thumbnailFrame
            blurEffect = nil
        case .thumbnail:
            finalFrame = self.view.frame
            blurEffect = UIBlurEffect(style: .dark)
        }
        
        animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.8, animations: {
            self.photoView.frame = finalFrame
            self.blurView.effect = blurEffect
        })
    }
    
    func animate(for state: ViewRenderType) {
        switch state {
        case .fullscreen:
            animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.8, animations: {
                self.blurView.effect = UIBlurEffect(style: .dark)
                self.photoView.frame = self.view.frame
            })
        case .thumbnail:
            animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.8, animations: {
                self.blurView.effect = nil
                self.photoView.frame = self.thumbnailFrame
            })
        }
        
        animator.addCompletion { (position) in
            self.currentRenderingType = state
            self.animator = nil
        }
        animator.startAnimation()
    }
}

