'see license.txt For source licenses
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
	Field file:SpineFile
	Public
	Field Scale:Float

	Method New(atlas:SpineAtlas, file:SpineFile)
		If file = Null Throw New SpineArgumentNullException("file loader cannot be Null.")
		
		'save the loader objects
		Self.attachmentLoader = New SpineAtlasAttachmentLoader(atlas)
		Self.file = file
		
		'do some final setup
		Scale = 1.0
	End
	
	Method ReadSkeletonData:SpineSkeletonData()
		'read
		Local skeletonData:SpineSkeletonData = New SpineSkeletonData
		skeletonData.Name = SpineExtractFilenameWithoutExtension(file.path)

		Local jsonRoot:= JsonObject(file.ReadAll())
		If jsonRoot = Null Throw New SpineException("Invalid JSON.")

		Local jsonGroupArray:JsonArray
		Local jsonGroupObject:JsonObject
		Local jsonGroupIndex:Int
		Local jsonName:String
		Local jsonObject:JsonObject
		Local jsonItem:JsonValue
		Local jsonChildArray:JsonArray
		Local jsonChildIndex:Int
		
		Local boneName:String
		Local boneData:SpineBoneData
		
		'Skeleton.
		jsonItem = jsonRoot.Get("skeleton")
		If jsonItem <> Null
			jsonObject = JsonObject(jsonItem)
			skeletonData.Hash = GetJsonString(jsonObject, "hash", "")
			skeletonData.Version = GetJsonString(jsonObject, "version", "")
			skeletonData.Width = GetJsonFloat(jsonObject, "width", 0.0)
			skeletonData.Height = GetJsonFloat(jsonObject, "height", 0.0)
		EndIf
		
		'Bones.
		jsonGroupArray = JsonArray(jsonRoot.Get("bones"))
		If jsonGroupArray <> Null
			Local boneParentData:SpineBoneData
			
			'iterate over bone objects
			For jsonGroupIndex = 0 Until jsonGroupArray.Length
				jsonObject = JsonObject(jsonGroupArray.Get(jsonGroupIndex))
				If jsonObject = Null Continue
				
				boneParentData = Null
				
				jsonItem = jsonObject.Get("parent");
				If jsonItem <> Null
					boneName = jsonItem.StringValue()
					boneParentData = skeletonData.FindBone(boneName)
					If boneParentData = Null Throw New SpineException("Parent not:bone found: " + boneName)
				EndIf
				
				boneData = New SpineBoneData(GetJsonString(jsonObject, "name", ""), boneParentData)
				boneData.Length = GetJsonFloat(jsonObject, "length", 0.0) * Scale
				boneData.X = GetJsonFloat(jsonObject, "x", 0.0) * Scale
				boneData.Y = GetJsonFloat(jsonObject, "y", 0.0) * Scale
				boneData.Rotation = GetJsonFloat(jsonObject, "rotation", 0.0)
				boneData.ScaleX = GetJsonFloat(jsonObject, "scaleX", 1.0)
				boneData.ScaleY = GetJsonFloat(jsonObject, "scaleY", 1.0)
				boneData.InheritScale = GetJsonBool(jsonObject, "inheritScale", True)
				boneData.InheritRotation = GetJsonBool(jsonObject, "inheirtRotation", True)
				skeletonData.AddBone(boneData)
			Next
		EndIf

		'IK constraints.
		jsonGroupArray = JsonArray(jsonRoot.Get("ik"))
		If jsonGroupArray <> Null
			Local ikConstraintData:SpineIkConstraintData
			Local targetName:String
			
			Local bones:SpineBoneData[10]
			Local bonesCount:Int
			
			For jsonGroupIndex = 0 Until jsonGroupArray.Length
				jsonObject = JsonObject(jsonGroupArray.Get(jsonGroupIndex))
				If jsonObject = Null Continue
				
				ikConstraintData = New SpineIkConstraintData(GetJsonString(jsonObject, "name", ""))
							
				jsonChildArray = JsonArray(jsonObject.Get("bones"))
				bonesCount = 0
				If jsonChildArray <> Null
					For jsonChildIndex = 0 Until jsonChildArray.Length
						boneName = jsonChildArray.Get(jsonChildIndex).StringValue()

						boneData = skeletonData.FindBone(boneName)
						If boneData = Null Throw New SpineException("IK bone found: " + boneName)
						
						If bonesCount = bones.Length() bones = bones.Resize(bonesCount * 2 + 10)
						bones[bonesCount] = boneData
						bonesCount += 1
					Next
				EndIf
				
				If bonesCount > 0 ikConstraintData.Bones = bones[ .. bonesCount]
			
				targetName = GetJsonString(jsonObject, "target", "")
				ikConstraintData.Target = skeletonData.FindBone(targetName)
				If ikConstraintData.Target = Null Throw New SpineException("Target bone not found: " + targetName)
				
				'ikConstraintData.bendDirection = GetBoolean(ikMap, "bendPositive", True) ? 1 : -1
				If GetJsonBool(jsonObject, "bendPositive", True)
					ikConstraintData.BendDirection = 1
				Else
					ikConstraintData.BendDirection = -1
				EndIf
				skeletonData.AddIkConstraint(ikConstraintData)
			Next
		EndIf
		
		'slots
		Local slotName:String
		Local slotData:SpineSlotData
		Local color:String
		jsonGroupArray = JsonArray(jsonRoot.Get("slots"))
		If jsonGroupArray <> Null
			'iterate over bone objects
			For jsonGroupIndex = 0 Until jsonGroupArray.Length
				jsonObject = JsonObject(jsonGroupArray.Get(jsonGroupIndex))
				If jsonObject = Null Continue
				
				'process this object
				slotName = GetJsonString(jsonObject, "name", "")
				boneName = GetJsonString(jsonObject, "bone", "")
				boneData = skeletonData.FindBone(boneName)
				
				If boneData = Null Throw New SpineException("Slot bone not found: " + boneName)
				slotData = New SpineSlotData(slotName, boneData)

				jsonItem = jsonObject.Get("color")
				If jsonItem <> Null
					color = jsonItem.StringValue()
					slotData.R = ParseHexColor(color, 0)
					slotData.G = ParseHexColor(color, 1)
					slotData.B = ParseHexColor(color, 2)
					slotData.A = ParseHexColor(color, 3)
				EndIf

				jsonItem = jsonObject.Get("attachment")
				If jsonItem <> Null
					slotData.AttachmentName = jsonItem.StringValue()
				EndIf
				
				jsonItem = jsonObject.Get("additive")
				If jsonItem <> Null
					slotData.AdditiveBlending = jsonItem.BoolValue()
				EndIf

				skeletonData.AddSlot(slotData)
			Next
		EndIf

		'skins
		Local skin:SpineSkin
		Local slotIndex:Int
		Local attachment:SpineAttachment
		Local attachmentName:String
		Local eventData:SpineEventData
		Local jsonSlot:JsonObject
		Local jsonAttachment:JsonObject
		
		'iterate over skins
		jsonGroupObject = JsonObject(jsonRoot.Get("skins"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.GetData().Keys()
				'get skin from name
				jsonObject = JsonObject(jsonGroupObject.Get(jsonName))
				skin = New SpineSkin(jsonName)
				
				'iterate over slots in skin
				For slotName = EachIn jsonObject.GetData().Keys()
					jsonSlot = JsonObject(jsonObject.Get(slotName))
					slotIndex = skeletonData.FindSlotIndex(slotName)
					
					'iterate over attachments in slot
					For attachmentName = EachIn jsonSlot.GetData().Keys()
						jsonAttachment = JsonObject(jsonSlot.Get(attachmentName))
						
						attachment = ReadAttachment(skin, attachmentName, jsonAttachment)
						skin.AddAttachment(slotIndex, attachmentName, attachment)
					Next
				Next
				
				skeletonData.AddSkin(skin)
				If skin.Name = "default" skeletonData.DefaultSkin = skin
			Next
		EndIf
		
		'events
		jsonGroupObject = JsonObject(jsonRoot.Get("events"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.GetData().Keys()
				'get event from name
				jsonObject = JsonObject(jsonGroupObject.Get(jsonName))
				eventData = New SpineEventData(jsonName)
				eventData.IntValue = GetJsonInt(jsonObject, "int", 0)
				eventData.FloatValue = GetJsonFloat(jsonObject, "float", 0.0)
				eventData.StringValue = GetJsonString(jsonObject, "string", "")
				
				'add it
				skeletonData.AddEvent(eventData)
			Next
		EndIf

		'animations.
		jsonGroupObject = JsonObject(jsonRoot.Get("animations"))
		If jsonGroupObject <> Null
			For jsonName = EachIn jsonGroupObject.GetData().Keys()
				'get animation from name
				jsonObject = JsonObject(jsonGroupObject.Get(jsonName))
				ReadAnimation(jsonName, jsonObject, skeletonData)
			Next
		EndIf

		skeletonData.TrimArrays()
		
		Return skeletonData
	End

	Method ReadAttachment:SpineAttachment(skin:SpineSkin, name:String, jsonAttachment:JsonObject)
		Local jsonItem:JsonValue
		Local color:String
		
		jsonItem = jsonAttachment.Get("name")
		If jsonItem <> Null name = jsonItem.StringValue()

		Local type:Int = SpineAttachmentType.Region'defaults to region aiiighhht
		jsonItem = jsonAttachment.Get("type")
		If jsonItem <> Null type = SpineAttachmentType.FromString(jsonItem.StringValue())

		Local path:String = name
		jsonItem = jsonAttachment.Get("path")
		If jsonItem <> Null path = jsonItem.StringValue()

		Select type
			Case SpineAttachmentType.Region
				Local region:SpineRegionAttachment = attachmentLoader.NewRegionAttachment(skin, name, path)
				If region = Null
					Return Null
				EndIf
				
				region.Path = path
				region.X = GetJsonFloat(jsonAttachment, "x", 0.0) * Scale
				region.Y = GetJsonFloat(jsonAttachment, "y", 0.0) * Scale
				region.ScaleX = GetJsonFloat(jsonAttachment, "scaleX", 1.0)
				region.ScaleY = GetJsonFloat(jsonAttachment, "scaleY", 1.0)
				region.Rotation = GetJsonFloat(jsonAttachment, "rotation", 0.0)
				region.Width = GetJsonFloat(jsonAttachment, "width", 32.0) * Scale
				region.Height = GetJsonFloat(jsonAttachment, "height", 32.0) * Scale
				region.UpdateOffset()
				
				jsonItem = jsonAttachment.Get("color")
				If jsonItem <> Null
					color = jsonItem.StringValue()
					region.R = ParseHexColor(color, 0)
					region.G = ParseHexColor(color, 1)
					region.B = ParseHexColor(color, 2)
					region.A = ParseHexColor(color, 3)
				EndIf
				
				Return region
				
			Case SpineAttachmentType.Mesh
				Local mesh:SpineMeshAttachment = attachmentLoader.NewMeshAttachment(skin, name, path)
				If mesh = Null
					Return Null
				EndIf
				
				mesh.Path = path
				mesh.Vertices = GetJsonFloatArray(jsonAttachment, "vertices", Scale)
				mesh.Triangles = GetJsonIntArray(jsonAttachment, "triangles")
				mesh.RegionUVs = GetJsonFloatArray(jsonAttachment, "uvs", 1.0)
				mesh.UpdateUVs()
				
				jsonItem = jsonAttachment.Get("color")
				If jsonItem <> Null
					color = jsonItem.StringValue()
					mesh.R = ParseHexColor(color, 0)
					mesh.G = ParseHexColor(color, 1)
					mesh.B = ParseHexColor(color, 2)
					mesh.A = ParseHexColor(color, 3)
				EndIf
				
				mesh.HullLength = GetJsonFloat(jsonAttachment, "hull", 0) * 2
				
				jsonItem = jsonAttachment.Get("edges")
				If jsonItem <> Null mesh.Edges = GetJsonIntArray(jsonAttachment, "edges")
				
				mesh.Width = GetJsonFloat(jsonAttachment, "width", 0.0) * Scale
				mesh.Height = GetJsonFloat(jsonAttachment, "height", 0.0) * Scale
				
				Return mesh
				
			Case SpineAttachmentType.SkinnedMesh
				Local mesh:SpineSkinnedMeshAttachment = attachmentLoader.NewSkinnedMeshAttachment(skin, name, path)
				If mesh = Null
					Return Null
				EndIf
				
				mesh.Path = path
				Local uvs:= GetJsonFloatArray(jsonAttachment, "uvs", 1.0)
				
				Local vertices:= GetJsonFloatArray(jsonAttachment, "vertices", 1.0)'1.0...Should this be Scale ???
				Local verticesCount:= vertices.Length()
				Local bonesCount:Int
				Local meshBonesCount:Int
				Local meshWeightsCount:Int
				Local i:Int
				Local nn:Int
				
				i = 0
				While i < verticesCount
					bonesCount = vertices[i]
					meshBonesCount += bonesCount + 1
					meshWeightsCount += bonesCount * 3
					i += 1 + bonesCount * 4
				Wend
				
				Local bones:Int[meshBonesCount]
				Local weights:Float[meshWeightsCount]
				Local b:Int
				Local w:Int
				
				i = 0
				While i < verticesCount
					bonesCount = vertices[i]
					i += 1
					
					bones[b] = bonesCount
					b += 1
					
					nn = i + bonesCount * 4
					While i < nn
						bones[b] = vertices[i]
						
						weights[w] = vertices[i + 1] * Scale
						weights[w + 1] = vertices[i + 2] * Scale
						weights[w + 2] = vertices[i + 3]
						
						i += 4
						b += 1
						w += 3
					Wend
				Wend
				
				mesh.Bones = bones
				mesh.Weights = weights
				mesh.Triangles = GetJsonIntArray(jsonAttachment, "triangles")
				mesh.RegionUVs = uvs
				mesh.UpdateUVs()
				
				jsonItem = jsonAttachment.Get("color")
				If jsonItem <> Null
					color = jsonItem.StringValue()
					mesh.R = ParseHexColor(color, 0)
					mesh.G = ParseHexColor(color, 1)
					mesh.B = ParseHexColor(color, 2)
					mesh.A = ParseHexColor(color, 3)
				EndIf
				
				mesh.HullLength = GetJsonInt(jsonAttachment, "hull", 0) * 2
				
				jsonItem = jsonAttachment.Get("edges")
				If jsonItem <> Null mesh.Edges = GetJsonIntArray(jsonAttachment, "edges")
				
				mesh.Width = GetJsonFloat(jsonAttachment, "width", 0.0) * Scale
				mesh.Height = GetJsonFloat(jsonAttachment, "height", 0.0) * Scale
				
				Return mesh
				
			Case SpineAttachmentType.BoundingBox
				Local box:SpineBoundingBoxAttachment = attachmentLoader.NewBoundingBoxAttachment(skin, name)
				If box = Null
					Return Null
				EndIf
				
				box.Vertices = GetJsonFloatArray(jsonAttachment, "vertices", Scale)
				Return box
		End

		Return Null
	End
	
	Method GetJsonFloatArray:Float[] (jsonObject:JsonObject, name:String, scale:Float)
		Local list:= JsonArray(jsonObject.Get(name))
		If list = Null Return[]
		
		Local values:Float[list.Length()]
		If scale = 1.0
			Local listItem:JsonValue
			For Local listIndex:= 0 Until list.Length()
				listItem = list.Get(listIndex)
				values[listIndex] = listItem.FloatValue()
			Next
		Else
			Local listItem:JsonValue
			For Local listIndex:= 0 Until list.Length()
				listItem = list.Get(listIndex)
				values[listIndex] = listItem.FloatValue() * scale
			Next
		EndIf
		Return values
	End
	
	Method GetJsonIntArray:Int[] (jsonObject:JsonObject, name:String)
		Local list:= JsonArray(jsonObject.Get(name))
		If list = Null Return[]
		
		Local values:Int[list.Length()]
		
		Local listItem:JsonValue
		For Local listIndex:= 0 Until list.Length()
			listItem = list.Get(listIndex)
			values[listIndex] = listItem.IntValue()
		Next
		
		Return values
	End
	
	Method GetJsonBool:Bool(jsonObject:JsonObject, name:String, value:Bool = False)
		Local jsonValue:= JsonBool(jsonObject.Get(name))
		If jsonValue = Null
			Return value
		EndIf
		Return jsonValue.BoolValue()
	End
	
	Method GetJsonInt:Int(jsonObject:JsonObject, name:String, value:int = 0)
		Local jsonValue:= JsonNumber(jsonObject.Get(name))
		If jsonValue = Null
			Return value
		EndIf
		Return jsonValue.IntValue()
	End
	
	Method GetJsonFloat:Float(jsonObject:JsonObject, name:String, value:Float = 0.0)
		Local jsonValue:= JsonNumber(jsonObject.Get(name))
		If jsonValue = Null
			Return value
		EndIf
		Return jsonValue.FloatValue()
	End
	
	Method GetJsonString:String(jsonObject:JsonObject, name:String, value:String = "")
		Local jsonValue:= JsonString(jsonObject.Get(name))
		If jsonValue = Null
			Return value
		EndIf
		Return jsonValue.StringValue()
	End
	
	Function ParseHexColor:Float(hex:String, colorIndex:Int)
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
			EndIf
			
		Next
		Return val / 255.0
	End

	Private
	Method ReadAnimation:Void(name:String, jsonAnimation:JsonObject, skeletonData:SpineSkeletonData)
		Local timelines:SpineTimeline[]
		Local timelineCount:Int

		Local duration:Float = 0.0

		Local index:Int
		Local jsonGroupObject:JsonObject
		Local jsonGroupArray:JsonArray
		Local jsonBone:JsonObject
		Local jsonTimeline:JsonArray
		Local jsonTimelineFrame:JsonObject
		Local boneName:String
		Local boneIndex:Int
		Local timelineName:String
		Local frameIndex:Int
		Local timelineScale:Float
		Local slotIndex:Int
		Local slotName:String
		
		'slots
		jsonGroupObject = JsonObject(jsonAnimation.Get("slots"))
		If jsonGroupObject <> Null
			Local jsonSlot:JsonObject
			Local c:String
			
			For slotName = EachIn jsonGroupObject.GetData().Keys()
				jsonSlot = JsonObject(jsonGroupObject.Get(slotName))
				If jsonSlot = Null Continue
			
				slotIndex = skeletonData.FindSlotIndex(slotName)
				
				For timelineName = EachIn jsonSlot.GetData().Keys()
					jsonTimeline = JsonArray(jsonSlot.Get(timelineName))
				
					Select timelineName
						Case TIMELINE_COLOR
							Local timeline:SpineColorTimeline = New SpineColorTimeline(jsonTimeline.Length())
							timeline.SlotIndex = slotIndex
	
							For frameIndex = 0 Until jsonTimeline.Length()
								'convert to correct object format
								jsonTimelineFrame = JsonObject(jsonTimeline.Get(frameIndex))
								
								'process object
								c = GetJsonString(jsonTimelineFrame, "color", "")
								timeline.SetFrame(frameIndex, GetJsonFloat(jsonTimelineFrame, "time", 0.0), ParseHexColor(c, 0), ParseHexColor(c, 1), ParseHexColor(c, 2), ParseHexColor(c, 3))
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 5 - 5])
							
						Case TIMELINE_ATTACHMENT
							Local timeline:SpineAttachmentTimeline = New SpineAttachmentTimeline(jsonTimeline.Length())
							timeline.SlotIndex = slotIndex
	
							For frameIndex = 0 Until jsonTimeline.Length()
								'convert to correct object format
								jsonTimelineFrame = JsonObject(jsonTimeline.Get(frameIndex))
								
								'process object
								timeline.SetFrame(frameIndex, GetJsonFloat(jsonTimelineFrame, "time", 0.0), GetJsonString(jsonTimelineFrame, "name", ""))
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
						Default
							Throw New SpineException("Invalid type:timeline For a slot: " + timelineName + " (" + slotName + ")")
					End
					
				Next
			Next
		EndIf
		
		'bones
		jsonGroupObject = JsonObject(jsonAnimation.Get("bones"))
		If jsonGroupObject <> Null
			For boneName = EachIn jsonGroupObject.GetData().Keys()
				jsonBone = JsonObject(jsonGroupObject.Get(boneName))
				If jsonBone = Null Continue
				
				boneIndex = skeletonData.FindBoneIndex(boneName)
				If boneIndex = -1 Throw New SpineException("Bone not found: " + boneName)
				
				For timelineName = EachIn jsonBone.GetData().Keys()
					jsonTimeline = JsonArray(jsonBone.Get(timelineName))
					If jsonTimeline = Null Continue
					
					Select timelineName
						Case TIMELINE_ROTATE
							Local timeline:SpineRotateTimeline = New SpineRotateTimeline(jsonTimeline.Length())
							timeline.BoneIndex = boneIndex
	
							For frameIndex = 0 Until jsonTimeline.Length()
								'convert to correct object format
								jsonTimelineFrame = JsonObject(jsonTimeline.Get(frameIndex))
								
								'process object
								timeline.SetFrame(frameIndex, GetJsonFloat(jsonTimelineFrame, "time", 0.0), GetJsonFloat(jsonTimelineFrame, "angle", 0.0))
								Print "got here"
								If name = "hit" And boneName = "front_thigh" And timelineName = "rotate"
									'DebugStop()
								EndIf
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
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
								timeline = New SpineScaleTimeline(jsonTimeline.Length())
							Else
								timeline = New SpineTranslateTimeline(jsonTimeline.Length())
								timelineScale = Scale
							EndIf
							timeline.BoneIndex = boneIndex
	
							For frameIndex = 0 Until jsonTimeline.Length()
								'convert to correct object format
								jsonTimelineFrame = JsonObject(jsonTimeline.Get(frameIndex))
								
								'process object
								timeline.SetFrame(frameIndex, GetJsonFloat(jsonTimelineFrame, "time", 0.0), GetJsonFloat(jsonTimelineFrame, "x", 0.0) * timelineScale, GetJsonFloat(jsonTimelineFrame, "y", 0.0) * timelineScale)
								ReadCurve(timeline, frameIndex, jsonTimelineFrame)
							Next
							
							If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
							timelines[timelineCount] = timeline
							timelineCount += 1
							
							duration = Max(duration, timeline.Frames[timeline.FrameCount() * 3 - 3])
						Default
							Throw New SpineException("Invalid type:timeline For a bone: " + timelineName + " (" + boneName + ")")
					End
				Next
			Next
		EndIf
		
		'ik
		jsonGroupArray = JsonArray(jsonAnimation.Get("ik"))
		If jsonGroupArray <> Null
			Local jsonIkConstraint:JsonObject
			Local bendPositive:Int

			Local timeline:SpineIkConstraintTimeline = New SpineIkConstraintTimeline(jsonGroupArray.Length())

			For frameIndex = 0 Until jsonTimeline.Length()
				'convert to correct object format
				jsonIkConstraint = JsonObject(jsonTimeline.Get(frameIndex))
				
				If GetJsonBool(jsonTimelineFrame, "bendPositive", True)
					bendPositive = 1
				Else
					bendPositive = -1
				EndIf
				
				timeline.SetFrame(frameIndex, GetJsonFloat(jsonTimelineFrame, "time", 0.0), GetJsonFloat(jsonTimelineFrame, "mix", 1.0), bendPositive)
				ReadCurve(timeline, frameIndex, jsonTimelineFrame)
			Next
			
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
							
			duration = Max(duration, timeline.Frames[timeline.FrameCount() * 3 - 3])
		EndIf
		
		'ffd
		jsonGroupObject = JsonObject(jsonAnimation.Get("ffd"))
		If jsonGroupObject <> Null
			Local skin:SpineSkin
			Local jsonFfdGroup:JsonObject
			Local jsonSlotGroup:JsonObject
			Local jsonMeshArray:JsonArray
			Local jsonMesh:JsonObject
			Local jsonMeshVertices:JsonArray
			Local jsonMeshVerticesItem:JsonValue
			Local slotKey:String
			Local meshKey:String
			Local timeline:SpineFFDTimeline
			Local attachment:SpineAttachment
			Local vertexCount:Int
			Local vertices:Float[]
			Local start:Int
			Local i:Int
			
			For Local ffdKey:String = EachIn jsonGroupObject.GetData().Keys()
				jsonFfdGroup = JsonObject(jsonGroupObject.Get(ffdKey))
				If jsonFfdGroup = Null Continue
				
				skin = skeletonData.FindSkin(ffdKey)
				
				For slotKey = EachIn jsonFfdGroup.GetData().Keys()
					jsonSlotGroup = JsonObject(jsonFfdGroup.Get(slotKey))
					If jsonSlotGroup = Null Continue
					
					slotIndex = skeletonData.FindSlotIndex(slotKey)
					
					For meshKey = EachIn jsonSlotGroup.GetData().Keys()
						jsonMeshArray = JsonArray(jsonSlotGroup.Get(meshKey))
						
						attachment = skin.GetAttachment(slotIndex, meshKey)
						If attachment = Null Throw New SpineException("FFD attachment not found: " + meshKey)
						
						timeline = New SpineFFDTimeline(jsonMeshArray.Length())
						timeline.SlotIndex = slotIndex
						timeline.Attachment = attachment
						
						If attachment.Type = SpineAttachmentType.Mesh
							vertexCount = SpineMeshAttachment(attachment).Vertices.Length()
						Else
							vertexCount = SpineSkinnedMeshAttachment(attachment).Weights.Length() / 3 * 2
						EndIf
						
						For frameIndex = 0 Until jsonMeshArray.Length()
							jsonMesh = JsonObject(jsonMeshArray.Get(frameIndex))
							
							jsonMeshVertices = JsonArray(jsonMesh.Get("vertices"))
							If jsonMeshVertices = Null
								If attachment.Type = SpineAttachmentType.Mesh
									vertices = SpineMeshAttachment(attachment).Vertices
								Else
									vertices = New Float[vertexCount]
								EndIf
							Else
								vertices = New Float[vertexCount]
								start = GetJsonInt(jsonMesh, "offset", 0)
								
								If Scale = 1.0
									For i = 0 Until jsonMeshVertices.Length()
										jsonMeshVerticesItem = jsonMeshVertices.Get(i)
										vertices[i + start] = jsonMeshVerticesItem.FloatValue()
									Next
								Else
									For i = 0 Until jsonMeshVertices.Length()
										jsonMeshVerticesItem = jsonMeshVertices.Get(i)
										vertices[i + start] = jsonMeshVerticesItem.FloatValue() * Scale
									Next
								EndIf
								
								If attachment.Type = SpineAttachmentType.Mesh
									Local meshVertices:= SpineMeshAttachment(attachment).Vertices
									For i = 0 Until vertexCount
										vertices[i] += meshVertices[i]
									Next
								EndIf
							EndIf
							
							timeline.SetFrame(frameIndex, GetJsonFloat(jsonMesh, "time", 0.0), vertices)
							ReadCurve(timeline, frameIndex, jsonMesh)
						Next
						
						If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
						timelines[timelineCount] = timeline
						timelineCount += 1
							
						duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
					Next
				Next
			Next
		EndIf
		
		'draw order
		jsonGroupArray = JsonArray(jsonAnimation.Get("draworder"))
		If jsonGroupArray <> Null
			Local jsonOrder:JsonObject
			Local jsonOffsetArray:JsonArray
			Local jsonOffsetTotal:Int
			Local jsonOffset:JsonObject
			Local jsonOffsetIndex:Int
			Local originalIndex:Int
			Local unchangedIndex:Int
			Local offset:Int
			
			'get slot count
			'we get it from the count value as we are still reading json data
			'if we use teh array size then the code below will use teh size of the unfilled array elements
			Local slotsCount:= skeletonData.slotsCount
			
			'create this New timeline
			Local timeline:SpineDrawOrderTimeline = New SpineDrawOrderTimeline(jsonGroupArray.Length())
			frameIndex = 0
			
			'iterate over frame keys
			For frameIndex = 0 Until jsonGroupArray.Length()
				jsonOrder = JsonObject(jsonGroupArray.Get(frameIndex))
				
				Local drawOrder:Int[]
				
				'get the offset array
				jsonOffsetArray = JsonArray(jsonOrder.Get("offsets"))
				If jsonOffsetArray <> Null
					jsonOffsetTotal = jsonOffsetArray.Length()
					
					'create draw order array and reset it
					drawOrder = New Int[slotsCount]
					For slotIndex = slotsCount - 1 To 0 Step - 1
						drawOrder[slotIndex] = -1
					Next
					
					'create unchanged array
					Local unchanged:= New Int[slotsCount - jsonOffsetTotal]
					
					originalIndex = 0
					unchangedIndex = 0
					
					'iterate over offsets
					For jsonOffsetIndex = 0 Until jsonOffsetArray.Length()
						jsonOffset = JsonObject(jsonOffsetArray.Get(jsonOffsetIndex))
					
						'get slot index
						slotName = GetJsonString(jsonOffset, "slot")
						slotIndex = skeletonData.FindSlotIndex(slotName)
						
						'check slot is valid
						If slotIndex = -1 Throw New SpineException("Slot not found: " + slotName)
											
						'collect unchanges items
						While originalIndex <> slotIndex
							unchanged[unchangedIndex] = originalIndex
							unchangedIndex += 1
							originalIndex += 1
						Wend
						
						'get offset
						offset = GetJsonInt(jsonOffset, "offset", 0)
						
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
				EndIf
				
				'process frame in timeline
				timeline.SetFrame(frameIndex, GetJsonFloat(jsonOrder, "time", 0.0), drawOrder)
			Next
			
			'add timeline
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
			
			'update duration
			duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
		EndIf
		
		'events
		jsonGroupArray = JsonArray(jsonAnimation.Get("events"))
		If jsonGroupArray <> Null
			Local eventName:String
			Local jsonEvent:JsonObject
			Local event:SpineEvent
			Local eventData:SpineEventData
			
			Local timeline:SpineEventTimeline = New SpineEventTimeline(jsonGroupArray.Length())

			For frameIndex = 0 Until jsonGroupArray.Length()
				jsonEvent = JsonObject(jsonGroupArray.Get(frameIndex))
				
				'lookup the event
				eventName = GetJsonString(jsonEvent, "name")
				eventData = skeletonData.FindEvent(eventName)
				If eventData = Null Throw New SpineException("Event not found: " + eventName)
				
				'create New event
				event = New SpineEvent(eventData)
				event.IntValue = GetJsonInt(jsonEvent, "int", eventData.IntValue)
				event.FloatValue = GetJsonFloat(jsonEvent, "float", eventData.FloatValue)
				event.StringValue = GetJsonString(jsonEvent, "string", eventData.StringValue)
				
				'process frame in timeline
				timeline.SetFrame(frameIndex, GetJsonFloat(jsonEvent, "time", 0.0), event)
			Next
			
			'add timeline
			If timelineCount >= timelines.Length() timelines = timelines.Resize(timelines.Length() * 2 + 10)
			timelines[timelineCount] = timeline
			timelineCount += 1
			
			'update duration
			duration = Max(duration, timeline.Frames[timeline.FrameCount() -1])
		EndIf

		'trim timeline
		If timelineCount < timelines.Length() timelines = timelines.Resize(timelineCount)
		
		skeletonData.AddAnimation(New SpineAnimation(name, timelines, duration))
	End

	Method ReadCurve:Void(timeline:SpineCurveTimeline, frameIndex:Int, jsonTimelineFrame:JsonObject)
		Local jsonItem:JsonValue
		
		jsonItem = jsonTimelineFrame.Get("curve")
		If jsonItem = Null Return
		
		Local jsonString:= JsonString(jsonItem)
		If jsonString <> Null
			Select jsonString.StringValue()
				Case "stepped"
					timeline.SetStepped(frameIndex)
			End
		Else
			Local jsonArray:JsonArray = JsonArray(jsonItem)
			If jsonArray <> Null
				'bezier curve
				Local curve:= jsonArray.GetData()
				timeline.SetCurve(frameIndex, curve[0].FloatValue(), curve[1].FloatValue(), curve[2].FloatValue(), curve[3].FloatValue())
			EndIf
		EndIf
	End
End
