@{
    RootModule = 'PSFluentObjectValidation.psm1'
    ModuleVersion = '1.0.2'
    GUID = '90ac3c83-3bd9-4da5-8705-7b82b21963c8'
    Author = 'Joshua Wilson'
    CompanyName = 'PwshDevs'
    Copyright = '(c) 2025 PwshDevs. All rights reserved.'
    Description = 'Contains a helper class and functions to validate objects.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Test-Exist', 'Assert-Exist')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @('exists', 'asserts', 'tests')
    PrivateData = @{
        PSData = @{
            Tags = @('PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS', 'Validation', 'Object', 'Fluent', 'Helper', 'Assert', 'Test', 'Exists')
            LicenseUri = 'https://github.com/pwshdevs/PSFluentObjectValidation/blob/main/LICENSE'
            ProjectUri = 'https://github.com/pwshdevs/PSFluentObjectValidation'
            ReleaseNotes = 'https://github.com/pwshdevs/PSFluentObjectValidation/blob/main/CHANGELOG.md'
        }
    }
}
