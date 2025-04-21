#Requires AutoHotkey v2+
; #Include <Includes\Basic>
; Git Repository Synchronization Tool
; This script automates the synchronization of multiple git repositories

; Define your repositories
class GitRepo {
	remote := ""
	local := ""
	branch := "master"  ; Default branch name
	
	__New(remoteRepo, localRepo, branchRepo := "master") {
		this.remote := remoteRepo
		; Convert backslashes to forward slashes in local path
		this.local := StrReplace(localRepo, "\", "/")
		this.branch := branchRepo
	}
}
GitRepoGui
Class GitRepoGui {
	; GUI class to manage the Git repository synchronization tool
	__New() {

		; Array of repositories to manage
		repos := [
			GitRepo("https://github.com/OvercastBTC/AHK.Standard.Lib", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib"),
			; GitRepo("https://github.com/OvercastBTC/AHK.User.Lib", "C:\Users\bacona\Documents\AutoHotkey\Lib"),
			GitRepo("https://github.com/OvercastBTC/AHK.User.Lib", A_MyDocuments "\AutoHotkey\Lib"),
			GitRepo("https://github.com/OvercastBTC/Personal", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Personal"),
			GitRepo("https://github.com/OvercastBTC/AHK.ObjectTypeExtensions", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib\Extensions"),
			GitRepo("https://github.com/OvercastBTC/AHK.Projects.v2", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2"),
			GitRepo("https://github.com/OvercastBTC/AHK.ExplorerClassicContextMenu", "C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2\AHK.ExplorerClassicContextMenu")
		]

		; Load settings first
		this.settings := Settings.Load()

		; Set up sync scheduler if enabled
		if this.settings.autoSync{
			SyncScheduler.Schedule(this.settings.autoSync)
		}

		; Create GUI
		guiOptions := ' +ReSize'
		; guiOptions .= ' +AlwaysOnTop'
		myGui := Gui(guiOptions, "Git Repository Manager")
		SettingsGui.mainGui := myGui
		; myGui.SetFont("s10")
		; myGui.BackColor := GuiColors.mColors['darkgray']
		myGui.BackColor := StrReplace('#D3D3D3', '#', '0x')  ; Light gray color
		myGui.SetFont('s10 Q5', 'Segoe UI')
		myGUi.Font := 'Segoe UI'

		; Add title
		myGui.AddText("w800 h30 Center", "Git Repository Synchronization Tool")
		myGui.AddText("w800 h2 0x10")  ; Horizontal Line

		; Modify the ListView columns order and data display
		LV := myGui.AddListView("w800 h300", ["Repository", "Status", "Submodule Status", "Last Synced", "Local Path"])

		; Populate ListView with repos
		for repo in repos {
			repoName := gitSplitPath(repo.remote).filename
			formattedPath := PathFormatter.FormatPath(repo.local)
			; Updated column order matches ListView definition
			LV.Add(, repoName, "Not checked", "Checking...", "Never", formattedPath)
		}

		; ; After populating the ListView, call AutosizeColumns
		; AutosizeColumns(LV)

		; Add buttons
		buttonGroup := myGui.AddGroupBox("w800 h100", "Actions")
		btnCheckAll := myGui.AddButton("xm+10 yp+30 w180 h40", "Check All Repositories").OnEvent("Click", CheckAllRepos)
		btnPush := myGui.AddButton("x+20 w180 h40", "Push Local to Remote").OnEvent("Click", PushToRemote)
		btnPull := myGui.AddButton("x+20 w180 h40", "Pull from Remote").OnEvent("Click", PullFromRemote)
		btnInit := myGui.AddButton("x+20 w180 h40", "Initialize Repositories").OnEvent("Click", InitRepos)

		; Add log window
		myGui.AddText("xm w800 h20", "Operation Log:")
		; Add log window
		myGui.AddText("xm w800 h20", "Operation Log:")
		logEdit := myGui.AddEdit("xm w800 h200 ReadOnly -Wrap")

		; Initialize log with history
		LogManager.InitializeLog(logEdit)

		; ; Show the GUI
		myGui.Show()
		; myGui.Show("Hide")      ; Create but don't show yet
		
		; Run initial check
		CheckAllRepos()
		
		; Enable and show GUI
		myGui.Opt("-Disabled")  ; Re-enable GUI
		myGui.Show('AutoSize')           ; Now show it

		; After populating the ListView, call AutosizeColumns
		AutosizeColumns(LV)

		; Store control references as class properties
		this.myGui := myGui
		this.LV := LV
		this.buttonGroup := buttonGroup
		this.logEdit := logEdit
		this.btnCheckAll := btnCheckAll
		this.btnPush := btnPush
		this.btnPull := btnPull
		this.btnInit := btnInit

		; Calculate button sizes based on text
		this.buttons := [btnCheckAll, btnPush, btnPull, btnInit]
		maxWidth := GetMaxButtonWidth(this.buttons)
		
		; Add resize handler
		myGui.OnEvent("Size", GuiSize)

		; Function to check all repositories
		CheckAllRepos(*) {
			LogMsg("Checking all repositories...")
			
			for i, repo in repos {
				repoName := gitSplitPath(repo.remote).filename
				LogMsg("Checking " . repoName . "...")
				
				; Check directory
				if !DirExist(repo.local) {
					LV.Modify(i, , , "Local directory missing", "N/A", "Never")
					continue
				}
				
				; Check git repo
				if !DirExist(repo.local . "\.git") {
					LV.Modify(i, , , "Not a Git repository", "N/A", "Never")
					continue
				}
				
				; Check status including submodules
				status := CheckGitRepoStatus(repo)
				LV.Modify(i, , , status.status, status.submoduleStatus, FormatTime(, "yyyy-MM-dd HH:mm:ss"))
			}
			
			LogMsg("Repository check complete.")
		}

		; Function to check detailed Git repository status
		CheckGitRepoStatus(repo) {
			; Check remote
			remoteOutput := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git remote -v')
			if !InStr(remoteOutput, repo.remote)
				return {status: "Wrong remote URL", submoduleStatus: "N/A"}
			
			; Check branch
			branchOutput := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git branch')
			if !InStr(branchOutput, repo.branch)
				return {status: "Branch not found", submoduleStatus: "N/A"}
			
			; Check submodules first
			submoduleStatus := SubmoduleManager.CheckAndUpdateSubmodules(repo.local)
			
			; Check for changes
			statusOutput := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git status --porcelain')
			
			return {
				status: statusOutput ? "Changes pending" : "Repository ready",
				submoduleStatus: submoduleStatus,
				lastUpdate: FormatTime(FileGetTime(repo.local "\.git\HEAD"), "yyyy-MM-dd HH:mm:ss")
			}
		}

		; Function to push local to remote
		PushToRemote(*) {
			row := LV.GetNext(0)
			if !row {
				MsgBox("Please select a repository first.")
				return
			}
			
			repo := repos[row]
			repoName := gitSplitPath(repo.remote).filename
			
			LogMsg("Checking status of " . repoName . "...")
			
			try {
				; First check if we're in a git repository
				if !DirExist(repo.local . "\.git") {
					LogMsg("Error: Not a git repository: " . repo.local)
					return
				}

				; Check for submodules
				if FileExist(repo.local . "\.gitmodules") {
					LogMsg("Submodules detected. Updating submodules first...")
					
					; Initialize and update submodules
					output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git submodule update --init --recursive')
					LogMsg("Submodule update result: " . output)
					
					; Check submodule status
					output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git submodule status')
					LogMsg("Submodule status: " . output)
				}

				; Get status before push
				statusOutput := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git status --porcelain')
				if !statusOutput {
					LogMsg("No changes to commit in " . repoName)
					return
				}

				; Stage and commit changes including submodules
				LogMsg("Staging changes...")
				output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git add -A')
				
				; Commit with detailed message
				commitMsg := Format("Auto-sync commit from {1}`nTimestamp: {2}`nStatus before commit:`n{3}",
					A_ComputerName,
					FormatTime(, "yyyy-MM-dd HH:mm:ss"),
					statusOutput)
					
				output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git commit -m "' . commitMsg . '"')
				LogMsg("Commit result: " . output)
				
				; Push changes
				LogMsg("Pushing changes to remote...")
				output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git push --recurse-submodules=on-demand origin ' . repo.branch)
				LogMsg("Push result: " . output)
				
				LV.Modify(row, , , "Pushed to remote", FormatTime(, "yyyy-MM-dd HH:mm:ss"))
			}
			catch as e {
				LogMsg("Error: " . e.Message . "`nCommand output: " . (IsSet(output) ? output : "No output"))
				MsgBox("Error pushing repository. Check the log for details.", "Push Error", "Icon!")
			}
		}

		; Function to pull from remote
		PullFromRemote(*) {
			row := LV.GetNext(0)
			if !row {
				MsgBox("Please select a repository first.")
				return
			}
			
			repo := repos[row]
			repoName := gitSplitPath(repo.remote).filename
			
			LogMsg("Pulling " . repoName . " from remote...")
			
			try {
				; Backup untracked files first
				backupDir := A_Temp . "\git_backup_" . FormatTime(,"yyyyMMdd_HHmmss")
				DirCreate(backupDir)
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git ls-files --others --exclude-standard > " . backupDir . "\untracked_files.txt")
				
				; Fetch and reset to remote
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git reset --hard origin/" . repo.branch)
				LogMsg(output)
				LV.Modify(row, , , , "Pulled from remote", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
				
				; Inform about backup
				LogMsg("Untracked files list saved to: " . backupDir . "\untracked_files.txt")
			}
			catch as e {
				LogMsg("Error: " . e.Message)
			}
		}

		; Function to initialize repositories
		InitRepos(*) {
			row := LV.GetNext(0)
			if !row {
				MsgBox("Please select a repository first.")
				return
			}
			
			repo := repos[row]
			repoName := gitSplitPath(repo.remote).filename
			
			LogMsg("Initializing " . repoName . "...")
			
			try {
				; Create directory if it doesn't exist
				if !DirExist(repo.local) {
					DirCreate(repo.local)
					LogMsg("Created directory: " . repo.local)
				}
				
				; Enhanced check for existing Git repository
				if DirExist(repo.local . "\.git") {
					LogMsg("Found existing Git repository. Checking configuration...")
					
					; Check if the remote URL matches
					remoteOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote -v")
					
					if InStr(remoteOutput, repo.remote) {
						LogMsg("Remote URL already correctly configured.")
					} else {
						; Check if origin exists
						if InStr(remoteOutput, "origin") {
							output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote set-url origin " . repo.remote)
							LogMsg("Updated existing remote URL to: " . repo.remote)
						} else {
							output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote add origin " . repo.remote)
							LogMsg("Added remote 'origin' with URL: " . repo.remote)
						}
					}
					
					; Check if branch exists
					branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch")
					
					if !InStr(branchOutput, repo.branch) {
						LogMsg("Creating branch '" . repo.branch . "' tracking remote...")
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
						LogMsg(output)
					} else {
						; Make sure the branch is correctly tracking
						trackingOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -vv")
						
						if !InStr(trackingOutput, "origin/" . repo.branch) {
							LogMsg("Setting correct tracking for branch '" . repo.branch . "'...")
							output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch --set-upstream-to=origin/" . repo.branch . " " . repo.branch)
							LogMsg(output)
						} else {
							LogMsg("Branch '" . repo.branch . "' already correctly tracking remote.")
						}
					}
				} else {
					; Initialize a completely new repository
					LogMsg("No Git repository found. Initializing new repository...")
					output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git init && git remote add origin " . repo.remote)
					LogMsg("Initialized new Git repository and added remote.")
					
					; Try to fetch and track the remote branch
					fetchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin")
					LogMsg("Fetched remote repository.")
					
					; Check if the remote branch exists
					branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -r")
					
					if InStr(branchOutput, "origin/" . repo.branch) {
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
						LogMsg("Created local branch tracking remote branch '" . repo.branch . "'.")
					} else {
						; Create an empty branch with the right name
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout --orphan " . repo.branch)
						LogMsg("Created new branch '" . repo.branch . "'. Remote branch does not exist yet.")
					}
				}
				
				; Update status
				LV.Modify(row, , , , "Repository configured", FormatTime(,"yyyy-MM-dd HH:mm:ss"))
			}
			catch as e {
				LogMsg("Error: " . e.Message)
			}
		}

		; ; Helper function to execute command and get output
		; RunCmdAndGetOutput(cmd, maxRetries := 3) {
		; 	loop maxRetries {
		; 		try {
		; 			tempFile := A_Temp . "\git_cmd_output.txt"
		; 			RunWait("cmd.exe /c " . cmd . " > " . tempFile . " 2>&1",, "Hide")
		; 			output := FileRead(tempFile)
		; 			FileDelete(tempFile)
		; 			return output
		; 		}
		; 		catch as e {
		; 			if A_Index = maxRetries
		; 				throw e
		; 			Sleep(1000)  ; Wait before retry
		; 		}
		; 	}
		; }

		; Helper function to add messages to the log
		; Add persistent log handling
		LogMsg(msg) {
			static logFile := A_ScriptDir . "\git_sync_history.log"
			
			; Format message with computer name and timestamp
			formattedMsg := Format("[{1}][{2}][{3}] {4}", 
				A_ComputerName,
				FormatTime(, "yyyy-MM-dd"),
				FormatTime(, "HH:mm:ss"),
				msg)
			
			; Update GUI - Add new messages at top
			logEdit.Value := formattedMsg . "`r`n" . logEdit.Value
			
			; Append to log file - Keep chronological order in file
			try FileAppend(formattedMsg . "`n", logFile)
		}
		; LogMsg(msg) {
		; 	logEdit.Value := FormatTime(,"[yyyy-MM-dd HH:mm:ss] ") . msg . "`r`n" . logEdit.Value
		; }

		; SplitPath function for v2 (since the built-in doesn't return an object)
		gitSplitPath(Path) {
			FileName := ""
			Dir := ""
			Ext := ""
			NameNoExt := ""
			Drive := ""
			
			; Split the path into components
			SplitPath(Path, &FileName, &Dir, &Ext, &NameNoExt, &Drive)
			
			; Return as an object
			return { path: Path, filename: FileName, dir: Dir, ext: Ext, nameNoExt: NameNoExt, drive: Drive }
		}

		; Function to add a repository to the ListView
		AddRepo(repo) {
			repoName := gitSplitPath(repo.remote).filename
			LV.Add(, repoName, "Not checked", "Never", repo.local)
		}

		; Add this after creating the ListView
		AutosizeColumns(LV) {
			static LVM_SETCOLUMNWIDTH := 0x101E
			
			; Auto-size each column
			Loop LV.GetCount("Col"){
				SendMessage(LVM_SETCOLUMNWIDTH, A_Index-1, -2, LV) ; -2 = LVSCW_AUTOSIZE_USEHEADER
			}
		}

		CheckSubmodules(repoPath) {
			if !FileExist(repoPath . "\.gitmodules"){
				return "No submodules"
			}
			output := RunCmdAndGetOutput('cd /d "' . repoPath . '" && git submodule foreach git status --porcelain')
			if output{
				return "Submodule changes detected"
			}
			return "Submodules synced"
		}

		GetMaxButtonWidth(params*) {
			maxWidth := 0
			for btn in params {
				; Create temporary GUI to measure text
				measureGui := Gui("-Caption +ToolWindow")
				measureGui.SetFont(,myGui.Font)
				; measureText := measureGui.AddText(, btn.Text)
				measureText := measureGui.AddText()
				measureText.GetPos(&x, &y, &w, &h)
				metrics := {w:w, h:h, x:x, y:y}
				measureGui.Destroy()
				
				; Add padding (20px on each side)
				width := metrics.w + 40
				maxWidth := Max(maxWidth, width)
			}
			return maxWidth
		}

		GuiSize(thisGui, minMax, width, height) {
			if minMax = -1    ; If window is minimized
				return

			; Calculate margins and spacing
			margin := 10
			padding := 5
			
			; Calculate available width
			availWidth := width - (2 * margin)
			
			; Resize ListView
			this.LV.Move(margin, margin, availWidth, height * 0.5)
			
			; Resize button group and position buttons
			buttonGroupHeight := 80
			this.buttonGroup.Move(margin, height * 0.5 + margin, availWidth, buttonGroupHeight)
			
			; Calculate button positions
			btnWidth := GetMaxButtonWidth()
			totalBtnWidth := (btnWidth + padding) * this.buttons.Length
			startX := (availWidth - totalBtnWidth) / 2
			btnY := (height * 0.5 + margin) + 30  ; 30px from top of group box
			
			; ; Position buttons
			; for i, btn in this.buttons {
			; 	btn.Move(startX + ((i-1) * (btnWidth + padding)), btnY, btnWidth, 40)
			; }
			
			; Resize log window
			logY := height * 0.5 + margin + buttonGroupHeight + margin
			logHeight := height - logY - margin
			this.logEdit.Move(margin, logY, availWidth, logHeight)
		}

		AddToolbar() {
			toolbar := this.myGui.AddToolbar()
			toolbar.Add("Icon1", "Add Repository", (*) => myGui.Show())
			toolbar.Add("Icon2", "Settings", (*) => SettingsGui.Show())
			toolbar.Add("Icon3", "Health Check", (*) => ShowRepoHealth())
		}

		ShowRepoHealth() {
			row := this.LV.GetNext(0)
			if !row
				return
				
			repo := repos[row]
			metrics := RepoHealth.Check(repo)
			
			; Show health report
			healthGui := Gui("+Owner" . this.myGui.Hwnd, "Repository Health")
			healthGui.AddText(, "Branch Status: " . metrics.branchStatus)
			healthGui.AddText(, "Last Commit: " . metrics.lastCommit)
			healthGui.AddText(, "Submodule Health: " . metrics.submoduleHealth)
			healthGui.AddText(, "Uncommitted Changes: " . metrics.uncommittedChanges)
			healthGui.Show()
		}
	}
	; Helper function to execute command and get output
	static RunCmdAndGetOutput(cmd, maxRetries := 3) {
		loop maxRetries {
			try {
				tempFile := A_Temp . "\git_cmd_output.txt"
				RunWait("cmd.exe /c " . cmd . " > " . tempFile . " 2>&1",, "Hide")
				output := FileRead(tempFile)
				FileDelete(tempFile)
				return output
			}
			catch as e {
				if A_Index = maxRetries
					throw e
				Sleep(1000)  ; Wait before retry
			}
		}
	}
	RunCmdAndGetOutput(cmd, maxRetries := 3) {
		return GitRepoGui.RunCmdAndGetOutput(cmd, maxRetries)
	}
}
RunCmdAndGetOutput(cmd, maxRetries := 3) => GitRepoGui.RunCmdAndGetOutput(cmd, maxRetries)

class PathFormatter {
	static FormatPath(path) {
		; Replace backslashes with forward slashes
		path := StrReplace(path, "\", "/")
		
		; Replace user profile path with ~
		userProfile := EnvGet("USERPROFILE")
		if InStr(path, userProfile) = 1
			path := "~" . SubStr(path, StrLen(userProfile) + 1)
		
		return path
	}
}

; Add this class for submodule management
class SubmoduleManager {
	static CheckAndUpdateSubmodules(repoPath) {
		if !FileExist(repoPath . "\.gitmodules")
			return "No submodules"
			
		try {
			; Initialize submodules if needed
			RunWait('cd /d "' . repoPath . '" && git submodule init', , "Hide")
			
			; Update submodules recursively
			RunWait('cd /d "' . repoPath . '" && git submodule update --init --recursive', , "Hide")
			
			; Check submodule status
			output := GitRepoGui().RunCmdAndGetOutput('cd /d "' . repoPath . '" && git submodule foreach git status --porcelain')
			if output
				return "Submodule changes pending"
				
			return "Submodules synced"
		}
		catch as e {
			return "Submodule error: " . e.Message
		}
	}

	static SyncSubmodules(repoPath) {
		try {
			; Update submodules
			RunWait('cd /d "' . repoPath . '" && git submodule update --init --recursive', , "Hide")
			
			; Stage submodule changes
			RunWait('cd /d "' . repoPath . '" && git add -A', , "Hide")
			
			; Commit submodule changes
			RunWait('cd /d "' . repoPath . '" && git commit -m "Update submodules"', , "Hide")
			
			; Push with submodules
			RunWait('cd /d "' . repoPath . '" && git push --recurse-submodules=on-demand', , "Hide")
			
			return true
		}
		catch {
			return false
		}
	}
}

class ProgressGui {
	static pg := 0
	static Show(title, text) {
		if !IsObject(this.pg)
			pg := Gui("+AlwaysOnTop", "Progress")
		pg.Add("Text",, text)
		pg.Show("NoActivate")
		return pg
	}
	
	static Hide() {
		if IsObject(this.pg){
			this.pg.Hide()
		}
	}
}

class Settings {
	static file := A_ScriptDir . "\git_sync_settings.ini"
	
	static Save(repos) {
		for i, repo in repos {
			IniWrite(repo.remote, this.file, "Repo" . i, "remoteRepo")
			IniWrite(repo.local, this.file, "Repo" . i, "localRepo")
			IniWrite(repo.branch, this.file, "Repo" . i, "branchRepo")
		}
	}
	
	static Load() {
		settings := {
			repos: [],
			autoSync: 0,
			defaultBranch: "master",
			autostart: 0
		}

		; Load settings
		try {
			settings.autoSync := Integer(this.Get("AutoSync", "0"))
			settings.defaultBranch := this.Get("DefaultBranch", "master")
			settings.autostart := Integer(this.Get("Autostart", "0"))
		}

		; Load repositories
		i := 1
		while true {
			try {
				remoteRepo := IniRead(this.file, "Repo" . i, "remoteRepo")
				localRepo := IniRead(this.file, "Repo" . i, "localRepo")
				branchRepo := IniRead(this.file, "Repo" . i, "branchRepo")
				settings.repos.Push(GitRepo(remoteRepo, localRepo, branchRepo))
				i++
			}
			catch
				break
		}
		return settings
	}

	static Get(key, default := "") {
		try {
			return IniRead(this.file, "Settings", key)
		}
		catch {
			return default
		}
	}
}

class LogManager {
	static LoadHistory() {
		static logFile := A_ScriptDir . "\git_sync_history.log"
		if FileExist(logFile) {
			try {
				history := FileRead(logFile)
				return history
			}
		}
		return ""
	}
	
	static InitializeLog(logEdit) {
		history := this.LoadHistory()
		if history
			logEdit.Value := history
	}
}
class SettingsGui {
	static mainGui := ""

	static Create() {
		settingsGui := Gui("+Owner" . this.mainGui.Hwnd . " +ToolWindow", "Repository Settings")
		; settingsGui := Gui("+Owner" . mainGui.Hwnd . " +ToolWindow", "Repository Settings")
		; settingsGui.BackColor := GuiColors.mColors['darkgray']
		settingsGui.BackColor := StrReplace('#D3D3D3', '#', '0x')  ; Light gray color
		settingsGui.SetFont('s10 Q5', 'Segoe UI')
		
		; Settings controls
		settingsGui.AddText("w200", "Default Branch:")
		defaultBranch := settingsGui.AddEdit("w180", Settings.Get("DefaultBranch", "master"))
		
		settingsGui.AddText("w200", "Auto-sync Interval (minutes):")
		autoSync := settingsGui.AddEdit("w180", Settings.Get("AutoSync", "0"))
		
		settingsGui.AddCheckbox("w200 vAutostart", "Start with Windows")
			.Value := Settings.Get("Autostart", 0)
			
		settingsGui.AddButton("w100", "Save").OnEvent("Click", (*) => this.SaveSettings(settingsGui))
		settingsGui.AddButton("x+10 w100", "Cancel").OnEvent("Click", (*) => settingsGui.Hide())
		
		return settingsGui
	}
	
	static Show() {
		if !this.gui
			this.gui := this.Create()
		this.gui.Show("AutoSize")
	}

	static SaveSettings(settingsGui) {
		defaultBranch := settingsGui["defaultBranch"].Value
		autoSync := settingsGui["autoSync"].Value
		autostart := settingsGui["Autostart"].Value

		; Save to INI file
		IniWrite(defaultBranch, Settings.file, "Settings", "DefaultBranch")
		IniWrite(autoSync, Settings.file, "Settings", "AutoSync")
		IniWrite(autostart, Settings.file, "Settings", "Autostart")

		; Update sync scheduler if needed
		if autoSync > 0
			SyncScheduler.Schedule(autoSync)

		settingsGui.Hide()
	}
}

class AddRepoGui {
	static Create() {
		addGui := Gui("+Owner" . SettingsGui.mainGui.Hwnd . " +ToolWindow", "Add Repository")
		; addGui.BackColor := GuiColors.mColors['darkgray']
		addGui.BackColor := StrReplace('#D3D3D3', '#', '0x')  ; Light gray color
		addGui.SetFont('s10 Q5', 'Segoe UI')
		
		; Local repo section
		addGui.AddText("w200", "Local Repository:")
		localPath := addGui.AddEdit("w400")
		addGui.AddButton("x+5 w80", "Browse").OnEvent("Click", (*) => this.BrowseFolder(localPath))
		
		; Preset paths
		addGui.AddGroupBox("xm w485 h100", "Quick Paths")
		addGui.AddCheckbox("xm+10 yp+20", "Standard Library")
			.OnEvent("Click", (*) => localPath.Value := A_MyDocuments "\AutoHotkey\Lib")
		addGui.AddCheckbox("x+10", "User Library")
			.OnEvent("Click", (*) => localPath.Value := A_AppData "\AutoHotkey\Lib")
		
		; Remote repo section
		addGui.AddText("xm w200", "Remote Repository:")
		remotePath := addGui.AddEdit("w400")
		addGui.AddButton("x+5 w80", "Browse Existing").OnEvent("Click", (*) => this.ShowExistingRepos())
		
		; Branch selection
		addGui.AddGroupBox("xm w485 h120", "Branch Options")
		branchOpt := addGui.AddRadio("xm+10 yp+20", "Master")
		addGui.AddRadio("x+10", "Main")
		addGui.AddRadio("x+10", "Follow Remote")
		customBranch := addGui.AddRadio("x+10", "Custom:")
		branchName := addGui.AddEdit("xm+10 y+5 w150 Disabled")
		customBranch.OnEvent("Click", (*) => branchName.Enabled := true)
		
		; Add/Cancel buttons
		addGui.AddButton("xm w100", "Add Repository")
			.OnEvent("Click", (*) => this.AddRepository(localPath.Value, remotePath.Value, this.GetBranchName(branchOpt, branchName), addGui))
		addGui.AddButton("x+10 w100", "Cancel").OnEvent("Click", (*) => addGui.Hide())
		
		return addGui
	}
	
	static GetBranchName(radioGroup, customEdit) {
		if radioGroup.Value = 1
			return "master"
		else if radioGroup.Value = 2
			return "main"
		else if radioGroup.Value = 3
			return ""  ; Will be determined from remote
		return customEdit.Value
	}
	
	static BrowseFolder(editCtrl) {
		if folder := FileSelect("D")
			editCtrl.Value := folder
	}

	static AddRepository(localPath, remotePath, branch, gui) {
		if (!localPath || !remotePath) {
			MsgBox("Please provide both local and remote repository paths.", "Required Fields Missing", "Icon!")
			return
		}

		try {
			; Create new repository entry
			newRepo := GitRepo(remotePath, localPath, branch)
			
			; Add to settings
			Settings.Save([newRepo])
			
			; Close the add repository dialog
			gui.Hide()
			
			; Refresh main GUI
			SettingsGui.mainGui.PostMessage(0x0111)  ; Simulate refresh
		}
		catch as err {
			MsgBox("Error adding repository: " err.Message, "Error", "Icon!")
		}
	}

	static ShowExistingRepos() {
		; Create a GUI to show existing repositories
		repoGui := Gui("+Owner" . SettingsGui.mainGui.Hwnd . " +ToolWindow", "Existing Repositories")
		; repoGui.BackColor := GuiColors.mColors['darkgray']
		repoGui.BackColor := StrReplace('#D3D3D3', '#', '0x')  ; Light gray color
		repoGui.SetFont('s10 Q5', 'Segoe UI')
		
		; Add ListView to show repos
		LV := repoGui.AddListView("w400 h200", ["Repository", "Local Path"])
		
		; Load and display existing repos from settings
		repos := Settings.Load()
		for repo in repos {
			repoName := SubStr(repo.remote, InStr(repo.remote, "/", , -1) + 1)
			LV.Add(, repoName, repo.local)
		}
		
		repoGui.Show()
	}
}

class RepoHealth {
	static Check(repo) {
		metrics := {
			branchStatus: this.CheckBranchStatus(repo),
			lastCommit: this.GetLastCommitInfo(repo),
			submoduleHealth: this.CheckSubmoduleHealth(repo),
			uncommittedChanges: this.CountUncommittedChanges(repo)
		}
		return metrics
	}

	static CheckBranchStatus(repo) {
		try {
			output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git status -b --porcelain')
			if InStr(output, "ahead")
				return "Ahead of remote"
			if InStr(output, "behind")
				return "Behind remote"
			return "In sync"
		}
		catch {
			return "Error checking branch"
		}
	}

	static GetLastCommitInfo(repo) {
		try {
			output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git log -1 --pretty=format:"%cr"')
			return output ? output : "No commits"
		}
		catch {
			return "Error checking commits"
		}
	}

	static CheckSubmoduleHealth(repo) {
		return SubmoduleManager.CheckAndUpdateSubmodules(repo.local)
	}

	static CountUncommittedChanges(repo) {
		try {
			output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git status --porcelain')
			return output ? StrSplit(output, "`n").Length : 0
		}
		catch {
			return "Error counting changes"
		}
	}
}

class RepoGroups {
	static Groups := Map(
		"Libraries", ["AHK.Standard.Lib", "AHK.User.Lib"],
		"Projects", ["Personal", "AHK.Projects.v2"],
		"Extensions", ["AHK.ObjectTypeExtensions"]
	)
}

class SyncScheduler {
	static Schedule(interval) {
		SetTimer(() => this.SyncAll(), interval * 60000)
	}

	static SyncAll() {
		; Get all repositories from settings
		repos := Settings.Load()
		for repo in repos {
			; Check and update each repository
			try {
				if DirExist(repo.local "\.git") {
					RunWait('cd /d "' repo.local '" && git pull', , "Hide")

				}
			}
		}
	}
}
