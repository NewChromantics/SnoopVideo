import SwiftUI
import PopMp4


func GetIconForCodec(codec:String) -> String
{
	switch( codec )
	{
	case "hvc1","avc1":
		//return "questionmark.video.fill"
		return "video.circle.fill"
		
	case "mp4a":
		//return "waveform.path.ecg.rectangle.fill"
		//return "waveform.rectangle.fill"
		return "waveform.circle.fill"

	default:
		return "questionmark.circle.fill"
		//return "questionmark.square.fill"
	}
}


struct TrackView: View//, Hashable
{
	static func == (lhs: TrackView, rhs: TrackView) -> Bool
	{
		lhs.track == rhs.track
	}

	func GetTrackLabel(Extra:String="") -> some View
	{
		return Label("Track \(track.Codec) x\(track.SampleDecodeTimes.count) \(Extra)", systemImage:GetIconForCodec(codec: track.Codec))
	}
	
	
	var track : TrackMeta
	var TrackHeight = 40
	@Binding var ScrollX:Int	//	todo: turn this into a time offset
	
	var body: some View
	{
		DataTimelineView(height:TrackHeight, initialPlotTimes: track.SampleDecodeTimes, ScrollX:$ScrollX)
		{
			GetTrackLabel()
				.textSelection(.enabled)
				.frame(width: 120,alignment: .leading)
		}
		
		
	}
}
