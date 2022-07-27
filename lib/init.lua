export type TypeId =
	"nil"
	| "boolean"
	| "number"
	| "string"
	| "table"
	| "function"
	| "thread"
	| "Literal"
	| "Tuple"
	| "Map" -- { [Type]: Type }
	| "Field" -- { field: Type }
	| "Any"
	| "Optional" -- x?
	| "Union" -- a | b, (...)
	| string -- custom type

export type Type = {
	Is: (...any) -> boolean,
	Type: TypeId,
}

export type NilType = Type

export type FunctionType = Type

export type ThreadType = Type

export type StringType = Type

export type NumberType = Type

export type BooleanType = Type

export type AnyType = Type

export type LiteralType = Type & {
	Value: any,
}

export type OptionalType = Type & {
	ValueType: Type,
}

export type Tuple = Type & {
	ValueTypes: { Type },
}

export type Union = Type & {
	Types: { Type },
}

export type MapType = Type & {
	KeyType: Type,
	ValueType: Type,
}

export type FieldType = Type & {
	Key: Type,
	ValueType: Type,
}

export type Table = Type & {
	Maps: { MapType },
	Fields: { FieldType },
}

local Types = {}
local TypeGlobals = {}
Types.Globals = TypeGlobals

local NilType = { Type = "nil" }
NilType.__index = NilType

function NilType:Is(value): boolean
	return value == nil
end

function NilType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == NilType
end

function NilType:__tostring(): string
	return "nil"
end

NilType = setmetatable({}, NilType) :: NilType
TypeGlobals["nil"] = NilType
Types.Nil = NilType

local StringType = { Type = "string" }
StringType.__index = StringType

function StringType:Is(value): boolean
	return type(value) == "string"
end

function StringType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == StringType
end

function StringType:__tostring(): string
	return "string"
end

StringType = setmetatable({}, StringType) :: StringType
TypeGlobals["string"] = StringType
Types.String = StringType

local NumberType = { Type = "number" }
NumberType.__index = NumberType

function NumberType:Is(value): boolean
	return type(value) == "number"
end

function NumberType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == NumberType
end

function NumberType:__tostring(): string
	return "number"
end

NumberType = setmetatable({}, NumberType) :: NumberType
TypeGlobals["number"] = NumberType
Types.Number = NumberType

local BooleanType = { Type = "boolean" }
BooleanType.__index = BooleanType

function BooleanType:Is(value): boolean
	return type(value) == "boolean"
end

function BooleanType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == BooleanType
end

function BooleanType:__tostring(): string
	return "boolean"
end

BooleanType = setmetatable({}, BooleanType) :: BooleanType
TypeGlobals["boolean"] = BooleanType
Types.Boolean = BooleanType

local FunctionType = { Type = "function" }
FunctionType.__index = FunctionType

function FunctionType:Is(value): boolean
	return type(value) == "function"
end

function FunctionType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == FunctionType
end

function FunctionType:__tostring(): string
	return "function"
end

FunctionType = setmetatable({}, FunctionType) :: FunctionType
TypeGlobals["function"] = FunctionType
Types.Function = FunctionType

local ThreadType = { Type = "thread" }
ThreadType.__index = ThreadType

function ThreadType:Is(value): boolean
	return type(value) == "thread"
end

function ThreadType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == ThreadType
end

function ThreadType:__tostring(): string
	return "thread"
end

ThreadType = setmetatable({}, ThreadType) :: ThreadType
TypeGlobals["thread"] = ThreadType
Types.Thread = ThreadType

local AnyType = { Type = "Any" }
AnyType.__index = AnyType

function AnyType:Is(): boolean
	return true
end

function AnyType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == AnyType
end

function AnyType:__tostring(): string
	return "any"
end

AnyType = setmetatable({}, AnyType) :: AnyType
TypeGlobals["any"] = AnyType
Types.Any = AnyType

local LiteralType = {}
LiteralType.__index = LiteralType

function LiteralType.new(value: any): LiteralType
	return setmetatable({
		Type = "Literal",
		Value = value,
	}, LiteralType) :: LiteralType
end

function LiteralType:Is(value: any): boolean
	return value == self.Value
end

function LiteralType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == LiteralType and self.Value == other.Value
end

function LiteralType:__tostring(): string
	local valueType = type(self.Value)
	if valueType == "string" then
		return '"' .. self.Value .. '"'
	end
	return tostring(self.Value)
end

Types.Literal = LiteralType

TypeGlobals["true"] = LiteralType.new(true)
TypeGlobals["false"] = LiteralType.new(false)

local OptionalType = {}
OptionalType.__index = OptionalType

function OptionalType.new(valueType: Type): OptionalType
	return setmetatable({
		Type = "Optional",
		ValueType = valueType,
	}, OptionalType) :: OptionalType
end

function OptionalType:Is(...): boolean
	if #{ ... } == 0 then
		return true
	end
	return self.ValueType:Is(...)
end

function OptionalType:__eq(other: any): boolean
	return type(other) == "table" and getmetatable(other) == OptionalType and self.ValueType == other.ValueType
end

function OptionalType:__tostring(): string
	return tostring(self.ValueType) .. "?"
end

Types.Optional = OptionalType

local Tuple = {}
Tuple.__index = Tuple

function Tuple.new(...): Tuple
	return setmetatable({
		Type = "Tuple",
		ValueTypes = { ... },
	}, Tuple) :: Tuple
end

