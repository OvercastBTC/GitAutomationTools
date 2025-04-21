## Code Standards

Core Requirements:

*   Use strict AHK v2 syntax
*   Follow OTB (One True Brace) style
*   Enable method chaining
*   Support static and instance calls
*   Implement error handling
*   Maintain documentation

Code Organization:

*   Class-based architecture
*   Consistent method signatures
*   Property getters/setters
*   Resource management
*   Dependency handling

Documentation:

*   JSDoc style comments
*   Version tracking
*   Dependencies list
*   Usage examples
*   Exception docs
*   Region documentation
*   Code standards documentation
*   Testing guidelines documentation
*   Documentation for community guidelines

Parameter Handling:

*   Use params\* pattern
*   Default values
*   Type validation
*   Method chaining
*   Error conditions

Testing & Quality:

*   Unit tests
*   Integration tests
*   Performance checks
*   Security review
*   Resource cleanup

## Development Standards

# AHK v2 Development Standards

## Core Requirements

*   Use strict AHK v2 syntax and patterns
*   Follow OTB (One True Brace) style
*   Enable method chaining
*   Support both static and instance calls
*   Implement comprehensive error handling
*   Maintain proper documentation

## Code Organization

*   Class-based architecture
*   Consistent method signatures
*   Property getters/setters
*   Resource management
*   Dependency handling

## Documentation

*   JSDoc style comments
*   Version tracking
*   Dependency lists
*   Usage examples
*   Exception documentation

## Parameter Handling

*   Flexible param types
*   Default values
*   Type validation
*   Method chaining support
*   Error conditions

## Testing & Quality

*   Unit tests
*   Integration tests
*   Performance benchmarks
*   Security checks
*   Resource cleanup

## Project Organization

### Directory Structure

project/  
├── filename.ahk ; Main script file  
├── lib/ ; Local libraries specific to the project  
│ └── ... ; Optionally symlink to standard AHK lib locations  
├── tests/ ; Test suite  
├── docs/ ; Documentation  
├── examples/ ; Usage examples  
├── README.md ; Project overview and instructions

### File Naming Conventions

*   Use PascalCase for class files: MyClass.ahk
*   Use lowercase for utility files: utils.ahk
*   Use descriptive prefixes for related files: gui\_controls.ahk
*   Use underscores for multi-word file names: my\_script.ahk
*   Ensure all files are properly documented
*   Maintain consistent formatting across all files
*   Include version history in documentation

## Version Control

*   Semantic versioning
*   Clear commit messages
*   Feature branches
*   Pull request reviews
*   Change documentation

## Community Guidelines

Class Design:

*   Proper \_\_New() constructor
*   Property getters/setters
*   Instance initialization
*   Method chaining
*   Resource cleanup
*   Reserved word checks
*   PascalCase naming

Common Patterns:

*   Basic class structure
*   Property accessors
*   Method chaining
*   Resource management
*   Event handling
*   Error handling

Key Resources:

*   Official documentation
*   Community examples
*   Code libraries
*   Development tools
*   Testing frameworks

## Foundation

#Requires AutoHotkey v2+

```
;@region Example Class
/**
 * @class ExampleClass
 * @description Example class demonstrating AHK v2 patterns
 * @version [1.0.0]
 * @author [Author Name]
 * @date [YYYY-MM-DD]
 * @requires AutoHotkey v2.0+
 */
```

class ExampleClass {  
;@region Static properties  
static version := \["1.0.0"\]  
static author := \["Author Name"\]  
;@endregion Static properties  
;@region Instance properties  
; Instance properties  
data := Map()  
;@endregion Instance properties

```
    ;@region Constructor
/**
 * @constructor
 * @param {Map|Object|Array|Any} params Optional initialization parameters
 */
__New(params?) {
    if IsSet(params) {
        this.initialize(params)
        }
}
;@endregion Constructor

    ;@region Initialization
/**
 * @description Initialize with parameters
 * @param {Map|Object|Array|Any} params Configuration parameters
 * @returns {ExampleClass} Current instance for method chaining
 */
initialize(params) {
    ; Implementation
    return this
}
;@endregion Initialization

;@region MethodName
/**
 * @description Example method that works with both static and instance calls
 * @param {Any} param Optional parameter
 * @returns {ExampleClass} This instance for method chaining
 */
methodName(param?) {
    if !IsSet(param) {
        param := this
        }
    ; Method logic
    return this
}
;@endregion MethodName

;@region Cleanup

/**
 * @description Clean up resources when object is destroyed
 */
__Delete() {
    this._releaseResources()
}
;@endregion Cleanup
    ;@region Private Methods
    /**
     * @private
     * @description Example private method for internal logic
     * @param {Any} param Parameter for processing
     * @returns {Any} Result of processing
     */
    privateMethod(param) {
        ; Implementation of the private method
        return param
    }
/**
 * @private
 * @description Helper method for resource cleanup
 */
_releaseResources() {
    ; Cleanup implementation
}
    ;@endregion Private Methods
```

}  
;@endregion Example Class

