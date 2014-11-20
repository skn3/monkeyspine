'see license.txt For source licenses
Strict

Import spine

Class SpineAttachment Abstract
	Field Name:String
	Field Type:Int

	Method New(name:String)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		Name = name
	End

	' --- api
	
	Method ToString:String()
		Return Name
	End
End
