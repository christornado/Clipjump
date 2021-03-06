;History Gui labels and functions
;A lot Thanks to chaz

gui_History()
; Creates and shows a GUI for managing and viewing the clipboard history
{
	global
	static x, y, how_sort := 2_sort := 3_sort := 0, what_sort := 2
	local selected_row
	;2_3_sort are the vars storing how cols are sorted , 1 means in Sort ; 0 means SortDesc

	Gui, History:new
	Gui, Margin, 7, 7
	Gui, +Resize +MinSize390x110

	Iniread, history_w, % CONFIGURATION_FILE, Clipboard_History_window, w, %A_Space%
	Iniread, h, % CONFIGURATION_FILE, Clipboard_History_window, h, %A_Space%

	Gui, Add, Button, w75 h23 Section Default	vhistory_ButtonPreview	ghistory_ButtonPreview, &Preview
	Gui, Add, Button, x+6 ys w75 h23			vhistory_ButtonDelete	ghistory_ButtonDelete, Dele&te item
	Gui, Add, Button, x+6 ys w75 h23 			vhistory_ButtonDeleteAll ghistory_ButtonDeleteAll, Clear &history
	Gui, Add, Text, x+15 ys+5 					vhistory_SearchText,	Search &Filter:
	Gui, Add, Checkbox, x+10 ys+5 w65 Checked%history_partial% vhistory_partial ghistory_SearchBox, Pa&rtial
	Gui, Add, Edit, ys  	ghistory_SearchBox	vhistory_SearchBox
	Gui, Font, s9, Courier New
	Gui, Font, s9, Consolas
	Gui, Add, ListView, % "xs+1 HWNDhistoryLV ghistoryLV vhistoryLV LV0x4000 w" (history_w ? history_w-25 : 675) , Clip|Date|Size(B)|Hiddendate

	Gui, Add, StatusBar
	Gui, Font
	GuiControl, Focus, history_SearchBox

	;History Right-Click Menu
	Menu, HisMenu, Add, % "&Preview" , history_MenuPreview
	Menu, HisMenu, Add
	;Use a Space and a tab to separate
	Menu, HisMenu, Add, % "&Copy 			(Ctrl+C)", history_clipboard
	Menu, HisMenu, Add, % "&Insta-Paste 	(Space)", history_InstaPaste
	Menu, HisMenu, Add, % "&Export Clip 	(Ctrl+E)", history_exportclip
	Menu, HisMenu, Add
	Menu, HisMenu, Add, % "&Refresh", history_SearchBox
	Menu, HisMenu, Add, % "&Delete", history_ButtonDelete 
	Menu, HisMenu, Default, % "&Preview"

	historyUpdate()
	history_UpdateSTB()
	LV_ModifyCol(what_sort, how_sort ? "Sort" : "SortDesc")

	if ((h+0) == WORKINGHT)
	{
		Gui, History:Show, Maximize, %PROGNAME% Clipboard History
		WinMinimize, %PROGNAME% Clipboard History
		WinMaximize, %PROGNAME% Clipboard History
		GuiControl, focus, history_SearchBox
	}
	else
		Gui, History:Show,% ( x ? "x" x " y" y : "" ) " w" (history_w?history_w:700) " h" (h?h:500), %PROGNAME% Clipboard History

	WinWaitActive, %PROGNAME% Clipboard History
	WinGetPos, x, y

	;create hotkeys
	Hotkey, IfWinActive, % PROGNAME " Clipboard History"
	Hotkey, F5, history_SearchBox, On
	Hotkey, If
	return

history_MenuPreview:
; Invoking the prev. button . 
	Send {vk0d}
	return

history_ButtonPreview:
	Gui, submit, nohide
	if (LV_GetNext() == "0")
		v := selected_row
	else v := LV_GetNext()

	LV_GetText(clip_file_path, v, hidden_date_no)
	gui_History_Preview(clip_file_path, history_SearchBox)
	return

history_ButtonDelete:
	Gui, History:Default

	temp_row_s := 0 , rows_selected := "" , list_clipfilepath := ""
	while (temp_row_s := Lv_GetNext(temp_row_s))
		rows_selected .= temp_row_s ","
	rows_selected := Substr(rows_selected, 1, -1)     ;get CSV row numbers

	;Get Row names
	loop, parse, rows_selected,`,
		LV_GetText(clip_file_path, A_LoopField, hidden_date_no)
		, list_clipfilepath .= clip_file_path "`n" 	;Important for faster results

	;Delete Rows
	loop, parse, rows_selected,`,
		LV_Delete(A_LoopField+1-A_index)

	;Delete items
	loop, parse, list_clipfilepath, `n
		FileDelete, % "cache\history\" A_LoopField
	
	Guicontrol, History:Focus, history_SearchBox
	history_UpdateSTB()
	return

history_ButtonDeleteAll:
	Gui, +OwnDialogs
	MsgBox, 257, Clear History, Are you sure you want to permanently clear %PROGNAME%'s clipboard history?
	IfMsgBox, OK
	{
		FileDelete, cache\history\*
		historyUpdate()
		history_UpdateSTB()
	}
	return

history_SearchBox:
	Critical, On
	Gui, History:Default
	Gui, History:Submit, NoHide
	historyUpdate(history_SearchBox, 0, history_partial)
	LV_ModifyCol(what_sort, how_sort ? "Sort" : "SortDesc") 		;sort column correctly
	return

historyLV:
	Gui, History:Default

	if A_GuiEvent = DoubleClick
		gosub, history_ButtonPreview
	else if (A_GuiEvent == "ColClick")
	{
		LV_SortArrow(historyLV, A_EventInfo)
		, what_sort := A_EventInfo
		, temp := %what_sort%_sort 				;retrieve currrent col value
		, 2_sort := 3_sort := 0					;change all cols values
		, how_sort := %what_sort%_sort := ! (temp) 			;update real current col value
	}
	return

history_clipboard:
	history_clipboard()
	return

historyGuiContextMenu:
	if (A_GuiControl != "historyLV") or (LV_GetNext() = 0)
		return
	selected_row := LV_GetNext()
	Menu, HisMenu, Show, %A_GuiX%, %A_GuiY%
	return

historyGuiSize:
	if (A_EventInfo != 1)	; ignore minimising
	{
		gui_w := a_guiwidth , gui_h := a_guiheight

		SendMessage, 0x1000+29, 1,	0, SysListView321, %PROGNAME% Clipboard History
		w2 := ErrorLevel
		SendMessage, 0x1000+29, 2,	0, SysListView321, %PROGNAME% Clipboard History
		w3 := ErrorLevel

		GuiControl, Move, historyLV, % "w" (gui_w - 15) " h" (gui_h - 65)     ;+20 H in no STatus Bar
		LV_ModifyCol(1, gui_w-15-w2-w3-25) 				;gui_w - x  where   x  =  width of all cols + 25
		GuiControl, Move, history_SearchBox, % "x400 w" (gui_w - 338 - 70)
	}
	return

historyGuiClose:
historyGuiEscape:
	Wingetpos, x, y,, h, %PROGNAME% Clipboard History

	h := h > WORKINGHT ? WORKINGHT : gui_h               ;gui_h and gui_w are function vars created in the historyGUISIze label (above).

	Ini_write(temp_h := "Clipboard_History_window", "w", gui_w, 0)
	Ini_write(temp_h, "h", h, 0)

	SendMessage, 0x1000+29, 1,	0, SysListView321, %PROGNAME% Clipboard History
	w2 := ErrorLevel
	SendMessage, 0x1000+29, 2,	0, SysListView321, %PROGNAME% Clipboard History
	w3 := ErrorLevel
	Ini_write(temp_h, "w2", w2, 0)
	Ini_write(temp_h, "w3", w3, 0)

	Gui, History:Destroy
	Menu, HisMenu, DeleteAll
	EmptyMem() 				;Free memory
	return
}