## Class Implementation

/\*\*

*   @class ExampleClass
*   @description Example class showing proper v2 implementation
*   @extends ParentClass

\*/  
class ExampleClass extends ParentClass {  
; Static properties  
static version := \["1.0.0"\]

```
; Instance properties (initialized automatically)
name := ""
data := Map()

/**
 * @constructor
 * @param {String} name Name for this instance
 */
__New(name := "Default") {
    this.name := name
}

/**
 * @description Method with standard implementation
 * @param {Any} param Optional parameter
 * @returns {ExampleClass} Current instance for method chaining
 */
doSomething(param?) {
    if !IsSet(param){
        param := "default value"
        }
    ; Method implementation
    this.data["lastAction"] := "Did something with " param

    return this  ; Return this for method chaining
}

/**
 * @description Example property with getter/setter
 */
Name {
    get => this.name
    set => this.name := value
}

/**
 * @description Cleanup resources when object is destroyed
 */
__Delete() {
    ; Cleanup code
}
```

}

## Method Structure

/\*\*

*   @description Standard method template with params\* pattern
*   @param {...Any} params Variable parameters
*   @returns {Class} This instance for method chaining
*   @throws {ValueError} When required parameters are missing
*   @throws {TypeError} When parameters have incorrect types

_/_  
_methodWithParams(params_) {  
; Initialize defaults  
config := {property: "defaultValue"}

```
; Parse parameters
for param in params {
    if IsObject(param) {
        ; Handle object parameters
        for key, value in param.OwnProps()
            config.%key% := value
    } else if param is String {
        ; Handle string parameters
        config.stringProperty := param
    } else if param is Number {
        ; Handle numeric parameters
        config.numericProperty := param
    }
}

; Validate
if !config.HasOwnProp("requiredProperty")
    throw ValueError("Missing required property", -1)

; Execute
this._executeLogic(config)

; Return for method chaining
return this
```

}

## Property Design

class PropertyExample {  
; Private backing field  
\_value := ""

```
/**
 * @property {String} Value
 * @description Property with getter and setter
 */
Value {
    get => this._value
    set => this._value := value
}

/**
 * @property {Number} ReadOnly
 * @description Read-only computed property
 */
ReadOnly => this._calculateValue()

_calculateValue() {
    return 42
}
```

}

## Documentation Standards

/\*\*

@class ClassName

@description Comprehensive description of class purpose and functionality

@version \[1.0.0\]

@author \[Author Name\]

@date \[YYYY-MM-DD\]

@requires AutoHotkey v2.0+

@property {Type} PropertyName Description of property

@method {ReturnType} MethodName Description of method

@example

instance := new ClassName()

result := instance.Method()

_/_  
_/_\*

*   @description Detailed description of method purpose
*   @param {Type} paramName Description of parameter
*   @param {Type} \[optionalParam\] Description of optional parameter
*   @returns {Type} Description of return value
*   @throws {ErrorType} Description of potential errors
*   @example
*   result := instance.MethodName(param)

_/_  
_/_\*

*   @property {Type} PropertyName
*   @description Detailed description of property
*   @example
*   value := instance.PropertyName

\*/

## Common Pitfalls

### Common Pitfalls and Solutions

**Incorrect Constructor Usage**:

*   ❌ Wrong: App := Application.new("Name")
*   ✅ Correct: App := Application("Name")

The new operator in AHK v2 doesn't work like in some other languages. Use ClassName() syntax to create instances.

**Infinite Recursion in Properties**:

❌ Wrong:

property {  
set => this.property := value  
get => this.property  
}

✅ Correct:

; Use a different backing field  
property {  
set => this.\_property := value  
get => this.\_property  
}

**Improper Property Initialization**:

*   Initialize instance properties in the class body or in \_\_New()
*   Ensure initialization before first use

