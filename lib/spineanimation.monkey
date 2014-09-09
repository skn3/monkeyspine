'see license.txt for source licenses
Strict

Import spine
 
Class SpineAnimation
	Field Timelines:SpineTimeline[]
	Field Duration:Float
	Field Name:String

	Method New(name:String, timelines:SpineTimeline[], duration:Float)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		If timelines.Length() = 0 Throw New SpineArgumentNullException("timelines cannot be Null.")
		Name = name
		Timelines = timelines
		Duration = duration
	End

	'Poses the skeleton at the specified time for this animation.
	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, loop:Bool)
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be Null.")

		'apply looped animation
		'this will convert the entire timeline into a single loop
		If loop And Duration <> 0
			time = time Mod Duration
			lastTime = lastTime Mod Duration
		EndIf
		
		'iterate over all timelines attached to animation
		For Local i:= 0 Until Timelines.Length()
			Timelines[i].Apply(skeleton, lastTime, time, events, 1.0)
		Next
	End

	'Poses the skeleton at the specified time for this animation mixed with the current pose.
	'@param alpha The amount of this animation that affects the current pose.
	Method Mix:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, loop:Bool, events:List<SpineEvent>, alpha:Float)
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be Null.")

		If loop And Duration <> 0
			time Mod= Duration
			lastTime Mod= Duration
		EndIf

		For Local i:= 0 Until Timelines.Length()
			Timelines[i].Apply(skeleton, lastTime, time, events, alpha)
		Next
	End
	
	Method Mix:Void(skeleton:SpineSkeleton, time:Float, loop:Bool, alpha:Float)
		Mix(skeleton, SPINE_MAX_FLOAT, time, loop, Null, alpha)
	End
	
	'@param target After the first and before the last entry.
	Private
	Function binarySearch:Int(values:Float[], target:Float, theStep:Int)
		Local low:Int = 0
		Local high:Int = values.Length() / theStep - 2
		If high = 0 Return theStep
		Local current:Int = high shr 1
		While True
			If values[ (current + 1) * theStep] <= target
				low = current + 1
			Else
				high = current
			EndIf
			
			If low = high Return (low + 1) * theStep
			current = (low + high) Shr 1
		Wend
	End
	
	Function binarySearch:Int(values:Float[], target:Float)
		Local low:Int = 0
		Local high:Int = values.Length() -2
		If high = 0 Return 1
		Local current:Int = high shr 1
		While True
			If values[current + 1] <= target
				low = current + 1
			Else
				high = current
			EndIf
			
			If low = high Return low + 1
			current = (low + high) Shr 1
		Wend
	End

	Function linearSearch:Int(values:Float[], target:Float, theStep:Int)
		Local i:= 0
		Local last:= values.Length() - theStep
		While i <= last
			If values[i] > target Return i
			i += theStep
		Wend
		Return -1
	End
End

Interface SpineTimeline
	'Sets the value(s) for the specified time.
	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
	Method FrameCount:Int()
End

