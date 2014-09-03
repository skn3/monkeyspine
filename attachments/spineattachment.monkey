'see license.txt for source licenses
Strict

Import spine

Class SpineAttachment Abstract
	Field Name:String
	Field Type:Int

	Method New(name:String, type:Int)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		Type = type
		Name = name
	End

	Method ToString:String()
		Return Name
	End
End
