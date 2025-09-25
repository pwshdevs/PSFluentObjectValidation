<#
.SYNOPSIS
Asserts the existence and validity of a property within an object.

.DESCRIPTION
The `Assert-Exist` function validates the existence of a property within an object and ensures it meets the specified validation criteria. If the validation fails, it throws a detailed exception, making it suitable for scenarios where strict validation is required.

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
# Validate that the `user.name` property exists and is non-empty
Assert-Exist -InputObject $data -Key "user.name!"

.EXAMPLE
# Validate that all users in the array have a non-empty email
Assert-Exist -InputObject $data -Key "users[*].email!"

.EXAMPLE
# Validate that the `settings.theme` property exists
Assert-Exist -InputObject $data -Key "settings.theme"

.NOTES
Throws an exception if the validation fails. Use `Test-Exist` for a non-throwing alternative.

.LINK
https://www.pwshdevs.com/
#>
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
