'see license.txt For source licenses
Strict

Import spine

Interface SpineAttachmentLoader
	'Return May be Null to not load any attachment. 
	Method NewRegionAttachment:SpineRegionAttachment(skin:SpineSkin, name:String, path:String)
	Method NewMeshAttachment:SpineMeshAttachment(skin:SpineSkin, name:String, path:String)
	Method NewSkinnedMeshAttachment:SpineSkinnedMeshAttachment(skin:SpineSkin, name:String, path:String)
	Method NewBoundingBoxAttachment:SpineBoundingBoxAttachment(skin:SpineSkin, name:String)
End
