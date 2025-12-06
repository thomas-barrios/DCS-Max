; JXON - JSON library for AutoHotkey v2
; Based on: https://github.com/TheArkive/JXON_ahk2
; License: MIT
; 
; This library provides JSON parsing and stringifying for AutoHotkey v2.
; 
; Usage:
;   obj := Jxon_Load(&jsonString)     ; Parse JSON string to AHK object
;   str := Jxon_Dump(obj, indent)     ; Convert AHK object to JSON string

Jxon_Load(&src, args*) {
    pos := 1
    return _JsonParse(&src, &pos)
}

_JsonParse(&src, &pos) {
    _SkipWhitespace(&src, &pos)
    
    if (pos > StrLen(src))
        throw Error("Invalid JSON", 0, "Unexpected end of input")
    
    ch := SubStr(src, pos, 1)
    
    if (ch = "{")
        return _ParseObject(&src, &pos)
    else if (ch = "[")
        return _ParseArray(&src, &pos)
    else if (ch = '"')
        return _ParseString(&src, &pos)
    else if (ch = "t" || ch = "f")
        return _ParseBool(&src, &pos)
    else if (ch = "n")
        return _ParseNull(&src, &pos)
    else if (ch = "-" || RegExMatch(ch, "\d"))
        return _ParseNumber(&src, &pos)
    else
        throw Error("Invalid JSON", 0, "Unexpected char: '" ch "' at position " pos)
}

_SkipWhitespace(&src, &pos) {
    while (pos <= StrLen(src) && InStr(" `t`n`r", SubStr(src, pos, 1)))
        pos++
}

