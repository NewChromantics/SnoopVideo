//
//  ContentView.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI
import PopMp4

func FormatDataSize(Bytes:Int) -> String
{
	if ( Bytes < 1024 )
	{
		return "\(Bytes) bytes"
	}
	
	let MegaByte = 1024 * 1024;
	if ( Bytes < MegaByte )
	{
		let Kb = String(format: "%.2f", Double(Bytes)/1024.0)
		return "\(Kb) KB"
	}
	
	let Mb = String(format: "%.2f", Double(Bytes)/Double(MegaByte))
	return "\(Mb) MB"
}


struct AtomView: View, Hashable
{
	static func == (lhs: AtomView, rhs: AtomView) -> Bool
	{
		//lhs.atom.Fourcc == rhs.atom.Fourcc
		//lhs.atom.id == rhs.atom.id
		lhs.atom == rhs.atom
	}

	
	var atom : AtomMeta
	//	makes this non hashable :/ so root needs a map of expanded items?
	//@State var isExpanded: Bool
	

	
	var body: some View
	{
		DisclosureGroup()
		{
			//Label("Fourcc \(atom.Fourcc)", systemImage:"questionmark.square.fill")
			Label("Atom Size \(FormatDataSize(Bytes: atom.AtomSizeBytes))", systemImage:"questionmark.square.fill")
				.textSelection(.enabled)
			HStack
			{
				Label("Header Size \(FormatDataSize(Bytes: atom.HeaderSizeBytes))", systemImage:"questionmark.square.fill")
					.textSelection(.enabled)
				Label("Content Size \(FormatDataSize(Bytes: atom.ContentSizeBytes))", systemImage:"questionmark.square.fill")
					.textSelection(.enabled)
			}
			//Label("Content file offset\(atom.HeaderSizeBytes) bytes", systemImage:"questionmark.square.fill")
			
			
			if let children = atom.Children
			{
				ForEach(children)
				{
					//Label("child", systemImage:"questionmark.square.fill")
					child in
					AtomView( atom:child )
				}
			}
		}
		label:
		{
			HStack
			{
				Label("\(atom.Fourcc)", systemImage: "atom")
					.textSelection(.enabled)
				Spacer()
			}
		}
			/*stops selection and only applies to label
			 .onTapGesture(count:2)
			 {
			 print("on double tap \(atom.Fourcc)")
			 //isExpanded = !isExpanded
			 }
			 */
		
	}
}


//	render an mp4 instance's state & data
struct Mp4InstanceView: View
{
	@StateObject var mp4Model = Mp4ViewModel()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL
	@State var selectedAtom: UUID?
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
		
	}
}

#Preview 
{
	//Mp4InstanceView(documentUrl: .constant(SnoopVideoDocument()))
	Mp4InstanceView(documentUrl: URL(string:"/Volumes/Code/PopMp4/TestData/Test.mp4")! )
	
}

