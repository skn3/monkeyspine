'see license.txt for source licenses
Strict

Import spine

'mojo imports
Import mojo
Import brl.filepath
Import brl.databuffer
Import monkey.map

'spine mojo imports
Import spinemojoatlas
Import spinemojoatlasloader
Import spinemojoatlaspage
Import spinemojoatlasregion
Import spinemojofile
Import spinemojofileloader
Import spinemojorendererobject
Import spinemojotexture
Import spinemojotextureloader

'globals
Private
Global spineMojoFileLoader:SpineFileLoader = New SpineMojoFileLoader
Global spineMojoTextureLoader:SpineTextureLoader = New SpineMojoTextureLoader
Global spineMojoAtlasLoader:SpineAtlasLoader = New SpineMojoAtlasLoader
Public

'functions
Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String, atlasPath:String)
	Return New SpineEntity(skeletonPath, atlasPath, ExtractDir(atlasPath), spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End

Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String, atlasPath:String, atlasDir:String)
	Return New SpineEntity(skeletonPath, atlasPath, atlasDir, spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End