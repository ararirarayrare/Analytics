import UIKit

public struct Analytics {
    
    private let date: Date
    private let appID: String
    private let window: UIWindow?

    public init(dateString: String, appID: String, window: UIWindow?) {
        
        self.date = Date()
        self.appID = appID
        self.window = window
    }
    
    public func start() {
        
        let networking = Networking()
                
    }
    
}
