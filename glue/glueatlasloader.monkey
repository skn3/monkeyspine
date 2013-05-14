Strict

Import monkeyspine

Interface SpineAtlasLoader
	Method OnLoadAtlas:Void(atlas:SpineAtlas, fileStream:SpineFileStream, imageLoader:SpineImageLoader = SpineDefaultImageLoader.instance)
End

Class SpineMakeAtlasJSONAtlasLoader Implements SpineAtlasLoader
	Global instance:= New SpineMakeAtlasJSONAtlasLoader
		
	'callbacks
	Method OnLoadAtlas:Void(atlas:SpineAtlas, fileStream:SpineFileStream, imageLoader:SpineImageLoader = SpineDefaultImageLoader.instance)
		' --- read Make Atlas JSON texture file ---
		
		
		'trim the atlas arrays
		If pagesCount < atlas.pages.Length atlas.pages = atlas.pages.Resize(pagesCount)
		If regionsCount < atlas.regions.Length atlas.regions = atlas.regions.Resize(regionsCount)
	End
End