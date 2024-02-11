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
	@StateObject var fileDecoder = FileDecoderWrapper()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL
	@State var selectedAtom: UUID?
	@State var selectedTrack: UUID?
	@State var sharedScrollX : Int=1
	@State var fourccFilter: String=""
	
	//	when we have selected something in the tree, we asynchronously load it here
	//	which gets displayed in the hex view
	@State var visibleHexData: Data? = nil
	@State var visibleHexDataLabel: String = ""
	//@State var isExpanded : Bool[
	
	func GetTimelineMin() -> Int
	{
		return 0
	}
	func GetTimelineMax() -> Int
	{
		return 1000
	}
	
	func GetAtom(AtomUid:UUID?) -> AtomMeta?
	{
		if ( AtomUid == nil )
		{
			return nil
		}
		let RootAtoms = fileDecoder.lastMeta.AtomTree ?? []
		for atom in RootAtoms
		{
			let childMatch = atom.FindAtom(match: AtomUid!)
			if ( childMatch != nil )
			{
				return childMatch
			}
		}
		return nil
	}
	
	func AtomTree()-> some View
	{
		List(selection:$selectedAtom)
		{
			ForEach(fileDecoder.lastMeta.AtomTree ?? [])
			{
				atom in
				AtomView( atom:atom, fourccFilter: fourccFilter )
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
		.onChange(of: selectedAtom ?? UUID())
		{
			atomUid in
			Task
			{
				print("Selection changed \(atomUid)")
				var atom = GetAtom(AtomUid: atomUid)
				if ( atom == nil )
				{
					visibleHexDataLabel = ""
					visibleHexData = nil
					return
				}
				//	unselect old data
				visibleHexDataLabel = "\(atom!.Fourcc) loading... "
				visibleHexData = Data()
				do
				{
					//	emulate some slowness
					//await try await Task.sleep(nanoseconds: 1_000_000_000)//1sec
					
					visibleHexDataLabel = "\(atom!.Fourcc)"
					visibleHexData = try await fileDecoder.GetFileBytes(atom: atom)
					print("Got new hex data x\(visibleHexData?.count)")
				}
				catch
				{
					visibleHexDataLabel = "Error loading \(atom!.Fourcc); \(error.localizedDescription)"
					visibleHexData = Data()
				}
			}
		}
	}

	var body: some View
	{
		let Instance = fileDecoder.lastMeta.Instance ?? -1
		let BytesParsed = FormatDataSize( Bytes: fileDecoder.lastMeta.Mp4BytesParsed ?? 0 )
		let debug = "Parsed \(BytesParsed) (Instance \(Instance))"
		
		Label( "\(documentUrl.absoluteString) \(fileDecoder.loadingStatus.description)", systemImage: "bolt.fill")
			.padding(.all, 6.0)
			.textSelection(.enabled)

		Label( debug, systemImage: "info.bubble.fill")
			.textSelection(.enabled)
			.padding(.all, 6.0)
			.onAppear
			{
				Task
				{
					try await fileDecoder.Load(filename:documentUrl.absoluteString)
				}
			}

		if let error = fileDecoder.error
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
			//	seem to need geometry reader to make HSplitView work
			GeometryReader
			{
				geometry in
				VStack
				{
					HSplitView 
					{
						/* not currently redrawing list
						 HStack
						 {
						 Label("Filter",systemImage: "magnifyingglass")
						 TextField("moov",text:$fourccFilter)
						 .onChange(of: fourccFilter)
						 {
						 newvalue in
						 print("onChange fourccFilter=\(fourccFilter) newvalue=\(newvalue)")
						 fourccFilter = newvalue
						 }
						 }
						 Label(fourccFilter,systemImage: "bolt.car")
						 */
						
						AtomTree()
							.frame(maxWidth: .infinity, maxHeight: .infinity)
						
						VStack
						{
							Label(visibleHexDataLabel,systemImage: "info.square.fill")
								.frame(maxWidth: .infinity, alignment: .topLeading)
							HexView(input: visibleHexData)
								.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
					}
				}.frame(width: geometry.size.width, height: geometry.size.height)
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
					//print("slider on change \(sharedScrollX)")
				}
			}
			
			List(selection:$selectedTrack)
			{
				ForEach(fileDecoder.lastMeta.tracks)
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

