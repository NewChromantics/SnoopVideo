//
//  ContentView.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI
import PopMp4


//	mp4 file view
struct ContentView: View
{
	@StateObject var mp4Model = Mp4ViewModel()
	//@Binding var document: SnoopVideoDocument
	var documentUrl : URL

	var body: some View 
	{
		Label( documentUrl.absoluteString, systemImage: "bolt.fill")
		Label( "Loading status; \(self.mp4Model.loadingStatus.description)", systemImage: "bolt.fill")
			.labelStyle(.titleAndIcon)
		List
		{
			var strings = mp4Model.atomTree
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

