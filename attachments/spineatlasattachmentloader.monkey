'see license.txt for source licenses
Strict

Import monkeyspine

Class SpineAtlasAttachmentLoader Implements SpineAttachmentLoader
	Private
	Field atlas:SpineAtlas
	Public

	Method New(atlas:SpineAtlas)
		' --- create new attachment loader using atlas ---
		If atlas = Null Throw New SpineArgumentNullException("atlas cannot be null.")
		Self.atlas = atlas
	End

	Method NewAttachment:SpineAttachment(skin:SpineSkin, type:Int, name:String)
		If type = SpineAttachmentType.region
			'this odd class lets us load an "attachment" by looking it up on the existing atlas.
			Local region:SpineAtlasRegion = atlas.GetRegion(name)
			If region = Null Throw New SpineException("Region not found in atlas: " + name + " (" + type + ")")
			
			'modified to be monkey style!
			'create new region attachment
			Local attachment:SpineRegionAttachment = New SpineRegionAttachment(name, SpineAttachmentType.region)
			
			'copy image from atlas region
			attachment.Region = region
			
			'return teh new
			return attachment
		EndIf
		
		'unknown type!
		Throw New SpineException("Unknown attachment type: " + type)
		
		'must have return value
		Return Null
	End
End
