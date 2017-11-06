//
//  Elissa.swift
//  Kitchen Stories
//
//  Created by Kersten Broich on 05/04/16.
//  Copyright © 2016 Kitchen Stories. All rights reserved.
//

import UIKit

public protocol ElissaItemDelegate: class {
    func elissaItemDidGetTapped(_ item: ElissaItem)
}

public class ElissaItem: UIView {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    public weak var delegate: ElissaItemDelegate? = nil
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        delegate?.elissaItemDidGetTapped(self)
    }
}

public class ElissaItemConfig: NSObject {
    public var message: String?
    public var image: UIImage?
}

public class ElissaConfiguration: NSObject {
    public var items: [ElissaItemConfig] = []
    public var backgroundColor: UIColor?
    public var textColor: UIColor?
    public var font: UIFont?
    public var arrowOffset: CGFloat = 2
    
    public override init() {}
}

open class Elissa: UIView, ElissaItemDelegate {

    private weak var itemsView: UIStackView!
    
    private let arrowSize: CGSize = CGSize(width: 20, height: 10)
    private let popupHeight: CGFloat = 36.0
    private let offsetToSourceView: CGFloat = 5.0
    private var popupMinMarginScreenBounds: CGFloat = 5.0
    
    private let configuration: ElissaConfiguration
    private static var staticElissa: Elissa?
    private var completionHandler: (() -> Void)?
    private weak var sourceView: UIView?
    private weak var triangleLayer: CAShapeLayer?
    
    open static var isVisible: Bool {
        return staticElissa != nil
    }
    
    internal init(sourceView: UIView, configuration: ElissaConfiguration, completionHandler: (() -> Void)?) {
        self.configuration = configuration
        self.completionHandler = completionHandler
        self.sourceView = sourceView
        
        super.init(frame: CGRect.zero)
        
        //Add Items Stack View
        let itemsView = UIStackView()
        itemsView.axis = .horizontal
        itemsView.spacing = 0
        itemsView.alignment = .fill
        itemsView.distribution = .fill
        itemsView.backgroundColor = configuration.backgroundColor
        self.itemsView = itemsView
        addSubview(itemsView)
        
        let bundle = Bundle(for: type(of: self))
        
        for itemConfig in configuration.items {
            //Make View
            let views = bundle.loadNibNamed("ElissaItem", owner: nil, options: nil)
            guard let elissaItem = views?.first as? ElissaItem else { return }
            itemsView.addArrangedSubview(elissaItem)
            elissaItem.delegate = self
            //Load Data Into Item
            elissaItem.messageLabel.text = itemConfig.message
            elissaItem.messageLabel.font = configuration.font
            elissaItem.messageLabel.textColor = configuration.textColor
            //Image
            if let image = itemConfig.image {
                elissaItem.iconImageView.image = image
                elissaItem.iconImageView.tintColor = configuration.textColor
            } else {
                elissaItem.iconImageView.removeFromSuperview()
            }
            //Layout
            layoutIfNeeded()
        }
        calculatePositon()
        self.itemsView.layer.cornerRadius = 3.0

        self.itemsView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        bringSubview(toFront: self.itemsView)
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        calculatePositon()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open static func dismiss() {
        if let staticElissa = staticElissa {
            staticElissa.removeFromSuperview()
            self.staticElissa = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    static func showElissa(_ sourceView: UIView, configuration: ElissaConfiguration, completionHandler: (() -> Void)?) -> Elissa {
        NotificationCenter.default.addObserver(self, selector: #selector(dismiss), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        let staticElissa = Elissa(sourceView: sourceView, configuration: configuration, completionHandler: completionHandler)
        self.staticElissa = staticElissa
        return staticElissa
    }
    
    private func calculatePositon() {
        guard let sourceView = sourceView else { return }
        var updatedFrame = CGRect()
        
        let margin: CGFloat = 8
        for arrangedSubview in self.itemsView.arrangedSubviews {
            if let elissaItem = arrangedSubview as? ElissaItem {
                if let _ = elissaItem.iconImageView {
                    updatedFrame.size.width += (elissaItem.iconImageView.frame.size.width + elissaItem.messageLabel.frame.size.width + margin * 3)
                }
                else {
                    updatedFrame.size.width += (elissaItem.messageLabel.frame.size.width + margin * 2)
                }
            }
        }
        
        updatedFrame.size.height = popupHeight
        updatedFrame.origin.x = sourceView.center.x - updatedFrame.size.width / 2
        updatedFrame.origin.y = (sourceView.frame.origin.y - popupHeight) - arrowSize.height + configuration.arrowOffset
        
        frame = updatedFrame
        layer.cornerRadius = 5
        
        let checkPoint = frame.maxX
        
        let appWidth = superview?.frame.width ?? UIScreen.main.applicationFrame.size.width
        
        var offset: CGFloat = 0.0
        
        if checkPoint > appWidth {
            offset = checkPoint - appWidth + popupMinMarginScreenBounds
        } else if frame.origin.x < 5 {
            offset = frame.origin.x - popupMinMarginScreenBounds
        }
        applyOffset(offset, view: self)
        
        drawTriangleForTabBarItemIndicator(self, sourceView: sourceView)
    }
    
    private func drawTriangleForTabBarItemIndicator(_ contentView: UIView, sourceView: UIView) {
        triangleLayer?.removeFromSuperlayer()
        
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath()
        let startPoint = (sourceView.center.x - arrowSize.width / 2) - contentView.frame.origin.x
        
        path.move(to: CGPoint(x: startPoint, y: contentView.frame.size.height))
        path.addLine(to: CGPoint(x: startPoint + (arrowSize.width / 2), y: contentView.frame.size.height + arrowSize.height))
        path.addLine(to: CGPoint(x: startPoint + arrowSize.width, y: contentView.frame.size.height))
        
        path.close()
        
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = (configuration.backgroundColor ?? self.tintColor).cgColor
        contentView.layer.addSublayer(shapeLayer)
        
        triangleLayer = shapeLayer
    }
    
    private func applyOffset(_ offset: CGFloat, view: UIView) {
        var frame = view.frame
        frame.origin.x -= offset
        view.frame = frame
    }
    
    //MARK: ElissaItem Delegate
    
    public func elissaItemDidGetTapped(_ item: ElissaItem) {
        completionHandler?()
    }
}
