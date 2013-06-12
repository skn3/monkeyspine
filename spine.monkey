'see license.txt for source licenses
Strict

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