'Base class for frames that use an interpolation bezier curve.
Class SpineCurveTimeline Implements SpineTimeline Abstract
	Const LINEAR:= 0.0
	Const STEPPED:= 1.0
	Const BEZIER:= 2.0
	
	Const BEZIER_SEGMENTS:= 10
	Const BEZIER_SIZE:= BEZIER_SEGMENTS * 2 - 1

	Private
	Field curves:Float[0] 'dfx, dfy, ddfx, ddfy, dddfx, dddfy, ...
	
	Method New(frameCount:Int = 0)
		curves = New Float[ (frameCount - 1) * BEZIER_SIZE]
	End
	
	Public	
	Method FrameCount:Int()
		Return curves.Length() / BEZIER_SIZE + 1
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float) Abstract

	Method SetLinear:Void(frameIndex:Int)
		curves[frameIndex * BEZIER_SIZE] = LINEAR
	End

	Method SetStepped:Void(frameIndex:Int)
		curves[frameIndex * BEZIER_SIZE] = STEPPED
	End

	'Sets the control handle positions for an interpolation bezier curve used to transition from this keyframe to the next.
 	'cx1 and cx2 are from 0 to 1, representing the percent of time between the two keyframes. cy1 and cy2 are the percent of
 	'the difference between the keyframe's values.
	Method SetCurve:Void(frameIndex:Int, cx1:Float, cy1:Float, cx2:Float, cy2:Float)
		Local subdiv1:Float = 1.0 / BEZIER_SEGMENTS
		Local subdiv2:Float = subdiv1 * subdiv1
		Local subdiv3:Float = subdiv2 * subdiv1
		Local pre1:Float = 3 * subdiv1
		Local pre2:Float = 3 * subdiv2
		Local pre4:Float = 6 * subdiv2
		Local pre5:Float = 6 * subdiv3
		Local tmp1x:Float = -cx1 * 2 + cx2
		Local tmp1y:Float = -cy1 * 2 + cy2
		Local tmp2x:Float = (cx1 - cx2) * 3 + 1
		Local tmp2y:Float = (cy1 - cy2) * 3 + 1
		Local dfx:Float = cx1 * pre1 + tmp1x * pre2 + tmp2x * subdiv3
		Local dfy:Float = cy1 * pre1 + tmp1y * pre2 + tmp2y * subdiv3
		Local ddfx:Float = tmp1x * pre4 + tmp2x * pre5
		Local ddfy:Float = tmp1y * pre4 + tmp2y * pre5
		Local dddfx:Float = tmp2x * pre5
		Local dddfy:Float = tmp2y * pre5

		Local i:= frameIndex * BEZIER_SIZE
		curves[i] = BEZIER
		i += 1

		Local x:= dfx
		Local y:= dfy
		
		Local n:= i + BEZIER_SIZE - 1
		For i = i - 1 Until n Step 2
			curves[i] = x
			curves[i + 1] = y
			dfx += ddfx
			dfy += ddfy
			ddfx += dddfx
			ddfy += dddfy
			x += dfx
			y += dfy
		Next
	End

	Method GetCurvePercent:Float(frameIndex:Int, percent:Float)
		Local i:= frameIndex * BEZIER_SIZE
		Local type:Float = curves[i]
		
		If type = LINEAR Return percent
		If type = STEPPED Return 0
		
		i += 1
		Local x:Float
		Local start:= i
		Local n:= i + BEZIER_SIZE - 1
		For i = i Until n Step 2
			x = curves[i]
			If x >= percent
				Local prevX:Float
				Local prevY:Float
				
				If i = start
					prevX = 0
					prevY = 0
				Else
					prevX = curves[i - 2]
					prevY = curves[i - 1]
				EndIf
				
				Return prevY + (curves[i + 1] - prevY) * (percent - prevX) / (x - prevX)
			EndIf
		Next
		
		Local y:Float = curves[i - 1]
		Return y + (1 - y) * (percent - x) / (1 - x)'Last point is 1, 1.
	End
End

Class SpineRotateTimeline Extends SpineCurveTimeline
	Const LAST_FRAME_TIME:= -2
	Const FRAME_VALUE:= 1

	Field BoneIndex:Int
	Field Frames:Float[]

	Method New(frameCount:Int)
		Super.New(frameCount)
		Frames = New Float[frameCount * 2]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:Float, angle:Float)
		frameIndex *= 2
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = angle
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]
		Local amount:Float

		'check if time is after last frame.
		If time >= Frames[Frames.Length() - 2]
			amount = bone.Data.Rotation + Frames[Frames.Length() - 1] - bone.Rotation
			While amount > 180
				amount -= 360
			Wend
			While amount < - 180
				amount += 360
			Wend
			bone.Rotation += (amount * alpha)
			Return
		EndIf
		
		'interpolate between the last frame and the current frame.
		Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 2)
		Local lastFrameValue:Float = Frames[frameIndex - 1]
		Local frameTime:Float = Frames[frameIndex]
		Local percent:Float = 1 - (time - frameTime) / (Frames[frameIndex + LAST_FRAME_TIME] - frameTime)
		
		percent = GetCurvePercent( (frameIndex Shr 1) - 1, Max(0.0, Min(1.0, percent)))
		
		amount = Frames[frameIndex + FRAME_VALUE] - lastFrameValue
		While amount > 180
			amount -= 360
		Wend
		While amount < - 180
			amount += 360
		Wend
		amount = bone.Data.Rotation + (lastFrameValue + amount * percent) - bone.Rotation
		While amount > 180
			amount -= 360
		Wend
		While amount < - 180
			amount += 360
		Wend
		
		bone.Rotation += (amount * alpha)
	End
