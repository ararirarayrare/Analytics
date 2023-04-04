import UIKit

@objc(Analytics)
public class Analytics: NSObject {
    
    private let date: Date
    private let appID: String
    private let window: UIWindow?

    public init(dateString: String, appID: String, window: UIWindow?) {
        
        self.date = Date()
        self.appID = appID
        self.window = window
    }
    
    @objc
    public init(dateString: NSString, appID: NSString, window: UIWindow?) {
        
        self.date = Date()
        self.appID = appID as String
        self.window = window
    }
    
    @objc
    public func start() {
        
        let networking = Networking()
        networking.request()
    }
    
}
