# PSFluentObjectValidation: Complete Implementation Guide

| GitHub Actions                                                                                                                                        | PS Gallery                                          | License                              |
|-------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|--------------------------------------|
| [![GitHub Actions Status][github-actions-badge]][github-actions-build] [![GitHub Actions Status][github-actions-badge-publish]][github-actions-build] | [![PowerShell Gallery][psgallery-badge]][psgallery] | [![License][license-badge]][license] |

## General Overview

The PSFluentObjectValidation represents a comprehensive evolution from simple property validation to a high-performance, feature-rich validation engine with advanced array indexing capabilities.

## Installation

```powershell
Install-PSResource -Name PSFluentObjectValidation
# or
Install-Module -Name PSFluentObjectValidation

# Verify installation (long style)
Test-Exists -in @{ test = "value" } -with "test!"
# (short hand)
exists -with "test!" -in @{ test = "value" }
# or alternative
tests -with "test!" -in @{ test = "value" }
# or if you'd rather have thrown errors
Assert-Exists -in @{ test = "value" } -with "test!"
# or you can use a short hand version
asserts -with "test!" -in @{ test = "value" }
# Should return: True
```

## Syntax Guide

### Basic Property Access

```powershell
exists -with "user.name" -in $data              # Simple property
exists -with "user.profile.age" -in $data       # Nested objects
exists -with "config.db.host" -in $data         # Deep nesting
```

As an example, you would normally test this like so
```powershell
if(-not $data.user -or -not $data.user.name -or -not $data.user.profile -or -not $data.user.profile.age) {
    # do something when any of these fields do not exist
}
# vs. PSFluentObjectValidation
if(-not (exists -with "user.name" -in $data) -or -not (exists -with "user.profile.age" -in $data)) {
    # do something when any of these fields do not exist
}
```


### Validation Suffixes

```powershell
exists -with "user.email!" -in $data            # Non-empty validation
exists -with "user.profile?" -in $data          # Object existence
exists -with "settings.theme!" -in $data        # Non-empty string
```

### Array Indexing

```powershell
exists -with "users[0].name" -in $data         # First element
exists -with "users[1].email" -in $data        # Second element
exists -with "products[2].title" -in $data     # Third element
```

### Wildcard Array Validation

```powershell
exists -with "users[*].name" -in $data          # All users have names
exists -with "users[*].email!" -in $data        # All users have non-empty emails
exists -with "products[*].active" -in $data     # All products have active property
```

### Advanced Combinations

```powershell
exists -with "users[0].profile.settings.theme!" -in $data    # Deep + validation
exists -with "products[*].category.name!" -in $data          # Wildcard + deep + validation
exists -with "orders[1].items[*].price" -in $data            # Nested array access
```

## Usage Examples

### Real-World Scenarios

#### API Response Validation

```powershell
$apiResponse = @{
    users = @(
        @{ id = 1; name = "John"; email = "john@test.com"; active = $true },
        @{ id = 2; name = "Jane"; email = "jane@test.com"; active = $true }
    )
    metadata = @{
        total = 2
        page = 1
    }
}

# Validate all users have required fields
exists -in $apiResponse -with "users[*].id"      # All users have IDs
exists -in $apiResponse -with "users[*].name!"   # All users have non-empty names
exists -in $apiResponse -with "users[*].email!"  # All users have non-empty emails

# Validate specific user data
exists -in $apiResponse -with "users[0].active"  # First user has active status
exists -in $apiResponse -with "metadata.total!"  # Metadata has non-empty total
```

#### Configuration Validation

```powershell
$config = @{
    database = @{
        host = "localhost"
        port = 5432
        credentials = @{
            username = "admin"
            password = "secret123"
        }
    }
    servers = @(
        @{ name = "web-01"; ip = "192.168.1.10" },
        @{ name = "web-02"; ip = "192.168.1.11" }
    )
}

# Validate critical configuration
exists -in $config -with "database.host!"                    # Non-empty host
exists -in $config -with "database.credentials.password!"    # Non-empty password
exists -in $config -with "servers[*].name!"                  # All servers have names
exists -in $config -with "servers[*].ip!"                    # All servers have IPs
```

#### E-commerce Data Validation

```powershell
$order = @{
    id = "ORD-12345"
    customer = @{
        name = "John Doe"
        email = "john@example.com"
    }
    items = @(
        @{ sku = "LAPTOP-001"; price = 999.99; quantity = 1 },
        @{ sku = "MOUSE-001"; price = 29.99; quantity = 2 }
    )
}

# Comprehensive order validation
exists -in $order -with "id!"                      # Order has ID
exists -in $order -with "customer.email!"          # Customer has email
exists -in $order -with "items[*].sku!"            # All items have SKUs
exists -in $order -with "items[*].price"           # All items have prices
exists -in $order -with "items[0].quantity"        # First item has quantity
```

## Error Handling & Edge Cases

### Advanced Error Handling

#### Comprehensive Error Messages

```powershell
# Array bounds checking
tests -in $data -with "users[10].name"           # Returns false for out-of-bounds
asserts -in $data -with "users[10].name"         # Throws: "Array index [10] is out of bounds"

# Null safety
tests -in $data -with "user.profile.settings"    # Handles null intermediate objects
asserts -in $data -with "missing.property"       # Throws: "Property 'missing' does not exist"

# Type validation
tests -in $data -with "config.port[0]"          # Throws: "Property 'port' is not an array"
```

