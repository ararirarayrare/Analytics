//
//  File.swift
//  
//
//  Created by mac on 04.04.2023.
//

import Foundation
import Firebase
import FirebaseMessaging
import FirebaseFirestore

fileprivate struct URLBuilder {
    
    func url(withToken token: String, appID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "apps.vortexads.io"
        urlComponents.path = "/v2/guest"
        urlComponents.queryItems = [
            URLQueryItem(name: "uuid", value: token),
            URLQueryItem(name: "app", value: appID)
        ]
        
        return urlComponents.url
    }
    
}

class Networking: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private struct JSONResponse: Codable {
        var url: String
        var strategy: String
    }
    
    enum Result {
        case analytics(opening: Opening?)
        case error
        case native
    }
    
    
    
    func request(appID: String, _ completion: @escaping (_ result: Networking.Result) -> Void) {
        fetchToken { token in

            guard let url = URLBuilder().url(withToken: token, appID: appID) else {
                completion(.error)
                return
            }
            
            self.request(url: url, completion)
        }
    }
    
    
    
    private func request(url: URL, _ completion: @escaping (_ result: Networking.Result) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                completion(.error)
                return
            }
            
            DispatchQueue.main.async {
                
                switch statusCode {
                case 200:
                    guard let data = data,
                          let jsonResponse = try? JSONDecoder().decode(Networking.JSONResponse.self, from: data)  else {
                        completion(.error)
                        return
                    }
                    
//                    switch jsonResponse.strategy {
//                    case "PreviewURL":
//
//                        if let url = URL(string: jsonResponse.url) {
//                            self.checkIfFullScreen { fullScreen in
//                                let opening = Opening(url: url, fullScreen: fullScreen)
//                                completion(.analytics(opening: opening))
//                            }
//                        }
//
//                    case "PreviousURL":
//
//                        completion(.analytics(opening: .previous))
//
//                    default:
//                        completion(.error)
//                    }
                    
                    self.result(from: jsonResponse, completion)
                    
                case 204:
                    
                    if let url = URL(string: "https://www.youtube.com/watch?v=g4QoJAqINLE&list=RDg4QoJAqINLE&start_radio=1") {
                        
                        self.checkIfFullScreen { fullScreen in
                            let opening = Opening(url: url, fullScreen: fullScreen)
                            completion(.analytics(opening: opening))
                        }
                    }
                    
//                    completion(.native)
                    
                default:
                    completion(.error)
                }
                
            }
            
        }.resume()
    }
    
    
    
    private func fetchToken(_ completion: @escaping (String) -> Void) {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
            
            DispatchQueue.main.async {
                
                Messaging.messaging().token { (result, error) in
                    if let error = error {
                        print("Error fetching remote instance ID: \(error)")
                        completion("")
                    } else if let result = result {
                        
                        print("Remote instance ID token: \(result)")
                        completion(result)
                    }
                }
                
            }
            
        }
    }
    
    
    
    private func result(from jsonResponse: JSONResponse,
                        _ resultHandler: @escaping (Networking.Result) -> Void) {
        
        switch jsonResponse.strategy {
        case "PreviewURL":
            
            if let url = URL(string: jsonResponse.url) {
                self.checkIfFullScreen { fullScreen in
                    let opening = Opening(url: url, fullScreen: fullScreen)
                    resultHandler(.analytics(opening: opening))
                }
            }
            
        case "PreviousURL":
            
            resultHandler(.analytics(opening: .previous))
            
        default:
            resultHandler(.error)
        }
    }
    
    private func checkIfFullScreen(_ completion: @escaping (_ fullScreen: Bool) -> Void) {
        let database = Firestore.firestore()
        let docRef = database.document("app/preferences")
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            
            if let fullScreen = data["fullScreen"] as? Bool {
                completion(fullScreen)
            }
        }
    }
    
        
}
