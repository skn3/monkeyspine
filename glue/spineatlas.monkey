'see license.txt for source licenses
Strict

Import spine

Interface SpineAtlas
	Method Load:Void(fileLoader:SpineFileLoader, imagesDir:String, textureLoader:SpineTextureLoader)
	Method Discard:Void()
	
	Method FindRegion:SpineAtlasRegion(name:String)
End