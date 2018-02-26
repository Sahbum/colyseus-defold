_G.bit = require "bit"
local fossil_delta = require 'colyseus.fossil_delta.fossil_delta'

function read_file(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function table.clone(org)
  return {table.unpack(org)}
end

local function make_array_from_str(str)
  local arr = {}
  local i = 0

  while i < string.len(str) do
    arr[i + 1] = string.byte(str, i + 1)
    i = i + 1
  end

  return arr
end

local origin = {}
local target = {}
local delta = {}

local i = 1
while i <= 5 do
  origin[i] = make_array_from_str( read_file("test/data/" .. i .. "/origin") )
  target[i] = make_array_from_str( read_file("test/data/" .. i .. "/target") )
  delta[i] = make_array_from_str( read_file("test/data/" .. i .. "/delta") )
  i = i + 1
end

local function to_string(arr)
  local str = ""
  for i,v in ipairs(arr) do
    str = str .. string.char(v)
  end
  return str
end

describe("colyseus", function()
  describe("fossil_delta", function()
    it("should expose 'create' and 'apply' methods", function()
      assert.truthy(fossil_delta.create)
      assert.truthy(fossil_delta.apply)
    end)

    it("should create delta", function()
      assert.are.same(fossil_delta.create(origin[1], target[1]), delta[1])
      assert.are.same(fossil_delta.create(origin[2], target[2]), delta[2])
      assert.are.same(fossil_delta.create(origin[3], target[3]), delta[3])
      assert.are.same(fossil_delta.create(origin[4], target[4]), delta[4])
      assert.are.same(fossil_delta.create(origin[5], target[5]), delta[5])
    end)

    it("should apply delta", function()
      assert.are.same(fossil_delta.apply(table.clone(origin[1]), delta[1]), target[1])
      assert.are.same(fossil_delta.apply(table.clone(origin[2]), delta[2]), target[2])
      assert.are.same(fossil_delta.apply(table.clone(origin[3]), delta[3]), target[3])
      assert.are.same(fossil_delta.apply(table.clone(origin[4]), delta[4]), target[4])
      assert.are.same(fossil_delta.apply(table.clone(origin[5]), delta[5]), target[5])
    end)

  end)
end)

