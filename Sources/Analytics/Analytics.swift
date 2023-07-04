import UIKit


@objc(Analytics)
public class Analytics: NSObject {
    
    public static var preferredOrientation: UIInterfaceOrientationMask = .landscape
    
    private(set) public static var orientation: UIInterfaceOrientationMask = preferredOrientation
    
    private let date: Date
    private let appID: String
    private let window: UIWindow?
        
    private let setupHandler: () -> UIViewController?
    
    private var analyticsAvailable: Bool {
        return (Date() >= self.date)
    }
    
    
    /// Creates analytics instance. Use start() method to make all the magic happen!
    ///
    /// - warning: Setup native root view controller only programmatically and only in setupHandler! If you use storyboard - remove initial view controller arrow!
    ///
    /// - parameter dateString: Date string must conform to "yyyy-MM-dd" format. Example: "2023-04-06".
    /// - parameter appID: Numeric ID from App Store Connect. Example: "6446656114".
    /// - parameter window: Application window.
    /// - parameter setupHandler: Closure will be executed if analytics is unavailable. You must return loader view controller which will set the window.rootViewController at the end of its animation.
    /// - returns: Analytics instance.

    public init(dateString: String,
                appID: String,
                window: UIWindow?,
                setupHandler: @escaping () -> UIViewController?) {
        self.date = Date(dateString: dateString)
        self.appID = appID
        self.window = window
        self.setupHandler = setupHandler
    }
    
    
    /// Creates analytics instance. Use start() method to make all the magic happen!
    ///
    /// - warning: Setup native root view controller only programmatically and only in setupHandler! If you use storyboard - remove initial view controller arrow!
    ///
    /// - parameter dateString: Date string must conform to "yyyy-MM-dd" format. Example: "2023-04-06".
    /// - parameter appID: Numeric ID from App Store Connect. Example: "6446656114".
    /// - parameter window: Application window.
    /// - parameter setupHandler: Closure will be executed if analytics is unavailable. Setup native root view controller here. Assign it to window.rootViewController. Make window key and visible.
    /// - returns: Analytics instance.
    
    @objc
    public init(dateString: NSString,
                appID: NSString,
                window: UIWindow?,
                setupHandler: @escaping () -> UIViewController?) {
        self.date = Date(dateString: dateString as String)
        self.appID = appID as String
        self.window = window
        self.setupHandler = setupHandler
    }
    
    /// Starts analytics
    ///
    /// - warning: Use as soon as app is launched. Only in AppDelegate / SceneDelegate.
    
    @objc
    public func start() {
        guard analyticsAvailable else {
            print("\n\n Ooops, somethins went wrong. Analytics is unavailable now. \n\n")
            self.openApp()
            return
        }
        
        // MARK: System background viewController untill responce is received!
    
        if #available(iOS 13.0, *) {
            window?.rootViewController = UIViewController()
            window?.rootViewController?.view.backgroundColor = .systemBackground
            window?.makeKeyAndVisible()
        }
        
        
        let networking = Networking()
        
        networking.request(appID: self.appID) { result in
            
            switch result {
            case .analytics(let opening):
                
                guard let opening = opening else {
                    self.openApp()
                    return
                }
                self.openAnalytics(opening: opening)
                
                print("\n\n Success! Did receive 'analytics' responce! Opening... \n\n")
                
            case .error:
                
                guard let previousOpening = Opening.previous else {
                    self.openApp()
                    print("\n\n Something went wrong :( \n\n")
                    return
                }
                self.openAnalytics(opening: previousOpening)
                
                print("\n\n Something went wrong, but you have previous opening! \n\n ")
                
            case .native:
                
                self.openApp()
                
                print("\n\n For some reason you have received 'native' responce \n\n")
                
            }
            
        }
    }
    
    /// Opens Analytics view controller.
    ///
    /// - parameter opening: Analytics opening preferences, such as URL and fullScreen boolean.
    
    private func openAnalytics(opening: Opening) {
        Analytics.orientation = .all
        
        let analyticsViewController = AnalyticsViewController(opening: opening)
        window?.rootViewController = analyticsViewController
        window?.makeKeyAndVisible()
    }
    
    private func openApp() {
        Analytics.orientation = Analytics.preferredOrientation
        
        let viewController = setupHandler()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
    
}

