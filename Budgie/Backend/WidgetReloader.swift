//
//  WidgetReloader.swift
//  Budgie
//
//  Created by Daniel Szurek on 5/26/25.
//

import WidgetKit
import Foundation

struct WidgetReloader {
    static func reloadWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 WidgetReloader: Requested widget timeline reload.")
        #else
        print("⚠️ WidgetReloader: WidgetKit not available.")
        #endif
    }
}
