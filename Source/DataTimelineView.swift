import SwiftUI
import SpriteKit


extension SKView {
	open override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		window?.acceptsMouseMovedEvents = true
	}
}


//	todo: replace anchorPoint with SKCameraNode
class GameScene: SKScene, ObservableObject
{
	//	temp vars whilst dragging for solid delta
	var dragStartScreenx : Int?
	var dragStartAnchorX : CGFloat?
	
	//	outgoing change, but really this should be a binding and we _detect_ changes
	@Published var ViewMinX : Int = 0
	@Published var ViewMaxX : Int = 0

	override init(size: CGSize)
	{
		//print("new scene size \(size.width)x\(size.height)")
		super.init(size:size)

		SetViewRangeMin(MinX: ViewMinX)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func didMove(to view: SKView)
	{
		//physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
		//	intialise view so we have a more 0,0 kinda initial setup (instead of 0.5,0.5)
		//anchorPoint.y = 0
	}
		
	override func mouseDown(with event: NSEvent)
	{
		let mousePosition = event.location(in: self)
		
		dragStartScreenx = Int(mousePosition.x)
		dragStartAnchorX = anchorPoint.x
		
		PlotPosition( Time:Int(mousePosition.x), Colour: .green, Width: 1 )
	}
	
	
	//	zoom with wheel
	override func scrollWheel(with event: NSEvent)
	{
		print(event)
	}
	
	//	hack for now, this should convert to snapping, but because of the way anchoring works, we need to re-set anchor every resize
	var AnchorToScrollScalar = 0.01
	
	func ScrollToAnchor(scroll:Int) -> CGFloat
	{
		return CGFloat( Double(scroll) * -(AnchorToScrollScalar))
	}
	
	func AnchorToScroll(anchor:CGFloat) -> Int
	{
		return Int( anchor * -(1.0/AnchorToScrollScalar) )
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
		//print("ScreenDeltax \(ScreenDeltax) AnchorDelta \(AnchorDelta)")
		var NewAnchor = dragStartAnchorX! + (AnchorDelta)
		var NewScroll = AnchorToScroll(anchor: NewAnchor)
		
		//	snap anchor to pixel
		NewAnchor = ScrollToAnchor(scroll:NewScroll)
		
		anchorPoint.x = NewAnchor
		//dragStartScreenx = Int(mousePosition.x)
		//dragStartAnchorX = anchorPoint.x
		ViewMinX = NewScroll
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
		//print("location \(location)")
		let box = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 4))
		box.position = location
		//box.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 4, height: 4))
		addChild(box)
		//print("mouseMoved GameScene has \(children.count) children")
	}
	
	func SetViewRangeMin(MinX:Int)
	{
		anchorPoint.x = ScrollToAnchor(scroll: MinX)
	}
	
	
	func PlotPosition(Time:Int,Colour:NSColor,Width:Int=3)
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
	
	func PlotPositions(Times:[Int],Colour:Color)
	{
		for time in Times
		{
			PlotPosition(Time:time,Colour:NSColor(Colour))
		}
	}

}


struct DataTimelineView<TrackLabel:View>: View
{
	let height:Int
	let initialPlotTimes : [Int]
	let backgroundColour : Color
	
	//	scroll is external to allow the variable to be synchronised
	@Binding var ViewMinTime:Int
	@Binding var ViewMaxTime:Int
	
	//	has to be last
	let label: () -> TrackLabel

	@StateObject private var scene: GameScene = {
			let scene = GameScene( size:CGSize(width:99,height:99) )
			//scene.size = CGSize(width: 300, height: height)
			scene.scaleMode = .resizeFill
			return scene
		}()

	var body: some View
	{
		HStack
		{
			label()

			//	resize scene to geometry
			GeometryReader
			{
				geometry in
				//let Height = geometry.size.height
				let Height = CGFloat(height)
				//let Height = geometry.size.height/2
				let Width = geometry.size.width
				//scene.size = CGSize(width: Width, height:Height)
				SpriteView(scene: scene, debugOptions: [/*.showsFPS, .showsNodeCount, .showsPhysics*/] )
					.frame(width: Width, height:Height)
					.ignoresSafeArea()
					.onAppear()
					{
						scene.backgroundColor = NSColor(backgroundColour)
						scene.PlotPositions(Times: initialPlotTimes, Colour: Color("TimelinePresentationTime"))
					}
					.onChange(of: ViewMinTime)
					{
						value in
						//print("ScrollX changed from above value=\(value) ScrollX=\(ScrollX)")
						//	gr: can the scene handle this automatically?
						scene.SetViewRangeMin(MinX: value)
					}
					.onChange(of: scene.ViewMinX)
					{
						value in
						//print("scene changed")
						ViewMinTime = value
					}
					.onChange(of: scene.ViewMaxX)
					{
						value in
						//print("scene changed")
						ViewMaxTime = value
					}
			}
		}
		.frame(height:CGFloat(height))
		
	}
}
