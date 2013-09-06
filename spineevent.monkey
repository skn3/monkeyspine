'see license.txt for source licenses
Strict

Import spine

Class SpineEvent
	Field Data:SpineEventData
	Field IntValue:int
	Field FloatValue:Float
	Field StringValue:String

	Method New(data:SpineEventData)
		Self.Data = data
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

	Method GetData:SpineEventData()
		Return Data
	End

	Method ToString:String()
		return Data.Name
	End
End