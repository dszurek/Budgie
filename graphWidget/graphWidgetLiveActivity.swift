//
//  graphWidgetLiveActivity.swift
//  graphWidget
//
//  Created by Daniel Szurek on 11/26/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct graphWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct graphWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: graphWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension graphWidgetAttributes {
    fileprivate static var preview: graphWidgetAttributes {
        graphWidgetAttributes(name: "World")
    }
}

extension graphWidgetAttributes.ContentState {
    fileprivate static var smiley: graphWidgetAttributes.ContentState {
        graphWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: graphWidgetAttributes.ContentState {
         graphWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: graphWidgetAttributes.preview) {
   graphWidgetLiveActivity()
} contentStates: {
    graphWidgetAttributes.ContentState.smiley
    graphWidgetAttributes.ContentState.starEyes
}
