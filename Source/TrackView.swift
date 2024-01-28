import SwiftUI
import PopMp4
import SpriteKit


extension SKView {
	open override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		window?.acceptsMouseMovedEvents = true
	}
}

class GameScene: SKScene 
{
	var dragStartScreenx : Int?
	var dragStartAnchorX : CGFloat?
	
	override func didMove(to view: SKView)
	{
		//physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
		anchorPoint.y = 0
	}
		
	override func mouseDown(with event: NSEvent)
	{
		let mousePosition = event.location(in: self)
		
		dragStartScreenx = Int(mousePosition.x)
		dragStartAnchorX = anchorPoint.x
		
		PlotPosition( Time:Int(mousePosition.x), Colour: .green, Width: 1 )
		
		//	anchor point is defaulted to 0.5,0.5
		//anchorPoint.x = anchorPoint.x - 0.10
	}
	
	
	//	zoom with wheel
	override func scrollWheel(with event: NSEvent)
	{
		print(event)
	}
	
	
	//	NSResponder
	override func mouseDragged(with event: NSEvent)
	{
		if ( dragStartScreenx == nil )
		{
			print("Not dragging")
			return
		}
		
		//	gr: when calculating local pos with .location(), the anchor pos is taken into account
		//		as we want to do everything relative to when we first started, we need to reset it
		//		to get an accurate diff from where we started
		anchorPoint.x = dragStartAnchorX!
		let mousePosition = event.location(in: self)
		
		let ScreenDeltax = Int(mousePosition.x) - dragStartScreenx!
		let AnchorDelta = CGFloat(ScreenDeltax) / frame.width
		print("ScreenDeltax \(ScreenDeltax) AnchorDelta \(AnchorDelta)")
		let NewAnchor = dragStartAnchorX! + (AnchorDelta)
		
		//	todo: snap anchor to pixel
		anchorPoint.x = NewAnchor
		//dragStartScreenx = Int(mousePosition.x)
		//dragStartAnchorX = anchorPoint.x

	}

	
	//	mouse moved with no button
	//override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
	//override func mouseDown(with event: NSEvent)
	override func mouseMoved(with event: NSEvent)
	{
		//print(event)
		//guard let touch = touches.first else { return }
		//let location = touch.location(in: self)
		var location = event.location(in: self)
		//location = CGPoint( x:location.x + anchorPoint.x, y:location.y )
		print("location \(location)")
		let box = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 4))
		box.position = location
		//box.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: 4))
		addChild(box)
	}
	
	func PlotPosition(Time:Int,Colour:NSColor=NSColor.white,Width:Int=3)
	{
		let SceneHeight = frame.height
		//	upside down plotting and anchor is 0.5
		let Ploth = Int(SceneHeight)*2
		let Ploty = 0
		let Plotx = Time
		let box = SKSpriteNode(color:Colour, size: CGSize(width: Width, height: Ploth))
		box.position = CGPoint( x:Plotx, y:Ploty )
		addChild(box)
	}
	
	func PlotPositions(Times:[Int])
	{
		for time in Times
		{
			PlotPosition(Time:time)
		}
	}

}



func GetIconForCodec(codec:String) -> String
{
	switch( codec )
	{
	case "hvc1","avc1":
		//return "questionmark.video.fill"
		return "video.circle.fill"
		
	case "mp4a":
		//return "waveform.path.ecg.rectangle.fill"
		//return "waveform.rectangle.fill"
		return "waveform.circle.fill"

	default:
		return "questionmark.circle.fill"
		//return "questionmark.square.fill"
	}
}

struct MatrixEntry : Identifiable
{
	public let id = UUID()
	
	var positive: String
	var negative: String
	var num: Double
}

struct TrackView: View, Hashable
{
	static func == (lhs: TrackView, rhs: TrackView) -> Bool
	{
		lhs.track == rhs.track
	}

	
	var track : TrackMeta

	var scene: SKScene
	{
		let scene = GameScene()
		scene.size = CGSize(width: 400, height: TrackHeight)
		//scene.scaleMode = .fill
		scene.scaleMode = .resizeFill
		scene.PlotPositions(Times:track.SampleDecodeTimes)
		return scene
	}
	
	var TrackHeight = 40
	
	var body: some View
	{
		HStack
		{
			Label("Track \(track.Codec)", systemImage:GetIconForCodec(codec: track.Codec))
				//.font(.system(size: 24))
				.textSelection(.enabled)
				.frame(width: 120,alignment: .leading)	//	make sure label always visible
				//.background(.blue)
			
			//	resize scene to geometry
			GeometryReader
			{
				geometry in
				//let Height = geometry.size.height
				let Height = CGFloat(TrackHeight)
				//let Height = geometry.size.height/2
				let Width = geometry.size.width
				//scene.size = CGSize(width: Width, height:Height)
				SpriteView(scene: scene)
					.frame(width: Width, height:Height)
					.ignoresSafeArea()
			}
			/*
			//ForEach(track.SampleDecodeTimes, id: \.self)
			ForEach(0...100, id: \.self)
			{
				DecodeTimeMs in
				Label("", systemImage:"character")
			}
			 */
			

/*
			var data: [MatrixEntry] = [
				MatrixEntry(positive: "+", negative: "+", num: 200),
				MatrixEntry(positive: "+", negative: "-", num: 10),
				MatrixEntry(positive: "-", negative: "-", num: 80),
				MatrixEntry(positive: "-", negative: "+", num: 1)
			]
*/
		
		}
		.frame(height:CGFloat(TrackHeight))
	}
}
