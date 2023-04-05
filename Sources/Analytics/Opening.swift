//
//  File.swift
//  
//
//  Created by mac on 05.04.2023.
//

import Foundation


struct Opening: Codable {
    
    let url: URL
    
    let fullScreen: Bool
    
    static var previous: Opening? {
        get {
            if let data = UserDefaults.standard.data(forKey: "previous"),
               let opening = try? JSONDecoder().decode(Opening.self, from: data) {
                return opening
            } else {
                return nil
            }
        }
        
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: "previous")
        }
    }
    
}
