import SwiftUI



struct Triangle: Shape {
	func path(in rect: CGRect) -> Path {
		Path { path in
			let TopY = rect.minY
			let BotY = rect.maxY
			path.move(to: CGPoint(x: rect.midX, y: BotY))
			path.addLine(to: CGPoint(x: rect.maxX, y: TopY))
			path.addLine(to: CGPoint(x: rect.minX, y: TopY))
			path.addLine(to: CGPoint(x: rect.midX, y: BotY))
		}
	}
}

func clamp(_ value:Int,Min:Int,Max:Int) -> Int
{
	let clamped = min(max(value, Min), Max)
	return clamped
}


extension Color 
{
	func brighten(_ Multiplier: Float) -> Color
	{
		let rgb = NSColor(self).cgColor.components
		let r = rgb![0] * CGFloat(Multiplier)
		let g = rgb![1] * CGFloat(Multiplier)
		let b = rgb![2] * CGFloat(Multiplier)
		return Color( red:r, green:g, blue:b )
		/*
		//	todo: proper HSL conversion
		UIColor(Color.blue).cgColor.components)
		let r = components * Multiplier
		return Color.yellow
		 */
	}
}
	
	
	

//	taken from https://stackoverflow.com/a/72774150/355753
struct RangeSlider: View {
	@ObservedObject var viewModel: ViewModel
	@State private var isActive: Bool = false
	//	we copy the values when we start dragging
	//	@state private to be able to use tis in Preview
	@State private var DraggedLineStartPosition : ClosedRange<Int>? = nil
	let sliderPositionChanged: (ClosedRange<Int>) -> Void
	var activeColour = Color.green
	var inactiveColour = Color.red
	var rangeSliderThumbSize = 10.0
	var trackedLineHeightPercent : CGFloat = 1.0
	var untrackedLineHeightPercent : CGFloat = 0.3

	var activeThumbColour : Color
	{
		return activeColour.brighten(1.7)
	}
	var inactiveThumbColour : Color
	{
		return inactiveColour.brighten(1.7)
	}

	
	var body: some View {
		GeometryReader { geometry in
			sliderView(sliderSize: geometry.size,
					   sliderViewYCenter: geometry.size.height / 2)
		}
		//.frame(height: ** insert your height of range slider **)
		.frame(height: 10)
	}

	
	func OnDraggedLineEnded(_ dragValue:DragGesture.Value,sliderGeometrySize: CGSize)
	{
		DraggedLineStartPosition = nil
		isActive = false
	}
	
	func OnDraggedLine(_ dragValue:DragGesture.Value,sliderGeometrySize: CGSize)
	{
		//	start of drag
		if ( DraggedLineStartPosition == nil )
		{
			DraggedLineStartPosition = viewModel.sliderPosition
		}
		
		var DeltaPx = dragValue.location.x - dragValue.startLocation.x
		var StepPx = viewModel.stepWidthInPixel(width: sliderGeometrySize.width)
		var StepDelta = Int(DeltaPx / StepPx)
	
		let Min = viewModel.sliderBounds.lowerBound
		let Max = viewModel.sliderBounds.upperBound
		var Left = DraggedLineStartPosition!.lowerBound + StepDelta
		var Right = DraggedLineStartPosition!.upperBound + StepDelta
		
		//	retain the width we had when we started dragging
		let Width = DraggedLineStartPosition!.upperBound - DraggedLineStartPosition!.lowerBound

		//	clamp and push out from edge
		Right = clamp( Right, Min:Min, Max:Max )
		Left = clamp( Left, Min:Min, Max:Max )
		if ( Right - Left < Width )
		{
			Right = Left + Width
		}
		Right = clamp( Right, Min:Min, Max:Max )
		if ( Right - Left < Width )
		{
			Left = Right - Width
		}

		viewModel.sliderPosition = Left...Right
		sliderPositionChanged(viewModel.sliderPosition)
		isActive = true
	}
	