_ParseObject(&src, &pos) {
    obj := Map()
    obj.CaseSense := false
    pos++  ; Skip {
    _SkipWhitespace(&src, &pos)
    
    if (SubStr(src, pos, 1) = "}") {
        pos++
        return obj
    }
    
    loop {
        _SkipWhitespace(&src, &pos)
        
        if (SubStr(src, pos, 1) != '"')
            throw Error("Invalid JSON", 0, "Expected string key at position " pos)
        
        key := _ParseString(&src, &pos)
        _SkipWhitespace(&src, &pos)
        
        if (SubStr(src, pos, 1) != ":")
            throw Error("Invalid JSON", 0, "Expected ':' at position " pos)
        pos++
        
        _SkipWhitespace(&src, &pos)
        value := _JsonParse(&src, &pos)
        obj[key] := value
        
        _SkipWhitespace(&src, &pos)
        ch := SubStr(src, pos, 1)
        
        if (ch = "}") {
            pos++
            return obj
        } else if (ch = ",") {
            pos++
        } else {
            throw Error("Invalid JSON", 0, "Expected ',' or '}' at position " pos)
        }
    }
}

_ParseArray(&src, &pos) {
    arr := []
    pos++  ; Skip [
    _SkipWhitespace(&src, &pos)
    
    if (SubStr(src, pos, 1) = "]") {
        pos++
        return arr
    }
    
    loop {
        _SkipWhitespace(&src, &pos)
        value := _JsonParse(&src, &pos)
        arr.Push(value)
        
        _SkipWhitespace(&src, &pos)
        ch := SubStr(src, pos, 1)
        
        if (ch = "]") {
            pos++
            return arr
        } else if (ch = ",") {
            pos++
        } else {
            throw Error("Invalid JSON", 0, "Expected ',' or ']' at position " pos)
        }
    }
}

_ParseString(&src, &pos) {
    if (SubStr(src, pos, 1) != '"')
        throw Error("Invalid JSON", 0, "Expected quote at position " pos)
    
    pos++  ; Skip opening quote
    start := pos
    result := ""
    
    while (pos <= StrLen(src)) {
        ch := SubStr(src, pos, 1)
        
        if (ch = '"') {
            pos++  ; Skip closing quote
            return result
        } else if (ch = "\") {
            pos++
            if (pos > StrLen(src))
                throw Error("Invalid JSON", 0, "Unexpected end of escape sequence")
            
            esc := SubStr(src, pos, 1)
            if (esc = '"')
                result .= '"'
            else if (esc = "\")
                result .= "\"
            else if (esc = "/")
                result .= "/"
            else if (esc = "b")
                result .= "`b"
            else if (esc = "f")
                result .= "`f"
            else if (esc = "n")
                result .= "`n"
            else if (esc = "r")
                result .= "`r"
            else if (esc = "t")
                result .= "`t"
            else if (esc = "u") {
                hex := SubStr(src, pos + 1, 4)
                if (StrLen(hex) = 4 && RegExMatch(hex, "^[0-9A-Fa-f]{4}$"))
                    result .= Chr("0x" hex)
                else
                    throw Error("Invalid JSON", 0, "Invalid unicode escape at position " pos)
                pos += 4
            } else {
                result .= esc  ; Unknown escape, keep as-is
            }
            pos++
        } else {
            result .= ch
            pos++
        }
    }
    
    throw Error("Invalid JSON", 0, "Unterminated string starting at position " start)
}

_ParseNumber(&src, &pos) {
    start := pos
    
    ; Optional minus
    if (SubStr(src, pos, 1) = "-")
        pos++
    
    ; Integer part - either single 0 or digits starting with 1-9
    ch := SubStr(src, pos, 1)
    if (ch = "0") {
        pos++
        ; After leading 0, must not be followed by another digit (except for decimals)
    } else if (RegExMatch(ch, "[1-9]")) {
        pos++
        while (pos <= StrLen(src) && RegExMatch(SubStr(src, pos, 1), "\d"))
            pos++
    } else {
        throw Error("Invalid JSON", 0, "Invalid number at position " start)
    }
    
    isFloat := false
    
    ; Decimal part
    if (pos <= StrLen(src) && SubStr(src, pos, 1) = ".") {
        isFloat := true
        pos++
        if (pos > StrLen(src) || !RegExMatch(SubStr(src, pos, 1), "\d"))
            throw Error("Invalid JSON", 0, "Invalid number - expected digit after decimal at position " pos)
        while (pos <= StrLen(src) && RegExMatch(SubStr(src, pos, 1), "\d"))
            pos++
    }
    
    ; Exponent part
    if (pos <= StrLen(src)) {
        ch := SubStr(src, pos, 1)
        if (ch = "e" || ch = "E") {
            isFloat := true
            pos++
            if (pos <= StrLen(src)) {
                ch := SubStr(src, pos, 1)
                if (ch = "+" || ch = "-")
                    pos++
            }
            if (pos > StrLen(src) || !RegExMatch(SubStr(src, pos, 1), "\d"))
                throw Error("Invalid JSON", 0, "Invalid number - expected digit in exponent at position " pos)
            while (pos <= StrLen(src) && RegExMatch(SubStr(src, pos, 1), "\d"))
                pos++
        }
    }
    
    numStr := SubStr(src, start, pos - start)
    try {
        return isFloat ? Float(numStr) : Integer(numStr)
    } catch as e {
        throw Error("Invalid number: '" numStr "' - " e.Message, 0, "At position " start)
    }
}

_ParseBool(&src, &pos) {
    if (SubStr(src, pos, 4) = "true") {
        pos += 4
        return true
    } else if (SubStr(src, pos, 5) = "false") {
        pos += 5
        return false
    }
    throw Error("Invalid JSON", 0, "Expected 'true' or 'false' at position " pos)
}

_ParseNull(&src, &pos) {
    if (SubStr(src, pos, 4) = "null") {
        pos += 4
        return ""
    }
    throw Error("Invalid JSON", 0, "Expected 'null' at position " pos)
}

Jxon_Dump(obj, indent := "", lvl := 1) {
    if IsObject(obj) {
        if (obj is Map) {
            is_array := false
        } else {
            is_array := true
        }
        
        if (indent = "") {
            if is_array {
                str := "["
                for k, v in obj
                    str .= Jxon_Dump(v, indent, lvl) . ","
                return RTrim(str, ",") . "]"
            } else {
                str := "{"
                for k, v in obj
                    str .= Jxon_Dump(k, indent, lvl) . ":" . Jxon_Dump(v, indent, lvl) . ","
                return RTrim(str, ",") . "}"
            }
        } else {
            indent_str := ""
            Loop lvl
                indent_str .= indent
            indent_str_prev := SubStr(indent_str, 1, StrLen(indent_str) - StrLen(indent))
            
            if is_array {
                str := "[`n"
                for k, v in obj
                    str .= indent_str . Jxon_Dump(v, indent, lvl + 1) . ",`n"
                str := RTrim(str, ",`n") . "`n" . indent_str_prev . "]"
                return str
            } else {
                str := "{`n"
                for k, v in obj
                    str .= indent_str . Jxon_Dump(k, indent, lvl + 1) . ": " . Jxon_Dump(v, indent, lvl + 1) . ",`n"
                str := RTrim(str, ",`n") . "`n" . indent_str_prev . "}"
                return str
            }
        }
    } else if (Type(obj) = "Integer" || Type(obj) = "Float") {
        return obj
    } else if (obj = "") {
        return "null"
    } else if (obj = true) {
        return "true"
    } else if (obj = false) {
        return "false"
    } else {
        obj := StrReplace(obj, "\", "\\")
        obj := StrReplace(obj, "`t", "\t")
        obj := StrReplace(obj, "`r", "\r")
        obj := StrReplace(obj, "`n", "\n")
        obj := StrReplace(obj, "`b", "\b")
        obj := StrReplace(obj, "`f", "\f")
        obj := StrReplace(obj, '"', '\"')
        
        return '"' . obj . '"'
    }
}

; Helper function to deep merge two objects
; target is modified in place, source values override target values
DeepMerge(target, source) {
    if !(source is Map)
        return target
    
    for key, value in source {
        if (target.Has(key) && (target[key] is Map) && (value is Map)) {
            DeepMerge(target[key], value)
        } else {
            target[key] := value
        }
    }
    return target
}

; Helper function to get nested value with default
GetNestedValue(obj, path, defaultValue := "") {
    parts := StrSplit(path, ".")
    current := obj
    
    for part in parts {
        if !(current is Map) || !current.Has(part)
            return defaultValue
        current := current[part]
    }
    return current
}