End

Class SpineTranslateTimeline Extends SpineCurveTimeline
	Const LAST_FRAME_TIME:= -3
	Const FRAME_X:= 1
	Const FRAME_Y:= 2

	Field BoneIndex:Int
	Field Frames:Float[]

	Method New(frameCount:Int)
		Super.New(frameCount)
		Frames = New Float[frameCount * 3]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:Float, x:Float, y:Float)
		frameIndex *= 3
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = x
		Frames[frameIndex + 2] = y
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]

		If time >= Frames[Frames.Length() - 3] ' Time is after last frame.
			bone.X += ( (bone.Data.X + Frames[Frames.Length() - 2] - bone.X) * alpha)
			bone.Y += ( (bone.Data.Y + Frames[Frames.Length() - 1] - bone.Y) * alpha)
			Return
		EndIf

		' Interpolate between the last frame and the current frame.
		Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 3)
		Local lastFrameX:Float = Frames[frameIndex - 2]
		Local lastFrameY:Float = Frames[frameIndex - 1]
		Local frameTime:Float = Frames[frameIndex]
		Local percent:Float = 1 - (time - frameTime) / (Frames[frameIndex + LAST_FRAME_TIME] - frameTime)
		percent = GetCurvePercent(frameIndex / 3 - 1, Max(0.0, Min(1.0, percent)))

		bone.X += ( (bone.Data.X + lastFrameX + (Frames[frameIndex + FRAME_X] - lastFrameX) * percent - bone.X) * alpha)
		bone.Y += ( (bone.Data.Y + lastFrameY + (Frames[frameIndex + FRAME_Y] - lastFrameY) * percent - bone.Y) * alpha)
	End
End

Class SpineScaleTimeline Extends SpineTranslateTimeline
	Method New(frameCount:Int)
		Super.New(frameCount)
		Frames = New Float[frameCount * 3]
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]
		If time >= Frames[Frames.Length() - 3] ' Time is after last frame.
			bone.ScaleX += ( (bone.Data.ScaleX - 1 + Frames[Frames.Length() - 2] - bone.ScaleX) * alpha)
			bone.ScaleY += ( (bone.Data.ScaleY - 1 + Frames[Frames.Length() - 1] - bone.ScaleY) * alpha)
			Return
		EndIf

		' Interpolate between the last frame and the current frame.
		Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 3)
		Local lastFrameX:Float = Frames[frameIndex - 2]
		Local lastFrameY:Float = Frames[frameIndex - 1]
		Local frameTime:Float = Frames[frameIndex]
		Local percent:Float = 1 - (time - frameTime) / (Frames[frameIndex + LAST_FRAME_TIME] - frameTime)
		percent = GetCurvePercent(frameIndex / 3 - 1, Max(0.0, Min(1.0, percent)))

		bone.ScaleX += ( (bone.Data.ScaleX - 1 + lastFrameX + (Frames[frameIndex + FRAME_X] - lastFrameX) * percent - bone.ScaleX) * alpha)
		bone.ScaleY += ( (bone.Data.ScaleY - 1 + lastFrameY + (Frames[frameIndex + FRAME_Y] - lastFrameY) * percent - bone.ScaleY) * alpha)
	End
