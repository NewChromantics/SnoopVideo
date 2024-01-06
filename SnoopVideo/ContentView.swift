//
//  ContentView.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI


//	mp4 file view
struct ContentView: View
{
	@StateObject var mp4Model = Mp4ViewModel()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL

	var body: some View 
	{
		Label( documentUrl.absoluteString, systemImage: "bolt.fill")
			.labelStyle(.titleAndIcon)
		//TextEditor(text: documentUrl.absoluteString )
		List
		{
			var strings = mp4Model.AtomTree
			ForEach(strings, id:\.self)
			{
				string in
						Text(string)
			}
		}
		//.task{}
		.onAppear
		{
			Task
			{
				try await mp4Model.Load(filename:"")
			}
		}
	}
}

#Preview 
{
	//ContentView(documentUrl: .constant(SnoopVideoDocument()))
	ContentView(documentUrl: URL(string:"Preview.mp4")! )
}
