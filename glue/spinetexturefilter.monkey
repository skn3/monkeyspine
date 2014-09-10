'see license.txt For source licenses
Strict

Import spine

Class SpineTextureFilter
	Const Nearest:= 0
	Const Linear:= 1
	Const MipMap:= 2
	Const MipMapNearestNearest:= 3
	Const MipMapLinearNearest:= 4
	Const MipMapNearestLinear:= 5
	Const MipMapLinearLinear:= 6
		
	Function FromString:Int(name:String)
		Select name.ToLower()
			Case "nearest"
				Return Nearest
			Case "linear"
				Return Linear
			Case "mipmap"
				Return MipMap
			Case "mipmapnearestnearest"
				Return MipMapNearestNearest
			Case "mipmaplinearnearest"
				Return MipMapLinearNearest
			Case "mipmapnearestlinear"
				Return MipMapNearestLinear
			Case "mipmaplinearlinear"
				Return MipMapLinearLinear
		End
		Return -1
	End
End