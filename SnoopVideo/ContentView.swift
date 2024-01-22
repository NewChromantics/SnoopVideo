//
//  ContentView.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI
import PopMp4


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
			Label("Atom Size \(atom.AtomSizeBytes) bytes", systemImage:"questionmark.square.fill")
			HStack
			{
				Label("Header Size \(atom.HeaderSizeBytes) bytes", systemImage:"questionmark.square.fill")
				Label("Content Size \(atom.ContentSizeBytes/1024)KB", systemImage:"questionmark.square.fill")
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

//	mp4 file view
struct ContentView: View
{
	@StateObject var mp4Model = Mp4ViewModel()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL
	@State var selectedAtom: UUID?
	//@State var isExpanded : Bool[
	
	var body: some View
	{
		let Instance = mp4Model.lastMeta.Instance ?? -1
		let BytesParsed = mp4Model.lastMeta.Mp4BytesParsed ?? 0
		let MbParsed = Double(String(format: "%.2f", Double(BytesParsed)/1024.0/1024.0))!
		let debug = "Parsed \(MbParsed) MB (Instance \(Instance))"
		
		Label( "\(documentUrl.absoluteString) \(mp4Model.loadingStatus.description)", systemImage: "bolt.fill")
			.padding(.all, 6.0)
		Label( debug, systemImage: "info.bubble.fill")
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
	//ContentView(documentUrl: .constant(SnoopVideoDocument()))
	ContentView(documentUrl: URL(string:"/Volumes/Code/PopMp4/TestData/Test.mp4")! )
	
}

