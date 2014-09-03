'see license.txt for source licenses
Strict

Import spine

Class SpineEventData
	Field Name:String
	Field IntValue:int
	Field FloatValue:Float
	Field StringValue:String

	Method New(name:String)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be null.")
		Self.Name = name
	End

	Method GetInt:Int()
		Return IntValue
	End

	Method SetInt:Void(intValue:Int)
		Self.IntValue = intValue
	End

	Method GetFloat:Float()
		Return FloatValue
	End

	Method SetFloat:Void(floatValue:Float)
		Self.FloatValue = floatValue
	End

	Method GetString:String()
		Return StringValue
	End

	Method SetString:Void(stringValue:String)
		Self.StringValue = stringValue
	End

	Method ToString:String()
		return Name
	End
End