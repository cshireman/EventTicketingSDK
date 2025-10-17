//
//  String+Additions.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/13/25.
//
import Foundation

extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
