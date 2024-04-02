//
//  ImageExtension.swift
//  AVFoundationSwiftUIPlayground
//
//  Created by Anthony Da cruz on 13/12/2022.
//

import Foundation
import SwiftUI

extension Image {
    func centerCropped() -> some View {
        GeometryReader { geo in
            self
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
    }
}
