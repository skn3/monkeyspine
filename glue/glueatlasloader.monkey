Strict

Import spine

Interface SpineAtlasLoader
	Method OnLoadAtlas:Void(atlas:SpineAtlas, fileStream:SpineFileStream, imageLoader:SpineImageLoader = SpineDefaultImageLoader.instance)
End

Class SpineDefaultAtlasLoader Implements SpineAtlasLoader
	Global instance:= New SpineDefaultAtlasLoader
		
	'callbacks
	Method OnLoadAtlas:Void(atlas:SpineAtlas, fileStream:SpineFileStream, imageLoader:SpineImageLoader = SpineDefaultImageLoader.instance)
		' --- read spine produced atlas file ---
		
		'trim the atlas arrays
		If pagesCount < atlas.pages.Length atlas.pages = atlas.pages.Resize(pagesCount)
		If regionsCount < atlas.regions.Length atlas.regions = atlas.regions.Resize(regionsCount)
	End
End

Class SpineMakeAtlasLoader Implements SpineAtlasLoader
	Global instance:= New SpineMakeAtlasLoader
		
	'callbacks
	Method OnLoadAtlas:Void(atlas:SpineAtlas, fileStream:SpineFileStream, imageLoader:SpineImageLoader = SpineDefaultImageLoader.instance)
		' --- read Make Atlas JSON texture file ---
		
		'trim the atlas arrays
		If pagesCount < atlas.pages.Length atlas.pages = atlas.pages.Resize(pagesCount)
		If regionsCount < atlas.regions.Length atlas.regions = atlas.regions.Resize(regionsCount)
	End
End