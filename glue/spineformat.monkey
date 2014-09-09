Strict

Import spine

Class SpineFormat
	Const Alpha:= 0
	Const Intensity:= 1
	Const LuminanceAlpha:= 2
	Const RGB565:= 3
	Const RGBA4444:= 4
	Const RGB888:= 5
	Const RGBA8888:= 6
		
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "alpha"
				Return Alpha
			Case "intensity"
				Return Intensity
			Case "luminancealpha"
				Return LuminanceAlpha
			Case "rgb565"
				Return RGB565
			Case "rgba4444"
				Return RGBA4444
			Case "rgb888"
				Return RGB888
			Case "rgba8888"
				Return RGBA8888
		End
		Return -1
	End
End