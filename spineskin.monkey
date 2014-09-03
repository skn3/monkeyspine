'see license.txt for source licenses
Strict

Import spine

' Stores attachments by index:slot and attachment name. 
Class SpineSkin
	Field Name:String
	Field attachments:IntMap<StringMap<SpineAttachment>>

	Method New(name:String)
		If name.Length() = 0 Throw New SpineArgumentNullException("name cannot be empty.")
		Name = name
	End

	Method AddAttachment:Void(slotIndex:int, name:String, attachment:SpineAttachment)
		If attachment = Null Throw New SpineArgumentNullException("attachment cannot be null.")
		If attachments = Null attachments = New IntMap<StringMap<SpineAttachment>>
		Local slotMap:= attachments.ValueForKey(slotIndex)
		If slotMap = Null
			slotMap = New StringMap<SpineAttachment>
			attachments.Insert(slotIndex, slotMap)
		EndIf
		slotMap.Insert(name, attachment)
	End

	'return May be null. 
	Method GetAttachment:SpineAttachment(slotIndex:int, name:String)
		If attachments = Null Return Null
		Local slotMap:= attachments.ValueForKey(slotIndex)
		If slotMap = Null Return Null
		Return slotMap.ValueForKey(name)
	End

	Method FindNamesForSlot:String[] (slotIndex:int)
		If attachments = Null Return New String[0]
		Local slotMap:= attachments.ValueForKey(slotIndex)
		If slotMap = Null Return New String[0]
		
		Local results:String[slotMap.Count()]
		Local resultIndex:Int = 0
		
		For Local name:= EachIn slotMap.Keys()
			results[resultIndex] = name
			resultIndex += 1
		Next
		Return results
	End

	Method FindAttachmentsForSlot:SpineAttachment[] (slotIndex:int)
		
		If attachments = Null Return New SpineAttachment[0]
		Local slotMap:= attachments.ValueForKey(slotIndex)
		If slotMap = Null Return New SpineAttachment[0]
		
		Local results:SpineAttachment[slotMap.Count()]
		Local resultIndex:Int = 0
		
		For Local attachment:= EachIn slotMap.Values()
			results[resultIndex] = attachment
			resultIndex += 1
		Next
		Return results
	End

	Method ToString:String()
		return Name
	End

	' Attach all attachments from this if:skin the corresponding attachment from the old is:skin currently attached. 
	Private
	Method AttachAll:Void(skeleton:SpineSkeleton, oldSkin:SpineSkin)
		If oldSkin.attachments = Null Return
		
		Local slot:SpineSlot
		Local slotMap:StringMap<SpineAttachment>
		Local name:string
		Local attachment:SpineAttachment
		
		'fugly
		For Local slotIndex:= EachIn oldSkin.attachments.Keys()
			slot = skeleton.Slots[slotIndex]
			slotMap = oldSkin.attachments.ValueForKey(slotIndex)
			If slotMap
				For name = EachIn slotMap.Keys()
					attachment = slotMap.ValueForKey(name)
					
					If slot.Attachment = attachment
						attachment = GetAttachment(slotIndex, name)
						If attachment <> Null slot.Attachment = attachment
					EndIf
				Next
			EndIf
		Next
	End
End
