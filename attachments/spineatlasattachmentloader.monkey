'see license.txt for source licenses
Strict

Import spine

Class SpineAtlasAttachmentLoader Implements SpineAttachmentLoader
	Private
	Field atlas:SpineAtlas
	Public

	Method New(atlas:SpineAtlas)
		' --- create new attachment loader using atlas ---
		If atlas = Null Throw New SpineArgumentNullException("atlas cannot be Null.")
		Self.atlas = atlas
	End

	Method NewRegionAttachment:SpineRegionAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.GetRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		
		Local attachment:= New SpineRegionAttachment()
		attachment.RenderObject = region
		attachment.SetUVs(region.U, region.v, region.u2, region.v2, region.rotate)
		attachment.RegionOffsetX = region.offsetX
		attachment.RegionOffsetY = region.offsetY
		attachment.RegionWidth = region.width
		attachment.RegionHeight = region.height
		attachment.RegionOriginalWidth = region.originalWidth
		attachment.RegionOriginalHeight = region.originalHeight
		Return attachment
	End

	Method NewMeshAttachment:SpineMeshAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.GetRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		
		Local attachment:= New SpineMeshAttachment()
		attachment.RenderObject = region
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
	
	Method NewMeshAttachment:SkinnedMeshAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.GetRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		
		Local attachment:= New SpineSkinnedMeshAttachment()
		attachment.RenderObject = region
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
