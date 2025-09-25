BeforeAll {
    # Remove any existing module from session to avoid conflicts
    if (Get-Module PSFluentObjectValidation) {
        Remove-Module PSFluentObjectValidation -Force
    }

    # Import the module from the build output directory (if it exists) or development directory
    $OutputModulePath = "$PSScriptRoot\..\Output\PSFluentObjectValidation\1.0.2\PSFluentObjectValidation.psd1"
    $DevModulePath = "$PSScriptRoot\..\PSFluentObjectValidation\PSFluentObjectValidation.psd1"

    if (Test-Path $OutputModulePath) {
        Import-Module $OutputModulePath -Force
    } elseif (Test-Path $DevModulePath) {
        Import-Module $DevModulePath -Force
    } else {
        throw "Could not find PSFluentObjectValidation module at expected paths"
    }
}

Describe 'PSFluentObjectValidation Module Tests' {

    BeforeAll {
        # Test data structures for comprehensive validation
        $script:TestData = @{
            # Simple properties
            name = "John Doe"
            age = 30
            active = $true

            # Null and empty values
            nullValue = $null
            emptyString = ""
            whitespaceString = "   "
            emptyArray = @()

            # Nested objects
            user = @{
                profile = @{
                    email = "john@example.com"
                    settings = @{
                        theme = "dark"
                        notifications = $true
                    }
                }
                preferences = @{
                    language = "en"
                    timezone = $null
                }
            }

            # Arrays with objects
            users = @(
                @{ id = 1; name = "Alice"; email = "alice@test.com"; active = $true }
                @{ id = 2; name = "Bob"; email = "bob@test.com"; active = $false }
                @{ id = 3; name = "Charlie"; email = ""; active = $true }
                @{ id = 4; name = ""; email = "diana@test.com"; active = $true }
            )

            # Mixed array types
            products = @(
                @{
                    id = 1
                    title = "Laptop"
                    category = @{ name = "Electronics"; active = $true }
                    tags = @("computer", "portable")
                    price = 999.99
                }
                @{
                    id = 2
                    title = "Mouse"
                    category = @{ name = "Accessories"; active = $true }
                    tags = @("peripheral")
                    price = 29.99
                }
            )

            # Complex nested structure
            orders = @(
                @{
                    id = "ORD-001"
                    customer = @{
                        name = "John Smith"
                        email = "john.smith@example.com"
                    }
                    items = @(
                        @{ sku = "LAPTOP-001"; quantity = 1; price = 999.99 }
                        @{ sku = "MOUSE-001"; quantity = 2; price = 29.99 }
                    )
                    metadata = @{
                        source = "web"
                        campaign = $null
                    }
                }
                @{
                    id = "ORD-002"
                    customer = @{
                        name = "Jane Doe"
                        email = "jane@example.com"
                    }
                    items = @(
                        @{ sku = "KEYBOARD-001"; quantity = 1; price = 79.99 }
                    )
                    metadata = @{
                        source = "mobile"
                        campaign = "SUMMER2025"
                    }
                }
            )

            # Empty nested structures
            emptyStructure = @{
                emptyArray = @()
                emptyObject = @{}
                nullArray = $null
            }
        }

        # PSObject test data
        $script:PSObjectData = New-Object PSObject -Property @{
            name = "PSObject Test"
            nested = New-Object PSObject -Property @{
                value = 42
                array = @(1, 2, 3)
            }
        }

        # .NET object test data
        $script:NetObjectData = [PSCustomObject]@{
            Property1 = "Value1"
            Property2 = [PSCustomObject]@{
                SubProperty = "SubValue"
            }
        }
    }

    Context 'Test-Exist Function Tests' {

        Describe 'Basic Property Access' {

            It 'Should return true for existing simple properties' {
                Test-Exist -In $TestData -With "name" | Should -Be $true
                Test-Exist -In $TestData -With "age" | Should -Be $true
                Test-Exist -In $TestData -With "active" | Should -Be $true
            }

            It 'Should return false for non-existing properties' {
                Test-Exist -In $TestData -With "nonexistent" | Should -Be $false
                Test-Exist -In $TestData -With "missing.property" | Should -Be $false
            }

            It 'Should handle null values gracefully' {
                Test-Exist -In $TestData -With "nullValue" | Should -Be $true
            }

            It 'Should work with nested properties' {
                Test-Exist -In $TestData -With "user.profile.email" | Should -Be $true
                Test-Exist -In $TestData -With "user.profile.settings.theme" | Should -Be $true
                Test-Exist -In $TestData -With "user.preferences.language" | Should -Be $true
            }

            It 'Should return false for missing nested properties' {
                Test-Exist -In $TestData -With "user.profile.missing" | Should -Be $false
                Test-Exist -In $TestData -With "user.missing.property" | Should -Be $false
                Test-Exist -In $TestData -With "missing.user.property" | Should -Be $false
            }
        }

        Describe 'Validation Operators' {

            Context 'Non-empty validation (!)' {

                It 'Should return true for non-empty values' {
                    Test-Exist -In $TestData -With "name!" | Should -Be $true
                    Test-Exist -In $TestData -With "user.profile.email!" | Should -Be $true
                    Test-Exist -In $TestData -With "user.profile.settings.theme!" | Should -Be $true
                }

                It 'Should return false for null values' {
                    Test-Exist -In $TestData -With "nullValue!" | Should -Be $false
                    Test-Exist -In $TestData -With "user.preferences.timezone!" | Should -Be $false
                }

                It 'Should return false for empty strings' {
                    Test-Exist -In $TestData -With "emptyString!" | Should -Be $false
                    Test-Exist -In $TestData -With "whitespaceString!" | Should -Be $false
                }

                It 'Should return false for empty arrays' {
                    Test-Exist -In $TestData -With "emptyArray!" | Should -Be $false
                    Test-Exist -In $TestData -With "emptyStructure.emptyArray!" | Should -Be $false
                }

                It 'Should return false for non-existing properties' {
                    Test-Exist -In $TestData -With "nonexistent!" | Should -Be $false
                }
            }

            Context 'Existence validation (?)' {

                It 'Should return true for existing properties even if null' {
                    Test-Exist -In $TestData -With "nullValue?" | Should -Be $true
                    Test-Exist -In $TestData -With "user.preferences.timezone?" | Should -Be $true
                }

                It 'Should return true for non-empty values' {
                    Test-Exist -In $TestData -With "name?" | Should -Be $true
                    Test-Exist -In $TestData -With "user.profile.email?" | Should -Be $true
                }

                It 'Should return false for empty arrays' {
                    Test-Exist -In $TestData -With "emptyArray?" | Should -Be $false
                    Test-Exist -In $TestData -With "emptyStructure.emptyArray?" | Should -Be $false
                }

                It 'Should return false for non-existing properties' {
                    Test-Exist -In $TestData -With "nonexistent?" | Should -Be $false
                }
            }
        }

        Describe 'Array Indexing' {

            It 'Should access array elements by index' {
                Test-Exist -In $TestData -With "users[0]" | Should -Be $true
                Test-Exist -In $TestData -With "users[1]" | Should -Be $true
                Test-Exist -In $TestData -With "users[2]" | Should -Be $true
                Test-Exist -In $TestData -With "users[3]" | Should -Be $true
            }

            It 'Should access properties of array elements' {
                Test-Exist -In $TestData -With "users[0].name" | Should -Be $true
                Test-Exist -In $TestData -With "users[1].email" | Should -Be $true
                Test-Exist -In $TestData -With "users[0].id" | Should -Be $true
            }

            It 'Should return false for out-of-bounds indices' {
                Test-Exist -In $TestData -With "users[10]" | Should -Be $false
                Test-Exist -In $TestData -With "users[100].name" | Should -Be $false
            }

            It 'Should handle negative indices gracefully' {
                Test-Exist -In $TestData -With "users[-1]" | Should -Be $false
            }

            It 'Should work with nested array access' {
                Test-Exist -In $TestData -With "orders[0].items[0]" | Should -Be $true
                Test-Exist -In $TestData -With "orders[0].items[0].sku" | Should -Be $true
                Test-Exist -In $TestData -With "orders[1].items[0].price" | Should -Be $true
            }
        }

        Describe 'Wildcard Array Validation' {

            It 'Should validate properties exist on all array elements' {
                Test-Exist -In $TestData -With "users[*].id" | Should -Be $true
                Test-Exist -In $TestData -With "users[*].name" | Should -Be $true
                Test-Exist -In $TestData -With "users[*].active" | Should -Be $true
            }

            It 'Should return false if any element is missing the property' {
                Test-Exist -In $TestData -With "users[*].missing" | Should -Be $false
            }

            It 'Should work with wildcard validation operators' {
                Test-Exist -In $TestData -With "users[*].id!" | Should -Be $true
                Test-Exist -In $TestData -With "users[*].email!" | Should -Be $false  # One user has empty email
                Test-Exist -In $TestData -With "users[*].name!" | Should -Be $false   # One user has empty name
            }

            It 'Should work with nested wildcard validation' {
                Test-Exist -In $TestData -With "products[*].category.name" | Should -Be $true
                Test-Exist -In $TestData -With "products[*].category.name!" | Should -Be $true
                Test-Exist -In $TestData -With "orders[*].customer.email!" | Should -Be $true
            }

            It 'Should handle empty arrays' {
                Test-Exist -In $TestData -With "emptyArray[*].property" | Should -Be $false
                Test-Exist -In $TestData -With "emptyStructure.emptyArray[*].property" | Should -Be $false
            }
        }

        Describe 'Complex Combinations' {

            It 'Should handle deep nesting with validation' {
                Test-Exist -In $TestData -With "user.profile.settings.theme!" | Should -Be $true
                Test-Exist -In $TestData -With "orders[0].customer.email!" | Should -Be $true
                Test-Exist -In $TestData -With "products[0].category.active?" | Should -Be $true
            }

            It 'Should handle mixed indexing and wildcards' {
                Test-Exist -In $TestData -With "orders[0].items[*].sku" | Should -Be $true
                Test-Exist -In $TestData -With "orders[1].items[*].price!" | Should -Be $true
                # Fixed: Complex wildcard+indexing patterns now work
                Test-Exist -In $TestData -With "orders[*].items[0].quantity" | Should -Be $true
            }

            It 'Should validate complex nested structures' {
                Test-Exist -In $TestData -With "orders[*].customer.name!" | Should -Be $true
                Test-Exist -In $TestData -With "orders[*].metadata.source!" | Should -Be $true
                Test-Exist -In $TestData -With "orders[*].metadata.campaign!" | Should -Be $false  # One order has null campaign
            }
        }

        Describe 'Different Object Types' {

            It 'Should work with PSObjects' {
                Test-Exist -In $PSObjectData -With "name" | Should -Be $true
                Test-Exist -In $PSObjectData -With "nested.value" | Should -Be $true
                Test-Exist -In $PSObjectData -With "nested.array[0]" | Should -Be $true
            }

            It 'Should work with .NET objects' {
                Test-Exist -In $NetObjectData -With "Property1" | Should -Be $true
                Test-Exist -In $NetObjectData -With "Property2.SubProperty" | Should -Be $true
            }
        }

        Describe 'Edge Cases' {

            It 'Should handle null input objects gracefully' {
                # PowerShell parameter binding prevents null InputObject, so we test the C# class directly
                [PSFluentObjectValidation]::TestExists($null, "property") | Should -Be $false
            }

            It 'Should handle empty property paths gracefully' {
                # PowerShell parameter binding prevents empty Key, so we test the C# class directly
                [PSFluentObjectValidation]::TestExists($TestData, "") | Should -Be $false
            }

            It 'Should handle invalid array indices gracefully' {
                Test-Exist -In $TestData -With "users[abc]" | Should -Be $false
                Test-Exist -In $TestData -With "users[]" | Should -Be $false
            }

            It 'Should handle properties that are not arrays when using array syntax' {
                Test-Exist -In $TestData -With "name[0]" | Should -Be $false
                Test-Exist -In $TestData -With "age[*]" | Should -Be $false
            }
        }
    }

    Context 'Assert-Exist Function Tests' {

        Describe 'Basic Property Access' {

            It 'Should not throw for existing properties' {
                { Assert-Exist -In $TestData -With "name" } | Should -Not -Throw
                { Assert-Exist -In $TestData -With "user.profile.email" } | Should -Not -Throw
            }

            It 'Should throw for non-existing properties' {
                { Assert-Exist -In $TestData -With "nonexistent" } | Should -Throw
                { Assert-Exist -In $TestData -With "user.profile.missing" } | Should -Throw
            }

            It 'Should throw with descriptive error messages for missing properties' {
                { Assert-Exist -In $TestData -With "nonexistent" } | Should -Throw -ExpectedMessage "*Property 'nonexistent' does not exist*"
                { Assert-Exist -In $TestData -With "user.missing" } | Should -Throw -ExpectedMessage "*Property 'missing' does not exist*"
            }
        }

        Describe 'Validation Operators' {

            Context 'Non-empty validation (!)' {

                It 'Should not throw for non-empty values' {
                    { Assert-Exist -In $TestData -With "name!" } | Should -Not -Throw
                    { Assert-Exist -In $TestData -With "user.profile.email!" } | Should -Not -Throw
                }

                It 'Should throw for null values' {
                    { Assert-Exist -In $TestData -With "nullValue!" } | Should -Throw -ExpectedMessage "*is null*"
                    { Assert-Exist -In $TestData -With "user.preferences.timezone!" } | Should -Throw -ExpectedMessage "*is null*"
                }

                It 'Should throw for empty strings' {
                    { Assert-Exist -In $TestData -With "emptyString!" } | Should -Throw -ExpectedMessage "*is empty*"
                    { Assert-Exist -In $TestData -With "whitespaceString!" } | Should -Throw -ExpectedMessage "*is empty or whitespace*"
                }

                It 'Should throw for empty arrays' {
                    { Assert-Exist -In $TestData -With "emptyArray!" } | Should -Throw -ExpectedMessage "*is empty*"
                }
            }

            Context 'Existence validation (?)' {

                It 'Should not throw for existing properties even if null' {
                    { Assert-Exist -In $TestData -With "nullValue?" } | Should -Not -Throw
                    { Assert-Exist -In $TestData -With "user.preferences.timezone?" } | Should -Not -Throw
                }

                It 'Should throw for empty arrays' {
                    { Assert-Exist -In $TestData -With "emptyArray?" } | Should -Throw -ExpectedMessage "*is empty*"
                }

                It 'Should throw for non-existing properties' {
                    { Assert-Exist -In $TestData -With "nonexistent?" } | Should -Throw -ExpectedMessage "*does not exist*"
                }
            }
        }

        Describe 'Array Indexing' {

            It 'Should not throw for valid array indices' {
                { Assert-Exist -In $TestData -With "users[0]" } | Should -Not -Throw
                { Assert-Exist -In $TestData -With "users[0].name" } | Should -Not -Throw
            }

            It 'Should throw for out-of-bounds indices with descriptive messages' {
                { Assert-Exist -In $TestData -With "users[10]" } | Should -Throw -ExpectedMessage "*Array index*out of bounds*"
                { Assert-Exist -In $TestData -With "users[100]" } | Should -Throw -ExpectedMessage "*Array index*out of bounds*"
            }

            It 'Should throw when trying to index non-array properties' {
                { Assert-Exist -In $TestData -With "name[0]" } | Should -Throw -ExpectedMessage "*is not an array*"
                { Assert-Exist -In $TestData -With "age[*]" } | Should -Throw -ExpectedMessage "*is not an array*"
            }
        }

        Describe 'Wildcard Array Validation' {

            It 'Should not throw when all elements have the property' {
                { Assert-Exist -In $TestData -With "users[*].id" } | Should -Not -Throw
                { Assert-Exist -In $TestData -With "products[*].title" } | Should -Not -Throw
            }

            It 'Should throw when any element is missing the property' {
                { Assert-Exist -In $TestData -With "users[*].missing" } | Should -Throw -ExpectedMessage "*does not have property*"
            }

            It 'Should throw with element context for validation failures' {
                { Assert-Exist -In $TestData -With "users[*].email!" } | Should -Throw -ExpectedMessage "*element*empty*"
                { Assert-Exist -In $TestData -With "users[*].name!" } | Should -Throw -ExpectedMessage "*element*empty*"
            }

            It 'Should throw for empty arrays with wildcard' {
                { Assert-Exist -In $TestData -With "emptyArray[*].property" } | Should -Throw -ExpectedMessage "*empty*cannot validate*"
            }
        }

        Describe 'Error Message Quality' {

            It 'Should provide context in error messages for deep nesting' {
                { Assert-Exist -In $TestData -With "user.profile.missing.deep" } | Should -Throw -ExpectedMessage "*Property 'missing' does not exist*"
            }

            It 'Should provide array context in error messages' {
                { Assert-Exist -In $TestData -With "users[0].missing" } | Should -Throw -ExpectedMessage "*Property 'missing' does not exist*"
            }

            It 'Should provide validation context in error messages' {
                { Assert-Exist -In $TestData -With "orders[0].metadata.campaign!" } | Should -Throw -ExpectedMessage "*is null*"
            }
        }

        Describe 'Input Validation' {

            It 'Should throw for null input objects' {
                # PowerShell parameter binding prevents null, so test C# class directly
                { [PSFluentObjectValidation]::AssertExists($null, "property") } | Should -Throw -ExpectedMessage "*InputObject cannot be null*"
            }

            It 'Should throw for null or empty keys' {
                # PowerShell parameter binding prevents null/empty, so test C# class directly
                { [PSFluentObjectValidation]::AssertExists($TestData, $null) } | Should -Throw -ExpectedMessage "*Key cannot be null or empty*"
                { [PSFluentObjectValidation]::AssertExists($TestData, "") } | Should -Throw -ExpectedMessage "*Key cannot be null or empty*"
            }
        }
    }

    Context 'Function Aliases' {

        It 'Should support Test-Exist aliases' {
            exists -In $TestData -With "name" | Should -Be $true
            tests -In $TestData -With "user.profile.email" | Should -Be $true
        }

        It 'Should support Assert-Exist aliases' {
            { asserts -In $TestData -With "name" } | Should -Not -Throw
        }
    }

    Context 'Performance and Edge Cases' {

        It 'Should handle deeply nested structures efficiently' {
            $deepData = @{ level1 = @{ level2 = @{ level3 = @{ level4 = @{ value = "deep" } } } } }
            Test-Exist -In $deepData -With "level1.level2.level3.level4.value" | Should -Be $true
        }

        It 'Should handle large arrays efficiently' {
            $largeArray = 1..100 | ForEach-Object { @{ id = $_; name = "Item$_" } }
            $largeData = @{ items = $largeArray }
            Test-Exist -In $largeData -With "items[99].name" | Should -Be $true
            Test-Exist -In $largeData -With "items[*].id" | Should -Be $true
        }

        It 'Should handle mixed validation patterns' {
            Test-Exist -In $TestData -With "orders[0].items[*].sku!" | Should -Be $true
            Test-Exist -In $TestData -With "orders[*].customer.name!" | Should -Be $true
            # Fixed: Wildcard followed by array indexing now works
            Test-Exist -In $TestData -With "products[*].tags[0]" | Should -Be $true
        }
    }
}
