# EXBuildAutomation
Scripts to Automate the Building of Demo Environments

## BuildADUsers.ps1
This is script takes a CSV file with user information to build the associated accounts in ActiveDirectory.  This file makes use of the **BuildParams.json** files for portability.

## AddAADUserLicenses.ps1
This script is use to add the M365 licenses to the users.  These licenses are required for Auto-Pilot.  At some point this needs to be added to *BuildUsers.ps1* to avoid forgetting this step.

## BuildADUsers.json
This file is used to hold parameters that are used in the scripts above.

## ForceADSync.ps1
There are times when you add users that you want to immediately update AzureAD.  This script forces a sync.  This is run on the machine that is hosting AD Connect.
