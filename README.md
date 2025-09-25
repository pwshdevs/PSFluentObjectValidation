# PSFluentObjectValidation: Complete Implementation Guide

**Github**

[![GitHub Actions Status][github-actions-badge]][github-actions-build] [![GitHub Actions Status][github-actions-badge-publish]][github-actions-build] [![GitHub Open Issues Status][github-open-issues-badge]][github-open-issues] [![GitHub Closed Issues Status][github-closed-issues-badge]][github-closed-issues] [![License][license-badge]][license]

**PSGallery**

[![PowerShell Gallery][psgallery-badge]][psgallery] [![PSGallery Version][psgallery-version-badge]][psgallery] [![PSGallery Playform][psgallery-platform-badge]][psgallery] [![PSGallery Playform][ps-desktop-badge]][psgallery]

## General Overview

## Installation

```powershell
Install-PSResource -Name PSFluentObjectValidation
```

or

```powershell
Install-Module -Name PSFluentObjectValidation
```

Once installed, you can run a couple of tests to verify it works as expected:

```powershell
# Verify installation
Test-Exist -In @{ test = "value" } -With "test!"
# Should return: True
```

## Syntax Guide

### Basic Property Access

```powershell
Test-Exist -With "user.name" -In $data              # Simple property
Test-Exist -With "user.profile.age" -In $data       # Nested objects
Test-Exist -With "config.db.host" -In $data         # Deep nesting
```

As an example, you would normally test this like so:

```powershell
if(-not $data.user -or -not $data.user.name -or [string]::IsNullOrWhitespace($data.user.name) -or -not $data.user.profile -or -not $data.user.profile.age) {
    # do something when any of these fields do not exist
}
```

vs. PSFluentObjectValidation

```powershell
if(-not (Test-Exist -With "user.name!" -In $data) -or -not (Test-Exist -With "user.profile.age" -In $data)) {
    # do something when any of these fields do not exist
}
```


### Validation Suffixes

```powershell
Test-Exist -With "user.email!" -In $data            # Non-empty validation
Test-Exist -With "user.profile?" -In $data          # Object existence
Test-Exist -With "settings.theme!" -In $data        # Non-empty string
```

### Array Indexing

```powershell
Test-Exist -With "users[0].name" -In $data         # First element
Test-Exist -With "users[1].email" -In $data        # Second element
Test-Exist -With "products[2].title" -In $data     # Third element
```

### Wildcard Array Validation

```powershell
Test-Exist -With "users[*].name" -In $data          # All users have names
Test-Exist -With "users[*].email!" -In $data        # All users have non-empty emails
Test-Exist -With "products[*].active" -In $data     # All products have active property
```

### Advanced Combinations

```powershell
Test-Exist -With "users[0].profile.settings.theme!" -In $data    # Deep + validation
Test-Exist -With "products[*].category.name!" -In $data          # Wildcard + deep + validation
Test-Exist -With "orders[1].items[*].price" -In $data            # Nested array access
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
Test-Exist -In $apiResponse -With "users[*].id"      # All users have IDs
Test-Exist -In $apiResponse -With "users[*].name!"   # All users have non-empty names
Test-Exist -In $apiResponse -With "users[*].email!"  # All users have non-empty emails

# Validate specific user data
Test-Exist -In $apiResponse -With "users[0].active"  # First user has active status
Test-Exist -In $apiResponse -With "metadata.total!"  # Metadata has non-empty total
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
Test-Exist -In $config -With "database.host!"                    # Non-empty host
Test-Exist -In $config -With "database.credentials.password!"    # Non-empty password
Test-Exist -In $config -With "servers[*].name!"                  # All servers have names
Test-Exist -In $config -With "servers[*].ip!"                    # All servers have IPs
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
Test-Exist -In $order -With "id!"                      # Order has ID
Test-Exist -In $order -With "customer.email!"          # Customer has email
Test-Exist -In $order -With "items[*].sku!"            # All items have SKUs
Test-Exist -In $order -With "items[*].price"           # All items have prices
Test-Exist -In $order -With "items[0].quantity"        # First item has quantity
```

## Error Handling & Edge Cases

### Advanced Error Handling

#### Comprehensive Error Messages

```powershell
# Array bounds checking
Test-Exist -In $data -With "users[10].name"           # Returns false for out-of-bounds
Assert-Exist -In $data -With "users[10].name"         # Throws: "Array index [10] is out of bounds"

# Null safety
Test-Exist -In $data -With "user.profile.settings"    # Handles null intermediate objects
Assert-Exist -In $data -With "missing.property"       # Throws: "Property 'missing' does not exist"

# Type validation
Test-Exist -In $data -With "config.port[0]"          # Throws: "Property 'port' is not an array"
```

#### Wildcard Validation Error Handling

```powershell
# Empty array validation
Test-Exist -In @{ users = @() } -With "users[*].name"       # Throws: "Array 'users' is empty"

# Partial validation failures
Test-Exist -In $data -With "users[*].email!"                # Validates ALL users have non-empty emails
Assert-Exist -In $data -With "users[*].phone!"              # Throws if ANY user lacks phone
```

### Function Reference

#### `Test-Exist`

> **Purpose Safely**: test property existence and validation<br>
> **Syntax**: `Test-Exist -In $object -With $propertyPath`<br>
> **Returns**: `$true` if validation passes, `$false` otherwise<br>
> **Error Handling**: Never throws exceptions<br>

#### `Assert-Exist`

> **Purpose**: Assert property existence with detailed error reporting<br>
> **Syntax**: `Assert-Exist -In $object -With $propertyPath`<br>
> **Returns**: `void` (throws on failure)<br>
> **Error Handling**: Throws descriptive exceptions for debugging<br>

[github-actions-badge]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSFluentObjectValidation/CI.yaml?label=build&style=for-the-badge
[github-actions-badge-publish]: https://img.shields.io/github/actions/workflow/status/pwshdevs/PSFluentObjectValidation/publish.yaml?label=publish&style=for-the-badge
[github-actions-build]: https://github.com/pwshdevs/PSFluentObjectValidation/actions
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/PSFluentObjectValidation?label=downloads&style=for-the-badge
[psgallery]: https://www.powershellgallery.com/packages/PSFluentObjectValidation
[psgallery-version-badge]: https://img.shields.io/powershellgallery/v/PSFluentObjectValidation?label=version&style=for-the-badge
[license-badge]: https://img.shields.io/github/license/pwshdevs/PSFluentObjectValidation?style=for-the-badge
[license]: https://raw.githubusercontent.com/pwshdevs/PSFluentObjectValidation/main/LICENSE
[github-open-issues-badge]: https://img.shields.io/github/issues/pwshdevs/PSFluentObjectValidation?style=for-the-badge
[github-closed-issues-badge]: https://img.shields.io/github/issues-closed/pwshdevs/PSFluentObjectValidation?style=for-the-badge
[github-closed-issues]: https://github.com/pwshdevs/PSFluentObjectValidation/issues?q=is%3Aissue%20state%3Aclosed
[github-open-issues]: https://github.com/pwshdevs/PSFluentObjectValidation/issues
[psgallery-platform-badge]: https://img.shields.io/powershellgallery/p/PSFluentObjectValidation?style=for-the-badge
[ps-desktop-badge]: https://img.shields.io/badge/powershell-5.1,_7.0+-blue?style=for-the-badge
[ps-core-badge]: https://img.shields.io/badge/powershell-5.1,_7.0+-blue?style=for-the-badge
