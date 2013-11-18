'see license.txt for source licenses
Strict

'version 16
' - fixed issue with draworder not resetting for non loopd animations (cheers rikman)
'version 15
' - added SetDebugHideImages() to entity so we can disable drawing of images
' - fixed issue where transform/scale/rotation animation was being ignored for root bone, cheers rikman
' - made atlas, data and skeleton fields in spineentity public for hackables, cheers rikman
' - fixed issue where scale on single axis was deforming in monkey, cheers rikman.
'version 14
' - added small fix so snap to turns image handles into ints
'version 13
' - MASSIVE UPDATE
' - added support for native spine texture atlas
' - changed so default texture atlas loader type is the spine texture atlas loader
' - renamed the seperate image loader to SpineSeperateImageLoader
' - fixed file stream wrapper so eof works
' - added event callback to SpineEntityCallback interface
' - implemented spine events
' - implemeneted spine draw order
' - added SetSnapToPixels() to spineentity, this will draw images at int coordinates
' - Added GetSlotAlpha() and SetSlotAlpha()
' - fixed seperate image loader collisions + bounding not working
'version 12
' - added GetFirstSlot() GetLastSlot() GetNextSlot(slot) GetPreviousSlot(slot) for iterating over slots in spine entity
' - added FindFirstSlotWithAttachment() FindLastSlotWithAttachment() FindNextSlotWithAttachment(slot) FindPreviousSloWithAttachmentt(slot) for iterating over attachment slots in spine entity
' - changed RectOverlapsSlot() and PointInsideSlot() so precision param is boolean
'version 11
' - added PointInsideSlot() and RectOverlapsSlot() methods to spineentity. There are two versions of the method one accepst name:String and the other slot:SpineSlot
'version 10
' - added SetAlpha() and GetAlpha() to spineentity
'version 9
' - fixed mid handle issue with source images that have padding around edges (reported by ziggy)
'version 8
' - added spineEntity.GetAtlas() to get atlas of spine entity (thanks ziggy)
' - added SpineLoadAtlas() function to load an atlas outside of creating a spine entity
' - added SpineAtlas.Use() so that the spine glue will reference count an atlas
' - changed SpineAtlas.Free(force=false) added a force flag which will force teh atlas to be freed.
'   If force is false and atlas is being used by something else then only a eference count will be decreased
'version 7
' - fixed map issues, thanks ziggy
'version 6
' - Added IsAnimationRunning() to SpineEntity this will return true if the animation is still running
' - Added GetAnimationTime() to SpineEntity this will get the current time in ms for the animation
' - Added Free() to spineentity and certain acompanying objects
'version 5
' - more fixes by ziggy
'version 4
' - fixed lots of typo-ish bugs reported by ziggy
'version 3
' - moved module into root modules folder
'version 2
' - fixed getflip return type to bool, cheers Zwer99
'version 1
' - first public commit

'spine requires these file types to operate normally
#TEXT_FILES += "*.atlas;*.json;"

'core
Import mojo
Import monkey.map
Import monkey.boxes
Import brl.databuffer

'3rd party
Import json

'glue code
Import glue.gluevalues
Import glue.gluefunctions
Import glue.glueexceptions
Import glue.gluefiles
Import glue.glueatlas
Import glue.gluespineentity

'spine lib
Import spineanimation
Import spineanimationstate
Import spineanimationstatedata
Import spineatlas
Import spinebone
Import spinebonedata
Import spineevent
Import spineeventdata
Import spineskeleton
Import spineskeletondata
Import spineskeletonjson
Import spineskin
Import spineslot
Import spineslotdata
Import attachments.spineatlasattachmentloader
Import attachments.spineattachment
Import attachments.spineattachmentloader
Import attachments.spineattachmenttype
Import attachments.spineregionattachment