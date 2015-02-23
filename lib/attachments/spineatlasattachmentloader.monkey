'see license.txt For source licenses
Strict

Import spine

Class SpineAtlasAttachmentLoader Implements SpineAttachmentLoader
	Private
	Field atlas:SpineAtlas
	Public

	Method New(atlas:SpineAtlas)
		' --- create New attachment loader using atlas ---
		If atlas = Null Throw New SpineArgumentNullException("atlas cannot be Null.")
		Self.atlas = atlas
	End

	Method NewRegionAttachment:SpineRegionAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.FindRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		
		Local attachment:= New SpineRegionAttachment(name)
		attachment.RenderObject = region.rendererObject
		attachment.SetUVs(region.u, region.v, region.u2, region.v2, region.rotate)
		attachment.RegionOffsetX = region.offsetX
		attachment.RegionOffsetY = region.offsetY
		attachment.RegionWidth = region.width
		attachment.RegionHeight = region.height
		attachment.RegionOriginalWidth = region.originalWidth
		attachment.RegionOriginalHeight = region.originalHeight
		Return attachment
	End

	Method NewMeshAttachment:SpineMeshAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.FindRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		
		Local attachment:= New SpineMeshAttachment(name)
		attachment.RenderObject = region.rendererObject
		attachment.RegionU = region.u
		attachment.RegionV = region.v
		attachment.RegionU2 = region.u2
		attachment.RegionV2 = region.v2
		attachment.RegionRotate = region.rotate
		attachment.RegionOffsetX = region.offsetX
		attachment.RegionOffsetY = region.offsetY
		attachment.RegionWidth = region.width
		attachment.RegionHeight = region.height
		attachment.RegionOriginalWidth = region.originalWidth
		attachment.RegionOriginalHeight = region.originalHeight
		Return attachment
	End
	
	Method NewSkinnedMeshAttachment:SpineSkinnedMeshAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.FindRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		
		Local attachment:= New SpineSkinnedMeshAttachment(name)
		attachment.RenderObject = region.rendererObject
		attachment.RegionU = region.u
		attachment.RegionV = region.v
		attachment.RegionU2 = region.u2
		attachment.RegionV2 = region.v2
		attachment.RegionRotate = region.rotate
		attachment.RegionOffsetX = region.offsetX
		attachment.RegionOffsetY = region.offsetY
		attachment.RegionWidth = region.width
		attachment.RegionHeight = region.height
		attachment.RegionOriginalWidth = region.originalWidth
		attachment.RegionOriginalHeight = region.originalHeight
		Return attachment
	End
	
	Method NewBoundingBoxAttachment:SpineBoundingBoxAttachment(skin:SpineSkin, name:String)
		Return New SpineBoundingBoxAttachment(name)
	End
End
