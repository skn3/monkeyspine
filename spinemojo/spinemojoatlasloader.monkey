'see license.txt For source licenses
Strict

Import spine.spinemojo

Class SpineMojoAtlasLoader Implements SpineAtlasLoader
	Method Load:SpineAtlas(file:SpineFile, dir:String, textureLoader:SpineTextureLoader)
		Local atlas:= New SpineMojoAtlas
		atlas.Load(file, dir, textureLoader)
		Return atlas
	End
End