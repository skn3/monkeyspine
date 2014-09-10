'see license.txt for source licenses
Strict

Import spine

Class SpineBone
	Const yDown:Bool = True

	Field Data:SpineBoneData
	Field Skeleton:SpineSkeleton
	
	Field parentIndex:Int
	Field Parent:SpineBone
	
	Field X:Float
	Field Y:Float
	Field Rotation:Float
	Field RotationIK:Float
	Field ScaleX:Float
	Field ScaleY:Float
	
	Field M00:Float
	Field M01:Float
	Field M10:Float
	Field M11:Float
	
	Field WorldX:Float
	Field WorldY:Float
	Field WorldRotation:Float
	Field WorldScaleX:Float
	Field WorldScaleY:Float
	
	Method New(data:SpineBoneData, skeleton:SpineSkeleton, parent:SpineBone)
		If data = Null Throw New SpineArgumentNullException("data cannot be Null.")
		If skeleton = Null Throw New SpineArgumentNullException("skeleton cannot be Null.")
		Data = data
		Skeleton = skeleton
		Parent = parent
		SetToSetupPose()
	End

	'<summary>Computes the world SRT using the parent bone and the local SRT.</summary>
	Method UpdateWorldTransform:Void()
		' --- compute world SRT based on bone and parent ---
		If Parent <> Null
			WorldX = X * Parent.M00 + Y * Parent.M01 + Parent.WorldX
			WorldY = X * Parent.M10 + Y * Parent.M11 + Parent.WorldY
			If Data.InheritScale
				WorldScaleX = Parent.WorldScaleX * ScaleX
				WorldScaleY = Parent.WorldScaleY * ScaleY
			Else
				WorldScaleX = ScaleX
				WorldScaleY = ScaleY
			EndIf
			
			If Data.InheritRotation
				WorldRotation = Parent.WorldRotation + RotationIK
			Else
				WorldRotation = RotationIK
			EndIf
		Else
			If Skeleton.FlipX
				WorldX = -X
			Else
				WorldX = X
			EndIf
			
			If Skeleton.FlipY <> yDown
				WorldY = -Y
			Else
				WorldY = Y
			EndIf
			
			WorldScaleX = ScaleX
			WorldScaleY = ScaleY
			
			WorldRotation = RotationIK
		EndIf
		
		'Float radians = worldRotation * (Float) Math.PI / 180
		'Float cos = (Float)Math.Cos(radians)
		'Float sin = (Float)Math.Sin(radians)
		Local cos:Float = Cos(WorldRotation)
		Local sin:Float = Sin(WorldRotation)
		
		If Skeleton.FlipX
			M00 = -cos * WorldScaleX
			M01 = sin * WorldScaleY
		Else
			M00 = cos * WorldScaleX
			M01 = -sin * WorldScaleY
		EndIf
		
		If Skeleton.FlipY <> yDown
			M10 = -sin * WorldScaleX
			M11 = -cos * WorldScaleY
		Else
			M10 = sin * WorldScaleX
			M11 = cos * WorldScaleY
		EndIf
	End

	Method SetToSetupPose:Void()
		' --- sets to the bind pose ---
		Local data:SpineBoneData = Data
		X = data.X
		Y = data.Y
		Rotation = data.Rotation
		RotationIK = Rotation
		ScaleX = data.ScaleX
		ScaleY = data.ScaleY
	End
	
	Method WorldToLocal:Void(worldX:Float, worldY:Float, out:Float[])
		Local dx:= worldX - WorldX
		Local dy:= worldY - WorldY
		Local m00:= M00
		Local m10:= M10
		Local m01:= M01
		Local m11:= M11
		
		If Skeleton.FlipX <> (Skeleton.FlipY <> yDown)
			m00 *= -1
			m11 *= -1
		EndIf
		
		Local invDet:Float = 1.0 / (m00 * m11 - m01 * m10)
		out[0] = (dx * m00 * invDet - dy * m01 * invDet)
		out[1] = (dy * m11 * invDet - dx * m10 * invDet)
	End
	
	Method LocalToWorld:Void(localX:Float, localY:Float, out:Float[])
		out[0] = localX * M00 + localY * M01 + WorldX
		out[1] = localX * M10 + localY * M11 + WorldY
	End

	Method ToString:String()
		Return Data.Name
	End
End
