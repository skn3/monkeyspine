'see license.txt For source licenses
Strict

Import spine

Class SpineIkConstraint
	'Const radDeg:Float = 180.0 / Math.PI

	Field Data:SpineIkConstraintData
	Field Bones:SpineBone[]
	Field Target:SpineBone
	Field BendDirection:Int = 1
	Field Mix:Float = 1.0
	
	Field parentIndex:Int

	Method New(data:SpineIkConstraintData, skeleton:SpineSkeleton)
		Data = data
		Mix = data.Mix
		BendDirection = data.BendDirection

		Bones = New SpineBone[data.Bones.Length()]
		Local boneData:SpineBoneData
		For Local i:= 0 Until data.Bones.Length()
			boneData = data.Bones[i]
			Bones[i] = skeleton.FindBone(boneData.Name)
			Target = skeleton.FindBone(data.Target.Name)
		Next
	End

	Method Apply:Void()
		'DebugStop()
		Select Bones.Length()
			Case 1
				Apply(Bones[0], Target.WorldX, Target.WorldY, Mix)
			Case 2
				Apply(Bones[0], Bones[1], Target.WorldX, Target.WorldY, BendDirection, Mix)
		End
	End

	Method ToString:String()
		Return Data.Name
	End
	
	'<summary>Adjusts the bone rotation so the tip is as close to the Target position as possible. The Target is specified
	'in the world coordinate system.</summary>
	Function Apply:Void(bone:SpineBone, targetX:Float, targetY:Float, alpha:Float)
		Local parentRotation:Float
		If Not bone.Data.InheritRotation Or bone.Parent = Null
			parentRotation = 0.0
		Else
			parentRotation = bone.Parent.WorldRotation
		EndIf
		Local rotation:Float = bone.Rotation
		'Local rotationIK:Float = ATan2(targetY - bone.WorldY, targetX - bone.WorldX) * radDeg - parentRotation
		Local rotationIK:Float = ATan2(targetY - bone.WorldY, targetX - bone.WorldX) - parentRotation
		bone.RotationIK = rotation + (rotationIK - rotation) * alpha
	End

	'<summary>Adjusts the parent and child bone rotations so the tip of the child is as close to the Target position as
	'possible. The Target is specified in the world coordinate system.</summary>
	'<param name="child">Any descendant bone of the parent.</param>
	Function Apply:Void(parent:SpineBone, child:SpineBone, targetX:Float, targetY:Float, bendDirection:Int, alpha:Float)
		'DebugStop()
		Local childRotation:= child.Rotation
		Local parentRotation:= parent.Rotation
		if alpha = 0.0
			child.RotationIK = childRotation
			parent.RotationIK = parentRotation
			Return
		EndIf
		
		Local positionXY:Float[2]
		Local parentParent:SpineBone = parent.Parent
		if parentParent
			parentParent.WorldToLocal(targetX, targetY, positionXY)
			targetX = (positionXY[0] - parent.X) * parentParent.WorldScaleX
			targetY = (positionXY[1] - parent.Y) * parentParent.WorldScaleY
		Else
			targetX -= parent.X
			targetY -= parent.Y
		EndIf
		
		If child.Parent = parent
			positionXY[0] = child.X
			positionXY[1] = child.Y
		Else
			child.Parent.LocalToWorld(child.X, child.Y, positionXY)
			parent.WorldToLocal(positionXY[0], positionXY[1], positionXY)
		EndIf
		
		Local childX:Float = positionXY[0] * parent.WorldScaleX
		Local childY:Float = positionXY[1] * parent.WorldScaleY
		Local offset:Float = ATan2(childY, childX)
		Local len1:Float = Sqrt(childX * childX + childY * childY)
		Local len2:Float = child.Data.Length * child.WorldScaleX
		
		'Based on code by Ryan Juckett with permission: Copyright (c) 2008-2009 Ryan Juckett, http://www.ryanjuckett.com/
		Local cosDenom:Float = 2.0 * len1 * len2
		If cosDenom < 0.0001
			'child.rotationIK = childRotation + ( (Float) Math.Atan2(targetY, targetX) * radDeg - parentRotation - childRotation) * alpha
			child.RotationIK = childRotation + (ATan2(targetY, targetX) - parentRotation - childRotation) * alpha
			Return
		EndIf
		Local cos:Float = (targetX * targetX + targetY * targetY - len1 * len1 - len2 * len2) / cosDenom
		If cos < - 1.0
			cos = -1.0
		ElseIf cos > 1.0
			cos = 1.0
		EndIf
		
		Local childAngle:Float = ACos(cos) * bendDirection
		Local adjacent:Float = len1 + len2 * cos
		Local opposite:Float = len2 * Sin(childAngle)
		Local parentAngle:Float = ATan2(targetY * adjacent - targetX * opposite, targetX * adjacent + targetY * opposite)
		'Float rotation = (parentAngle - offset) * radDeg - parentRotation
		Local rotation:Float = (parentAngle - offset) - parentRotation
		If rotation > 180.0
			rotation -= 360.0
		ElseIf rotation < - 180.0
			rotation += 360.0
		EndIf
		parent.RotationIK = parentRotation + rotation * alpha
		'rotation = (childAngle + offset) * radDeg - childRotation
		rotation = (childAngle + offset) - childRotation
		If rotation > 180.0
			rotation -= 360.0
		ElseIf rotation < - 180.0
			rotation += 360.0
		EndIf
		child.RotationIK = childRotation + (rotation + parent.WorldRotation - child.Parent.WorldRotation) * alpha
	End
End
