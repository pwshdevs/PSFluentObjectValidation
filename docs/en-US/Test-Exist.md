---
external help file: PSFluentObjectValidation-help.xml
Module Name: PSFluentObjectValidation
online version: https://www.pwshdevs.com/
schema: 2.0.0
---

# Test-Exist

## SYNOPSIS
Tests the existence and validity of a property within an object.

## SYNTAX

```
Test-Exist [-InputObject] <Object> [-Key] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The \`Test-Exist\` function validates the existence of a property within an object and ensures it meets the specified validation criteria.
Unlike \`Assert-Exist\`, this function does not throw exceptions; instead, it returns a boolean value indicating whether the validation passed.

## EXAMPLES

### EXAMPLE 1
```
Test-Exist -InputObject $data -Key "user.name!"
```

Tests that the \`user.name\` property exists and is non-empty.

### EXAMPLE 2
```
Test-Exist -InputObject $data -Key "users[*].email!"
```

Tests that all users in the array have a non-empty email.

### EXAMPLE 3
```
Test-Exist -InputObject $data -Key "settings.theme"
```

Tests that the \`settings.theme\` property exists.

## PARAMETERS

### -InputObject
The object to validate.
This can be a hashtable, PSObject, .NET object, or any other object type.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: In

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key
The property path to validate.
Supports fluent syntax with validation operators:
- \`property.nested\` - Basic navigation
- \`property!\` - Non-empty validation (rejects null/empty/whitespace)
- \`property?\` - Existence validation (allows null values)
- \`array\[0\]\` - Array indexing
- \`array\[*\]\` - Wildcard validation (all elements must pass)

```yaml
Type: String
Parameter Sets: (All)
Aliases: With, Test

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Returns \`$true\` if the validation passes, \`$false\` otherwise.
Use \`Assert-Exist\` for a throwing alternative.

## RELATED LINKS

[https://www.pwshdevs.com/](https://www.pwshdevs.com/)