End

Class SpineColorTimeline Extends SpineCurveTimeline
	Const LAST_FRAME_TIME:= -5
	Const FRAME_R:= 1
	Const FRAME_G:= 2
	Const FRAME_B:= 3
	Const FRAME_A:= 4

	Field SlotIndex:Int
	Field Frames:Float[]

	Method New(frameCount:Int)
		Super.New(frameCount)
		Frames = new Float[frameCount * 5]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:Float, r:Float, g:Float, b:Float, a:Float)
		frameIndex *= 5
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = r
		Frames[frameIndex + 2] = g
		Frames[frameIndex + 3] = b
		Frames[frameIndex + 4] = a
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local r:Float
		Local g:Float
		Local b:Float
		Local a:Float
		
		If time >= Frames[Frames.Length() - 5] ' Time is after last frame.
			Local i:Int = Frames.Length() - 1
			r = Frames[i - 3]
			g = Frames[i - 2]
			b = Frames[i - 1]
			a = Frames[i]
		Else
			' Interpolate between the last frame and the current frame.
			Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 5)
			Local lastFrameR:Float = Frames[frameIndex - 4]
			Local lastFrameG:Float = Frames[frameIndex - 3]
			Local lastFrameB:Float = Frames[frameIndex - 2]
			Local lastFrameA:Float = Frames[frameIndex - 1]
			Local frameTime:Float = Frames[frameIndex]
			Local percent:Float = 1 - (time - frameTime) / (Frames[frameIndex + LAST_FRAME_TIME] - frameTime)
			percent = GetCurvePercent(frameIndex / 5 - 1, Max(0.0, Min(1.0, percent)))

			r = lastFrameR + (Frames[frameIndex + FRAME_R] - lastFrameR) * percent
			g = lastFrameG + (Frames[frameIndex + FRAME_G] - lastFrameG) * percent
			b = lastFrameB + (Frames[frameIndex + FRAME_B] - lastFrameB) * percent
			a = lastFrameA + (Frames[frameIndex + FRAME_A] - lastFrameA) * percent
		EndIf

		Local slot:= skeleton.Slots[SlotIndex]
		If alpha < 1
			slot.R += (r - slot.R) * alpha
			slot.G += (g - slot.G) * alpha
			slot.B += (b - slot.B) * alpha
			slot.A += (a - slot.A) * alpha
		Else
			slot.R = r
			slot.G = g
			slot.B = b
			slot.A = a
		EndIf
	End
End

Class SpineAttachmentTimeline Implements SpineTimeline
	Field SlotIndex:Int
	Field Frames:Float[]
	Field AttachmentNames:String[]

	Method New(frameCount:Int)
		Frames = New Float[frameCount]
		AttachmentNames = new String[frameCount]
	End
		
	Method FrameCount:Int()
		Return Frames.Length()
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:Float, attachmentName:String)
		Frames[frameIndex] = time
		AttachmentNames[frameIndex] = attachmentName
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
		If time < Frames[0]
			'If (lastTime > time) Apply(skeleton, lastTime, Int.MaxValue, Null, 0)
			'Return
			time = SPINE_MAX_FLOAT
			events = Null
			alpha = 0.0
		ElseIf lastTime > time
			lastTime = -1
		EndIf
		
		Local frameIndex:Int
		If time >= Frames[Frames.Length() - 1] ' Time is after last frame.
			frameIndex = Frames.Length() - 1
		Else
			frameIndex = SpineAnimation.binarySearch(Frames, time) - 1
		EndIf
		
		If Frames[frameIndex] <= lastTime
			Return
		EndIf

		Local attachmentName:String = AttachmentNames[frameIndex]
		If attachmentName.Length() = 0
			skeleton.Slots[SlotIndex].Attachment = Null
		Else
			skeleton.Slots[SlotIndex].Attachment = skeleton.GetAttachment(SlotIndex, attachmentName)
		EndIf
		
	End
