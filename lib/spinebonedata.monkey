'see license.txt For source licenses
Strict

Import spine

Class SpineBoneData
	' May be Null. 
	Field Parent:SpineBoneData
	Field Name:String
	Field Length:Float
	Field X:Float
	Field Y:Float
	Field Rotation:Float
	Field ScaleX:= 1.0
	Field ScaleY:= 1.0
	Field InheritScale:= True
	Field InheritRotation:= True

	'param parent May be Null. 
	Method New(name:String, parent:SpineBoneData)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be Null.")
		Name = name
		Parent = parent
	End

	Method ToString:String()
		Return Name
	End
End
