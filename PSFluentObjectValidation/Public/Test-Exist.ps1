<#
.SYNOPSIS
Tests the existence and validity of a property within an object.

.DESCRIPTION
The `Test-Exist` function validates the existence of a property within an object and ensures it meets the specified validation criteria. Unlike `Assert-Exist`, this function does not throw exceptions; instead, it returns a boolean value indicating whether the validation passed.

.PARAMETER InputObject
The object to validate. This can be a hashtable, PSObject, .NET object, or any other object type.

.PARAMETER Key
The property path to validate. Supports fluent syntax with validation operators:
- `property.nested` - Basic navigation
- `property!` - Non-empty validation (rejects null/empty/whitespace)
- `property?` - Existence validation (allows null values)
- `array[0]` - Array indexing
- `array[*]` - Wildcard validation (all elements must pass)

.EXAMPLE
# Test if the `user.name` property exists and is non-empty
Test-Exist -InputObject $data -Key "user.name!"

.EXAMPLE
# Test if all users in the array have a non-empty email
Test-Exist -InputObject $data -Key "users[*].email!"

.EXAMPLE
# Test if the `settings.theme` property exists
Test-Exist -InputObject $data -Key "settings.theme"

.NOTES
Returns `$true` if the validation passes, `$false` otherwise. Use `Assert-Exist` for a throwing alternative.

.LINK
https://www.pwshdevs.com/
#>
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
