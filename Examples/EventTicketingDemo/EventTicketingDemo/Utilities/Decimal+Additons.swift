//
//  Decimal+Additons.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/17/25.
//

import Foundation

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }

    func formatted(as currency: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = currency ? .currency : .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "0.00"
    }
}
