#Requires AutoHotkey v2.0
#Include <Extensions\Gui>

/**
 * @class HardlinkCreator
 * @description Creates hardlinks for copilot-instructions.md files across multiple directories
 * @version 1.0.1
 * @author GitHub Copilot
 * @date 2025-04-11
 * @requires AutoHotkey v2.0+
 */
class HardlinkCreator {
    ; Static properties
    masterCopy := "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Lib\.github\copilot-instructions.md"
    targetLocations := [
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\VSCode_DefFiles\.github\copilot-instructions.md",
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Peep\.github\copilot-instructions.md",
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\AHK.Projects.v2\.github\copilot-instructions.md",
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Quartz-RTE\.github\copilot-instructions.md",
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\ICSGUITemplate\.github\copilot-instructions.md",
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\IntelliSense\.github\copilot-instructions.md",
        "c:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\GitAutomationTools\.github\copilot-instructions.md"
    ]
    
    ; Instance properties
    logMessages := []
    logger := ""
    
    /**
     * @constructor
     * @description Initialize the HardlinkCreator with error logging
     */
    __New() {
        ; Initialize error logger for the class
        this.logger := ErrorLogger("HardlinkCreator")
        this.logger.Log("HardlinkCreator initialized")
    }
    
    /**
     * @description Execute the hardlink creation process
     * @returns {HardlinkCreator} Current instance for method chaining
     */
    Execute() {
        this.logger.Log("Starting hardlink creation process")
        
        ; Fix license spelling in master file
        try {
            this._FixMasterFile()
        } catch Error as err {
            this.logger.Log("Error fixing master file")
            this.logger.LogErrorProps(err)
        }
        
        ; Process each target location
        for targetFile in this.targetLocations {
            try {
                this._CreateHardlink(targetFile)
            } catch Error as err {
                this._Log("Error creating hardlink for " targetFile ": " err.Message)
                this.logger.Log("Error creating hardlink for " targetFile)
                this.logger.LogErrorProps(err)
            }
        }
        
        ; Show success message
        this._ShowResults()
        this.logger.Log("Hardlink creation process completed")
        return this
    }
    
    /**
     * @description Fix any spelling issues in the master file
     * @private
     * @throws {Error} If the master file cannot be read or modified
     */
    _FixMasterFile() {
        this.logger.Log("Checking master file for spelling issues: " this.masterCopy)
        
        ; Check if master file exists
        if !FileExist(this.masterCopy) {
            this._Log("Master file not found: " this.masterCopy)
            this.logger.Log("Master file not found")
            throw Error("Master file not found: " this.masterCopy, -1)
        }
        
        try {
            ; Read the master file
            fileContent := FileRead(this.masterCopy)
            
            ; Replace "liscense" with "license" if found
            if InStr(fileContent, "@liscense") {
                this._Log("Fixing license spelling in master file")
                this.logger.Log("Found '@liscense' in master file, correcting to '@license'")
                
                fileContent := StrReplace(fileContent, "@liscense", "@license")
                
                ; Write the corrected content back
                FileDelete(this.masterCopy)
                FileAppend(fileContent, this.masterCopy)
                this._Log("Master file updated with correct spelling")
                this.logger.Log("Master file updated with correct spelling")
            } else {
                this._Log("No spelling issues found in master file")
                this.logger.Log("No spelling issues found in master file")
            }
        } catch Error as err {
            this._Log("Error fixing master file: " err.Message)
            this.logger.Log("Error processing master file")
            throw Error("Error fixing master file: " err.Message, -1, err)
        }
    }
    
