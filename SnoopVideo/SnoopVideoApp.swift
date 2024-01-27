//
//  SnoopVideoApp.swift
//  SnoopVideo
//
//  Created by Graham Reeves on 02/01/2024.
//

import SwiftUI

@main
struct SnoopVideoApp: App 
{
	var body: some Scene 
	{
		let DefaultUrl = URL(string:"")
		DocumentGroup(viewing: SnoopVideoDocument.self)
		{
			file in
			Mp4InstanceView(documentUrl: (file.fileURL ?? DefaultUrl)! )
		}
		/*
		DocumentGroup(newDocument: SnoopVideoDocument())
		{ 
			file in
			ContentView(document: file.$document)
		}
		 */
	}
}

