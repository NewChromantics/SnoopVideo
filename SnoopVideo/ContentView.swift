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
		Label( "\(documentUrl.absoluteString) \(self.mp4Model.loadingStatus.description)", systemImage: "bolt.fill")
			.padding(.all, 6.0)
		
		if let error = self.mp4Model.error
		{
			Label("Decoding Error: \(error)", systemImage: "exclamationmark.triangle.fill")
				.padding(.all, 8.0)
				.background(.red)
				.foregroundColor(.white)
				.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
				
				
		}
		
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