gui_History_Preview(path, history_SearchBox)
; Creates and shows a GUI for viewing history items
{
	global prev_copybtn, prev_findtxt, prev_handle, preview_search, prev_picture, preview
	static wt := A_ScreenWidth / 2 , ht := A_ScreenHeight / 2 , maxlines = Round(ht / 13)
	preview := {}

	preview.isimg := Instr(Substr(path, -2), "jpg") ? 1 : 0
	preview.path := A_scriptdir "\cache\history\" path

	Gui, Preview:New
	Gui, Margin, 0, 0

	if preview.isimg
	{
		Gui, Add, Picture, w%wt% h%ht% vprev_picture, 
		Gdip_getlengths(preview.path, w, h)
		preview.w := w , preview.h := h
		wf := preview.w/wt , hf := preview.h/ht
		if (wf>=hf) && (wf>1)
			wn := preview.w/wf , hn:= preview.h/wf
		else if (hf>wf) && (hf>1)
			wn := preview.w/hf , hn := preview.h/hf
		else
		 	wn := preview.w , hn := preview.h
		GuiControl, , prev_picture,% " *w" wn " *h" hn " " preview.path
	}
	else
	{
		Gui, Add, ActiveX, w%wt% h%ht% vprev_handle, Shell.Explorer
		prev_handle.Navigate( preview.path )
	}

	Gui, Font, s11
	Gui, Add, Button, % "x5 y+10 w125 h27 gbutton_Copy_To_Clipboard Default vprev_copybtn Section", Copy to Clipboard
	; button's x till 130 , search's width will 200 p from right
	Gui, Add, Text, % "x" wt-200 " yp+2 w30 h23 vprev_findtxt", Fin&d 		; +2 to level text
	Gui, Font, norm
	Gui, Add, Edit, % "x+10 yp-2 w155 h23 vpreview_search gpreviewSearch " ( preview.isimg ? "+ReadOnly" : "" ),  	; -5 margin on right side
	Gui, Add, Text, x5 y+0 w5 			; white-space just below the button

	Gui, Preview:+OwnerHistory
	Gui, History:+Disabled
	Gui, Preview: +Resize +MaximizeBox -MinimizeBox
	Gui, Preview:Show, AutoSize, Preview

	if !preview.isimg
		GuiControl, , preview_search, % history_SearchBox
	return
	
button_Copy_to_Clipboard:
	Gui, Preview:Submit, nohide
	if !preview.isimg
		try Fileread, Clipboard, % preview.path
	else
		Gdip_SetImagetoClipboard(preview.path)
	sleep 500
	gosub, previewGuiClose
	return

previewGuiClose:
previewGuiEscape:
	Gui, History:-Disabled
	Gui, Preview:Destroy
	prev_handle := ""
	prev_document := ""
	EmptyMem()
	return

previewSearch:
	Critical
	Gui, submit, nohide
	prev_document := prev_handle.Document.body.createTextRange
	prev_document.execCommand("BackColor", 0, "White")
	preview_search := Trim(preview_search, A_space)
	if preview_search =
		return

	try {
	;highlight partial matches
	if history_partial
		loop, parse, preview_search, %A_space%, %A_space%
		{
			while prev_document.findtext(A_LoopField)
				prev_document.execCommand("BackColor", 0, "Aqua")        
				, prev_document.Collapse(0)
			prev_document := prev_handle.Document.body.createTextRange
		}

	;highlight exact matches
	while prev_document.findtext(preview_search)
		prev_document.execCommand("BackColor", 0, "Yellow")        
		, prev_document.Collapse(0) 

	}
	return

PreviewGuiSize:
	if (A_EventInfo != 1)
	{
		gui_w := A_GuiWidth , gui_h := A_GuiHeight
		GuiControl, move, preview_search, % "x" gui_w-160 " y" gui_h-30
		GuiControl, move, prev_findtxt, % "x" gui_w-200 " y" gui_h-30
		GuiControl, move, prev_copybtn, % "y" gui_h-32
		if !preview.isimg
			GuiControl, move, prev_handle, % "w" gui_w " h" gui_h-42
		else {
			GuiControl, move, prev_handle, % "w" gui_w " h" gui_h-42

			wn := gui_w , hn := gui_h-42
			if (gui_w+0)>preview.w
				wn := preview.w
			if (gui_h-42)>preview.h
				hn := preview.h
			
			GuiControl, , prev_picture, % "*w" wn " *h" hn " " preview.path
		}
	}
	return

}


