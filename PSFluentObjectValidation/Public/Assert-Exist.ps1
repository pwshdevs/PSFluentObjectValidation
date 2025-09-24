function Assert-Exist {
    param(
        [Parameter(Mandatory=$true)]
        [Alias('In')]
        $InputObject,
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [Alias('With', 'Test')]
        [string]$Key
    )

    [PSFluentObjectValidation]::AssertExists($InputObject, $Key)
}

New-Alias -Name asserts -Value Assert-Exist
