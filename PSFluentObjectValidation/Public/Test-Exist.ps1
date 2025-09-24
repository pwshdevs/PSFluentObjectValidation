Function Test-Exist {
    param(
        [Parameter(Mandatory=$true)]
        [Alias('In')]
        $InputObject,
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [Alias('With', 'Test')]
        [string]$Key
    )

    return [PSFluentObjectValidation]::TestExists($InputObject, $Key)
}

New-Alias -Name exists -Value Test-Exist
New-Alias -Name tests -Value Test-Exist
