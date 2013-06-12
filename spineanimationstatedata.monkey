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

	Method New(skeletonData:SpineSkeletonData)
		SkeletonData = skeletonData
	End

	Method SetMix:Void(fromName:String, toName:String, duration:float)
		Local fromAnimation:SpineAnimation = SkeletonData.FindAnimation(fromName)
		If fromAnimation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + fromName)
		Local toAnimation:SpineAnimation = SkeletonData.FindAnimation(toName)
		If toAnimation = Null Throw New SpineArgumentNullException("SpineAnimation not found: " + toName)
		SetMix(fromAnimation, toAnimation, duration)
	End

	Method SetMix:Void(fromAnimation:SpineAnimation, toAnimation:SpineAnimation, duration:float)
		If fromAnimation = Null Throw New SpineArgumentNullException("from cannot be null.")
		If toAnimation = Null Throw New SpineArgumentNullException("to cannot be null.")
		
		If animationToMixTime = Null animationToMixTime = New SpineAnimationMap<SpineAnimationMap<FloatObject>>
		
		Local fromMap:= animationToMixTime.ValueForKey(fromAnimation)
		If fromMap = Null
			fromMap = New SpineAnimationMap<FloatObject>
			animationToMixTime.Insert(fromAnimation, fromMap)
		EndIf
		
		Local floatObject:= fromMap.ValueForKey(toAnimation)
		If floatObject
			'reuse old float object
			floatObject.value = duration
		Else
			'create new float object
			fromMap.Insert(toAnimation, New FloatObject(duration))
		EndIf
	End

	Method GetMix:float(fromAnimation:SpineAnimation, ToAnimation:SpineAnimation)
		If animationToMixTime = Null Return 0.0
		Local fromMap:= animationToMixTime.ValueForKey(fromAnimation)
		If fromMap = Null Return 0.0
		Local floatObject:= fromMap.ValueForKey(ToAnimation)
		If floatObject = Null Return 0.0
		Return floatObject.value
	End
End
