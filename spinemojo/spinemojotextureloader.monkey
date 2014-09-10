'see license.txt for source licenses
Strict

Import spine.spinemojo

Class SpineMojoTextureLoader Implements SpineTextureLoader
	Method Load:SpineTexture(path:String)
		Local texture:= New SpineMojoTexture
		texture.Load(path)
		Return texture
	End
End