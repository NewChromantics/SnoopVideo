import SwiftUI
import PopMp4

struct TrackView: View, Hashable
{
	static func == (lhs: TrackView, rhs: TrackView) -> Bool
	{
		lhs.track == rhs.track
	}

	
	var track : TrackMeta

	
	var body: some View
	{
		Label("Track", systemImage:"questionmark.square.fill")
	}
}
