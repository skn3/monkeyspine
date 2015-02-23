Strict

Import spine.spinemojo

'SpineAttachment that displays a texture region.
Class SpineMojoImageAttachment Extends SpineRegionAttachment
	Method New(name:String, path:String)
		Super.New(name)
		Type = SpineAttachmentType.Region
		RenderObject = New SpineMojoImageRenderObject(path)
	End
	
	Method New(name:String, image:Image)
		Super.New(name)
		Type = SpineAttachmentType.Region
		RenderObject = New SpineMojoImageRenderObject(image)
	End
End