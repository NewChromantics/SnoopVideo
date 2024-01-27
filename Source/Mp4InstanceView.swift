import SwiftUI
import PopMp4


//	render an mp4 instance's state & data
struct Mp4InstanceView: View
{
	@StateObject var mp4Model = Mp4ViewModel()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL
	@State var selectedAtom: UUID?
	@State var selectedTrack: UUID?
	//@State var isExpanded : Bool[
	
	var body: some View
	{
		let Instance = mp4Model.lastMeta.Instance ?? -1
		let BytesParsed = FormatDataSize( Bytes: mp4Model.lastMeta.Mp4BytesParsed ?? 0 )
		let debug = "Parsed \(BytesParsed) (Instance \(Instance))"
		
		Label( "\(documentUrl.absoluteString) \(mp4Model.loadingStatus.description)", systemImage: "bolt.fill")
			.padding(.all, 6.0)
			.textSelection(.enabled)

		Label( debug, systemImage: "info.bubble.fill")
			.textSelection(.enabled)
			.padding(.all, 6.0)
			.onAppear
			{
				Task
				{
					try await mp4Model.Load(filename:documentUrl.absoluteString)
				}
			}

		if let error = mp4Model.error
		{
			Label("Decoding Error: \(error)", systemImage: "exclamationmark.triangle.fill")
				.textSelection(.enabled)
				.padding(.all, 8.0)
				.background(.red)
				.foregroundColor(.white)
				.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
				
				
		}
		
		List(selection:$selectedAtom)
		{
			ForEach(mp4Model.lastMeta.AtomTree ?? [])
			{
				atom in
				AtomView( atom:atom )
					//.background(.cyan)
					//.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
				/* this stops selection working
					.onTapGesture(count:2)
				{
					print("double click atom")
				}
				*/
			}
		}
		
		/*
		List(selection:$selectedTrack)
		{
			ForEach(mp4Model.lastMeta.tracks)
			{
				track in
				TrackView( track:track )
					.contentShape(Rectangle())
			}
		}
		 */
	}
}

#Preview 
{
	//Mp4InstanceView(documentUrl: .constant(SnoopVideoDocument()))
	Mp4InstanceView(documentUrl: URL(string:"/Volumes/Code/PopMp4/TestData/Test.mp4")! )
	
}

