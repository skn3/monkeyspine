'see license.txt For source licenses
Strict

Import spine

Class SpineIkConstraintData
	Field Name:String
	Field Bones:SpineBoneData[]
	Field Target:SpineBoneData
	Field BendDirection:= 1
	Field Mix:= 1.0

	Method New(name:String)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be Null.")
		Name = name
	End

	Method ToString:String()
		Return Name
	End
End