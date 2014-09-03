'see license.txt for source licenses
Strict

Import spine

Class SpineEventData
	Field Name:String
	Field IntValue:Int
	Field FloatValue:Float
	Field StringValue:String

	Method New(name:String)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be Null.")
		Self.Name = name
	End

	Method ToString:String()
		Return Name
	End
End