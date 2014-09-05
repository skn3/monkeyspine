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
		Local region:SpineAtlasRegion = atlas.FindRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		Local attachment:= New SpineRegionAttachment(name)
		attachment.RendererObject = region
		attachment.SetUVs(region.u, region.v, region.u2, region.v2, region.rotate)
		attachment.RenderObjectOffsetX = region.offsetX
		attachment.RenderObjectOffsetY = region.offsetY
		attachment.RenderObjectWidth = region.width
		attachment.RenderObjectHeight = region.height
		attachment.RenderObjectOriginalWidth = region.originalWidth
		attachment.RenderObjectOriginalHeight = region.originalHeight
		Return attachment
	End

	Method NewMeshAttachment:SpineMeshAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.FindRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		Local attachment:= New SpineMeshAttachment(name)
		attachment.RendererObject = region
		attachment.RenderObjectU = region.u
		attachment.RenderObjectV = region.v
		attachment.RenderObjectU2 = region.u2
		attachment.RenderObjectV2 = region.v2
		attachment.RenderObjectRotate = region.rotate
		attachment.RenderObjectOffsetX = region.offsetX
		attachment.RenderObjectOffsetY = region.offsetY
		attachment.RenderObjectWidth = region.width
		attachment.RenderObjectHeight = region.height
		attachment.RenderObjectOriginalWidth = region.originalWidth
		attachment.RenderObjectOriginalHeight = region.originalHeight
		Return attachment
	End
	
	Method NewMeshAttachment:SkinnedMeshAttachment(skin:SpineSkin, name:String, path:String)
		Local region:SpineAtlasRegion = atlas.FindRegion(path)
		If region = Null Throw New SpineArgumentNullException("Region not found in atlas: " + path + " (region attachment: " + name + ")")
		Local attachment:= New SkinnedMeshAttachment(name)
		attachment.RendererObject = region
		attachment.RenderObjectU = region.u
		attachment.RenderObjectV = region.v
		attachment.RenderObjectU2 = region.u2
		attachment.RenderObjectV2 = region.v2
		attachment.RenderObjectRotate = region.rotate
		attachment.RenderObjectOffsetX = region.offsetX
		attachment.RenderObjectOffsetY = region.offsetY
		attachment.RenderObjectWidth = region.width
		attachment.RenderObjectHeight = region.height
		attachment.RenderObjectOriginalWidth = region.originalWidth
		attachment.RenderObjectOriginalHeight = region.originalHeight
		Return attachment
	End
	
	Method NewBoundingBoxAttachment:SpineBoundingBoxAttachment(skin:SpineSkin, name:String)
		Return New SpineBoundingBoxAttachment(name)
	End
End
