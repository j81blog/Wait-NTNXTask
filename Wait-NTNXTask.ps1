function Wait-NTNXTask {
    [cmdletbinding()]
    Param(
        # taskUuid returned from Nutanix commands
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$taskUuid,
        
        # If you don't want any data returned, specify this parameter
        [Parameter(Mandatory=$false)]
        [switch]$silent
    )
    Begin {
        if ([string]::IsNullOrEmpty($(Get-PSSnapin -Name NutanixCmdletsPSSnapin -Registered))) {
            Add-PSSnapin NutanixCmdletsPSSnapin
        }
        $task = [PSCustomObject]@{
            status = $null
            taskUuid = $taskUuid
        }
        $notFinished = $true
        $i=0
    } Process {
        do {
            $taskData = Get-NTNXTask -Taskid $task.taskUuid
			$task.status = $taskData.progressStatus
            Write-Verbose "Task: $($taskData | Format-List | Out-String)"
			if ($taskData.progressStatus -eq "Queued") {
			    Write-Verbose "Waiting for task to complete. Status: $($taskData.progressStatus)"
				Write-Progress -Activity "Waiting for task to complete" -Status "Task $($taskData.progressStatus)" -PercentComplete 1
				Start-Sleep -Seconds 1
			}
			if ($taskData.progressStatus -eq "Running") {
			    Write-Verbose "Waiting for task to complete. Status: $($taskData.progressStatus)"
				Write-Progress -Activity "Waiting for task to complete" -Status "Task $($taskData.progressStatus)" -PercentComplete 50
				Start-Sleep -Seconds 1
			}
			if ($taskData.progressStatus -in "Succeeded","Aborted","Failed") {
			    Write-Verbose "Status: $($taskData.progressStatus)"
				Write-Progress -Activity "Waiting for task to complete" -Status "Task $($taskData.progressStatus)" -PercentComplete 100 -Completed
				$notFinished = $false
            }
			if ([string]::IsNullOrEmpty($taskData.progressStatus)) {
			    Write-Verbose "Unknown status. Status: `"$($taskData.progressStatus)`""
				$task.status = "Unknown"
				if($i -gt 10) { Break } else { $i++ }
				Start-Sleep -Seconds 1
			}
        } while ($notFinished)
    } End {
        if (-Not $Silent) {
            Return $task
        }
    }
}
