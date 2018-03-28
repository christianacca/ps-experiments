Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

. "$PSScriptRoot\Write-Menu.ps1"
. "$PSScriptRoot\Read-HostEnhanced.ps1"

# Commands
# Rams5dev -Migration -Start
# Rams5dev -Migration -Abort
# Rams5dev -Migration -Create

$selected = Write-Menu -Menu 'Data and schema', 'Data only' -AddExit -Header 'What type of database migraton?'
if ($selected -eq 'Exit') {
    $false
    return
}
Write-Information 'Preparing for database migration...'
Write-Information 'Record start of migration'
Write-Information 'Add setting override to disable sample and demo data seeding code'
Write-Information 'Ensure database update-to-date (ie reinstall db)'
Write-Information 'Create migration snapshot for the current model'
if ($InformationPreference -eq 'Continue') {
    Write-Host 'Preparing for database migration... ' -NoNewline
    Write-Host 'done' -ForegroundColor Green    
}


$abortChoice = 'Abort'
$selected = Write-Menu -Menu 'Done making model changes (continue)', $abortChoice -Header 'Make your model code changes then come back here'
if ($selected -eq $abortChoice) {
    $false
    return
}

Write-Information 'Create sql migration'
Write-Information 'Add sql migration to clipboard'

Write-Host 'Create migration script then come back here (steps below)' -ForegroundColor Green
Write-Host "`t 1. Add new / open current migration script in readyroll (RR)"
Write-Host "`t 2. Paste the content of the clipboard into the script file"
Write-Host "`t 3. Execute the sql you pasted against the Series5_Dev db"
Write-Host "`t 4. In RR mark migration script as being deployed"
Write-Host "`t 4. Click refresh button in the RR DbSync tool to verify that the script is good"

$abortChoice = 'Abort'
$selected = Write-Menu -Menu 'Done creating sql migtation script (continue)', $abortChoice
if ($selected -eq $abortChoice) {
    $false
    return
}

$abortChoice = 'Abort'
$selected = Write-Menu -Menu 'Yes', 'No', $abortChoice -Header 'Any c# seed code required?'
if ($selected -eq $abortChoice) {
    $false
    return
}
if ($selected -eq 'Yes') {
    $selected = Write-Menu -Menu 'Done making seed code changes (continue)', $abortChoice -Header "Go add this now and come back here when you're done"
    if ($selected -eq $abortChoice) {
        $false
        return
    }
}


Write-Information 'Build sources'
Write-Information 'Apply seeding and meta data changes to database'


$abortChoice = 'Abort'
$selected = Write-Menu -Menu 'Yes', 'No', $abortChoice -Header 'Manually change configuration data using Spa screens?'
if ($selected -eq $abortChoice) {
    $false
    return
}
if ($selected -eq 'Yes') {
    Write-Information 'Show website'
    $selected = Write-Menu -Menu 'Done making config data changes (continue)', $abortChoice -Header "Go add this now and come back here when you're done"
    if ($selected -eq $abortChoice) {
        $false
        return
    }
}


Write-Host 'Add data changes to sql migration script (steps below)' -ForegroundColor Green
Write-Host "`t 1. Run the ReadyRoll (RR) import tool to script a data migration"
Write-Host "`t`t (note: you're going to treat the migration file RR creates as a temporary 'clipboard')"
Write-Host "`t 2. Copy the SQL code generated by RR and add it to the schema migration you created above"
Write-Host "`t 3. Delete this temporary migration"
Write-Host "`t 4. In RR mark the schema migration you've just edited as being deployed"
Write-Host "`t 5. Click refresh button in the RR DbSync tool to verify that the script is good"

$abortChoice = 'Abort'
$selected = Write-Menu -Menu 'Done adding data changes to migtation script (continue)', $abortChoice
if ($selected -eq $abortChoice) {
    $false
    return
}

Write-Information 'Completing migration...'
Write-Information 'Remove setting override that disabled sample and demo data seeding code'
Write-Information 'Test sql migration (ie reinstall db)'
Write-Information 'Record end of migration'

if ($InformationPreference -eq 'Continue') {
    Write-Host 'Completing migration... ' -NoNewline
    Write-Host 'done' -ForegroundColor Green    
}

# -Verbose supplied: explain what is going to happen; show menu giving the option to continue / exit
# Ask what type of migration:
    # 1. Data only
    # 2. Full
# record migration started phase
# Execute prepare phase:
    # Drop a yaml file overide into user folder - this turns off demo and sample data seeding
    # Runs -Reset
    # Full migration: 
        # Scalfold a script only migration
        # Execute the Migrations INSERT statement
# (full migration selected)
# Prompt developer with next step:
    # Make your changes to the model. Example changes:
        # c# model code
        # DbContext
        # Model creation conventions
    # Prompt:
        # Continue
        # Abort (what should happen here?)
# Scalfold a script only migration
    # copy to clipboard everyting except Migrations INSERT statement
# Prompt developer with next step:
    # 1. Add new / open current migration script in readyroll (see link to RR help)
    # 2. Paste the content of the clipboard into the script file
    # 3. Execute the sql against the Series5_Dev db
    # 4. In RR mark migration as being deployed
    # 5. click refresh button in the RR DbSync tool to verify that the script is good
    # Prompt:
        # Continue
        # Abort (what should happen here?)
# Prompt "C# seed code?"
    # Yes
    # No (continue)
    # Abort (what should happen here?)
# If Yes, prompt: "Go add this now and come back here when you're done"
    # Continue
    # Abort (what should happen here?)
# Runs -Build; -Install -Database
# Prompt "Manually add additional metadata?""
    # Yes
    # No (continue)
    # Abort (what should happen here?)
# If Yes to above prompt:
    # -ShowWebsite
    # Prompt:
        # Continue
        # Abort (what should happen here?)
# Prompt developer with next step:
    # Run the ReadyRoll import to script a migration
    # treat the migration just created by ReadyRoll as a temporary clipboard:
		# copy the SQL code and add it to the migration you created above in step 1
		# delete the temporary migration
		# mark the migration you've just edited as being deployed
	# click refresh button in the DbSync tool to verify that the script is good
# Prompt:
    # Done
    # Abort (what should happen here?)
# Remove the yaml override file
# Runs -Reset
    # What should happen if an error occurs here
