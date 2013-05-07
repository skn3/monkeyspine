'see license.txt for source licenses
Strict

Import spine
 
Class SpineAnimation
	Field Name:String
	Field Timelines:SpineTimeline[]
	Field Duration:float

	Method New(name:String, timelines:SpineTimeline[], duration:float)
		If name.Length = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		If timelines.Length = 0 Throw New SpineArgumentNullException("timelines cannot be null.")
		Name = name
		Timelines = timelines
		Duration = duration
	End

	'Poses the skeleton at the specified time for this animation.
	Method Apply:Void(skeleton:SpineSkeleton, time:Float, loop:Bool)
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be null.")

		If loop And Duration <> 0 time Mod= Duration

		For Local i:= 0 Until Timelines.Length
			Timelines[i].Apply(skeleton, time, 1)
		Next
	End

	'Poses the skeleton at the specified time for this animation mixed with the current pose.
	'@param alpha The amount of this animation that affects the current pose.
	Method Mix:Void(skeleton:SpineSkeleton, time:float, loop:bool, alpha:float)
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be null.")

		If loop And Duration <> 0 time Mod= Duration

		For Local i:= 0 Until Timelines.Length
			Timelines[i].Apply(skeleton, time, alpha)
		Next
	End

	'@param target After the first and before the last entry.
	Private
	Function binarySearch:Int(values:float[], target:float, theStep:int)
		Local low:Int = 0
		Local high:Int = values.Length / theStep - 2
		
		If high = 0 Return theStep
		Local current:Int = high shr 1
		While True
			If values[ (current + 1) * theStep] <= target
				low = current + 1
			else
				high = current
			EndIf
			
			If low = high Return (low + 1) * theStep
			current = (low + high) Shr 1
		Wend
	End

	Function linearSearch:Int(values:float[], target:float, theStep:Int)
		Local i:= 0
		Local last:= values.Length - theStep
		While i <= last
			If values[i] > target Return i
			i += theStep
		Wend
	End
End

Interface SpineTimeline
	'Sets the value(s) for the specified time.
	Method Apply:Void(skeleton:SpineSkeleton, time:Float, alpha:Float)
	Method FrameCount:Int()
End

