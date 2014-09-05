'see license.txt for source licenses
Strict

Import spine

Class SpineSkeleton
	Field Data:SpineSkeletonData
	Field Bones:SpineBone[]
	Field Slots:SpineSlot[]
	Field DrawOrder:SpineSlot[]
	Field IkConstraints:SpineIkConstraint[]
	Private
	Field boneCache:SpineBone[][]
	Public
	Field Skin:SpineSkin
	Field R:= 1.0
	Field G:= 1.0
	Field B:= 1.0
	Field A:= 1.0
	Field Time:Float
	Field FlipX:Bool
	Field FlipY:Bool
	Field X:Float
	Field Y:Float
	
	Method RootBone:SpineBone()
		If Bones.Length() = 0 Return Null
		Return Bones[0]
	End

	Method New(data:SpineSkeletonData)
		If data = Null Throw New SpineArgumentNullException("data cannot be Null.")
		Data = data
		
		Local addIndex:Int
		Local index:Int
		Local indexOf:Int
		Local parent:SpineBone
		Local boneData:SpineBoneData
		Local bone:SpineBone
		Local slot:SpineSlot
		Local ikConstraint:SpineIkConstraint
		
		addIndex = 0
		Bones = New SpineBone[Data.Bones.Length()]
		For index = 0 Until Data.Bones.Length()
			'find bone data and parent
			boneData = Data.Bones[index]
			parent = Null
			If boneData.Parent
				For indexOf = 0 Until Data.Bones.Length()
					If Data.Bones[indexOf] = boneData.Parent
						parent = Bones[indexOf]
						Exit
					EndIf
				Next
			EndIf
			
			'create new bone
			Bones[addIndex] = New SpineBone(boneData, Self, parent)
			Bones[addIndex].parentIndex = addIndex
			
			addIndex += 1
		Next

		addIndex = 0
		Slots = New SpineSlot[Data.Slots.Length()]
		DrawOrder = New SpineSlot[Data.Slots.Length()]
		For index = 0 Until Data.Slots.Length()
			bone = Null
			For indexOf = 0 Until Data.Bones.Length()
				If Data.Bones[indexOf] = Data.Slots[index].BoneData
					bone = Bones[indexOf]
					Exit
				EndIf
			Next
			
			'create new slot
			slot = New SpineSlot(Data.Slots[index], bone)
			slot.parentIndex = addIndex
			
			Slots[addIndex] = slot
			DrawOrder[addIndex] = slot
			addIndex += 1
		Next
		
		addIndex = 0
		IkConstraints = New SpineIkConstraint[Data.IkConstraints.Length()]
		For index = 0 Until Data.IkConstraints.Length()
			ikConstraint = New SpineIkConstraint(Data.IkConstraints[index], Self)
			ikConstraint.parentIndex = addIndex
			
			IkConstraints[addIndex] = ikConstraint
			addIndex += 1
		Next

		UpdateCache()
	End

	'<summary>Caches information about bones and IK constraints. Must be called if bones or IK constraints are added or removed.</summary>
	Method UpdateCache:Void()
		Local boneIndex:Int
		Local ikContraintIndex:Int
		Local bone:SpineBone
		Local parent:SpineBone
		Local child:SpineBone
		Local ikContraint:SpineIkConstraint
		Local current:SpineBone
		Local ikConstraintsCount:Int = IkConstraints.Length()
		Local arrayCount:= ikConstraintsCount + 1
		Local break:Bool
		
		If arrayCount <> boneCache.Length() boneCache = New SpineBone[arrayCount][]
		
		For boneIndex = 0 Until arrayCount
			boneCache[boneIndex] = New SpineBone[IkConstraints.Length()]
		Next
		
		Local nonIkBones:= boneCache[0]
		
		For boneIndex = 0 Until Bones.Length()
			bone = Bones[boneIndex]
			current = bone
			
			break = False
			Repeat
				For ikContraintIndex = 0 Until ikConstraintsCount
					ikContraint = IkConstraints[ikContraintIndex]
					parent = ikContraint.Bones[0]
					child = ikContraint.Bones[ikContraint.Bones.Length() -1]
					Repeat
						If current = child
							boneCache[ikContraintIndex][boneIndex] = bone
							boneCache[ikContraintIndex + 1][boneIndex] = bone
							break = True
							Exit
						EndIf
						
						If child = parent Exit
						child = child.Parent
					Forever
					If break Exit
				Next
				If break Exit
				
				current = current.Parent
			Until current = Null
			
			nonIkBones[boneIndex] = bone
		Next
	End
	
	'<summary>Updates the world transform for each bone and applies IK constraints.</summary>
	Method UpdateWorldTransform:Void()
		Local i:Int
		Local ii:Int
		Local nn:Int
		Local bone:SpineBone
		Local last:= boneCache.Length() -1
		Local updateBones:SpineBone[]
		
		For Local i:= 0 Until Bones.Length()
			bone = Bones[i]
			bone.RotationIK = bone.Rotation
		Next
		
		Repeat
			updateBones = boneCache[i]
			nn = updateBones.Length()
			For ii = 0 Until nn
				updateBones[ii].UpdateWorldTransform()
			Next
			If i = last Exit
			IkConstraints[i].Apply()
			i += 1
		Forever
	End

	'<summary>Sets the bones and slots to their setup pose values.</summary>
	Method SetToSetupPose:Void()
		SetBonesToSetupPose()
		SetSlotsToSetupPose()
	End

	Method SetBonesToSetupPose:Void()
		Local i:Int
		Local n:= Bones.Length()
		Local ikConstraint:SpineIkConstraint
		
		For i = 0 Until n
			Bones[i].SetToSetupPose()
		Next
		
		n = IkConstraints.Length()
		For i = 0 Until n
			ikConstraint = IkConstraints[i]
			ikConstraint.BendDirection = ikConstraint.Data.BendDirection
			ikConstraint.Mix = ikConstraint.Data.Mix
		Next
	End

	Method SetSlotsToSetupPose:Void()
		Local i:Int
		Local n:= Slots.Length()
		
		For i = 0 Until n
			DrawOrder[i] = Slots[i]
		Next
		
		For i = 0 Until n
			Slots[i].SetToSetupPose(i)
		Next
	End

	Method FindBone:SpineBone(boneName:String)
		If boneName.Length() = 0 Throw New SpineArgumentNullException("boneName cannot be Null.")
		Local n:= Bones.Length()
		For Local i:= 0 Until n
			If Bones[i].Data.Name = boneName Return Bones[i]
		Next
		Return Null
	End

	Method FindBoneIndex:Int(boneName:String)
		If boneName.Length() = 0 Throw New SpineArgumentNullException("boneName cannot be Null.")
		Local n:= Bones.Length()
		For Local i:= 0 Until n
			If Bones[i].Data.Name = boneName Return i
		Next
		Return -1
	End

	Method FindSlot:SpineSlot(slotName:String)
		If slotName.Length() = 0 Throw New SpineArgumentNullException("slotName cannot be Null.")
		Local n:= Slots.Length()
		For Local i:= 0 Until n
			If Slots[i].Data.Name = slotName Return Slots[i]
		Next
		Return Null
	End

	Method FindSlotIndex:Int(slotName:String)
		If slotName.Length() = 0 Throw New SpineArgumentNullException("slotName cannot be Null.")
		Local n:= Slots.Length()
		For Local i:= 0 Until n
			If Slots[i].Data.Name = slotName Return i
		Next
		Return -1
	End

	Method SetSkin:Void(skinName:String)
		Local skin:SpineSkin = Data.FindSkin(skinName)
		If skin = Null Throw New SpineException("Spine skin '" + skinName + "' not found")
		SetSkin(skin)
	End

	Method SetSkin:Void(newSkin:SpineSkin)
		If newSkin <> Null
			If Skin <> Null
				newSkin.AttachAll(Self, Skin)
			Else
				Local n:= Slots.Length()
				Local slot:SpineSlot
				Local name:String
				Local attachment:SpineAttachment
				
				For Local i:= 0 Until n
					slot = Slots[i]
					name = slot.Data.AttachmentName
					If name.Length()
						attachment = newSkin.GetAttachment(i, name)
						If attachment slot.Attachment = attachment
					EndIf
				Next
			EndIf
		EndIf
		Skin = newSkin
	End

	Method GetAttachment:SpineAttachment(slotName:String, attachmentName:String)
		Return GetAttachment(Data.FindSlotIndex(slotName), attachmentName)
	End

	Method GetAttachment:SpineAttachment(slotIndex:Int, attachmentName:String)
		If attachmentName.Length() = 0 Throw New SpineArgumentNullException("attachmentName cannot be Null.")
		If Skin <> Null
			Local attachment:SpineAttachment = Skin.GetAttachment(slotIndex, attachmentName)
			If attachment <> Null Return attachment
		EndIf
		If Data.DefaultSkin <> Null Return Data.DefaultSkin.GetAttachment(slotIndex, attachmentName)
		Return Null
	End

	Method SetAttachment:Void(slotName:String, attachmentName:String)
		If slotName.Length() = 0 Throw New SpineArgumentNullException("slotName cannot be empty.")
		
		Local n:= Slots.Length()
		Local slot:SpineSlot
		For Local i:= 0 Until n
			slot = Slots[i]
			If slot.Data.Name = slotName
				Local attachment:SpineAttachment
				If attachmentName <> ""
					attachment = GetAttachment(i, attachmentName)
					If attachment = Null Throw New SpineArgumentNullException("attachment not found: " + attachmentName + ", for slot: " + slotName)
				EndIf
				slot.Attachment = attachment
				Return
			EndIf
		Next
		Throw New SpineException("slot not found: " + slotName)
	End
	
	' @Return May be Null.
	Method FindIkConstraint:SpineIkConstraint(ikConstraintName:String)
		if ikConstraintName.Length() = 0 Throw new SpineArgumentNullException("ikConstraintName cannot be Null.")

		Local n:= IkConstraints.Length()
		Local ikConstraint:SpineIkConstraint
		For Local i:= 0 Until n
			ikConstraint = IkConstraints[i]
			If ikConstraint.Data.Name = ikConstraintName Return ikConstraint
		Next
	
		Return Null
	End

	Method Update:Void(delta:Float)
		Time += delta
	End
End