    /**
     * @description Create hardlink for a specific target file
     * @param {String} targetFile Path to the target file
     * @private
     * @throws {Error} If hardlink creation fails
     */
    _CreateHardlink(targetFile) {
        this.logger.Log("Creating hardlink for: " targetFile)
        
        ; Ensure directory exists
        dirPath := SubStr(targetFile, 1, InStr(targetFile, "\", , , -1))
        if !DirExist(dirPath) {
            this._Log("Creating directory: " dirPath)
            this.logger.Log("Creating directory: " dirPath)
            try {
                DirCreate(dirPath)
            } catch Error as err {
                this.logger.Log("Failed to create directory")
                this.logger.LogErrorProps(err)
                throw Error("Failed to create directory: " dirPath, -1, err)
            }
        }
        
        ; Delete existing file if it exists
        if FileExist(targetFile) {
            this._Log("Removing existing file: " targetFile)
            this.logger.Log("Removing existing file: " targetFile)
            try {
                FileDelete(targetFile)
            } catch Error as err {
                this.logger.Log("Failed to delete existing file")
                this.logger.LogErrorProps(err)
                throw Error("Failed to delete existing file: " targetFile, -1, err)
            }
        }
        
        ; Create the hardlink using CMD
        this._Log("Creating hardlink: " targetFile)
        this.logger.Log("Running mklink command for: " targetFile)
        
        try {
            runResult := RunWait('cmd.exe /c mklink /H "' targetFile '" "' this.masterCopy '"', , "Hide")
            
            if (runResult != 0) {
                this.logger.Log("mklink command failed with exit code: " runResult)
                throw Error("Failed to create hardlink with exit code: " runResult, -1)
            }
                
            this._Log("Hardlink created successfully: " targetFile)
            this.logger.Log("Hardlink created successfully: " targetFile)
        } catch Error as err {
            this.logger.Log("Error executing mklink command")
            this.logger.LogErrorProps(err)
            throw err
        }
    }
    
    /**
     * @description Add a log message
     * @param {String} message The message to log
     * @private
     */
    _Log(message) {
        this.logMessages.Push(FormatTime(, "yyyy-MM-dd HH:mm:ss") " - " message)
    }
    
    /**
     * @description Show results of the operation
     * @private
     */
    _ShowResults() {
        ; Create a summary
        successCount := 0
        for targetFile in this.targetLocations {
            if FileExist(targetFile)
                successCount++
        }
        
        ; Log the summary
        this.logger.Log("Operation completed. Successful links: " successCount " / " this.targetLocations.Length)
        
        ; Show summary message
        summaryMsg := "Operation completed.`n`n"
            . "Successful links: " successCount " / " this.targetLocations.Length "`n`n"
            . "Would you like to see the detailed log?"
            
        if (MsgBox(summaryMsg, "Hardlink Creator", "YesNo Icon√") = "Yes") {
            logText := ""
            for msg in this.logMessages
                logText .= msg "`n"
                
            ; Display log in a larger window
            this._ShowLogWindow(logText)
        }
    }
    
    /**
     * @description Show log contents in a custom GUI
     * @param {String} logText The log text to display
     * @private
     */
    _ShowLogWindow(logText) {
        ; Create error log GUI using ErrorLogGui class
        errorLogGui := ErrorLogGui("Hardlink Creator Log", logText)
        errorLogGui.Show()
    }
    
    /**
     * @description Clean up resources when object is destroyed
     */
    __Delete() {
        this.logger.Log("HardlinkCreator instance destroyed")
    }
}

; Main execution block
try {
    ; Create and initialize error logger for main script
    mainLogger := ErrorLogger("HardlinkCreator-Main")
    mainLogger.Log("Starting hardlink creation script")
    
    ; Create and execute the hardlink creator
    makehardlinks := HardlinkCreator()
    makehardlinks.Execute()
    
    mainLogger.Log("Hardlink creation completed successfully")
} catch Error as err {
    ; Handle uncaught exceptions
    if IsSet(mainLogger) {
        mainLogger.Log("Critical error in script execution")
        mainLogger.LogErrorProps(err)
    } else {
        ; Fallback error handling if logger couldn't be created
        MsgBox("Critical error: " err.Message, "Error", "Icon!")
    }
    
    ; Display error log GUI with the error details
    ; Display error log GUI with the error details
    errorText := "Critical error occurred:`n"
        . "Message: " err.Message "`n"
        . "File: " err.File "`n"
        . "Line: " err.Line "`n"
        . "What: " err.What "`n"
        . "Extra: " err.Extra
        
    ; Create a simple GUI to display the error
    elogGui := Gui(, "Hardlink Creator Error")
    elogGui.SetFont("s10", "Consolas")
    elogGui.AddText("w600 h400", errorText)
    elogGui.AddButton("Default w80", "OK").OnEvent("Click", (*) => elogGui.Destroy())
    elogGui.Show()
    ; elogGui := ErrorLogGui("Hardlink Creator Error", errorText)
    ; elogGui.Show()
}
