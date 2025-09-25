$PSFluentObjectValidation = @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Text.RegularExpressions;

public static class PSFluentObjectValidation
{
    private static readonly Regex PropertyWithValidation = new Regex(@"^(.+)([?!])$", RegexOptions.Compiled);
    private static readonly Regex ArrayIndexPattern = new Regex(@"^(.+)\[(\*|\d+)\]$", RegexOptions.Compiled);

    public static bool TestExists(object inputObject, string key)
    {
        try
        {
            AssertExists(inputObject, key);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static void AssertExists(object inputObject, string key)
    {
        if (inputObject == null)
            throw new ArgumentException("InputObject cannot be null");

        if (String.IsNullOrEmpty(key))
            throw new ArgumentException("Key cannot be null or empty");

        string[] keyParts = key.Split('.');
        object currentObject = inputObject;

        foreach (string part in keyParts)
        {
            currentObject = ProcessKeyPart(currentObject, part);
        }
    }

    private static object ProcessKeyPart(object currentObject, string part)
    {
        // Handle wildcard array wrapper specially
        if (currentObject is WildcardArrayWrapper)
        {
            WildcardArrayWrapper wrapper = (WildcardArrayWrapper)currentObject;
            return ProcessWildcardPropertyAccess(wrapper.ArrayObject, part);
        }

        // Check for array indexing: property[index] or property[*]
        Match arrayMatch = ArrayIndexPattern.Match(part);
        if (arrayMatch.Success)
        {
            string propertyName = arrayMatch.Groups[1].Value;
            string indexStr = arrayMatch.Groups[2].Value;

            return ProcessArrayAccess(currentObject, propertyName, indexStr);
        }

        // Check for validation suffixes: property? or property!
        Match validationMatch = PropertyWithValidation.Match(part);
        if (validationMatch.Success)
        {
            string propertyName = validationMatch.Groups[1].Value;
            char validator = validationMatch.Groups[2].Value[0];

            return ProcessPropertyWithValidation(currentObject, propertyName, validator);
        }

        // Regular property navigation
        return ProcessRegularProperty(currentObject, part);
    }

    private static object ProcessArrayAccess(object currentObject, string propertyName, string indexStr)
    {
        // First get the property (should be an array)
        if (!HasProperty(currentObject, propertyName))
            throw new InvalidOperationException(String.Format("Property '{0}' does not exist", propertyName));

        object arrayObject = GetProperty(currentObject, propertyName);

        if (arrayObject == null)
            throw new InvalidOperationException(String.Format("Property '{0}' is null", propertyName));

        if (!IsArrayLike(arrayObject))
            throw new InvalidOperationException(String.Format("Property '{0}' is not an array", propertyName));

        // Handle wildcard [*] - means all elements must exist and be valid
        if (indexStr == "*")
        {
            return ProcessWildcardAccess(arrayObject, propertyName);
        }

        // Handle numerical index [0], [1], etc.
        int index;
        if (int.TryParse(indexStr, out index))
        {
            return ProcessNumericalAccess(arrayObject, propertyName, index);
        }

        throw new InvalidOperationException(String.Format("Invalid array index '{0}' for property '{1}'", indexStr, propertyName));
    }

    private static object ProcessWildcardAccess(object arrayObject, string propertyName)
    {
        int count = GetCount(arrayObject);

        if (count == 0)
            throw new InvalidOperationException(String.Format("Array '{0}' is empty - cannot validate [*]", propertyName));

        // For wildcard, we return the array object itself
        // The next part in the chain will validate against all elements
        return new WildcardArrayWrapper(arrayObject);
    }

    private static object ProcessNumericalAccess(object arrayObject, string propertyName, int index)
    {
        int count = GetCount(arrayObject);

        if (index < 0 || index >= count)
            throw new InvalidOperationException(String.Format("Array index [{0}] is out of bounds for '{1}' (length: {2})", index, propertyName, count));

        // Get the specific element
        if (arrayObject is Array)
        {
            Array array = (Array)arrayObject;
            return array.GetValue(index);
        }

        if (arrayObject is IList)
        {
            IList list = (IList)arrayObject;
            return list[index];
        }

        // For IEnumerable, we need to iterate to the index
        if (arrayObject is IEnumerable)
        {
            IEnumerable enumerable = (IEnumerable)arrayObject;
            int currentIndex = 0;
            foreach (object item in enumerable)
            {
                if (currentIndex == index)
                    return item;
                currentIndex++;
            }
        }

        throw new InvalidOperationException(String.Format("Cannot access index [{0}] on array '{1}'", index, propertyName));
    }

    private static object ProcessPropertyWithValidation(object currentObject, string propertyName, char validator)
    {
        // Handle wildcard array wrapper first
        if (currentObject is WildcardArrayWrapper)
        {
            WildcardArrayWrapper wrapper = (WildcardArrayWrapper)currentObject;
            return ProcessWildcardPropertyAccess(wrapper.ArrayObject, propertyName + validator);
        }

        if (validator == '?')
        {
            // Handle object/array validation: key? - ONLY check existence, allow null values
            if (!HasProperty(currentObject, propertyName))
                throw new InvalidOperationException(String.Format("Property '{0}' does not exist", propertyName));

            object value = GetProperty(currentObject, propertyName);

            // For ? operator, we only care about existence, not null values
            // If it's an array-like object, check it's not empty, but allow null values otherwise
            if (value != null && IsArrayLike(value))
            {
                // For arrays, check that it's not empty
                if (GetCount(value) == 0)
                    throw new InvalidOperationException(String.Format("Array '{0}' is empty", propertyName));
            }
            // Note: We don't check IsObjectLike here because ? only validates existence

            return value;  // Can be null - that's valid for ? operator
        }
        else if (validator == '!')
        {
            // Validate non-empty: key!
            if (!HasProperty(currentObject, propertyName))
                throw new InvalidOperationException(String.Format("Property '{0}' does not exist", propertyName));

            object value = GetProperty(currentObject, propertyName);

            if (value == null)
                throw new InvalidOperationException(String.Format("Property '{0}' is null", propertyName));

            if (IsEmpty(value))
                throw new InvalidOperationException(String.Format("Property '{0}' is empty or whitespace", propertyName));

            return value;
        }

        throw new InvalidOperationException(String.Format("Unknown validator '{0}'", validator));
    }

    private static object ProcessRegularProperty(object currentObject, string propertyName)
    {
        // Handle wildcard array wrapper - validate property exists on ALL elements
        if (currentObject is WildcardArrayWrapper)
        {
            WildcardArrayWrapper wrapper = (WildcardArrayWrapper)currentObject;
            return ProcessWildcardPropertyAccess(wrapper.ArrayObject, propertyName);
        }

        // Check for validation suffixes even in regular properties
        Match validationMatch = PropertyWithValidation.Match(propertyName);
        if (validationMatch.Success)
        {
            string actualPropertyName = validationMatch.Groups[1].Value;
            char validator = validationMatch.Groups[2].Value[0];

            return ProcessPropertyWithValidation(currentObject, actualPropertyName, validator);
        }

        // Regular property navigation - allow null values (only ! operator should reject nulls)
        if (!HasProperty(currentObject, propertyName))
            throw new InvalidOperationException(String.Format("Property '{0}' does not exist", propertyName));

        object value = GetProperty(currentObject, propertyName);

        // For regular navigation, null values are allowed (property exists but is null)
        // Only the ! operator should reject null/empty values
        return value;
    }

    private static object ProcessWildcardPropertyAccess(object arrayObject, string propertyName)
    {
        // First check if this is an array indexing pattern: property[index] or property[*]
        Match arrayMatch = ArrayIndexPattern.Match(propertyName);
        if (arrayMatch.Success)
        {
            string basePropertyName = arrayMatch.Groups[1].Value;
            string indexStr = arrayMatch.Groups[2].Value;

            // Handle array indexing after wildcard: items[0], tags[*], etc.
            if (arrayObject is Array)
            {
                Array array = (Array)arrayObject;
                for (int i = 0; i < array.Length; i++)
                {
                    object element = array.GetValue(i);
                    if (element == null)
                        throw new InvalidOperationException(String.Format("Array element [{0}] is null", i));

                    if (!HasProperty(element, basePropertyName))
                        throw new InvalidOperationException(String.Format("Array element [{0}] does not have property '{1}'", i, basePropertyName));

                    object propertyValue = GetProperty(element, basePropertyName);
                    if (propertyValue == null)
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is null", basePropertyName, i));
                    if (!IsArrayLike(propertyValue))
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is not an array", basePropertyName, i));
                }

                // All elements are valid, now handle the indexing
                object firstElement = array.GetValue(0);
                object firstPropertyValue = GetProperty(firstElement, basePropertyName);

                if (indexStr == "*")
                {
                    return new WildcardArrayWrapper(firstPropertyValue);
                }
                else
                {
                    int index = int.Parse(indexStr);
                    int count = GetCount(firstPropertyValue);
                    if (index < 0 || index >= count)
                        throw new InvalidOperationException(String.Format("Array index [{0}] is out of bounds for property '{1}' (length: {2})", index, basePropertyName, count));

                    if (firstPropertyValue is Array)
                    {
                        Array firstArray = (Array)firstPropertyValue;
                        return firstArray.GetValue(index);
                    }
                    if (firstPropertyValue is IList)
                    {
                        IList firstList = (IList)firstPropertyValue;
                        return firstList[index];
                    }
                }
            }

            if (arrayObject is IList)
            {
                IList list = (IList)arrayObject;
                for (int i = 0; i < list.Count; i++)
                {
                    object element = list[i];
                    if (element == null)
                        throw new InvalidOperationException(String.Format("Array element [{0}] is null", i));
                    if (!HasProperty(element, basePropertyName))
                        throw new InvalidOperationException(String.Format("Array element [{0}] does not have property '{1}'", i, basePropertyName));

                    object propertyValue = GetProperty(element, basePropertyName);
                    if (propertyValue == null)
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is null", basePropertyName, i));
                    if (!IsArrayLike(propertyValue))
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is not an array", basePropertyName, i));
                }

                // All elements are valid, now handle the indexing
                object firstElement = list[0];
                object firstPropertyValue = GetProperty(firstElement, basePropertyName);

                if (indexStr == "*")
                {
                    return new WildcardArrayWrapper(firstPropertyValue);
                }
                else
                {
                    int index = int.Parse(indexStr);
                    int count = GetCount(firstPropertyValue);
                    if (index < 0 || index >= count)
                        throw new InvalidOperationException(String.Format("Array index [{0}] is out of bounds for property '{1}' (length: {2})", index, basePropertyName, count));

                    if (firstPropertyValue is Array)
                    {
                        Array firstArray = (Array)firstPropertyValue;
                        return firstArray.GetValue(index);
                    }
                    if (firstPropertyValue is IList)
                    {
                        IList firstList = (IList)firstPropertyValue;
                        return firstList[index];
                    }
                }
            }

            throw new InvalidOperationException(String.Format("Cannot process wildcard array indexing on type {0}", arrayObject.GetType().Name));
        }



        // Parse validation suffix if present
        Match validationMatch = PropertyWithValidation.Match(propertyName);
        string actualPropertyName = propertyName;
        char? validator = null;

        if (validationMatch.Success)
        {
            actualPropertyName = validationMatch.Groups[1].Value;
            validator = validationMatch.Groups[2].Value[0];
        }

        // Validate ALL elements have this property
        if (arrayObject is Array)
        {
            Array array = (Array)arrayObject;
            for (int i = 0; i < array.Length; i++)
            {
                object element = array.GetValue(i);
                if (element == null)
                    throw new InvalidOperationException(String.Format("Array element [{0}] is null", i));
                if (!HasProperty(element, actualPropertyName))
                    throw new InvalidOperationException(String.Format("Array element [{0}] does not have property '{1}'", i, actualPropertyName));

                if (validator.HasValue)
                {
                    object elementValue = GetProperty(element, actualPropertyName);
                    if (elementValue == null)
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is null", actualPropertyName, i));
                    if (validator == '!' && IsEmpty(elementValue))
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is empty", actualPropertyName, i));
                }
            }
            return GetProperty(array.GetValue(0), actualPropertyName);
        }

        if (arrayObject is IList)
        {
            IList list = (IList)arrayObject;
            for (int i = 0; i < list.Count; i++)
            {
                object element = list[i];
                if (element == null)
                    throw new InvalidOperationException(String.Format("Array element [{0}] is null", i));
                if (!HasProperty(element, actualPropertyName))
                    throw new InvalidOperationException(String.Format("Array element [{0}] does not have property '{1}'", i, actualPropertyName));

                if (validator.HasValue)
                {
                    object elementValue = GetProperty(element, actualPropertyName);
                    if (elementValue == null)
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is null", actualPropertyName, i));
                    if (validator == '!' && IsEmpty(elementValue))
                        throw new InvalidOperationException(String.Format("Property '{0}' in element [{1}] is empty", actualPropertyName, i));
                }
            }
            return GetProperty(list[0], actualPropertyName);
        }

        throw new InvalidOperationException(String.Format("Cannot validate wildcard array"));
    }

    private static void ValidatePropertyValue(object value, string propertyName, char validator, int? arrayIndex = null)
    {
        string context = arrayIndex.HasValue ? String.Format(" in array element [{0}]", arrayIndex) : "";

        if (validator == '?')
        {
            if (value == null)
                throw new InvalidOperationException(String.Format("Property '{0}'{1} is null", propertyName, context));

            if (IsArrayLike(value) && GetCount(value) == 0)
                throw new InvalidOperationException(String.Format("Array '{0}'{1} is empty", propertyName, context));
        }
        else if (validator == '!')
        {
            if (value == null)
                throw new InvalidOperationException(String.Format("Property '{0}'{1} is null", propertyName, context));

            if (IsEmpty(value))
                throw new InvalidOperationException(String.Format("Property '{0}'{1} is empty or whitespace", propertyName, context));
        }
    }

    // Helper methods (same as before)
    private static bool HasProperty(object obj, string propertyName)
    {
        if (obj == null) return false;

        if (obj is Hashtable)
        {
            Hashtable hashtable = (Hashtable)obj;
            return hashtable.ContainsKey(propertyName);
        }

        if (obj is IDictionary)
        {
            IDictionary dictionary = (IDictionary)obj;
            return dictionary.Contains(propertyName);
        }

        if (obj is PSObject)
        {
            PSObject psObj = (PSObject)obj;
            return psObj.Properties[propertyName] != null;
        }

        var type = obj.GetType();
        return type.GetProperty(propertyName) != null || type.GetField(propertyName) != null;
    }

    private static object GetProperty(object obj, string propertyName)
    {
        if (obj == null) return null;

        if (obj is Hashtable)
        {
            Hashtable hashtable = (Hashtable)obj;
            return hashtable[propertyName];
        }

        if (obj is IDictionary)
        {
            IDictionary dictionary = (IDictionary)obj;
            return dictionary[propertyName];
        }

        if (obj is PSObject)
        {
            PSObject psObj = (PSObject)obj;
            var prop = psObj.Properties[propertyName];
            return prop != null ? prop.Value : null;
        }

        var type = obj.GetType();
        var property = type.GetProperty(propertyName);
        if (property != null)
            return property.GetValue(obj);

        var field = type.GetField(propertyName);
        if (field != null)
            return field.GetValue(obj);

        return null;
    }

    private static bool IsObjectLike(object obj)
    {
        if (obj == null) return false;
        return obj is Hashtable || obj is IDictionary || obj is PSObject ||
               (!IsArrayLike(obj) && !(obj is string));
    }

    private static bool IsArrayLike(object obj)
    {
        if (obj == null || obj is string) return false;
        return obj is Array || obj is IList || obj is IEnumerable;
    }

    private static int GetCount(object obj)
    {
        if (obj == null) return 0;

        if (obj is Array)
        {
            Array array = (Array)obj;
            return array.Length;
        }

        if (obj is ICollection)
        {
            ICollection collection = (ICollection)obj;
            return collection.Count;
        }

        if (obj is IEnumerable)
        {
            IEnumerable enumerable = (IEnumerable)obj;
            int count = 0;
            foreach (var item in enumerable)
                count++;
            return count;
        }

        return 1;
    }

    private static bool IsEmpty(object value)
    {
        if (value == null) return true;

        if (value is string)
        {
            string str = (string)value;
            return string.IsNullOrWhiteSpace(str);
        }

        if (value is Array)
        {
            Array array = (Array)value;
            return array.Length == 0;
        }

        if (value is ICollection)
        {
            ICollection collection = (ICollection)value;
            return collection.Count == 0;
        }

        return value.Equals("");
    }
}

// Wrapper class to handle wildcard array processing
public class WildcardArrayWrapper
{
    public object ArrayObject { get; set; }

    public WildcardArrayWrapper(object arrayObject)
    {
        ArrayObject = arrayObject;
    }
}
"@

try {
    Add-Type -TypeDefinition $PSFluentObjectValidation -ReferencedAssemblies @(
        'System.Core',
        'System.Management.Automation',
        'System.Text.RegularExpressions'
    ) -Language CSharp
} catch {
    throw
}
