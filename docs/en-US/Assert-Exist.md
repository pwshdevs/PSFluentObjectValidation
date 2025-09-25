---
external help file: PSFluentObjectValidation-help.xml
Module Name: PSFluentObjectValidation
online version: https://www.pwshdevs.com/
schema: 2.0.0
---

# Assert-Exist

## SYNOPSIS
Asserts the existence and validity of a property within an object.

## SYNTAX

```
Assert-Exist [-InputObject] <Object> [-Key] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The \`Assert-Exist\` function validates the existence of a property within an object and ensures it meets the specified validation criteria.
If the validation fails, it throws a detailed exception, making it suitable for scenarios where strict validation is required.

## EXAMPLES

### EXAMPLE 1
```
Assert-Exist -InputObject $data -Key "user.name!"
```

Asserts that the \`user.name\` property exists and is non-empty

### EXAMPLE 2
```
Assert-Exist -InputObject $data -Key "users[*].email!"
```

Asserts that all users in the array have a non-empty email

### EXAMPLE 3
```
Assert-Exist -InputObject $data -Key "settings.theme"
```

Asserts that the \`settings.theme\` property exists

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
Throws an exception if the validation fails.
Use \`Test-Exist\` for a non-throwing alternative.

## RELATED LINKS

[https://www.pwshdevs.com/](https://www.pwshdevs.com/)

