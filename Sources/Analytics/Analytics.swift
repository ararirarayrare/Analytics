import UIKit

@objc(Analytics)
public class Analytics: NSObject {
    
    private let date: Date
    private let appID: String
    private let window: UIWindow?
        
    private let setupHandler: () -> Void
    

    public init(dateString: String,
                appID: String,
                window: UIWindow?,
                setupHandler: @escaping () -> Void) {
        self.date = Date()
        self.appID = appID
        self.window = window
        self.setupHandler = setupHandler
    }
    
    @objc
    public init(dateString: NSString,
                appID: NSString,
                window: UIWindow?,
                setupHandler: @escaping () -> Void) {
        self.date = Date()
        self.appID = appID as String
        self.window = window
        self.setupHandler = setupHandler
    }
    
    @objc
    public func start() {
        let networking = Networking()
        
        networking.request(appID: self.appID) { result in
            
            switch result {
            case .analytics(let opening):
                guard let opening = opening else {
                    self.setupHandler()
                    return
                }
                self.openAnalytics(opening: opening)
                
            case .error:
                guard let previousOpening = Opening.previous else {
                    self.setupHandler()
                    return
                }
                self.openAnalytics(opening: previousOpening)
                
            case .native:
                self.setupHandler()
            }
            
        }
    }
    
    
    private func openAnalytics(opening: Opening) {
        let analyticsViewController = AnalyticsViewController(opening: opening)
        window?.rootViewController = analyticsViewController
        window?.makeKeyAndVisible()
    }
    
}
