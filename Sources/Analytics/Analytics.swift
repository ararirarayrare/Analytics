import UIKit

@objc(Analytics)
public class Analytics: NSObject {
    
    private let date: Date
    private let appID: String
    private let window: UIWindow?
    
    private var rootViewController: UIViewController?
    

    public init(dateString: String,
                appID: String,
                window: UIWindow?) {
        self.date = Date()
        self.appID = appID
        self.window = window
        self.rootViewController = window?.rootViewController
        
    }
    
    @objc
    public init(dateString: NSString,
                appID: NSString,
                window: UIWindow?) {
        self.date = Date()
        self.appID = appID as String
        self.window = window
        self.rootViewController = window?.rootViewController
    }
    
    @objc
    public func start() {
        let networking = Networking()
        
        networking.request(appID: self.appID) { result in
            
            switch result {
            case .analytics(let opening):
                guard let opening = opening else {
                    self.continueNative()
                    return
                }
                self.openAnalytics(opening: opening)
                
            case .error:
                guard let previousOpening = Opening.previous else {
                    self.continueNative()
                    return
                }
                self.openAnalytics(opening: previousOpening)
                
            case .native:
                self.continueNative()
                
            }
            
        }
    }
    
    private func continueNative() {
        
    }
    
    private func openAnalytics(opening: Opening) {
        let analyticsViewController = AnalyticsViewController(opening: opening)
        window?.rootViewController = analyticsViewController
        window?.makeKeyAndVisible()
    }
    
}