End

Class SpineEventTimeline Implements SpineTimeline
	Field Frames:Float[] ' time, ...
	Field Events:SpineEvent[]

	Method New(frameCount:Int)
		Frames = new Float[frameCount]
		Events = new SpineEvent[frameCount]
	End

	Method FrameCount:Int()
		Return Frames.Length()
	End

	Method SetFrame:Void(frameIndex:Int, time:Float, event:SpineEvent)
		'Sets the time of the specified keyframe
		Frames[frameIndex] = time
		Events[frameIndex] = event
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, firedEvents:List<SpineEvent>, alpha:Float)
		'we should only fire events that have happened in the space between lastTime and time
		If firedEvents = Null Return
		Local frameCount:Int = Frames.Length()

		If lastTime > time 'Fire events after last time for looped animations.
			Apply(skeleton, lastTime, SPINE_MAX_FLOAT, firedEvents, alpha)
			lastTime = -1.0
		ElseIf lastTime >= Frames[frameCount - 1] 'Last time is after last frame.
			Return
		EndIf

		if time < Frames[0] Return 'Time is before first frame.

		Local frameIndex:Int
		if lastTime < Frames[0]
			frameIndex = 0
		Else
			frameIndex = SpineAnimation.binarySearch(Frames, lastTime)
			Local frame:Float = Frames[frameIndex]
			while frameIndex > 0 'Fire multiple events with the same frame.
				If Frames[frameIndex - 1] <> frame Exit
				frameIndex -= 1
			Wend
		EndIf

		While frameIndex < frameCount and time >= Frames[frameIndex]
			firedEvents.AddLast(Events[frameIndex])
			frameIndex += 1
		Wend
	End
End

Class SpineDrawOrderTimeline Implements SpineTimeline
	Field Frames:Float[] ' time, ...
	Field DrawOrders:Int[][]

	Method New(frameCount:Int)
		Frames = new Float[frameCount]
		DrawOrders = new Int[frameCount][]
	End

	Method FrameCount:Int()
		Return Frames.Length()
	End

	Method SetFrame:Void(frameIndex:Int, time:Float, drawOrder:Int[])
		' Sets the time of the specified keyframe. 
		Frames[frameIndex] = time
		DrawOrders[frameIndex] = drawOrder
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, events:List<SpineEvent>, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.
		
		Local frameIndex:Int
		If time >= Frames[Frames.Length() - 1] ' Time is after last frame.
			frameIndex = Frames.Length() - 1
		Else
			frameIndex = SpineAnimation.binarySearch(Frames, time) - 1
		EndIf

		Local drawOrder:= skeleton.DrawOrder
		Local slots:= skeleton.Slots
		
		Local drawOrderToSetupIndex:= DrawOrders[frameIndex]
		If drawOrderToSetupIndex.Length() = 0
			For Local i:= 0 Until drawOrder.Length()
				drawOrder[i] = slots[i]
			Next
		Else
			Local n:= drawOrderToSetupIndex.Length()
			For Local i:= 0 Until n
				drawOrder[i] = slots[drawOrderToSetupIndex[i]]
			Next
		EndIf
	End
End

