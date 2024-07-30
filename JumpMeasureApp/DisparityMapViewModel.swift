//
//  DisparityMapViewModel.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/30.
//

import UIKit

final class DisparityMapViewModel {
    private var points: [CGPoint] = []
    @Published var pointState: State = .zeroPoint
    @Published var route: Route?

    enum State {
        case zeroPoint
        case onePoint
        case twoPoint(CGPoint, CGPoint)
    }

    enum Route {
        case modal
        case back
    }

    // MARK: - Public func
    func didTapPoint(location: CGPoint) {
        switch pointState {
        case .zeroPoint:
            points.append(location)
            pointState = .onePoint
        case .onePoint:
            points.append(location)
            pointState = .twoPoint(points[0], points[1])
        case .twoPoint: break
        }
    }

    func openModal() {
        route = .modal
    }

    func closeModal() {
        route = nil
        points.removeAll()
        pointState = .zeroPoint
    }
}
