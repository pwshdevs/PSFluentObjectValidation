# Copilot Instructions for PSFluentObjectValidation

## Project Overview
PSFluentObjectValidation is a PowerShell module that provides fluent syntax for validating complex object structures using dot notation with validation operators. The core functionality is implemented as a C# class embedded in PowerShell, supporting deep object traversal, array indexing, and wildcard validation.

## Architecture

### Core Components
- **C# Implementation**: `PSFluentObjectValidation/Private/PSFluentObjectValidation.ps1` contains the main logic as embedded C# code using `Add-Type`
- **Public Functions**: Thin PowerShell wrappers around the C# class
  - `Test-Exist`: Safe validation that returns boolean
  - `Assert-Exist`: Throws exceptions with detailed error messages
- **Module Structure**: Standard PowerShell module with Public/Private folder separation

### Key Design Patterns

#### Validation Syntax
The module uses a fluent dot notation with special operators:
- `property.nested` - Basic navigation
- `property!` - Non-empty validation (rejects null/empty/whitespace)
- `property?` - Existence validation (allows null values)
- `array[0]` - Array indexing
- `array[*]` - Wildcard validation (all elements must pass)

#### Error Handling Strategy
- `Test-Exist` wraps `Assert-Exist` in try/catch, never throws
- `Assert-Exist` provides detailed error messages with context
- C# implementation uses regex patterns for parsing validation operators

## Development Workflows

### Build System (psake + PowerShellBuild)
```powershell
# Bootstrap dependencies first (one-time setup)
./build.ps1 -Bootstrap

# Standard development workflow
./build.ps1 -Task Build    # Compiles and validates module
./build.ps1 -Task Test     # Runs Pester tests + analysis
./build.ps1 -Task Clean    # Cleans output directory
```

The build uses PowerShellBuild tasks defined in `psakeFile.ps1`. The `requirements.psd1` manages all build dependencies including Pester 5.4.0, PSScriptAnalyzer, and psake.

### Testing Strategy
Tests live in `tests/` directory following these patterns:
- `Manifest.tests.ps1` - Module manifest validation
- `Meta.tests.ps1` - Code quality and PSScriptAnalyzer rules
- `Help.tests.ps1` - Documentation validation
- Use `ScriptAnalyzerSettings.psd1` for custom analysis rules

### Module Compilation
The module uses **non-monolithic** compilation (`$PSBPreference.Build.CompileModule = $false`), preserving individual Public/Private .ps1 files in the output rather than combining into a single .psm1.

## Critical Implementation Details

### C# Embedded Code Patterns
When modifying the C# implementation:
- Use `Add-Type` with `ReferencedAssemblies` for System.Management.Automation
- Regex patterns are compiled for performance: `PropertyWithValidation`, `ArrayIndexPattern`
- Support multiple object types: Hashtables, PSObjects, .NET objects, Arrays, IList, IEnumerable

### Array Processing
The `WildcardArrayWrapper` class enables wildcard validation by:
1. Wrapping array objects during `[*]` processing
2. Validating properties exist on ALL elements
3. Returning first element's value for continued navigation

### Property Resolution Order
1. Check for array indexing pattern `property[index]`
2. Check for validation suffixes `property!` or `property?`
3. Handle wildcard array wrapper context
4. Fall back to regular property navigation

## Common Patterns

### Adding New Validation Operators
1. Update regex patterns in C# code
2. Add case handling in `ProcessPropertyWithValidation`
3. Add validation logic in `ValidatePropertyValue`
4. Update documentation and examples

### Testing Complex Object Structures
Use the fluent syntax patterns from README.md:
```powershell
# Deep nesting with validation
Test-Exist -In $data -With "users[0].profile.settings.theme!"

# Wildcard array validation
Test-Exist -In $data -With "users[*].email!"

# Mixed indexing and wildcards
Test-Exist -In $data -With "orders[1].items[*].price"
```

### Error Message Conventions
- Include property path context: `"Property 'user.name' does not exist"`
- For arrays: `"Array index [10] is out of bounds for 'users' (length: 5)"`
- For wildcards: `"Property 'email' in element [2] is empty"`

## Cross-Platform Considerations
The module targets PowerShell 5.1+ and supports Windows/Linux/macOS. The CI pipeline tests on all three platforms using GitHub Actions with the psmodulecache action for dependency management.
