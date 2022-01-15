//
//  MeasureSize.swift
//  AZSlider
//
//  Created by Adam Zarn on 1/7/22.
//

import SwiftUI

struct MeasureSize: ViewModifier {
    var didMeasureSize: (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear.preference(key: SizePreferenceKey.self, value: proxy.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { size in
                self.didMeasureSize(size)
            }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero
    
    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

extension View {
    func measureSize(_ didMeasureSize: @escaping (CGSize) -> Void) -> some View {
        modifier(MeasureSize(didMeasureSize: didMeasureSize))
    }
}