Class SpineFFDTimeline Extends SpineCurveTimeline
	Field SlotIndex:Int
	Field Frames:Float[]
	Field FrameVertices:Float[][]
	Field Attachment:SpineAttachment

	Method New(frameCount:Int)
		Super.New(frameCount)
		Frames = new Float[frameCount]
		FrameVertices = new Float[frameCount][]
	End

	'Sets the time and value of the specified keyframe
	Method SetFrame:Void(frameIndex:Int, time:Float, vertices:Float[])
		Frames[frameIndex] = time
		FrameVertices[frameIndex] = vertices
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, firedEvents:List<SpineEvent>, alpha:Float)
		Local slot := skeleton.Slots[SlotIndex]
		if slot.Attachment <> Attachment Return

		if time < Frames[0]
			slot.AttachmentVerticesCount = 0
			Return ' Time is before first frame.
		EndIf

		Local vertexCount := FrameVertices[0].Length()

		Local vertices := slot.AttachmentVertices
		if vertices.Length() <> vertexCount alpha = 1.0
		if vertices.Length() < vertexCount
			vertices = new Float[vertexCount]
			slot.AttachmentVertices = vertices
		EndIf
		slot.AttachmentVerticesCount = vertexCount

		if time >= Frames[Frames.Length() - 1] ' Time is after last frame.
			Local lastVertices := FrameVertices[Frames.Length() - 1]
			if alpha < 1.0
				For Local i:= 0 Until vertexCount
					vertices[i] += ( (lastVertices[i] - vertices[i]) * alpha)
				Next
			Else
				'Array.Copy(lastVertices, 0, vertices, 0, vertexCount)
				For Local i:= 0 Until vertexCount
					vertices[i] = lastVertices[i]
				Next
			EndIf
			Return
		EndIf

		' Interpolate between the previous frame and the current frame.
		Local frameIndex:= SpineAnimation.binarySearch(Frames, time)
		Local frameTime := Frames[frameIndex]
		Local percent:Float = 1.0 - (time - frameTime) / (Frames[frameIndex - 1] - frameTime)
		percent = GetCurvePercent(frameIndex - 1, Max(0.0, Min(1.0, percent)))

		Local prevVertices := FrameVertices[frameIndex - 1]
		Local nextVertices := FrameVertices[frameIndex]

		If alpha < 1.0
			for Local i := 0 until vertexCount
				Local prev := prevVertices[i]
				vertices[i] += (prev + (nextVertices[i] - prev) * percent - vertices[i]) * alpha
			Next
		Else
			for Local i := 0 until vertexCount
				Local prev := prevVertices[i]
				vertices[i] = prev + (nextVertices[i] - prev) * percent
			Next
		EndIf
	End
End

Class SpineIkConstraintTimeline Extends SpineCurveTimeline
	Private
	const PREV_FRAME_TIME := -3
	const FRAME_MIX := 1
	const FRAME_BEND_DIRECTION := 2
	Public

	Field IkConstraintIndex:Int
	Field Frames:Float[]

	Method New(frameCount:Int)
		Super.New(frameCount)
		Frames = new Float[frameCount * 3]
	End

	'Sets the time, mix and bend direction of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:Float, mix:Float, bendDirection:Int)
		frameIndex *= 3
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = mix
		Frames[frameIndex + 2] = bendDirection
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, firedEvents:List<SpineEvent>, alpha:Float)
		if time < Frames[0] Return ' Time is before first frame.

		Local ikConstraint:SpineIkConstraint = skeleton.IkConstraints[IkConstraintIndex]

		if time >= Frames[Frames.Length() - 3]' Time is after last frame.
			ikConstraint.Mix += (Frames[Frames.Length() -2] - ikConstraint.Mix) * alpha
			ikConstraint.BendDirection = Frames[Frames.Length() -1]
			Return
		EndIf

		' Interpolate between the previous frame and the current frame.
		Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 3)
		Local prevFrameMix:Float = Frames[frameIndex - 2]
		Local frameTime:Float = Frames[frameIndex]
		Local percent:Float = 1 - (time - frameTime) / (Frames[frameIndex + PREV_FRAME_TIME] - frameTime)
		percent = GetCurvePercent(frameIndex / 3 - 1, Max(0.0, Min(1.0, percent)))

		Local mix:= prevFrameMix + (Frames[frameIndex + FRAME_MIX] - prevFrameMix) * percent
		ikConstraint.Mix += (mix - ikConstraint.Mix) * alpha
		ikConstraint.BendDirection = Frames[frameIndex + FRAME_BEND_DIRECTION]
	End
End