#### Wildcard Validation Error Handling

```powershell
# Empty array validation
Test-Exists @{ users = @() } "users[*].name"       # Throws: "Array 'users' is empty"

# Partial validation failures
Test-Exists $data "users[*].email!"                # Validates ALL users have non-empty emails
Assert-Exists $data "users[*].phone!"              # Throws if ANY user lacks phone
```

### Function Reference

#### `Test-Exists` or `tests` or `exists`

**Purpose**: Safely test property existence and validation
**Syntax**: `Test-Exists $object $propertyPath`
**Returns**: `$true` if validation passes, `$false` otherwise
**Error Handling**: Never throws exceptions

#### `Assert-Exists` or `asserts`

**Purpose**: Assert property existence with detailed error reporting
**Syntax**: `Assert-Exists $object $propertyPath`
**Returns**: `void` (throws on failure)
**Error Handling**: Throws descriptive exceptions for debugging

### Advanced Configuration

#### Performance Tuning

- **Warmup Iterations**: Recommended 1000+ for consistent measurements
- **Test Iterations**: 10,000+ for statistical significance
- **Memory Management**: Automatic garbage collection handling

#### Debugging Support

- **Verbose Error Messages**: Detailed exception information
- **Stack Trace Preservation**: Full error context maintenance
- **Development Mode**: Additional validation checks available

## Future Roadmap

### Potential Enhancements

1. **Dynamic Array Slicing**: `users[1:3].name` syntax
2. **Conditional Validation**: `users[active=true].email!` filtering
3. **Performance Profiling**: Built-in benchmarking tools
4. **Visual Studio Code Extension**: IntelliSense support for validation syntax

### Performance Targets

- **Sub-10μs Operations**: Further C# optimization
- **Parallel Validation**: Multi-threaded wildcard processing
- **Memory Optimization**: Zero-allocation validation paths

## Performance Results Overview

### Performance Comparison

Originally this module was written in pure powershell but comparing it against just standard manual testing showed it was very slow (in micro seconds, still fairly quick overall). The the module was rewritten to use a different format for testing, which improved performance but it was still relatively slow compared to just manual validation. The module was then implemented in C# and saw significate performance improvements over even manual processing. The module was updated a 4th time to handle arrays as there are times when its better to test before looping with | ForEach-Object. Below is a series of tests written against all 5 methods.

Based on 10,000 iterations with corrected V3-compatible scenario testing:

| Version | Average Performance | vs Manual | Technology | Array Support |
|---------|-------------------|-----------|------------|---------------|
| **Manual Validation** | 59.68 μs | ±0% | Native PowerShell | Limited |
| **V1 (PowerShell)** | 352.48 μs | +491% | Pure PowerShell | ❌ |
| **V2 (PowerShell)** | 318.71 μs | +434% | Pure PowerShell | ❌ |
| **V3 (C# Basic)** | **13.06 μs** | **-78.1%** | C# Compiled | ❌ |
| **V4 (C# Current)** | **13.86 μs** | **-76.8%** | C# + Array Logic | ✅ |

### Performance Highlights

- **V3**: **78.1% faster** than manual validation - C# performance breakthrough
- **V4**: **76.8% faster** than manual validation with revolutionary array features
- **V4 vs V3**: Only **6.1% slower** - excellent trade-off for massive feature expansion
- **Both C# versions**: **27x faster** than V1, **23x faster** than V2

## Features & Capabilities Matrix

| Feature | V1 | V2 | V3 | V4 | Description |
|---------|----|----|----|----|-------------|
| **Basic Properties** | ✅ | ✅ | ✅ | ✅ | `user.name`, `config.host` |
| **Validation Suffixes** | ✅ | ✅ | ✅ | ✅ | `property!` (non-empty), `property?` (exists) |
| **Nested Navigation** | ✅ | ✅ | ✅ | ✅ | `user.profile.settings.theme` |
| **Array Indexing** | ❌ | ❌ | ❌ | ✅ | `users[0].name`, `products[1].title` |
| **Wildcard Arrays** | ❌ | ❌ | ❌ | ✅ | `users[*].name` (all elements) |
| **Array + Validation** | ❌ | ❌ | ❌ | ✅ | `users[*].email!` (all non-empty) |
| **Deep Array Access** | ❌ | ❌ | ❌ | ✅ | `products[0].category.name` |
| **Error Handling** | Basic | Basic | Enhanced | Advanced | Bounds checking, null safety |

[github-actions-badge]: https://github.com/pwshdevs/PSFluentObjectValidation/actions/workflows/CI.yml/badge.svg
[github-actions-badge-publish]: https://github.com/pwshdevs/PSFluentObjectValidation/actions/workflows/publish.yaml/badge.svg
[github-actions-build]: https://github.com/pwshdevs/PSFluentObjectValidation/actions
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/PSFluentObjectValidation.svg
[psgallery]: https://www.powershellgallery.com/packages/PSFluentObjectValidation
[license-badge]: https://img.shields.io/github/license/pwshdevs/PSFluentObjectValidation.svg
[license]: https://raw.githubusercontent.com/pwshdevs/PSFluentObjectValidation/main/LICENSE
