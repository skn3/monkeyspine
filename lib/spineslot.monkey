'see license.txt For source licenses
Strict

Import spine

Class SpineSlot
	Field parentIndex:Int
	Field Data:SpineSlotData
	Field Bone:SpineBone
		
	Field R:Float
	Field G:Float
	Field B:Float
	Field A:Float

	' May be Null.
	Private
	Field attachment:SpineAttachment
	Field attachmentTime:Float
	Public
	
	Field AttachmentVertices:Float[]
	Field AttachmentVerticesCount:Int
	
	Method Skeleton:SpineSkeleton() Property
		Return Bone.Skeleton
	End
	
	Method Attachment:SpineAttachment() Property
		Return attachment
	End
	
	Method Attachment:Void(attachment:SpineAttachment) Property
		Self.attachment = attachment
		attachmentTime = Bone.Skeleton.Time
		AttachmentVerticesCount = 0
	End

	Method AttachmentTime:Float() Property
		Return Bone.Skeleton.Time - attachmentTime
	End
	
	Method AttachmentTime:Void(time:Float) Property
		attachmentTime = Bone.Skeleton.Time - time
	End	

	Method New(data:SpineSlotData, bone:SpineBone)
		If data = Null Throw New SpineArgumentNullException("data cannot be Null.")
		If bone = Null Throw New SpineArgumentNullException("bone cannot be Null.")
		Data = data
		Bone = bone
		SetToSetupPose()
	End

	Method SetToSetupPose:Void(slotIndex:Int)
		R = Data.R
		G = Data.G
		B = Data.B
		A = Data.A
		If Data.AttachmentName.Length() = 0
			Attachment = Null
		Else
			Attachment = Bone.Skeleton.GetAttachment(slotIndex, Data.AttachmentName)
		EndIf
	End

	Method SetToSetupPose:Void()
		Local slots:= Bone.Skeleton.Data.Slots
		Local length:= slots.Length()
		For Local indexOf:= 0 Until length
			If slots[indexOf] = Data
				SetToSetupPose(indexOf)
				Return
			EndIf
		Next
		SetToSetupPose(-1)
	End

	Method ToString:String()
		Return Data.Name
	End
End