function Tuple:AddValueType(value: Type)
	self.ValueTypes[#self.ValueTypes + 1] = value
end

function Tuple:ReplaceValueType(valueType: Type, newValueType: Type)
	for i, v in ipairs(self.ValueTypes) do
		if rawequal(v, valueType) then
			self.ValueTypes[i] = newValueType
			return
		end
	end
end

function Tuple:Is(...): boolean
	local values = { ... }
	for i, valueType in ipairs(self.ValueTypes) do
		if not valueType:Is(values[i]) then
			return false
		end
	end
	return true
end

function Tuple:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= Tuple then
		return false
	end
	if #self.ValueTypes ~= #other.ValueTypes then
		return false
	end
	for i, valueType in ipairs(self.ValueTypes) do
		if valueType ~= other.ValueTypes[i] then
			return false
		end
	end
	return true
end

function Tuple:__tostring(): string
	local valueStrings: { string } = {}
	for i, valueType in self.ValueTypes do
		valueStrings[i] = tostring(valueType)
	end
	return "(" .. table.concat(valueStrings, ", ") .. ")"
end

Types.Tuple = Tuple

local Union = {}
Union.__index = Union

function Union.new(...): Union
	return setmetatable({
		Type = "Union",
		Types = { ... },
	}, Union) :: Union
end

function Union:AddType(value: Type)
	self.Types[#self.Types + 1] = value
end

function Union:ReplaceType(valueType: Type, newValueType: Type)
	for i, v in ipairs(self.Types) do
		if rawequal(v, valueType) then
			self.Types[i] = newValueType
			return
		end
	end
end

function Union:Is(value: any): boolean
	if #self.Types == 0 then
		return false
	end
	for _, type in ipairs(self.Types) do
		if type:Is(value) then
			return true
		end
	end
	return false
end

function Union:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= Union then
		return false
	end
	if #self.Types ~= #other.Types then
		return false
	end
	for i, valueType in ipairs(self.Types) do
		if valueType ~= other.Types[i] then
			return false
		end
	end
	return true
end

function Union:__tostring(): string
	local valueStrings: { string } = {}
	for i, valueType in self.Types do
		valueStrings[i] = tostring(valueType)
	end
	return "(" .. table.concat(valueStrings, " | ") .. ")"
end

Types.Union = Union

local MapType = {}
MapType.__index = MapType

function MapType.new(keyType: any?, valueType: any?): MapType
	return setmetatable({
		Type = "Map",
		KeyType = keyType,
		ValueType = valueType,
	}, MapType) :: MapType
end

function MapType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= MapType then
		return false
	end
	return self.KeyType == other.KeyType and self.ValueType == other.ValueType
end

function MapType:__tostring(): string
	return "[" .. tostring(self.KeyType) .. "]: " .. tostring(self.ValueType)
end

Types.Map = MapType

local FieldType = {}
FieldType.__index = FieldType

function FieldType.new(key: any, valueType: any?): FieldType
	return setmetatable({
		Type = "Field",
		Key = key,
		ValueType = valueType,
	}, FieldType) :: FieldType
end

function FieldType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= FieldType then
		return false
	end
	return self.Key == other.Key and self.ValueType == other.ValueType
end

function FieldType:__tostring(): string
	return tostring(self.Key) .. ": " .. tostring(self.ValueType)
end

Types.Field = FieldType

local TableType = {}
TableType.__index = TableType

function TableType.new(maps: { MapType }?, fields: { FieldType }?): Table
	return setmetatable({
		Type = "table",
		Maps = maps or {},
		Fields = fields or {},
	}, TableType) :: Table
end

function TableType:AddMapType(entryType: MapType)
	self.Maps[#self.Maps + 1] = entryType
end

function TableType:AddFieldType(entry: FieldType)
	self.Fields[#self.Fields + 1] = entry
end

function TableType:Is(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	local validKeys: { any } = {}

	-- Check fields
	for _, field in ipairs(self.Fields) do
		local key = field.Key
		local keyValue = value[key]
		if keyValue == nil then
			return false
		end
		if not field.ValueType:Is(keyValue) then
			return false
		end
		validKeys[#validKeys + 1] = key
	end

	-- Check map types
	for _, map in ipairs(self.Maps) do
		for key, val in pairs(value) do
			if table.find(validKeys, key) then
				continue
			end
			if not (map.KeyType:Is(key) and map.ValueType:Is(val)) then
				return false
			end
		end
	end

	return true
end

function TableType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= TableType then
		return false
	end
	if #self.Maps ~= #other.Maps or #self.Fields ~= #other.Fields then
		return false
	end
	for i, map in ipairs(self.Maps) do
		if map ~= other.Maps[i] then
			return false
		end
	end
	for i, field in ipairs(self.Fields) do
		if field ~= other.Fields[i] then
			return false
		end
	end
	return true
end

function TableType:__tostring(): string
	local hasSpecificTypes = #self.Maps > 0 or #self.Fields > 0
	if not hasSpecificTypes then
		return "{}"
	end
	local fieldStrings: { string } = {}
	for i, field in ipairs(self.Fields) do
		fieldStrings[i] = tostring(field)
	end
	local mapStrings: { string } = {}
	for i, map in ipairs(self.Maps) do
		mapStrings[i] = tostring(map)
	end
	return "{ "
		.. table.concat(fieldStrings, "; ")
		.. (#fieldStrings > 0 and "; " or "")
		.. table.concat(mapStrings, "; ")
		.. " }"
end

Types.Table = TableType

return Types
