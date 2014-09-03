'see license.txt for source licenses
Strict

Import spine

Class SpineSlotData
	Field Name:String
	Field BoneData:SpineBoneData
	Field R:Float
	Field G:Float
	Field B:Float
	Field A:Float
	'param attachmentName May be null. 
	Field AttachmentName:String

	Method New(name:String, boneData:SpineBoneData)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		If boneData = Null Throw New SpineArgumentNullException("boneData cannot be null.")
		Name = name
		BoneData = boneData
		R = 1.0
		G = 1.0
		B = 1.0
		A = 1.0
	End

	Method ToString:String()
		return Name
	End
End
