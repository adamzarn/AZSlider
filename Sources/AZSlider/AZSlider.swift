//
//  AZSlider.swift
//  AZSlider
//
//  Created by Adam Zarn on 1/7/22.
//

import SwiftUI

public struct AZSlider<Value: BinaryFloatingPoint,
                       Track: View,
                       Fill: View,
                       Thumb: View>: View where Value.Stride: BinaryFloatingPoint {
    
    @Binding var value: Value
    let bounds: ClosedRange<Value>
    let step: Value
    let minimumValueLabel: Text?
    let maximumValueLabel: Text?
    let didStartDragging: ((_ value: Value) -> Void)?
    let didStopDragging: ((_ value: Value) -> Void)?
    let track: () -> Track
    let fill: (() -> Fill)?
    let thumb: () -> Thumb
    let thumbSize: CGSize
    
    var xOffset: CGFloat {
        return (trackSize.width - thumbSize.width) * CGFloat(percentage)
    }
    @State private var lastOffset: CGFloat = 0
    @State private var trackSize: CGSize = .zero
    
    public init(value: Binding<Value>,
                in bounds: ClosedRange<Value>,
                step: Value = 0.001,
                minimumValueLabel: Text? = nil,
                maximumValueLabel: Text? = nil,
                didStartDragging: ((_ value: Value) -> Void)? = nil,
                didStopDragging: ((_ value: Value) -> Void)? = nil,
                track: @escaping () -> Track,
                fill: (() -> Fill)?,
                thumb: @escaping () -> Thumb,
                thumbSize: CGSize) {
        _value = value
        self.bounds = bounds
        self.step = step
        self.minimumValueLabel = minimumValueLabel
        self.maximumValueLabel = maximumValueLabel
        self.didStartDragging = didStartDragging
        self.didStopDragging = didStopDragging
        self.track = track
        self.fill = fill
        self.thumb = thumb
        self.thumbSize = thumbSize
    }
    
    private var valueRange: Value {
        return bounds.upperBound - bounds.lowerBound
    }
    
    private var distanceFromLowerBound: Value {
        return value - bounds.lowerBound
    }
    
    private var percentage: Value {
        return distanceFromLowerBound/valueRange
    }
    
    private var availableTrackWidth: CGFloat {
        return trackSize.width - thumbSize.width
    }
    
    private var fillWidth: CGFloat {
        return trackSize.width * CGFloat(percentage)
    }
    
    public var body: some View {
        VStack {
            slider
            if minimumValueLabel != nil && maximumValueLabel != nil {
                labels
            }
        }
        .frame(height: max(trackSize.height, thumbSize.height))
    }
    
    var slider: some View {
        ZStack {
            sliderTrack
            sliderFill
        }
        .frame(width: trackSize.width, height: trackSize.height)
        .overlay(sliderThumb, alignment: .leading)
    }
    
    var sliderTrack: some View {
        track()
            .measureSize { size in
                trackSize = size
            }
    }
    
    var sliderFill: some View {
        fill?()
            .position(x: fillWidth - trackSize.width/2,
                      y: trackSize.height/2)
            .frame(width: fillWidth,
                   height: trackSize.height)
    }
    
    var sliderThumb: some View {
        thumb()
            .position(x: thumbSize.width/2,
                      y: thumbSize.height/2)
            .frame(width: thumbSize.width,
                   height: thumbSize.height)
            .offset(x: xOffset)
            .gesture(DragGesture(minimumDistance: 0)
                        .onChanged(onChanged(_:))
                        .onEnded(onEnded(_:)))
    }
    
    var labels: some View {
        HStack {
            minimumValueLabel.padding(.vertical, 4)
            Spacer()
            maximumValueLabel.padding(.vertical, 4)
        }
    }
    
    private func onChanged(_ gestureValue: DragGesture.Value) -> Void {
        if abs(gestureValue.translation.width) < 0.1 {
            lastOffset = xOffset
            didStartDragging?(value)
        }
        let newOffset = getUpdatedOffset(basedOn: gestureValue)
        let percentage = Value(newOffset/availableTrackWidth)
        let newValue = valueRange * percentage + bounds.lowerBound
        let steppedValue = getSteppedValue(basedOn: newValue)
        value = getUpdatedValue(basedOn: steppedValue)
    }
    
    private func getUpdatedOffset(basedOn gestureValue: DragGesture.Value) -> CGFloat {
        let updatedOffset = lastOffset + gestureValue.translation.width
        if updatedOffset < 0 { return 0 }
        if updatedOffset > availableTrackWidth { return availableTrackWidth }
        return updatedOffset
    }
    
    private func getSteppedValue(basedOn newValue: Value) -> Value {
        let numberOfSteps = round(newValue/step)
        return numberOfSteps * step
    }
    
    private func getUpdatedValue(basedOn steppedValue: Value) -> Value {
        if steppedValue < bounds.lowerBound { return bounds.lowerBound }
        if steppedValue > bounds.upperBound { return bounds.upperBound }
        return steppedValue
    }
    
    func onEnded(_ gestureValue: DragGesture.Value) -> Void {
        didStopDragging?(value)
    }
}

struct AZSlider_Previews: PreviewProvider {
    static var thumbRadius: CGFloat = 12
    static var horizontalPadding: CGFloat = 16
    
    static var previews: some View {
        AZSlider(value: Binding.constant(50),
                 in: 0...100,
                 minimumValueLabel: Text("0").font(.caption),
                 maximumValueLabel: Text("100").font(.caption),
                 track: {
            Capsule()
                .foregroundColor(.gray)
                .frame(width: UIScreen.main.bounds.width-2*horizontalPadding, height: 4)
        }, fill: {
            Capsule()
                .foregroundColor(.blue)
        }, thumb: {
            Circle()
                .foregroundColor(.blue)
                .shadow(radius: thumbRadius/1)
        }, thumbSize: CGSize(width: thumbRadius, height: thumbRadius))
            .padding(.horizontal, horizontalPadding)
    }
}