	@ViewBuilder private func sliderView(sliderSize: CGSize, sliderViewYCenter: CGFloat) -> some View {
		lineBetweenThumbs(from: viewModel.leftThumbLocation(width: sliderSize.width,sliderViewYCenter: sliderViewYCenter),
						  to: viewModel.rightThumbLocation(width: sliderSize.width,sliderViewYCenter: sliderViewYCenter),
						  trackedLineHeight:sliderSize.height*trackedLineHeightPercent,
						  untrackedLineHeight:sliderSize.height*untrackedLineHeightPercent
		)
		.highPriorityGesture( DragGesture(minimumDistance: 0)
			.onChanged { dragValue in
				OnDraggedLine(dragValue,sliderGeometrySize: sliderSize)
			}
			.onEnded { dragValue in
				OnDraggedLineEnded(dragValue,sliderGeometrySize: sliderSize)
			}
			)
			

		thumbView(position: viewModel.leftThumbLocation(width: sliderSize.width,
														sliderViewYCenter: sliderViewYCenter),
				  value: Float(viewModel.sliderPosition.lowerBound))
		.highPriorityGesture(DragGesture().onChanged { dragValue in
			let newValue = Int(viewModel.newThumbLocation(dragLocation: dragValue.location,
													  width: sliderSize.width))
			
			if newValue < viewModel.sliderPosition.upperBound {
				viewModel.sliderPosition = newValue...viewModel.sliderPosition.upperBound
				sliderPositionChanged(viewModel.sliderPosition)
				isActive = true
			}
		})

		thumbView(position: viewModel.rightThumbLocation(width: sliderSize.width,
														 sliderViewYCenter: sliderViewYCenter),
				  value: Float(viewModel.sliderPosition.upperBound))
		.highPriorityGesture(DragGesture().onChanged { dragValue in
			let newValue = Int(viewModel.newThumbLocation(dragLocation: dragValue.location,
													  width: sliderSize.width))
			
			if newValue > viewModel.sliderPosition.lowerBound {
				viewModel.sliderPosition = viewModel.sliderPosition.lowerBound...newValue
				sliderPositionChanged(viewModel.sliderPosition)
				isActive = true
			}
		})
	}

	@ViewBuilder func lineBetweenThumbs(from: CGPoint, to: CGPoint,trackedLineHeight:CGFloat,untrackedLineHeight:CGFloat) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: 4)
				.frame(height: untrackedLineHeight)

			Path { path in
				path.move(to: from)
				path.addLine(to: to)
			}
			.stroke(isActive ? activeColour : inactiveColour,
					lineWidth: trackedLineHeight)
		}.animation(.spring(), value: isActive)
	}

	@ViewBuilder func thumbView(position: CGPoint, value: Float) -> some View {
		Triangle()
			.frame(width: rangeSliderThumbSize,height: rangeSliderThumbSize)
		.foregroundColor(isActive ? activeThumbColour : inactiveThumbColour )
		.contentShape(Rectangle())
		.position(x: position.x, y: position.y)
		.animation(.spring(), value: isActive)
	}
}

extension RangeSlider {
	final class ViewModel: ObservableObject {
		@Published var sliderPosition: ClosedRange<Int>
		let sliderBounds: ClosedRange<Int>
		var sliderMinDifference = 0

		let sliderBoundDifference: Int

		init(sliderPosition: ClosedRange<Int>,
			 sliderBounds: ClosedRange<Int>,
			 sliderMinDifference:Int=0)
		{
			self.sliderPosition = sliderPosition
			self.sliderBounds = sliderBounds
			self.sliderBoundDifference = sliderBounds.count - 1
			self.sliderMinDifference = sliderMinDifference
		}

		func leftThumbLocation(width: CGFloat, sliderViewYCenter: CGFloat = 0) -> CGPoint {
			let sliderLeftPosition = CGFloat(sliderPosition.lowerBound - sliderBounds.lowerBound)
			return .init(x: sliderLeftPosition * stepWidthInPixel(width: width),
						 y: sliderViewYCenter)
		}

		func rightThumbLocation(width: CGFloat, sliderViewYCenter: CGFloat = 0) -> CGPoint {
			let sliderRightPosition = CGFloat(sliderPosition.upperBound - sliderBounds.lowerBound)
			
			return .init(x: sliderRightPosition * stepWidthInPixel(width: width),
						 y: sliderViewYCenter)
		}

		func newThumbLocation(dragLocation: CGPoint, width: CGFloat) -> Float {
			let xThumbOffset = min(max(0, dragLocation.x), width)
			return Float(sliderBounds.lowerBound) + Float(xThumbOffset / stepWidthInPixel(width: width))
		}

		func stepWidthInPixel(width: CGFloat) -> CGFloat {
			width / CGFloat(sliderBoundDifference)
		}
	}
}

struct RangeSlider_Previews: PreviewProvider {
	static var previews: some View 
	{
		VStack
		{
			Spacer().frame(height: 30)
			RangeSlider(viewModel: .init(sliderPosition: 5...40,
										 sliderBounds: 1...50,
										 sliderMinDifference: 10
										),
						sliderPositionChanged: { _ in },
						activeColour:Color.green,
						inactiveColour:Color.red
						)
			.frame(width: 200)

			Spacer().frame(height: 30)
		}
	}
}
