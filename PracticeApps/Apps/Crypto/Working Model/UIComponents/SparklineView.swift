//
//  CoinMarket.swift
//  PracticeApps
//
//  Created by Ashish Shaik on 1/10/26.
//

import SwiftUI

struct SparklineView: View {
    let prices: [Double]
    let isUp: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            if prices.count >= 2 {
                Path { path in
                    let minV = prices.min() ?? 0
                    let maxV = prices.max() ?? 1
                    let range = max(maxV - minV, 0.000001)

                    func point(_ i: Int) -> CGPoint {
                        let x = w * CGFloat(i) / CGFloat(prices.count - 1)
                        let normalized = (prices[i] - minV) / range
                        let y = h * (1 - CGFloat(normalized))
                        return CGPoint(x: x, y: y)
                    }

                    path.move(to: point(0))
                    for i in 1..<prices.count {
                        path.addLine(to: point(i))
                    }
                }
                .stroke(lineWidth: 2)
                .opacity(0.85)
                .animation(.easeInOut(duration: 0.35), value: prices)
            } else {
                EmptyView()
            }
        }
        .frame(width: 80, height: 28)
        .foregroundColor(isUp ? .green : .red)
    }
}