**Missing Method Return Values**:

*   Always explicitly return this from methods that should support chaining
*   For other methods, clearly define and document return values

**Resource Leaks**:

*   Implement \_\_Delete() for cleanup when an object is destroyed
*   Be aware that global/static variables may be released in an arbitrary order during script exit

## Common Implementation Patterns

class MyClassName {  
; Initialize properties in constructor  
\_\_New() {  
this.property := "default-value"  
}

```
; Method definition
method(x, y) {
    return x + y
}
```

}

; Create instance  
myInstance := MyClassName()

; Access property and method  
MsgBox "Property: " myInstance.property  
MsgBox "Method result: " myInstance.method(3, 2)  
class Person {  
; Private backing field  
\_name := ""  
\_age := 0

```
; Constructor
__New(name := "", age := 0) {
    this._name := name
    this._age := age
}

; Property with validation
Name {
    get => this._name
    set {
        if (value == "")
            throw ValueError("Name cannot be empty")
        this._name := value
    }
}

; Computed property
CanDriveInUS => this._age >= 16
```

}  
class StringBuilder {  
\_buffer := \[\]

```
append(text) {
    this._buffer.Push(text)
    return this  ; Enable method chaining
}

appendLine(text := "") {
    this._buffer.Push(text "
```

")  
return this  
}

```
clear() {
    this._buffer := []
    return this
}

toString() {
    return this._buffer.Length ? this._buffer.Join("") : ""
}
```

}

; Usage with method chaining  
text := StringBuilder()  
.append("Hello ")  
.append("World!")  
.appendLine()  
.append("Next line")  
.toString()

## Error Handling

/\*\*

*   @description Example of comprehensive error handling
*   @param {Any} params Parameters
*   @throws {Error} When operation fails

\*/  
operationWithErrors(params) {  
try {  
; Operation that might fail  
result := this.\_riskyOperation(params)  
return result  
} catch as err {  
; Log the error  
this.\_logError({  
message: err.Message,  
source: A\_LineFile,  
line: A\_LineNumber,  
type: err.What,  
stack: err.Stack  
})

```
    ; Rethrow with context
    throw Error("Operation failed: " err.Message, -1)
} finally {
    ; Cleanup code that always runs
    this._cleanup()
}
```

}

## Parameter Validation

/\*\*

*   @description Validate parameter types
*   @param {Any} value Value to validate
*   @param {String|Array} types Expected type(s)
*   @param {String} paramName Parameter name for error messages
*   @throws {TypeError} When value does not match expected types

\*/  
validateType(value, types, paramName := "Parameter") {  
if IsArray(types) {  
for type in types {  
if value is %type%  
return true  
}  
throw TypeError(paramName " must be one of: " Join(types, ", "), -1)  
} else {  
if !(value is %types%)  
throw TypeError(paramName " must be " types, -1)  
}  
}

## Resource Management

/\*\*

*   @class ResourceManager
*   @description Example of proper resource management

\*/  
class ResourceManager {  
resources := \[\]

```
/**
 * @description Add a resource to be managed
 * @param {Object} resource Resource to manage
 * @returns {ResourceManager} This instance for method chaining
 */
addResource(resource) {
    this.resources.Push(resource)
    return this
}

/**
 * @description Release all managed resources
 */
releaseResources() {
    for resource in this.resources {
        if HasMethod(resource, "Release")
            resource.Release()
        else if HasMethod(resource, "Close")
            resource.Close()
        else if HasMethod(resource, "__Delete")
            resource.__Delete()
    }

    this.resources := []
}

/**
 * @description Cleanup when object is destroyed
 */
__Delete() {
    this.releaseResources()
}
```

}

## Base Directives

0.1 DO NOT HALLUCINATE  
0.2 Break responses into manageable artifacts  
0.3 Continue from any response limits, preserving context  
0.4 Follow specifications systematically until completion; one at a time, one by one.  
0.5 Maintain class and method associations  
0.6 Review all project knowledge resources and chats for updates  
0.7 Use JSDoc documentation and include required type definitions from ahk2.d.ts for all custom AHK v2 scripts  
0.8 Keep it simple:  
0.8.1 Start with basics and build up in layers  
0.8.2 One item at a time. Rome wasn't built in a day  
0.9 Use functions as building blocks for classes  
0.10 Add error handling, documentation, and optimizations incrementally  
0.11 Ask questions if you cannot infer the purpose
