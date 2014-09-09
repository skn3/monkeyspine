'see license.txt for source licenses
Strict

Import spine

Class SpineAnimationMap<V> Extends Map<SpineAnimation, V>
	Method Compare:Int(a:SpineAnimation, b:SpineAnimation)
		'If a < b Then Return 1
		'If a > b Then Return -1
		If a = b Then Return 0
		Return -1
	End
End

Class SpineAnimationStateData
	Field SkeletonData:SpineSkeletonData
	Private
	Field animationToMixTime:SpineAnimationMap<SpineAnimationMap<FloatObject>>
	Public
	Field DefaultMix:Float

	Method New(skeletonData:SpineSkeletonData)
		SkeletonData = skeletonData
	End

	Method SetMix:Void(fromName:String, toName:String, duration:Float)
		Local fromAnimation:SpineAnimation = SkeletonData.FindAnimation(fromName)
		If fromAnimation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + fromName)
		Local toAnimation:SpineAnimation = SkeletonData.FindAnimation(toName)
		If toAnimation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + toName)
		SetMix(fromAnimation, toAnimation, duration)
	End

	Method SetMix:Void(fromAnimation:SpineAnimation, toAnimation:SpineAnimation, duration:Float)
		If fromAnimation = Null Throw New SpineArgumentNullException("from cannot be Null.")
		If toAnimation = Null Throw New SpineArgumentNullException("to cannot be Null.")
		
		If animationToMixTime = Null animationToMixTime = New SpineAnimationMap<SpineAnimationMap<FloatObject>>
		
		Local fromMap:= animationToMixTime.ValueForKey(fromAnimation)
		If fromMap = Null
			fromMap = New SpineAnimationMap<FloatObject>
			animationToMixTime.Insert(fromAnimation, fromMap)
		EndIf
		
		Local floatObject:= fromMap.ValueForKey(toAnimation)
		If floatObject
			'reuse old Float object
			floatObject.value = duration
		Else
			'create new Float object
			fromMap.Insert(toAnimation, New FloatObject(duration))
		EndIf
	End

	Method GetMix:Float(fromAnimation:SpineAnimation, toAnimation:SpineAnimation)
		If animationToMixTime = Null Return DefaultMix
		Local fromMap:= animationToMixTime.ValueForKey(fromAnimation)
		If fromMap = Null Return DefaultMix
		Local floatObject:= fromMap.ValueForKey(toAnimation)
		If floatObject = Null Return DefaultMix
		Return floatObject.value
	End
End
