'see license.txt for source licenses
Strict

Import spine

Class SpineBone
	Const yDown:bool = True

	Field Data:SpineBoneData
	Field parentIndex:Int
	Field Parent:SpineBone
	
	'these are values piped to by teh animation
	Field X:float
	Field Y:float
	Field Rotation:float
	Field ScaleX:float
	Field ScaleY:float
	
	'these are current final values calculated with inheritance
	Field WorldX:float
	Field WorldY:float
	Field WorldRotation:float
	Field WorldScaleX:float
	Field WorldScaleY:float
	
	Field M00:float
	Field M01:float
	Field M10:float
	Field M11:float

	'constructor
	Method New(data:SpineBoneData, parent:SpineBone)
		If data = Null Throw New SpineArgumentNullException("data cannot be null.")
		Data = data
		Parent = parent
		SetToBindPose()
	End

	'api
	Method UpdateWorldTransform:Void(flipX:bool, flipY:bool)
		' --- compute world SRT based on bone and parent ---
		If Parent <> Null
			WorldX = X * Parent.M00 + Y * Parent.M01 + Parent.WorldX
			WorldY = X * Parent.M10 + Y * Parent.M11 + Parent.WorldY
			WorldScaleX = Parent.WorldScaleX * ScaleX
			WorldScaleY = Parent.WorldScaleY * ScaleY
			WorldRotation = Parent.WorldRotation + Rotation
		Else
			WorldX = X
			WorldY = Y
			WorldScaleX = ScaleX
			WorldScaleY = ScaleY
			WorldRotation = Rotation
			
			Print "worldX for '" + Data.Name + "' = " + WorldX
		EndIf
		
		Local cos:float = Cos(WorldRotation)
		Local sin:float = Sin(WorldRotation)
		M00 = cos * WorldScaleX
		M10 = sin * WorldScaleX
		M01 = -sin * WorldScaleY
		M11 = cos * WorldScaleY
		
		'do flipping
		If flipX
			M00 = -M00
			M01 = -M01
		EndIf
		If flipY
			M10 = -M10
			M11 = -M11
		EndIf
		
		'this flips bottom to top to the monkey top to bottom (see global yDown)
		If yDown
			M10 = -M10
			M11 = -M11
		EndIf
	End

	Method SetToBindPose:Void()
		' --- sets to the bind pose ---
		Local data:SpineBoneData = Data
		X = data.X
		Y = data.Y
		Rotation = data.Rotation
		ScaleX = data.ScaleX
		ScaleY = data.ScaleY
	End

	Method ToString:String()
		return Data.Name
	End
End
