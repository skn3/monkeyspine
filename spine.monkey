'see license.txt for source licenses
Strict

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