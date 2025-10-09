//
//  URL+Additions.swift
//  EventTicketingSDK
//
//  Created by Chris Shireman on 10/9/25.
//

import Foundation

extension URL {
    func toWebSocket() -> URL? {
        URL(string: self.absoluteString.replacingOccurrences(of: "http", with: "ws") + "/ws")
    }
}
