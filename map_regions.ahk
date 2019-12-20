#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

overlay_x := 200
overlay_y := 100


mapdata := []
zones := ["Haewark Hamlet", "Tirn's End", "Lex Proxima", "Lex Ejoris", "New Vastir", "Glennach Cairns",  "Valdo's Rest",  "Lira Arthain"]
ranks := [1, 1, 1, 1, 1, 1, 1, 1]
zone := 1

init()
loadstate()
updateui()
show := 1

return

; Initializes map data and downloads missing icons
init()
{
	global overlay_x
	global overlay_y
	global mapdata
	global zones
	
	overlay_color = 000000
	Gui, Color, %overlay_color%
	Gui, 1:Margin , 0, 0
	Gui +lastFound +AlwaysOnTop +ToolWindow -Border -Caption +E0x20 ; E0x20 is clickthrough
	Gui, Add, Text, x10 y10 w450 ccffffff BackgroundTrans, % "Initializing Data.  This may take a while if it is your first run"
	Gui, Show, % "x" overlay_x " y" overlay_y " w450 h45 NoActivate"

	if not InStr(FileExist("images"), "D")
		FileCreateDir, images
	for key, zone in zones
	{
		mapdata[zone] := []
		Loop, Read, zones/%zone%.txt
		{
			line := StrSplit(A_LoopReadLine, "`t")
			current := {name: line[1], tiers: StrSplit(line[2], ","), icon: line[3]}
			mapdata[zone].push(current)
			icon := current.icon
			for key, val in current.tiers
				if val != 0
					IfNotExist, images/%icon%%val%.png
						URLDownloadToFile, https://web.poecdn.com/image/Art/2DItems/Maps/Atlas2Maps/New/%icon%.png?scale=1&w=1&h=1&mn=6&mt=%val%, images/%icon%%val%.png
		}
	}
	return
}

; load previous state at program start
loadstate()
{
	if not FileExist("state.ini")
		return
	global ranks
	global zone
	file := FileOpen("state.ini", "r")
	if !IsObject(file)
	{
		MsgBox Can't open "state.ini" for reading.
		return
	}
	for key in [1,2,3,4,5,6,7,8]
		ranks[key] := file.Read(1)
	zone := file.Read(1)
	file.Close()
	return
}

; save current state any time the ui is updated
savestate()
{
	global ranks
	global zone
	file := FileOpen("state.ini", "w")
	if !IsObject(file)
	{
		MsgBox Can't open "state.ini" for writing.
		return
	}
	for key,value in ranks
		file.Write(value)
	file.Write(zone)
	file.Close()
	return
}

; updates the ui when there is a change
updateui()
{
	savestate()
	global overlay_x
	global overlay_y
	
	global zone
	global zones
	global ranks
	global mapdata
	
	title := 30
	cell := 55

	overlay_color = 000000
	Gui, Destroy
	Gui, Color, %overlay_color%
	Gui, 1:Margin , 0, 0
	Gui +lastFound +AlwaysOnTop +ToolWindow -Border -Caption +E0x20 ; E0x20 is clickthrough
	Gui, Add, Text, x10 y10 w150 ccffffff BackgroundTrans, % zones[zone] " Rank: " (ranks[zone] - 1)
	x_off := 0
	y_off := 0
	for key, map in mapdata[zones[zone]]
	{
		tier := map.tiers[ranks[zone]]
		if tier != 0
		{
			icon := map.icon
			xval := 10+cell*x_off
			yval := 10+title+cell*y_off
			Gui, Add, Picture, % "x" xval " y" yval " w50 h50", images/%icon%%tier%.png
			xval -= 7
			Gui, Add, Text, % "x" xval " y" yval " w50 h50 ccffffff BackgroundTrans", % tier
			x_off++
			if x_off > 5
			{
				y_off++
				x_off := 0
			}
		}
		
	}
	if x_off = 0
	{
		y_off -= 1
	}
	if y_off = 0
		width := 20+cell * (x_off+1)
	else
		width := 20+cell * 6
	height := 20+title + (y_off + 1) * cell
;	WinSet, TransColor, %overlay_color% 255 ; uncomment to remove black background.  Makes text hard to read.
	Gui, Show, % "x" overlay_x " y" overlay_y " w" width " h" height " NoActivate"
	return
}

; toggle the visiblity of the Gui
NumpadEnter::
{
	if (show = 1) {
		show := 0
		Gui, Hide
	} else {
		show := 1
		Gui, Show
	}
	return
}
; increase rank of current region
NumpadAdd::
{
	if ranks[zone] < 5
	{
		ranks[zone]++
		updateui()
	}
	return
}
; decrease rank of current region
NumpadSub::
{
	if ranks[zone] > 1
	{
		ranks[zone]--
		updateui()
	}
	return
}
NumpadDiv::
{
	zone -= 1
	if zone < 1
		zone = 8
	updateui()
	return
}
; decrease rank of current region
NumpadMult::
{
	zone += 1
	if zone > 8
		zone = 1
	updateui()
	return
}
