'see license.txt for source licenses
Strict

Import monkeyspine

Class SpineBoneData
	' May be null. 
	Field Parent:SpineBoneData
	Field Name:String
	Field Length:float
	Field X:float
	Field Y:float
	Field Rotation:float
	Field ScaleX:float
	Field ScaleY:float

	'param parent May be null. 
	Method New(name:String, parent:SpineBoneData)
		If name.Length = 0 Throw New SpineArgumentNullException("name cannot be null.")
		Name = name
		Parent = parent
		ScaleX = 1
		ScaleY = 1
	End

	Method ToString:String()
		return Name
	End
End
