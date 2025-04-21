#Requires AutoHotkey v2+
#Include <Includes\Basic>
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

GitRepoGui()

/**
 * @class GitRepoGui
 * @description GUI class to manage Git repository synchronization
 * @version 1.1.0
 * @author OvercastBTC
 */
Class GitRepoGui {

	#Requires AutoHotkey v2+
	logger := ErrorLogger("GitRepoGui")
	; GUI class to manage the Git repository synchronization tool
	__New() {
		; Array of repositories to manage
		this.repos := [
			GitRepo("https://github.com/OvercastBTC/AHK.Standard.Lib", "C:\Users\" A_UserName "\AppData\Local\Programs\AutoHotkey\v2\Lib"),
			GitRepo("https://github.com/OvercastBTC/AHK.User.Lib", A_MyDocuments "\AutoHotkey\Lib"),
			GitRepo("https://github.com/OvercastBTC/Personal", "C:\Users\" A_UserName "\AppData\Local\Programs\AutoHotkey\v2\Personal"),
			GitRepo("https://github.com/OvercastBTC/AHK.ObjectTypeExtensions", "C:\Users\" A_UserName "\AppData\Local\Programs\AutoHotkey\v2\Lib\Extensions"),
			GitRepo("https://github.com/OvercastBTC/AHK.Projects.v2", "C:\Users\" A_UserName "\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2"),
			GitRepo("https://github.com/OvercastBTC/AHK.ExplorerClassicContextMenu", "C:\Users\" A_UserName "\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2\AHK.ExplorerClassicContextMenu")
		]

		; Load settings first
		this.settings := Settings.Load()
		
		; Add dynamically loaded repos from settings to the predefined list
		for repo in this.settings.repos {
			; Check if the repo is already in our list (avoid duplication)
			isDuplicate := false
			for existingRepo in this.repos {
				if (repo.remote = existingRepo.remote) {
					isDuplicate := true
					break
				}
			}
			
			if (!isDuplicate)
				this.repos.Push(repo)
		}

		; Set up sync scheduler if enabled
		if this.settings.autoSync {
			SyncScheduler.Schedule(this.settings.autoSync)
		}

		; Create GUI
		guiOptions := '+ReSize +MinSize600x400'
		this.myGui := Gui(guiOptions, "Git Repository Manager")
		SettingsGui.mainGui := this.myGui
		
		this.myGui.BackColor := GuiColors.Git.Selection
		this.myGui.SetFont('s10 Q5', 'Segoe UI')

		; Add title
		this.myGui.AddText("w800 h30 Center", "Git Repository Synchronization Tool")
		this.myGui.AddText("w800 h2 0x10")  ; Horizontal Line

		; Add menu with Settings and Add Repository options
		this.AddMenu()

		; Modify the ListView columns order and data display
		this.LV := this.myGui.AddListView("w800 h300", 
			["Repository", "Status", "Submodule Status", "Last Synced", "Local Path"])

		; Populate ListView with repos
		for repo in this.repos {
			repoName := PathUtility.SplitPath(repo.remote).filename
			formattedPath := PathFormatter.FormatPath(repo.local)
			; Updated column order matches ListView definition
			this.LV.Add(, repoName, "Not checked", "Checking...", "Never", formattedPath)
		}

		; Add buttons
		this.buttonGroup := this.myGui.AddGroupBox("w800 h100", "Actions")
		this.btnCheckAll := this.myGui.AddButton("xm+10 yp+30 w180 h40", "Check All Repositories")
			.OnEvent("Click", this.CheckAllRepos.Bind(this))
		this.btnPush := this.myGui.AddButton("x+20 w180 h40", "Push Local to Remote")
			.OnEvent("Click", this.PushToRemote.Bind(this))
		this.btnPull := this.myGui.AddButton("x+20 w180 h40", "Pull from Remote")
			.OnEvent("Click", this.PullFromRemote.Bind(this))
		this.btnInit := this.myGui.AddButton("x+20 w180 h40", "Initialize Repositories")
			.OnEvent("Click", this.InitRepos.Bind(this))

		; Add operations log
		this.myGui.AddText("xm w800 h20", "Operation Log:")
		this.logEdit := this.myGui.AddEdit("xm w800 h200 ReadOnly -Wrap", "")

		; Initialize log with history
		LogManager := LogManager()
		LogManager.InitializeLog(this.logEdit)

		; Store control references for resizing
		this.buttons := [this.btnCheckAll, this.btnPush, this.btnPull, this.btnInit]
		
		; Add resize handler
		this.myGui.OnEvent("Size", this.GuiSize.Bind(this))
		
		; Create but don't show yet
		this.myGui.Show("Hide")      
		
		; Run initial check
		this.CheckAllRepos()
		
		; Enable and show GUI
		this.myGui.Opt("-Disabled")  
		this.myGui.Show('AutoSize')
		
		; Make columns fit content
		; this.AutosizeColumns(this.LV)
		; Auto-size columns
		Loop this.LV.GetCount("Column"){
			this.LV.ModifyCol(A_Index, "AutoHdr")
		}
		this.AutosizeColumns(this.LV)  ; Ensure columns fit content after modification
	}

	/**
	 * @description Adds the main menu to the GUI
	 */
	AddMenu() {
		fileMenu := Menu()
		fileMenu.Add("Add Repository", (*) => AddRepoGui.Create().Show())
		fileMenu.Add("Settings", (*) => SettingsGui.Show())
		fileMenu.Add("Exit", (*) => this.myGui.Destroy())

		helpMenu := Menu()
		helpMenu.Add("About", (*) => MsgBox("Git Repository Manager v1.1.0`nAuthor: OvercastBTC", "About"))
		helpMenu.Add("Help", (*) => this.ShowHelp())

		mainMenu := MenuBar()
		mainMenu.Add("&File", fileMenu)
		mainMenu.Add("&Help", helpMenu)
		
		this.myGui.MenuBar := mainMenu
	}

	/**
	 * @description Shows help information
	 */
	ShowHelp() {
		helpText := "Git Repository Manager`n`n"
		helpText .= "This tool helps you manage multiple Git repositories in one place.`n`n"
		helpText .= "Features:`n"
		helpText .= "- Check status of all repositories`n"
		helpText .= "- Push local changes to remote repositories`n"
		helpText .= "- Pull changes from remote repositories`n"
		helpText .= "- Initialize or repair repository configuration`n"
		helpText .= "- Add new repositories to track`n"
		helpText .= "- Automatic synchronization with scheduler`n`n"
		helpText .= "For usage instructions, please see the documentation."
		
		MsgBox(helpText, "Help", "Info")
	}

	/**
	 * @description Check all repositories and update their status (instance method)
	 */
	CheckAllRepos(*) {
		this.LogMsg("Checking all repositories...")
		
		for i, repo in this.repos {
			repoName := PathUtility.SplitPath(repo.remote).filename
			this.LogMsg("Checking " . repoName . "...")
			
			try {
				; Check directory
				if !DirExist(repo.local) {
					this.LV.Modify(i, , , "Local directory missing", "N/A", "Never")
					continue
				}
				
				; Check git repo
				if !DirExist(repo.local . "\.git") {
					this.LV.Modify(i, , , "Not a Git repository", "N/A", "Never")
					continue
				}
				
				; Check status including submodules
				status := this.CheckGitRepoStatus(repo)
				this.LV.Modify(i, , , status.status, status.submoduleStatus, FormatTime(, "yyyy-MM-dd HH:mm:ss"))
			}
			catch as err {
				; Use ErrorLogger's static Log method instead
				ErrorLogger.LogErrorProps(err)
				; Update GUI
				this.LogMsg("Error checking " . repoName . ": " . err.Message)
				this.LV.Modify(i, , , "Error", "Error", FormatTime(, "yyyy-MM-dd HH:mm:ss"))
			}
		}
		
		this.LogMsg("Repository check complete.")
		
		; Resize columns to fit content
		this.AutosizeColumns(this.LV)
	}

	/**
	 * @description Check the status of a single Git repository
	 * @param {GitRepo} repo The repository to check
	 * @returns {Object} Status information for the repository
	 */
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

	/**
	 * @description Push local changes to the remote repository
	 */
	PushToRemote(*) {
		row := this.LV.GetNext(0)
		if !row {
			MsgBox("Please select a repository first.", "Repository Required", "Info")
			return
		}
		
		repo := this.repos[row]
		repoName := PathUtility.SplitPath(repo.remote).filename
		
		this.LogMsg("Checking status of " . repoName . "...")
		
		try {
			; First check if we're in a git repository
			if !DirExist(repo.local . "\.git") {
				this.LogMsg("Error: Not a git repository: " . repo.local)
				return
			}

			; Check for submodules
			if FileExist(repo.local . "\.gitmodules") {
				this.LogMsg("Submodules detected. Updating submodules first...")
				
				; Initialize and update submodules
				output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git submodule update --init --recursive')
				this.LogMsg("Submodule update result: " . output)
				
				; Check submodule status
				output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git submodule status')
				this.LogMsg("Submodule status: " . output)
			}

			; Get status before push
			statusOutput := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git status --porcelain')
			if !statusOutput {
				this.LogMsg("No changes to commit in " . repoName)
				return
			}

			; Stage and commit changes including submodules
			this.LogMsg("Staging changes...")
			output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git add -A')
			
			; Commit with detailed message
			commitMsg := Format("Auto-sync commit from {1}`nTimestamp: {2}`nStatus before commit:`n{3}",
				A_ComputerName,
				FormatTime(, "yyyy-MM-dd HH:mm:ss"),
				statusOutput)
				
			output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git commit -m "' . commitMsg . '"')
			this.LogMsg("Commit result: " . output)
			
			; Push changes
			this.LogMsg("Pushing changes to remote...")
			output := RunCmdAndGetOutput('cd /d "' . repo.local . '" && git push --recurse-submodules=on-demand origin ' . repo.branch)
			this.LogMsg("Push result: " . output)
			
			; Update status in list view
			status := this.CheckGitRepoStatus(repo)
			this.LV.Modify(row, , , status.status, status.submoduleStatus, FormatTime(, "yyyy-MM-dd HH:mm:ss"))
		}
		catch as err {
			; Use ErrorLogger's static Log method instead
			ErrorLogger.LogErrorProps(err)
			; Update GUI
			this.LogMsg("Error checking " . repoName . ": " . err.Message)
			this.LV.Modify(row, , , "Error", "Error", FormatTime(, "yyyy-MM-dd HH:mm:ss"))
		}
	}

	/**
	 * @description Pull changes from the remote repository
	 */
	PullFromRemote(*) {
		row := this.LV.GetNext(0)
		if !row {
			MsgBox("Please select a repository first.")
			return
		}
		
		repo := this.repos[row]
		repoName := PathUtility.SplitPath(repo.remote).filename
		
		this.LogMsg("Pulling " . repoName . " from remote...")
		
		try {
			; Show progress
			progressGui := ProgressGui.Show("Pulling Repository", "Backing up untracked files...")
			
			; Backup untracked files first
			backupDir := A_Temp . "\git_backup_" . FormatTime(,"yyyyMMdd_HHmmss")
			DirCreate(backupDir)
			output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git ls-files --others --exclude-standard > " . backupDir . "\untracked_files.txt")
			
			; Update progress
			progressGui.UpdateText("Fetching from remote...")
			
			; Fetch and reset to remote
			output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git reset --hard origin/" . repo.branch)
			this.LogMsg(output)
			
			; Update progress
			progressGui.UpdateText("Updating submodules...")
			
			; Update submodules if present
			if FileExist(repo.local . "\.gitmodules") {
				this.LogMsg("Updating submodules...")
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git submodule update --init --recursive")
				this.LogMsg("Submodule update result: " . output)
			}
			
			; Close progress dialog
			progressGui.Close()
			
			; Update status in list view
			status := this.CheckGitRepoStatus(repo)
			this.LV.Modify(row, , , status.status, status.submoduleStatus, FormatTime(,"yyyy-MM-dd HH:mm:ss"))
			
			; Inform about backup
			this.LogMsg("Untracked files list saved to: " . backupDir . "\untracked_files.txt")
			
			MsgBox("Successfully pulled latest changes from remote.", "Pull Complete", "Info")
		}
		catch as e {
			; Make sure to close progress dialog on error
			if IsSet(progressGui)
				progressGui.Close()
				
			errorMsg := "Error: " . e.Message
			this.LogMsg(errorMsg)
			ErrorLogger.Log(errorMsg, this.logEdit)
			MsgBox("Error pulling from repository. Check the log for details.", "Pull Error", "Icon!")
		}
	}

	/**
	 * @description Initialize or repair repository configuration
	 */
	InitRepos(*) {
		row := this.LV.GetNext(0)
		if !row {
			MsgBox("Please select a repository first.")
			return
		}
		
		repo := this.repos[row]
		repoName := PathUtility.SplitPath(repo.remote).filename
		
		this.LogMsg("Initializing " . repoName . "...")
		
		try {
			; Create directory if it doesn't exist
			if !DirExist(repo.local) {
				DirCreate(repo.local)
				this.LogMsg("Created directory: " . repo.local)
			}
			
			; Enhanced check for existing Git repository
			if DirExist(repo.local . "\.git") {
				this.LogMsg("Found existing Git repository. Checking configuration...")
				
				; Check if the remote URL matches
				remoteOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote -v")
				
				if InStr(remoteOutput, repo.remote) {
					this.LogMsg("Remote URL already correctly configured.")
				} else {
					; Check if origin exists
					if InStr(remoteOutput, "origin") {
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote set-url origin " . repo.remote)
						this.LogMsg("Updated existing remote URL to: " . repo.remote)
					} else {
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git remote add origin " . repo.remote)
						this.LogMsg("Added remote 'origin' with URL: " . repo.remote)
					}
				}
				
				; Check if branch exists
				branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch")
				
				if !InStr(branchOutput, repo.branch) {
					this.LogMsg("Creating branch '" . repo.branch . "' tracking remote...")
					output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
					this.LogMsg(output)
				} else {
					; Make sure the branch is correctly tracking
					trackingOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -vv")
					
					if !InStr(trackingOutput, "origin/" . repo.branch) {
						this.LogMsg("Setting correct tracking for branch '" . repo.branch . "'...")
						output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch --set-upstream-to=origin/" . repo.branch . " " . repo.branch)
						this.LogMsg(output)
					} else {
						this.LogMsg("Branch '" . repo.branch . "' already correctly tracking remote.")
					}
				}
			} else {
				; Initialize a completely new repository
				this.LogMsg("No Git repository found. Initializing new repository...")
				output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git init && git remote add origin " . repo.remote)
				this.LogMsg("Initialized new Git repository and added remote.")
				
				; Try to fetch and track the remote branch
				fetchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git fetch origin")
				this.LogMsg("Fetched remote repository.")
				
				; Check if the remote branch exists
				branchOutput := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git branch -r")
				
				if InStr(branchOutput, "origin/" . repo.branch) {
					output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout -b " . repo.branch . " --track origin/" . repo.branch)
					this.LogMsg("Created local branch tracking remote branch '" . repo.branch . "'.")
				} else {
					; Create an empty branch with the right name
					output := RunCmdAndGetOutput("cd /d " . '"' . repo.local . '"' . " && git checkout --orphan " . repo.branch)
					this.LogMsg("Created new branch '" . repo.branch . "'. Remote branch does not exist yet.")
				}
			}
			
			; Update status
			status := this.CheckGitRepoStatus(repo)
			this.LV.Modify(row, , , status.status, status.submoduleStatus, FormatTime(,"yyyy-MM-dd HH:mm:ss"))
			
			MsgBox("Repository initialized successfully!", "Repository Ready", "Info")
		}
		catch as e {
			errorMsg := "Error: " . e.Message
			this.LogMsg(errorMsg)
			ErrorLogger.Git(errorMsg, this.logEdit)
			MsgBox("Error initializing repository. Check the log for details.", "Init Error", "Icon!")
		}
	}

	/**
	 * @description Log a message to the operations log
	 * @param {String} msg Message to log
	 */
	LogMsg(msg) {
		; Format message with computer name and timestamp
		formattedMsg := Format("[{1}][{2}][{3}] {4}", 
			A_ComputerName,
			FormatTime(, "yyyy-MM-dd"),
			FormatTime(, "HH:mm:ss"),
			msg)
		
		; Update GUI - Add new messages at top
		this.logEdit.Value := formattedMsg . "`r`n" . this.logEdit.Value
		
		; Append to log file - Keep chronological order in file
		try FileAppend(formattedMsg . "`n", A_ScriptDir . "\git_sync_history.log")
	}

	/**
	 * @description Auto-size ListView columns to fit their content
	 * @param {ListView} LV ListView to resize columns
	 */
	AutosizeColumns(LV) {
		static LVM_SETCOLUMNWIDTH := 0x101E
		
		; Auto-size each column
		Loop LV.GetCount("Col") {
			SendMessage(LVM_SETCOLUMNWIDTH, A_Index-1, -2, LV) ; -2 = LVSCW_AUTOSIZE_USEHEADER
		}
	}

	/**
	 * @description Handle GUI resizing
	 * @param {Gui} thisGui GUI object
	 * @param {Integer} minMax Minimized/maximized state
	 * @param {Integer} width New width
	 * @param {Integer} height New height
	 */
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
		btnWidth := 180  ; Fixed button width
		totalBtnWidth := (btnWidth + padding) * this.buttons.Length
		startX := margin + (availWidth - totalBtnWidth) / 2
		btnY := (height * 0.5 + margin) + 30  ; 30px from top of group box
		
		; Position buttons
		try for i, btn in this.buttons {
			btn.Move(startX + ((i-1) * (btnWidth + padding)), btnY, btnWidth, 40)
		}
		
		; Resize log window
		logY := height * 0.5 + margin + buttonGroupHeight + margin
		logHeight := height - logY - margin
		this.logEdit.Move(margin, logY, availWidth, logHeight)
	}
}
/**
 * @class LogManager
 * @description Manages logging operations
 */
class LogManager {
	/**
	 * @description Initializes the log with a given control
	 * @param {Edit} logEdit The edit control to display logs
	 */
	InitializeLog(logEdit) {
		logEdit.Value := "Log initialized.`r`n"
	}
}

/**
 * @class PathUtility
 * @description Utility for working with file paths
 */

class PathUtility {
	/**
	 * @description Split a path into its components
	 * @param {String} Path Path to split
	 * @returns {Object} Path components
	 */
	static SplitPath(Path) {
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
}

/**
 * @class PathFormatter
 * @description Format paths for display
 */
class PathFormatter {
	/**
	 * @description Format a path for display
	 * @param {String} path Path to format
	 * @returns {String} Formatted path
	 */
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

/**
 * @class SubmoduleManager
 * @description Manage Git submodules
 */
class SubmoduleManager {
	/**
	 * @description Check and update submodules
	 * @param {String} repoPath Repository path
	 * @returns {String} Submodule status
	 */
	static CheckAndUpdateSubmodules(repoPath) {
		if !FileExist(repoPath . "\.gitmodules")
			return "No submodules"
			
		try {
			; Initialize submodules if needed
			RunWait('cd /d "' . repoPath . '" && git submodule init', , "Hide")
			
			; Update submodules recursively
			RunWait('cd /d "' . repoPath . '" && git submodule update --init --recursive', , "Hide")
			
			; Check submodule status
			output := RunCmdAndGetOutput('cd /d "' . repoPath . '" && git submodule foreach git status --porcelain')
			if output
				return "Submodule changes pending"
				
			return "Submodules synced"
		}
		catch as e {
			return "Submodule error: " . e.Message
		}
	}

	/**
	 * @description Sync submodules with remote
	 * @param {String} repoPath Repository path
	 * @returns {Boolean} True if successful
	 */
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

/**
 * @description Executes a command and returns its output
 * @param {String} cmd Command to execute
 * @returns {String} Output of the command
 */
RunCmdAndGetOutput(cmd) {
	try {
		output := ""
		output := ""
		RunWait(cmd, , "Hide", &output)
		return output
	} catch {
		return "Error executing command: " . cmd
	}
}

/**
 * @class ProgressGui
 * @description Simple progress indicator GUI
 */
class ProgressGui {
	pg := 0
	textControl := 0
	
	/**
	 * @description Show progress dialog
	 * @param {String} title Dialog title
	 * @param {String} text Status message
	 * @returns {ProgressGui} Progress dialog instance
	 */
	Show(title, text) {
		this.pg := Gui("+AlwaysOnTop +ToolWindow -SysMenu", title)
		this.pg.SetFont("s10", "Segoe UI")
		this.pg.BackColor := "EEEEEE"
		
		; Add text label
		this.textControl := this.pg.AddText("w300 h60 Center", text)
		
		; Add progress bar
		this.progressBar := this.pg.AddProgress("w300 h20 Range0-100", 0)
		
		; Show dialog
		this.pg.Show("AutoSize Center")
		
		; Start progress animation
		SetTimer(this.AnimateProgress.Bind(this), 100)
		
		return this
	}
	
	/**
	 * @description Update progress text
	 * @param {String} text New status message
	 */
	UpdateText(text) {
		this.textControl.Text := text
	}
	
	/**
	 * @description Animate progress bar
	 */
	AnimateProgress() {
		static value := 0
		value := Mod(value + 5, 100)
		this.progressBar.Value := value
	}
	
	/**
	 * @description Close progress dialog
	 */
	Close() {
		SetTimer(this.AnimateProgress.Bind(ProgressGui), 0)
		this.pg.Destroy()
	}
}

/**
 * @class Settings
 * @description Manage application settings
 */
class Settings {
	static file := A_ScriptDir . "\git_sync_settings.ini"
	static repos := []
	
	/**
	 * @description Save repositories to settings file
	 * @param {Array} repos Repositories to save
	 */
	static Save(repos) {
		for i, repo in repos {
			IniWrite(repo.remote, this.file, "Repo" . i, "remoteRepo")
			IniWrite(repo.local, this.file, "Repo" . i, "localRepo")
			IniWrite(repo.branch, this.file, "Repo" . i, "branchRepo")
		}
	}
	
	/**
	 * @description Load settings from file
	 * @returns {Object} Loaded settings
	 */
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
				branchRepo := IniRead(this.file, "Repo" . i, "branchRepo", "master")
				settings.repos.Push(GitRepo(remoteRepo, localRepo, branchRepo))
				i++
			}
			catch
				break
		}
		return settings
	}

	/**
	 * @description Get a setting value
	 * @param {String} key Setting key
	 * @param {String} default Default value
	 * @returns {String} Setting value
	 */
	static Get(key, default := "") {
		try {
			return IniRead(this.file, "Settings", key)
		}
		catch {
			return default
		}
	}

	/**
	 * @description Update a setting value
	 * @param {String} key Setting key
	 * @param {String} value Setting value
	 */
	static Set(key, value) {
		IniWrite(value, this.file, "Settings", key)
	}
}

/**
 * @class SettingsGui
 * @description Manages application settings GUI
 */
class SettingsGui {
    static mainGui := ""

	static Create() {
		settingsGui := Gui("+Owner" . this.mainGui.Hwnd . " +ToolWindow", "Repository Settings")
		; settingsGui := Gui("+Owner" . mainGui.Hwnd . " +ToolWindow", "Repository Settings")
		settingsGui.BackColor := GuiColors.mColors['darkgray']
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
		addGui.BackColor := GuiColors.mColors['darkgray']
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

	static AddRepository(localPath, remotePath, branchName, gui) {
		if (!localPath || !remotePath) {
			MsgBox("Please provide both local and remote repository paths.", "Required Fields Missing", "Icon!")
			return
		}
		
		try {
			repo := GitRepo(remotePath, localPath, branchName)
			Settings.repos.Push(repo)
			Settings.Save(Settings.repos)
			MsgBox("Repository added successfully.", "Success", "Info")
		} catch as err {
			MsgBox("Error adding repository: " err.Message, "Error", "Icon!")
		}
	}

	static ShowExistingRepos() {
		; Create a GUI to show existing repositories
		repoGui := Gui("+Owner" . SettingsGui.mainGui.Hwnd . " +ToolWindow", "Existing Repositories")
		repoGui.BackColor := GuiColors.mColors['darkgray']
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
