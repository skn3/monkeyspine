Strict

Import spine

Class SpineTextureWrap
	Const MirroredRepeat:= 0
	Const ClampToEdge:= 1
	Const RepeatTexture:= 2
	
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "mirroredrepeat"
				Return MirroredRepeat
			Case "clamptoedge"
				Return ClampToEdge
			Case "Repeat"
				Return RepeatTexture
		End
		Return -1
	End
End