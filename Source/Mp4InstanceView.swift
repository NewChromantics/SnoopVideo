import SwiftUI
import PopMp4

extension Double {
	 var int: Int {
		 get { Int(self) }
		 set { self = Double(int) }
	 }
 }

public extension Binding {

	static func convert<TInt, TFloat>(from intBinding: Binding<TInt>) -> Binding<TFloat>
	where TInt:   BinaryInteger,
		  TFloat: BinaryFloatingPoint{

		Binding<TFloat> (
			get: { TFloat(intBinding.wrappedValue) },
			set: { intBinding.wrappedValue = TInt($0) }
		)
	}

	static func convert<TFloat, TInt>(from floatBinding: Binding<TFloat>) -> Binding<TInt>
	where TFloat: BinaryFloatingPoint,
		  TInt:   BinaryInteger {

		Binding<TInt> (
			get: { TInt(floatBinding.wrappedValue) },
			set: { floatBinding.wrappedValue = TFloat($0) }
		)
	}
}

//	render an mp4 instance's state & data
struct Mp4InstanceView: View
{
	@StateObject var mp4Model = Mp4ViewModel()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL
	@State var selectedAtom: UUID?
	@State var selectedTrack: UUID?
	@State var sharedScrollX : Int=1
	//@State var isExpanded : Bool[
	
	func GetTimelineMin() -> Int
	{
		return 0
	}
	func GetTimelineMax() -> Int
	{
		return 1000
	}

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
		
		VSplitView()
		{
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
			
			HStack
			{
				Label("\(sharedScrollX)ms", systemImage: "clock.fill")
					.frame(minWidth: 30, alignment:.leading)
					.padding(.all, 6.0)
					.textSelection(.enabled)

				Slider(		value: .convert(from:$sharedScrollX),
							in: 0...100,
							onEditingChanged: { editing in
					//isEditing = editing
				}
				)
				.onChange(of: sharedScrollX)
				{
					print("slider on change \(sharedScrollX)")
				}
			}
			
			List(selection:$selectedTrack)
			{
				ForEach(mp4Model.lastMeta.tracks)
				{
					track in
					TrackView( track:track, ScrollX: $sharedScrollX )
						.contentShape(Rectangle())
				}
			}
		}
	}
}

#Preview 
{
	//Mp4InstanceView(documentUrl: .constant(SnoopVideoDocument()))
	Mp4InstanceView(documentUrl: URL(string:"/Volumes/Code/PopMp4/TestData/Test.mp4")! )
}

