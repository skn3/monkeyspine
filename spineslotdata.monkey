'see license.txt for source licenses
Strict

Import spine

Class SpineSlotData
	Field Name:String
	Field BoneData:SpineBoneData
	Field R:= 1.0
	Field G:= 1.0
	Field B:= 1.0
	Field A:= 1.0
	Field AttachmentName:String
	Field AdditiveBlending:Bool

	Method New(name:String, boneData:SpineBoneData)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		If boneData = Null Throw New SpineArgumentNullException("boneData cannot be Null.")
		Name = name
		BoneData = boneData
	End

	Method ToString:String()
		Return Name
	End
End
