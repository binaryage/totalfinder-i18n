#!/usr/bin/env ruby

file = ARGV[0]
report = File.read(file)

# OSX stack traces look like this:
# we want to test for presence of com.binaryage.totalfinder anywhere on the stack
#
# Thread 0:: Dispatch queue: com.apple.main-thread
# 0   com.apple.finder                  0x000000010209e896 0x102047000 + 358550
# 1   com.apple.finder                  0x00000001022106d1 0x102047000 + 1873617
# 2   com.apple.finder                  0x0000000102210bd5 0x102047000 + 1874901
# 3   com.apple.finder                  0x00000001022013b2 0x102047000 + 1811378
# 4   com.apple.finder                  0x00000001022caff0 0x102047000 + 2637808
# 5   com.apple.CoreFoundation          0x00007fff89be648d -[NSObject performSelector:withObject:] + 61
# 6   com.apple.finder                  0x00000001020c700d 0x102047000 + 524301
# 7   com.apple.AppKit                  0x00007fff8906652a -[NSApplication sendAction:to:from:] + 139
# 8   com.apple.AppKit                  0x00007fff891534c3 -[NSMenuItem _corePerformAction] + 399
# 9   com.apple.AppKit                  0x00007fff8915321a -[NSCarbonMenuImpl performActionWithHighlightingForItemAtIndex:] + 125
# 10  com.apple.AppKit                  0x00007fff893ee408 -[NSMenu _internalPerformActionForItemAtIndex:] + 38
# 11  com.apple.AppKit                  0x00007fff89280df5 -[NSCarbonMenuImpl _carbonCommandProcessEvent:handlerCallRef:] + 138
# 12  com.apple.AppKit                  0x00007fff890ccd2b NSSLMMenuEventHandler + 339
# 13  com.apple.HIToolbox               0x00007fff926a1e08 _ZL23DispatchEventToHandlersP14EventTargetRecP14OpaqueEventRefP14HandlerCallRec + 1263
# 14  com.apple.HIToolbox               0x00007fff926a1414 _ZL30SendEventToEventTargetInternalP14OpaqueEventRefP20OpaqueEventTargetRefP14HandlerCallRec + 446
# 15  com.apple.HIToolbox               0x00007fff926b81e3 SendEventToEventTarget + 76
# 16  com.apple.HIToolbox               0x00007fff926fe315 _ZL18SendHICommandEventjPK9HICommandjjhPKvP20OpaqueEventTargetRefS5_PP14OpaqueEventRef + 398
# 17  com.apple.HIToolbox               0x00007fff927e4f91 SendMenuCommandWithContextAndModifiers + 56
# 18  com.apple.HIToolbox               0x00007fff9282b459 SendMenuItemSelectedEvent + 253
# 19  com.apple.HIToolbox               0x00007fff926f74a5 _ZL19FinishMenuSelectionP13SelectionDataP10MenuResultS2_ + 101
# 20  com.apple.HIToolbox               0x00007fff92823e65 _ZL19PopUpMenuSelectCoreP8MenuData5PointdS1_tjPK4RecttjS4_S4_PK10__CFStringPP13OpaqueMenuRefPt + 1660
# 21  com.apple.HIToolbox               0x00007fff92824124 _HandlePopUpMenuSelection7 + 621
# 22  com.apple.AppKit                  0x00007fff89283ac1 _NSSLMPopUpCarbonMenu3 + 3860
# 23  com.apple.AppKit                  0x00007fff89281ac1 -[NSCarbonMenuImpl _popUpContextMenu:withEvent:forView:withFont:] + 190
# 24  com.apple.AppKit                  0x00007fff893ee23f -[NSMenu _popUpContextMenu:withEvent:forView:withFont:] + 193
# 25  com.apple.AppKit                  0x00007fff895d4eda -[NSView rightMouseDown:] + 129
# 26  com.apple.AppKit                  0x00007fff892d2458 -[NSControl _rightMouseUpOrDown:] + 459
# 27  com.apple.AppKit                  0x00007fff8902f62a -[NSWindow sendEvent:] + 7404
# 28  com.binaryage.totalfinder         0x0000000105681b0a -[NSWindow(TotalFinder) TotalFinder_TBrowserWindow_sendEvent:] + 56
# 29  com.apple.AppKit                  0x00007fff88fc7b20 -[NSApplication sendEvent:] + 4924
# 30  com.apple.AppKit                  0x00007fff88f5e9b0 -[NSApplication run] + 541
# 31  com.apple.AppKit                  0x00007fff891dc2ad NSApplicationMain + 860
# 32  com.apple.finder                  0x000000010204d4fb 0x102047000 + 25851
# 33  com.apple.finder                  0x000000010204d4bc 0x102047000 + 25788

exit 1 if report.match(/^\d+\s+com\.binaryage/m) # yes, present!
exit 0 # negative