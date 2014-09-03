'see license.txt for source licenses
Strict

Import spine

Class SpineSkeletonJson
	Const TIMELINE_SCALE:String = "scale"
	Const TIMELINE_ROTATE:String = "rotate"
	Const TIMELINE_TRANSLATE:String = "translate"
	Const TIMELINE_ATTACHMENT:String = "attachment"
	Const TIMELINE_COLOR:String = "color"

	Const ATTACHMENT_REGION:String = "region"
	Const ATTACHMENT_REGION_SEQUENCE:String = "regionSequence"

	Private
	Field attachmentLoader:SpineAttachmentLoader
	Field fileLoader:SpineFileLoader
	Public
	Field Scale:float

	Method New(atlas:SpineAtlas = Null, fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance)
		If atlas = Null Throw New SpineArgumentNullException("atlas cannot be null.")
		If fileLoader = Null Throw New SpineArgumentNullException("file loader cannot be null.")
		
		'create atlas loader
		Self.attachmentLoader = New SpineAtlasAttachmentLoader(atlas)
		
		'save the loader objects
		Self.fileLoader = fileLoader
		
		'do some final setup
		Scale = 1.0
	End

	Method New(attachmentLoader:SpineAttachmentLoader, fileLoader:SpineFileLoader = SpineDefaultFileLoader.instance)
		If attachmentLoader = Null Throw New SpineArgumentNullException("attachment loader cannot be null.")
		If fileLoader = Null Throw New SpineArgumentNullException("file loader cannot be null.")
		
		'save the loader objects
		Self.attachmentLoader = attachmentLoader
		Self.fileLoader = fileLoader
		
		'do some final setup
		Scale = 1.0
	End

	Method ReadSkeletonData:SpineSkeletonData(path:String)
		' --- read skeleton data from json ---
		'use the file loader to do teh loading
		Local fileStream:= fileLoader.LoadFile(path)
		
		'read 
		Local skeletonData:SpineSkeletonData = New SpineSkeletonData
		skeletonData.Name = SpineExtractFilenameWithoutExtension(path)

		Local jsonRoot:= JSONObject(JSONData.ReadJSON(fileStream.ReadAll()))
		If jsonRoot = Null Throw New SpineException("Invalid JSON.")

		Local jsonGroupArray:JSONArray
		Local jsonGroupObject:JSONObject
		Local jsonName:String
		Local jsonObjectDataItem:JSONDataItem
		Local jsonObject:JSONObject
		Local jsonItem:JSONDataItem

		'bones
		Local boneParentData:SpineBoneData
		Local boneName:String
		Local boneData:SpineBoneData
		jsonGroupArray = JSONArray(jsonRoot.GetItem("bones"))
		If jsonGroupArray <> Null
			'iterate over bone objects
			For jsonObjectDataItem = EachIn jsonGroupArray
				'convert to correct format
				jsonObject = JSONObject(jsonObjectDataItem)
				If jsonObject = Null Continue
				
				'process this object
				boneParentData = Null
				
				jsonItem = jsonObject.GetItem("parent")
				If jsonItem <> Null
					boneName = jsonItem.ToString()
					boneParentData = skeletonData.FindBone(boneName)
					If boneParentData = Null Throw New SpineException("Parent not:bone found: " + boneName)
				EndIf
				
				boneData = New SpineBoneData(jsonObject.GetItem("name", ""), boneParentData)
				
				boneData.Length() = jsonObject.GetItem("length", 0.0) * Scale
				boneData.X = jsonObject.GetItem("x", 0.0) * Scale
				boneData.Y = jsonObject.GetItem("y", 0.0) * Scale
				boneData.Rotation = jsonObject.GetItem("rotation", 0.0)
				boneData.ScaleX = jsonObject.GetItem("scaleX", 1.0)
				boneData.ScaleY = jsonObject.GetItem("scaleY", 1.0)
				
				skeletonData.AddBone(boneData)
			Next
		EndIf

		'slots
		Local slotName:String
		Local slotData:SpineSlotData
		Local color:String
		jsonGroupArray = JSONArray(jsonRoot.GetItem("slots"))
		If jsonGroupArray <> Null
			'iterate over bone objects
			For jsonObjectDataItem = EachIn jsonGroupArray
				'convert to correct format
				jsonObject = JSONObject(jsonObjectDataItem)
				If jsonObject = Null Continue
				
				'process this object
				slotName = jsonObject.GetItem("name", "")
				boneName = jsonObject.GetItem("bone","")
				boneData = skeletonData.FindBone(boneName)
				
				If boneData = Null Throw New SpineException("SpineSlot not:bone found: " + boneName)
				slotData = New SpineSlotData(slotName, boneData)

				jsonItem = jsonObject.GetItem("color")
				If jsonItem <> Null
					color = jsonItem.ToString()
					slotData.R = ToColor(color, 0)
					slotData.G = ToColor(color, 1)
					slotData.B = ToColor(color, 2)
					slotData.A = ToColor(color, 3)
				EndIf

				jsonItem = jsonObject.GetItem("attachment")
				If jsonItem <> Null slotData.AttachmentName = jsonItem.ToString()

				skeletonData.AddSlot(slotData)
			Next
		EndIf

		'skins
		Local skin:SpineSkin
		Local skinName:String
		Local slotIndex:Int
		Local attachment:SpineAttachment
		Local attachmentName:String
		Local eventData:SpineEventData
		Local jsonSlot:JSONObject
		Local jsonAttachment:JSONObject
		
		'iterate over skins
		jsonGroupObject = JSONObject(jsonRoot.GetItem("skins"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.Names()
				'get skin from name
				jsonObject = JSONObject(jsonGroupObject.GetItem(jsonName))
				skin = New SpineSkin(jsonName)
				
				'iterate over slots in skin
				For slotName = EachIn jsonObject.Names()
					jsonSlot = JSONObject(jsonObject.GetItem(slotName))
					slotIndex = skeletonData.FindSlotIndex(slotName)
					
					'iterate over attachments in slot
					For attachmentName = EachIn jsonSlot.Names()
						jsonAttachment = JSONObject(jsonSlot.GetItem(attachmentName))
						
						attachment = ReadAttachment(skin, attachmentName, jsonAttachment)
						skin.AddAttachment(slotIndex, attachmentName, attachment)
					Next
				Next
				
				skeletonData.AddSkin(skin)
				If skin.Name = "default" skeletonData.DefaultSkin = skin
			Next
		EndIf
		
		'events
		jsonGroupObject = JSONObject(jsonRoot.GetItem("events"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.Names()
				'get event from name
				jsonObject = JSONObject(jsonGroupObject.GetItem(jsonName))
				eventData = New SpineEventData(jsonName)
				
				'add it
				skeletonData.AddEvent(eventData)
			Next
		EndIf		

		'animations.
		jsonGroupObject = JSONObject(jsonRoot.GetItem("animations"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.Names()
				'get animation from name
				jsonObject = JSONObject(jsonGroupObject.GetItem(jsonName))
				ReadAnimation(jsonName, jsonObject, skeletonData)
			Next
		EndIf

		skeletonData.TrimArrays()
		
		Return skeletonData
	End

	Method ReadAttachment:SpineAttachment(skin:SpineSkin, name:String, jsonAttachment:JSONObject)
		Local jsonItem:JSONDataItem
		
		jsonItem = jsonAttachment.GetItem("name")
		If jsonItem <> Null name = jsonItem.ToString()

		Local type:Int = SpineAttachmentType.region
		jsonItem = jsonAttachment.GetItem("type")
		If jsonItem <> Null type = SpineAttachmentType.FromString(jsonItem.ToString())

		Local attachment:SpineAttachment = attachmentLoader.NewAttachment(skin, type, name)

		Local regionAttachment:= SpineRegionAttachment(attachment)
		If regionAttachment
			regionAttachment.X = jsonAttachment.GetItem("x", 0.0) * Scale
			regionAttachment.Y = jsonAttachment.GetItem("y", 0.0) * Scale
			regionAttachment.ScaleX = jsonAttachment.GetItem("scaleX", 1.0)
			regionAttachment.ScaleY = jsonAttachment.GetItem("scaleY", 1.0)
			regionAttachment.Rotation = jsonAttachment.GetItem("rotation", 0.0)
			regionAttachment.Width = jsonAttachment.GetItem("width", 32.0) * Scale
			regionAttachment.Height = jsonAttachment.GetItem("height", 32.0) * Scale
			regionAttachment.UpdateOffset()
		EndIf

		return attachment
	End

	Function ToColor:float(hex:String, colorIndex:int)
		If hex.Length() <> 8 Throw New SpineArgumentNullException("Color hexidecimal length must be 8, recieved: " + hex)
		
		Local val:Int = 0
		Local offset:Int = colorIndex * 2
		hex = hex.ToUpper()
		For Local i:Int = offset Until offset + 2
			val *=16	
			If hex[i] >= 48 And hex[i] <= 57
				val += (hex[i] - 48)
			Else
				val += (hex[i] - 55)
			Endif
			
		Next
		Return val / 255.0
	End

	Private
	Method ReadAnimation:Void(name:String, jsonAnimation:JSONObject, skeletonData:SpineSkeletonData)
		Local timelines:SpineTimeline[]
		Local timelineCount:Int

		Local duration:float = 0.0

		Local index:Int
		Local jsonGroupObject:JSONObject
		Local jsonGroupArray:JSONArray
		Local jsonBone:JSONObject
		Local jsonTimeline:JSONArray
		Local jsonTimelineFrameDataItem:JSONDataItem
		Local jsonTimelineFrame:JSONObject
		Local boneName:String
		Local boneIndex:Int
		Local timelineName:String
		Local frameIndex:Int
		Local timelineScale:float
		
		jsonGroupObject = JSONObject(jsonAnimation.GetItem("bones"))
		If jsonGroupObject <> Null
			For boneName = EachIn jsonGroupObject.Names()
				jsonBone = JSONObject(jsonGroupObject.GetItem(boneName))
				If jsonBone = Null Continue
				
				boneIndex = skeletonData.FindBoneIndex(boneName)
				If boneIndex = -1 Throw New SpineException("SpineBone not found: " + boneName)
				
				For timelineName = EachIn jsonBone.Names()
					jsonTimeline = JSONArray(jsonBone.GetItem(timelineName))
					If jsonTimeline = Null Continue
					
					Select timelineName
						Case TIMELINE_ROTATE
							Local timeline:SpineRotateTimeline = New SpineRotateTimeline(jsonTimeline.values.Count())
							timeline.BoneIndex = boneIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("angle", 0.0))
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
								frameIndex += 1
							Next
							
							'add timeline (maybe resize array)
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
		
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 2 - 2])
							
						Case TIMELINE_TRANSLATE, TIMELINE_SCALE
							Local timeline:SpineTranslateTimeline
							timelineScale = 1.0
							
							If timelineName = TIMELINE_SCALE
								timeline = New SpineScaleTimeline(jsonTimeline.values.Count())
							Else
								timeline = New SpineTranslateTimeline(jsonTimeline.values.Count())
								timelineScale = Scale
							EndIf
							timeline.BoneIndex = boneIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("x", 0.0) * timelineScale, jsonTimelineFrame.GetItem("y", 0.0) * timelineScale)
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
								frameIndex += 1
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 3 - 3])
						Default
							Throw New SpineException("Invalid type:timeline for a bone: " + timelineName + " (" + boneName + ")")
					End
				Next
			Next
		EndIf
		
		'slots
		Local slotName:String
		Local slotIndex:Int
		Local jsonSlot:JSONObject
		Local color:string
		
		jsonGroupObject = JSONObject(jsonAnimation.GetItem("slots"))
		If jsonGroupObject <> Null
			For slotName = EachIn jsonGroupObject.Names()
				jsonSlot = JSONObject(jsonGroupObject.GetItem(slotName))
				If jsonSlot = Null Continue
			
				slotIndex = skeletonData.FindSlotIndex(slotName)
				
				For timelineName = EachIn jsonSlot.Names()
					jsonTimeline = JSONArray(jsonSlot.GetItem(timelineName))
				
					Select timelineName
						Case TIMELINE_COLOR
							Local timeline:SpineColorTimeline = New SpineColorTimeline(jsonTimeline.values.Count())
							timeline.SlotIndex = slotIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								color = jsonTimelineFrame.GetItem("color", "")
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), ToColor(color, 0), ToColor(color, 1), ToColor(color, 2), ToColor(color, 3))
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
								frameIndex += 1
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 5 - 5])
							
						Case TIMELINE_ATTACHMENT
							Local timeline:SpineAttachmentTimeline = New SpineAttachmentTimeline(jsonTimeline.values.Count())
							timeline.SlotIndex = slotIndex
	
							frameIndex = 0
							For jsonTimelineFrameDataItem = EachIn jsonTimeline
								'convert to correct object format
								jsonTimelineFrame = JSONObject(jsonTimelineFrameDataItem)
								
								'process object
								timeline.SetFrame(frameIndex, jsonTimelineFrame.GetItem("time", 0.0), jsonTimelineFrame.GetItem("name", ""))
								frameIndex += 1
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
						Default
							Throw New SpineException("Invalid type:timeline for a slot: " + timelineName + " (" + slotName + ")")
					End
					
				Next
			Next
		EndIf
		
		'events
		Local eventName:String
		Local jsonEvent:JSONObject
		Local event:SpineEvent
		Local eventData:SpineEventData
		Local eventIndex:Int
		
		jsonGroupArray = JSONArray(jsonAnimation.GetItem("events"))
		If jsonGroupArray <> Null
			Local timeline:SpineEventTimeline = New SpineEventTimeline(jsonGroupArray.values.Count())
			frameIndex = 0
			
			For jsonTimelineFrameDataItem = EachIn jsonGroupArray
				jsonEvent = JSONObject(jsonTimelineFrameDataItem)
				
				'lookup the event
				eventName = jsonEvent.GetItem("name")
				eventIndex = skeletonData.FindEventIndex(eventName)
				If eventIndex = -1 Throw New SpineException("Event not found: " + eventName)
				
				'get teh event default data
				eventData = skeletonData.Events[eventIndex]
				
				'create new event
				event = New SpineEvent(eventData)
				event.IntValue = jsonEvent.GetItem("int", eventData.GetInt())
				event.FloatValue = jsonEvent.GetItem("float", eventData.GetFloat())
				event.StringValue = jsonEvent.GetItem("string", eventData.GetString())
				
				'process frame in timeline
				timeline.SetFrame(frameIndex, jsonEvent.GetItem("time", 0.0), event)
				
				'next frame index
				frameIndex += 1
			Next
			
			'add timeline
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
			
			'update duration
			duration = Max(duration, timeline.GetFrames()[timeline.FrameCount() -1])
		EndIf

		'draw order
		Local jsonOrder:JSONObject
		Local jsonOffsetDataItem:JSONDataItem
		Local jsonOffsetArray:JSONArray
		Local jsonOffsetTotal:Int
		Local jsonOffset:JSONObject
		Local originalIndex:Int
		Local unchangedIndex:Int
		Local offset:Int
		
		jsonGroupArray = JSONArray(jsonAnimation.GetItem("draworder"))
		If jsonGroupArray <> Null
			'get slot count 
			'we get it from the count value as we are still reading json data
			'if we use teh array size then the code below will use teh size of the unfilled array elements
			Local slotsCount:= skeletonData.slotsCount
			
			'create this new timeline
			Local timeline:SpineDrawOrderTimeline = New SpineDrawOrderTimeline(jsonGroupArray.values.Count())
			frameIndex = 0
			
			'iterate over frame keys
			For jsonTimelineFrameDataItem = EachIn jsonGroupArray
				jsonOrder = JSONObject(jsonTimelineFrameDataItem)
				
				'get the offset array
				jsonOffsetArray = JSONArray(jsonOrder.GetItem("offsets"))
				jsonOffsetTotal = jsonOffsetArray.values.Count()
				
				'create draw order array and reset it
				Local drawOrder:= New int[slotsCount]
				For slotIndex = slotsCount - 1 To 0 Step - 1
					drawOrder[slotIndex] = -1;
				Next
				
				'create unchanged array				
				Local unchanged:= New Int[slotsCount - jsonOffsetTotal]
				
				originalIndex = 0
				unchangedIndex = 0
				
				'iterate over offsets
				For jsonOffsetDataItem = EachIn jsonOffsetArray
					jsonOffset = JSONObject(jsonOffsetDataItem)
				
					'get slot index
					slotName = jsonOffset.GetItem("slot")
					slotIndex = skeletonData.FindSlotIndex(slotName)
					
					'check slot is valid
					If slotIndex = -1 Throw New SpineException("Slot not found: " + slotName);
										
					'collect unchanges items
					While originalIndex <> slotIndex
						unchanged[unchangedIndex] = originalIndex
						unchangedIndex += 1
						originalIndex += 1
					Wend
					
					'get offset
					offset = jsonOffset.GetItem("offset", 0)
					
					'set changed items
					drawOrder[originalIndex + offset] = originalIndex
					originalIndex += 1
				Next
				
				'collect remaining unchanged items
				While originalIndex < slotsCount
					unchanged[unchangedIndex] = originalIndex
					unchangedIndex += 1
					originalIndex += 1
				Wend
				
				'fill unchanged items
				For index = slotsCount - 1 To 0 Step - 1
					If drawOrder[index] = -1
						unchangedIndex -= 1
						drawOrder[index] = unchanged[unchangedIndex]
					EndIf
				Next
				
				'process frame in timeline
				timeline.SetFrame(frameIndex, jsonOrder.GetItem("time", 0.0), drawOrder)
				
				'next frame index
				frameIndex += 1
			Next
			
			'add timeline
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
			
			'update duration
			duration = Max(duration, timeline.GetFrames()[timeline.FrameCount() -1])
		EndIf

		'trim timeline
		If timelineCount < timelines.Length() timelines = timelines.Resize(timelineCount)
		
		skeletonData.AddAnimation(new SpineAnimation(name, timelines, duration))
	End

	Method ReadCurve:Void(timeline:SpineCurveTimeline, frameIndex:int, jsonTimelineFrame:JSONObject)
		Local jsonItem:JSONDataItem
		
		jsonItem = jsonTimelineFrame.GetItem("curve")
		If jsonItem = Null Return
		
		Local jsonArray:JSONArray = JSONArray(jsonItem)
		If jsonArray <> Null
			'bezier curve
			Local curve:= jsonArray.values.ToArray()
			timeline.SetCurve(frameIndex, float(curve[0]), float(curve[1]), float(curve[2]), float(curve[3]))
		Else
			'named curve
			Select jsonItem.ToString()
				Case "stepped"
					timeline.SetStepped(frameIndex)
				Default
					'linear
			End
		EndIf
	End
End