'Base class for frames that use an interpolation bezier curve.
Class SpineCurveTimeline Implements SpineTimeline Abstract
	Const LINEAR:= 0.0
	Const STEPPED:= -1.0
	Const BEZIER_SEGMENTS:= 10

	Private
	Field curves:Float[0] 'dfx, dfy, ddfx, ddfy, dddfx, dddfy, ...
	
	Public
	Method FrameCount:Int()
		Return curves.Length / 6 + 1
	End

	Method New(frameCount:Int = 0)
		curves = New float[ (frameCount - 1) * 6]
	End

	Method Apply:Void(skeleton:SpineSkeleton, time:float, alpha:float) Abstract

	Method SetLinear:Void(frameIndex:Int)
		curves[frameIndex * 6] = LINEAR
	End

	Method SetStepped:Void(frameIndex:Int)
		curves[frameIndex * 6] = STEPPED
	End

	'Sets the control handle positions for an interpolation bezier curve used to transition from this keyframe to the next.
 	'cx1 and cx2 are from 0 to 1, representing the percent of time between the two keyframes. cy1 and cy2 are the percent of
 	'the difference between the keyframe's values.
	Method SetCurve:Void(frameIndex:int, cx1:float, cy1:float, cx2:float, cy2:float)
		Local subdiv_step:Float = 1.0 / BEZIER_SEGMENTS
		Local subdiv_step2:Float = subdiv_step * subdiv_step
		Local subdiv_step3:Float = subdiv_step2 * subdiv_step
		Local pre1:Float = 3 * subdiv_step
		Local pre2:Float = 3 * subdiv_step2
		Local pre4:Float = 6 * subdiv_step2
		Local pre5:Float = 6 * subdiv_step3
		Local tmp1x:Float = -cx1 * 2 + cx2
		Local tmp1y:Float = -cy1 * 2 + cy2
		Local tmp2x:Float = (cx1 - cx2) * 3 + 1
		Local tmp2y:Float = (cy1 - cy2) * 3 + 1
		
		Local i:int = frameIndex * 6
		Local curves:float[] = Self.curves
		curves[i] = cx1 * pre1 + tmp1x * pre2 + tmp2x * subdiv_step3
		curves[i + 1] = cy1 * pre1 + tmp1y * pre2 + tmp2y * subdiv_step3
		curves[i + 2] = tmp1x * pre4 + tmp2x * pre5
		curves[i + 3] = tmp1y * pre4 + tmp2y * pre5
		curves[i + 4] = tmp2x * pre5
		curves[i + 5] = tmp2y * pre5
	End

	Method GetCurvePercent:float(frameIndex:Int, percent:float)
		Local curveIndex:Int = frameIndex * 6
		Local curves:float[] = Self.curves
		Local dfx:Float = curves[curveIndex]
		if (dfx = LINEAR) return percent
		if (dfx = STEPPED) return 0
		Local dfy:float = curves[curveIndex + 1]
		Local ddfx:float = curves[curveIndex + 2]
		Local ddfy:float = curves[curveIndex + 3]
		Local dddfx:float = curves[curveIndex + 4]
		Local dddfy:float = curves[curveIndex + 5]
		Local x:float = dfx
		Local y:float = dfy
		Local i:Int = BEZIER_SEGMENTS - 2
		While True
			If x >= percent
				Local lastX:float = x - dfx
				Local lastY:float = y - dfy
				return lastY + (y - lastY) * (percent - lastX) / (x - lastX)
			EndIf
			If i = 0 Exit
			i -= 1
			dfx += ddfx
			dfy += ddfy
			ddfx += dddfx
			ddfy += dddfy
			x += dfx
			y += dfy
		Wend
		return y + (1 - y) * (percent - x) / (1 - x) ' Last point is 1,1.
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

	Method Apply:Void(skeleton:SpineSkeleton, time:float, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]
		Local amount:Float

		'check if time is after last frame.
		If time >= Frames[Frames.Length - 2]
			amount = bone.Data.Rotation + Frames[Frames.Length - 1] - bone.Rotation
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

	Method Apply:Void(skeleton:SpineSkeleton, time:float, alpha:float)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]

		If time >= Frames[Frames.Length - 3] ' Time is after last frame.
			bone.X += ( (bone.Data.X + Frames[Frames.Length - 2] - bone.X) * alpha)
			bone.Y += ( (bone.Data.Y + Frames[Frames.Length - 1] - bone.Y) * alpha)
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

	Method Apply:Void(skeleton:SpineSkeleton, time:float, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local bone:SpineBone = skeleton.Bones[BoneIndex]
		If time >= Frames[Frames.Length - 3] ' Time is after last frame.
			bone.ScaleX += ( (bone.Data.ScaleX - 1 + Frames[Frames.Length - 2] - bone.ScaleX) * alpha)
			bone.ScaleY += ( (bone.Data.ScaleY - 1 + Frames[Frames.Length - 1] - bone.ScaleY) * alpha)
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

	Method Apply:Void(skeleton:SpineSkeleton, time:float, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local slot:SpineSlot = skeleton.Slots[SlotIndex]

		If time >= Frames[Frames.Length - 5] ' Time is after last frame.
			Local i:Int = Frames.Length - 1
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
		Return Frames.Length
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

	Method Apply:Void(skeleton:SpineSkeleton, time:float, alpha:Float)
		If time < Frames[0] Return ' Time is before first frame.

		Local frameIndex:Int
		If time >= Frames[Frames.Length - 1] ' Time is after last frame.
			frameIndex = Frames.Length - 1
		else
			frameIndex = SpineAnimation.binarySearch(Frames, time, 1) - 1
		EndIf

		Local attachmentName:String = AttachmentNames[frameIndex]
		If attachmentName.Length = 0
			skeleton.Slots[SlotIndex].Attachment = Null
		Else
			skeleton.Slots[SlotIndex].Attachment = skeleton.GetAttachment(SlotIndex, attachmentName)
		EndIf
		
	End
End