history_clipboard(){
; Transfers the selected item from Listview to Clipboard
; -
	Gui, History:Default
	row_selected := LV_GetNext(0)
	LV_GetText(clip_file_path, row_selected, hidden_date_no)
	if !Instr(clip_file_path, ".jpg")
	{
		FileRead, temp_Read, cache\history\%clip_file_path%
		try Clipboard := temp_Read
	}
	else
		Gdip_SetImagetoClipboard("cache\history\" clip_file_path)
}


historyUpdate(crit="", create=true, partial=false)
; Update the history GUI listview
; create=false will prevent re-drawing of Columns , useful when the function is called in the SearchBox label and Gui Size is customized.
{
	static his_obj := {}
	local totalSize := 0

	LV_Delete()

	Loop, cache\history\*
	{
		; Filling Text data in obj
		if Instr(A_LoopFileFullPath, ".txt")
		{
			if !his_obj[A_LoopFileName "_data"]
			{
				Fileread, lv_temp, %A_LoopFileFullPath%
				data := his_obj[A_LoopFileName "_data"] := lv_temp
			}
			else
				data := his_obj[A_LoopFileName "_data"]
		}
		else if Instr(A_LoopFileFullPath, ".jpg")
			data := his_obj[A_LoopFileName "_data"] := MSG_HISTORY_PREVIEW_IMAGE
		else Continue
		
		func := partial ? "Superinstr" : "Instr" 		;too smart - The third param 0 has diff meanings in both cases
		;  Searching
		if %func%(data, crit, partial ? 1 :0)
		{
			if !his_obj[A_LoopFileName "_date"]
			{
				his_obj[A_LoopFileName "_date"] := Substr(A_LoopFileName,1,4) "-" Substr(A_LoopFileName,5,2) "-" Substr(A_LoopFileName,7,2) "  "
						. Substr(A_LoopFileName,9,2) ":" Substr(A_LoopFileName,11,2) ":" Substr(A_LoopFileName, 13, 2)
				FileGetSize, O,% A_LoopFileFullPath
				his_obj[A_LoopFileName "_size"] := O
			}

			LV_Add("", data, his_obj[A_LoopFileName "_date"], t := his_obj[A_LoopFileName "_size"], A_LoopFileName)
			totalSize += t 				; speed factor
		}
	}

	history_UpdateSTB("" totalSize/1024)

	if create
	{
		Iniread, w2,% CONFIGURATION_FILE, Clipboard_History_window, w2, 155
		Iniread, w3,% CONFIGURATION_FILE, Clipboard_History_window, w3, 70
		w1 := (history_w - 15 - w2 - w3)
		LV_ModifyCol(1, w1) , LV_ModifyCol(2, w2?w2:155) , Lv_ModifyCol(3, (w3?w3:70) " Integer") , Lv_ModifyCol(4, "0")
	}
}

history_GetSize(I := ""){
;returns the size of given filename in history
	If I !=
		FileGetSize, R, % "cache\history\" I, B
	else
		Loop, cache\history\*.*, , 1
    		R += %A_LoopFileSize%

    return R/1024
}

history_UpdateSTB(size=""){
	; If size is passed, that size is used
	Gui, History:Default
	SB_SetText("Disk Consumption : " ( size="" ? history_GetSize() : size ) " KB")
}


history_InstaPaste:
	IniRead, clipboard_instapaste, % CONFIGURATION_FILE, Advanced, Instapaste_write_clipboard, %A_Space%
	if clipboard_instapaste
		history_clipboard()
	else
		CALLER := 0
		, history_clipboard()

	WinClose, %PROGNAME% Clipboard History
	WinWaitClose, %PROGNAME% Clipboard History
	Send, ^{vk56}
	CALLER := CALLER_STATUS
	return

history_exportclip:
	CALLER := false
	history_clipboard()
	ClipWait, ,1
	loop
		if !FileExist(temp := A_MyDocuments "\export" A_index ".cj")
			break
	Tooltip,% "Selected Clip exported to `n" temp
	SetTimer, TooltipOff, 1000
	try FileAppend, %ClipboardAll%, %temp%
	CALLER := CALLER_STATUS
	return

LV_SortArrow(h, c, d="")	; by Solar (http://www.autohotkey.com/forum/viewtopic.php?t=69642)
; Shows a chevron in a sorted listview column pointing in the direction of sort (like in Explorer)
; h = ListView handle (use +hwnd option to store the handle in a variable)
; c = 1 based index of the column
; d = Optional direction to set the arrow. "asc" or "up". "desc" or "down".
{
	static ptr, ptrSize, lvColumn, LVM_GETCOLUMN, LVM_SETCOLUMN
	if (!ptr)
		ptr := A_PtrSize ? ("ptr", ptrSize := A_PtrSize) : ("uint", ptrSize := 4)
		,LVM_GETCOLUMN := A_IsUnicode ? (4191, LVM_SETCOLUMN := 4192) : (4121, LVM_SETCOLUMN := 4122)
		,VarSetCapacity(lvColumn, ptrSize + 4), NumPut(1, lvColumn, "uint")
	c -= 1, DllCall("SendMessage", ptr, h, "uint", LVM_GETCOLUMN, "uint", c, ptr, &lvColumn)
	if ((fmt := NumGet(lvColumn, 4, "int")) & 1024) {
		if (d && d = "asc" || d = "up")
			return
		NumPut(fmt & ~1024 | 512, lvColumn, 4, "int")
	} else if (fmt & 512) {
		if (d && d = "desc" || d = "down")
			return
		NumPut(fmt & ~512 | 1024, lvColumn, 4, "int")
	} else {
		Loop % DllCall("SendMessage", ptr, DllCall("SendMessage", ptr, h, "uint", 4127), "uint", 4608)
			if ((i := A_Index - 1) != c)
				DllCall("SendMessage", ptr, h, "uint", LVM_GETCOLUMN, "uint", i, ptr, &lvColumn)
				,NumPut(NumGet(lvColumn, 4, "int") & ~1536, lvColumn, 4, "int")
				,DllCall("SendMessage", ptr, h, "uint", LVM_SETCOLUMN, "uint", i, ptr, &lvColumn)
		NumPut(fmt | (d && d = "desc" || d = "down" ? 512 : 1024), lvColumn, 4, "int")
	}
	return DllCall("SendMessage", ptr, h, "uint", LVM_SETCOLUMN, "uint", c, ptr, &lvColumn)
}

;------------------------------------ ACCESSIBILITY SHORTCUTS -------------------------------

#if IsActive("Edit1", "classnn") and IsActive(PROGNAME " Clipboard History", "window")
	$Down::
		Controlfocus, SysListView321, A
		Send {vk28}
		return
#if
#if ( IsActive("SysListView321", "classnn") and IsActive(PROGNAME " Clipboard History", "window") and ctrlRef!="pastemode" )
	Space::gosub history_InstaPaste
	^c::history_clipboard()
	^e::gosub history_exportclip
	Del::Send !{vk54}               ;Alt+T - shortcut for Delete
	!d::Send ^{vk46}  			   ;Alt+F - shortcut for Search
	^f::GuiControl, History:focus, history_SearchBox
#if
#if Winactive("Preview ahk_class AutoHotkeyGUI")
	^f::Send !{vk44}              ;Alt+D
#if