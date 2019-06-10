//
//  MSTooltip.swift
//  Created by Michal Sefl on 02.08.18.
//

import UIKit

// MARK: - MSTooltip

class Tooltip: UIView, Modal {
    var backgroundView = UIView()
    var imageView = UIImageView()
    var canBeDismissed = false

    convenience init(title: String) {
        self.init(frame: UIScreen.main.bounds)
        initialize(title: title)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func show(_ text: String) {
        let tooltip = Tooltip(title: text)
        tooltip.show(animated: true)
    }

    func initialize(title: String) {
        // background

        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.6
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnBackgroundView)))
        addSubview(backgroundView)

        let imageWidth = frame.width / 1.25
        let imageHeight = imageWidth / 1.75

        // image

        imageView.frame.origin = CGPoint(x: 0, y: 0)
        imageView.frame.size = CGSize(width: imageWidth, height: imageHeight)
        imageView.image = nil
        imageView.backgroundColor = UIColor(red: 42/255, green: 44/255, blue: 47/255, alpha: 1)
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnBackgroundView)))
        addSubview(imageView)

        // title

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributedString = NSMutableAttributedString(string: title, attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle
        ])

        let titleLabel = UILabel(frame: CGRect(x: imageWidth * 0.05, y: 0, width: imageWidth * 0.9, height: imageHeight))
        titleLabel.numberOfLines = 4
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.attributedText = attributedString
        imageView.addSubview(titleLabel)
        
        //var timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: Selector(("tooltipDidShow:")), userInfo: nil, repeats: false)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
            self.canBeDismissed = true
        }
    }

    @objc func didTapOnBackgroundView() {
        if canBeDismissed {
            dismiss(animated: true)
        }
    }
}

// MARK: - Tooltip Protocol

protocol Modal {
    func show(animated: Bool)
    func dismiss(animated: Bool)

    var backgroundView: UIView { get }
    var imageView: UIImageView { get set }
}

extension Modal where Self: UIView {
    func show(animated: Bool) {
        backgroundView.alpha = 0
        imageView.center = CGPoint(x: center.x, y: frame.height + imageView.frame.height / 2)

        UIApplication.shared.keyWindow?.addSubview(self)

        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 0.66
            })

            UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: UIView.AnimationOptions(rawValue: 0), animations: {
                self.imageView.center = self.center
            }, completion: { _ in

            })
        }
        else {
            backgroundView.alpha = 0.66
            imageView.center = center
        }
    }

    func dismiss(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 0
            }, completion: { _ in

            })

            UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: UIView.AnimationOptions(rawValue: 0), animations: {
                self.imageView.center = CGPoint(x: self.center.x, y: self.frame.height + self.imageView.frame.height / 2)
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
        else {
            removeFromSuperview()
        }
    }
}
