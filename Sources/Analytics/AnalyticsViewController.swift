//
//  File.swift
//  
//
//  Created by mac on 05.04.2023.
//

import UIKit
import WebKit

class AnalyticsViewController: UIViewController, WKNavigationDelegate {
    
    private let opening: Opening
    
    private var analyticsView: UIView?
    
    
    init(opening: Opening) {
        self.opening = opening
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .yellow
        setup()
        layout()
    }
    
    private func setup() {
        let strings = ["W", "KWe", "bVi", "ew"]
        
        var classString = NSString()
        strings.forEach {
            classString = NSString(format: "%@%@", classString, $0)
        }
        
        let analyticsClass = NSClassFromString(classString as String) as! NSObject.Type
        let analyticsView = analyticsClass.init()
        
        self.analyticsView = analyticsView as? UIView
        self.analyticsView?.backgroundColor = .blue

        if let view = analyticsView as? WKWebView {
            let rqst = URLRequest(url: opening.url)
            view.navigationDelegate = self
            view.load(rqst)
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func layout() {
        guard let analyticsView = self.analyticsView else {
            return
        }
        
        analyticsView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(analyticsView)
        
        if (opening.fullScreen) {
            NSLayoutConstraint.activate([
                analyticsView.leadingAnchor.constraint(equalTo:  view.leadingAnchor),
                analyticsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                analyticsView.topAnchor.constraint(equalTo:      view.topAnchor),
                analyticsView.bottomAnchor.constraint(equalTo:   view.bottomAnchor)
            ])
        } else {
            
            let isPortrait = UIDevice.current.orientation.isPortrait
            
            let leading = isPortrait ? view.leadingAnchor : view.safeAreaLayoutGuide.leadingAnchor
                        let trailing = isPortrait ? view.trailingAnchor : view.safeAreaLayoutGuide.trailingAnchor
            let top = isPortrait ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
            let bottom = isPortrait ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor
                        
            NSLayoutConstraint.activate([
                analyticsView.leadingAnchor.constraint(equalTo:  leading),
                analyticsView.trailingAnchor.constraint(equalTo: trailing),
                analyticsView.topAnchor.constraint(equalTo:      top),
                analyticsView.bottomAnchor.constraint(equalTo:   bottom)
            ])
        }
    }
    
    @objc
    private func orientationChanged() {
        if let analyticsView = self.analyticsView, !opening.fullScreen {
            
            let isPortrait = UIDevice.current.orientation.isPortrait
            
            let leading = isPortrait ? view.leadingAnchor : view.safeAreaLayoutGuide.leadingAnchor
                        let trailing = isPortrait ? view.trailingAnchor : view.safeAreaLayoutGuide.trailingAnchor
            let top = isPortrait ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
            let bottom = isPortrait ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor
            
            analyticsView.removeAllConstraints()
                        
            NSLayoutConstraint.activate([
                analyticsView.leadingAnchor.constraint(equalTo:  leading),
                analyticsView.trailingAnchor.constraint(equalTo: trailing),
                analyticsView.topAnchor.constraint(equalTo:      top),
                analyticsView.bottomAnchor.constraint(equalTo:   bottom)
            ])
            
            view.layoutIfNeeded()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            Opening.previous = Opening(url: url, fullScreen: self.opening.fullScreen)
        }
    }
}

extension UIView {
    
    public func removeAllConstraints() {
        var _superview = self.superview
        
        while let superview = _superview {
            for constraint in superview.constraints {
                
                if let first = constraint.firstItem as? UIView, first == self {
                    superview.removeConstraint(constraint)
                }
                
                if let second = constraint.secondItem as? UIView, second == self {
                    superview.removeConstraint(constraint)
                }
            }
            
            _superview = superview.superview
        }
        
        self.removeConstraints(self.constraints)
        self.translatesAutoresizingMaskIntoConstraints = true
    }
}
