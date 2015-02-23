'see license.txt For source licenses
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
Import spinemojoatlasregion
Import spinemojofile
Import spinemojofileloader
Import spinemojotexturerenderobject
Import spinemojoimagerenderobject
Import spinemojotexture
Import spinemojotextureloader
Import spinemojoimageattachment

'globals
Private
Global spineMojoFileLoader:SpineFileLoader = New SpineMojoFileLoader
Global spineMojoTextureLoader:SpineTextureLoader = New SpineMojoTextureLoader
Global spineMojoAtlasLoader:SpineAtlasLoader = New SpineMojoAtlasLoader
Public

'functions
Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String)
	'assumes the atlas has the same name!
	Local atlasDir:= ExtractDir(skeletonPath)
	Local atlasPath:= atlasDir + "/" + StripAll(skeletonPath) + ".atlas"
	Return New SpineEntity(skeletonPath, atlasPath, atlasDir, spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End

Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String, atlasPath:String)
	'assumes the atlas images are in same dir as atlas
	Local atlasDir:= ExtractDir(skeletonPath)
	Return New SpineEntity(skeletonPath, atlasPath, atlasDir, spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End

Function LoadMojoSpineEntity:SpineEntity(skeletonPath:String, atlasPath:String, atlasDir:String)
	'allows to specify atlas images dir
	Return New SpineEntity(skeletonPath, atlasPath, atlasDir, spineMojoFileLoader, spineMojoAtlasLoader, spineMojoTextureLoader)
End