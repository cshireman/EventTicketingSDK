//
//  NavigationRouter.swift
//  EventTicketingDemo
//
//  Created by Chris Shireman on 10/17/25.
//

import Foundation
import Combine
import SwiftUI

class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: Route) {
        path.append(route)
    }
}
