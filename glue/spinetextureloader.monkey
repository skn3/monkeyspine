Strict

Import spine

Interface SpineTextureLoader
	Method Load:SpineTexture(path:String)
End

Class SpineMojoTextureLoader
	Method Load:SpineTexture(path:String)
		Local texutre:= New SpineMojoTexture
		texture.Load(path)
		Return texture
	End
End