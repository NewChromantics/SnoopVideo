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
