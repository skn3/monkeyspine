'see license.txt for source licenses
Strict

Import spine
 
Class SpineAnimation
	Field Timelines:SpineTimeline[]
	Field Duration:float
	Field Name:String

	Method New(name:String, timelines:SpineTimeline[], duration:float)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		If timelines.Length() = 0 Throw New SpineArgumentNullException("timelines cannot be null.")
		Name = name
		Timelines = timelines
		Duration = duration
	End

	'Poses the skeleton at the specified time for this animation.
	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, events:List<SpineEvent>, loop:Bool)
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be null.")

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
	Method Mix:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, loop:bool, events:List<SpineEvent>, alpha:float)
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be null.")

		If loop And Duration <> 0
			time Mod= Duration
			lastTime Mod= Duration
		EndIf

		For Local i:= 0 Until Timelines.Length()
			Timelines[i].Apply(skeleton, lastTime, time, events, alpha)
		Next
	End
	
	Method Mix:Void(skeleton:SpineSkeleton, time:float, loop:bool, alpha:float)
		Mix(skeleton, MAX_FLOAT, time, loop, Null, alpha)
	End
	
	'@param target After the first and before the last entry.
	Private
	Function binarySearch:Int(values:float[], target:float)
		Local low:Int = 0
		Local high:Int = values.Length() -2
		If high = 0 Return 1
		Local current:Int = high shr 1
		While True
			If values[current + 1] <= target
				low = current + 1
			else
				high = current
			EndIf
			
			If low = high Return low + 1
			current = (low + high) Shr 1
		Wend
	End

	Function linearSearch:Int(values:float[], target:float, theStep:Int)
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
		curves = New float[ (frameCount - 1) * BEZIER_SIZE]
	End
	
	Public	
	Method FrameCount:Int()
		Return curves.Length() / BEZIER_SIZE + 1
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, events:List<SpineEvent>, alpha:float) Abstract

	Method SetLinear:Void(frameIndex:Int)
		curves[frameIndex * BEZIER_SIZE] = LINEAR
	End

	Method SetStepped:Void(frameIndex:Int)
		curves[frameIndex * BEZIER_SIZE] = STEPPED
	End

	'Sets the control handle positions for an interpolation bezier curve used to transition from this keyframe to the next.
 	'cx1 and cx2 are from 0 to 1, representing the percent of time between the two keyframes. cy1 and cy2 are the percent of
 	'the difference between the keyframe's values.
	Method SetCurve:Void(frameIndex:int, cx1:float, cy1:float, cx2:float, cy2:float)
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
		
		Local ddfx:Float = tmp1x * pre4 + tmp2x * pre5
		Local ddfy:Float = tmp1y * pre4 + tmp2y * pre5
		Local dddfx:Float = tmp2x * pre5
		Local dddfy:Float = tmp2y * pre5

		Local i:= frameIndex * BEZIER_SIZE
		Curves[i] = BEZIER
		i += 1

		Local x:= dfx
		Local y:= dfy
		
		Local n:= i + BEZIER_SIZE - 1
		For i = i - 1 Until n Step 2
			Curves[i] = x
			Curves[i + 1] = y
			dfx += ddfx
			dfy += ddfy
			ddfx += dddfx
			ddfy += dddfy
			x += dfx
			y += dfy
		Next
	End

	Method GetCurvePercent:float(frameIndex:Int, percent:float)
		Local i:= frameIndex * BEZIER_SIZE
		Local type:Float = Curves[i]
		
		If type = LINEAR Return percent
		If type = STEPPED Return 0
		
		i += 1
		Local x:Float
		Local start:= i
		Local n:= i + BEZIER_SIZE - 1
		For i = i Until n Step 2
			x = Curves[i]
			If x >= percent
				Local prevX:Float
				Local prevY:Float
				
				If i = start
					prevX = 0
					prevY = 0
				Else
					prevX = Curves[i - 2]
					prevY = Curves[i - 1]
				EndIf
				
				Return prevY + (Curves[i + 1] - prevY) * (percent - prevX) / (x - prevX)
			EndIf
		Next
		
		Local y:Float = Curves[i - 1]
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
		Frames = New float[frameCount * 2]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:float, angle:float)
		frameIndex *= 2
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = angle
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, alpha:Float, events:List<SpineEvent>)
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
			return
		EndIf
		
		'interpolate between the last frame and the current frame.
		Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 2)
		Local lastFrameValue:float = Frames[frameIndex - 1]
		Local frameTime:float = Frames[frameIndex]
		Local percent:float = 1 - (time - frameTime) / (Frames[frameIndex + LAST_FRAME_TIME] - frameTime)
		
		percent = GetCurvePercent(frameIndex / 2 - 1, Max(0.0, Min(1.0, percent)))
		
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
		Frames = New float[frameCount * 3]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:Float, x:float, y:float)
		frameIndex *= 3
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = x
		Frames[frameIndex + 2] = y
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, alpha:float, events:List<SpineEvent>)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]

		If time >= Frames[Frames.Length() - 3] ' Time is after last frame.
			bone.X += ( (bone.Data.X + Frames[Frames.Length() - 2] - bone.X) * alpha)
			bone.Y += ( (bone.Data.Y + Frames[Frames.Length() - 1] - bone.Y) * alpha)
			return
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
		Frames = New float[frameCount * 3]
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, alpha:Float, events:List<SpineEvent>)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]
		If time >= Frames[Frames.Length() - 3] ' Time is after last frame.
			bone.ScaleX += ( (bone.Data.ScaleX - 1 + Frames[Frames.Length() - 2] - bone.ScaleX) * alpha)
			bone.ScaleY += ( (bone.Data.ScaleY - 1 + Frames[Frames.Length() - 1] - bone.ScaleY) * alpha)
			return
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
		Frames = new float[frameCount * 5]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:Int, time:float, r:float, g:float, b:float, a:float)
		frameIndex *= 5
		Frames[frameIndex] = time
		Frames[frameIndex + 1] = r
		Frames[frameIndex + 2] = g
		Frames[frameIndex + 3] = b
		Frames[frameIndex + 4] = a
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, alpha:Float, events:List<SpineEvent>)
		If time < Frames[0] Return ' Time is before first frame.

		Local slot:SpineSlot = skeleton.Slots[SlotIndex]

		If time >= Frames[Frames.Length() - 5] ' Time is after last frame.
			Local i:Int = Frames.Length() - 1
			slot.R = Frames[i - 3]
			slot.G = Frames[i - 2]
			slot.B = Frames[i - 1]
			slot.A = Frames[i]
			return
		EndIf

		' Interpolate between the last frame and the current frame.
		Local frameIndex:Int = SpineAnimation.binarySearch(Frames, time, 5)
		Local lastFrameR:Float = Frames[frameIndex - 4]
		Local lastFrameG:Float = Frames[frameIndex - 3]
		Local lastFrameB:Float = Frames[frameIndex - 2]
		Local lastFrameA:Float = Frames[frameIndex - 1]
		Local frameTime:Float = Frames[frameIndex]
		Local percent:Float = 1 - (time - frameTime) / (Frames[frameIndex + LAST_FRAME_TIME] - frameTime)
		percent = GetCurvePercent(frameIndex / 5 - 1, Max(0.0, Min(1.0, percent)))

		Local r:float = lastFrameR + (Frames[frameIndex + FRAME_R] - lastFrameR) * percent
		Local g:float = lastFrameG + (Frames[frameIndex + FRAME_G] - lastFrameG) * percent
		Local b:float = lastFrameB + (Frames[frameIndex + FRAME_B] - lastFrameB) * percent
		Local a:float = lastFrameA + (Frames[frameIndex + FRAME_A] - lastFrameA) * percent
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
	
	Method FrameCount:Int()
		Return Frames.Length()
	End

	Method New(frameCount:Int)
		Frames = New float[frameCount]
		AttachmentNames = new String[frameCount]
	End

	'Sets the time and value of the specified keyframe.
	Method SetFrame:Void(frameIndex:int, time:float, attachmentName:String)
		Frames[frameIndex] = time
		AttachmentNames[frameIndex] = attachmentName
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:float, alpha:Float, events:List<SpineEvent>)
		If time < Frames[0] Return ' Time is before first frame.

		Local frameIndex:Int
		If time >= Frames[Frames.Length() - 1] ' Time is after last frame.
			frameIndex = Frames.Length() - 1
		else
			frameIndex = SpineAnimation.binarySearch(Frames, time, 1) - 1
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

	Method GetFrames:Float[]()
		Return Frames
	End

	Method GetEvents:SpineEvent[]()
		Return Events
	End

	Method SetFrame:Void(frameIndex:Int, time:Float, event:SpineEvent)
		'Sets the time of the specified keyframe
		Frames[frameIndex] = time
		Events[frameIndex] = event
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, alpha:Float, firedEvents:List<SpineEvent>)
		'we should only fire events that have happened in the space between lastTime and time
		'check for instant cancel
		If firedEvents = Null or Frames.Length() = 0 Return
		
		'check to see if the time (current) is before the first frame
		Local Frames:Float[] = Self.Frames
		If time < Frames[0] Return ' Time is before first frame.

		'check to see if the last checked time is after the last frame stored in the event timeline
		'this means the event would have already been fired
		Local frameCount:Int = Frames.Length()
		if lastTime >= Frames[frameCount - 1] Return ' Last time is after last frame.

		'simplified event checking... (strange...)
		For Local index:= 0 Until Frames.Length()
			If Frames[index] >= lastTime
				'check for past current time
				If Frames[index] > time Exit
				
				'add to fired events
				firedEvents.AddLast(Events[index])
			EndIf
		Next
		
		#rem
		'not sure why the spine runtime was coded this way, seems a bit of a waste...
		Local frameIndex:Int
		if frameCount = 1
			frameIndex = 0
		else
			frameIndex = SpineAnimation.binarySearch(Frames, lastTime, 1) - 1
			Local frame:Float = Frames[frameIndex]
			While frameIndex > 0 And frame = Frames[frameIndex - 1]
				frameIndex -= 1 ' Fire multiple Events with the same frame.
			Wend
		EndIf
		
		'add to fired events (hope this works?)
		While frameIndex < frameCount And time > Frames[frameIndex]
			firedEvents.AddLast(Events[frameIndex])
			frameIndex += 1
		Wend
		#end
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

	Method GetFrames:Float[]()
		Return Frames
	End

	Method GetDrawOrders:Int[][]()
		Return DrawOrders
	End

	Method SetFrame:Void(frameIndex:Int, time:Float, drawOrder:Int[])
		' Sets the time of the specified keyframe. 
		Frames[frameIndex] = time
		DrawOrders[frameIndex] = drawOrder
	End

	Method Apply:Void(skeleton:SpineSkeleton, lastTime:Float, time:Float, alpha:Float, events:List<SpineEvent>)
		If time < Frames[0] Return ' Time is before first frame.
		
		Local frameIndex:Int
		If time >= Frames[Frames.Length() - 1] ' Time is after last frame.
			frameIndex = Frames.Length() - 1
		else
			frameIndex = SpineAnimation.binarySearch(Frames, time, 1) - 1
		EndIf

		For Local index:= 0 Until DrawOrders[frameIndex].Length()
			skeleton.DrawOrder[index] = skeleton.Slots[DrawOrders[frameIndex][index]]
		Next
	End
End