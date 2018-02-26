local Connection = require('colyseus.connection')
local Room = require('colyseus.room')
local protocol = require('colyseus.protocol')
local EventEmitter = require('colyseus.events').EventEmitter
local msgpack = require('colyseus.messagepack.MessagePack')
local utils = require('colyseus.utils')

local client = { VERSION = "0.8.0" }
client.__index = client

function client.new (endpoint)
  local instance = EventEmitter:new({
    id = utils.get_colyseus_id(),
    roomStates = {}, -- object
    rooms = {}, -- object
    connectingRooms = {}, -- object
    joinRequestId = 0, -- number
  })
  setmetatable(instance, client)
  instance:init(endpoint)
  return instance
end

function client:init(endpoint)
  self.hostname = endpoint
  self.connection = Connection.new(self.hostname .. "/?colyseusid=" .. utils.get_colyseus_id())

  self.connection:on("message", function(message)
    self:on_batch_message(message)
  end)

  self.connection:on("close", function(message)
    self:emit("close", message)
  end)

  self.connection:on("error", function(message)
    self:emit("error", message)
  end)
end

function client:loop()
  self.connection:loop()

  for k, room in pairs(self.rooms) do
    room:loop()
  end
end

function client:close()
  self.connection:close()
end

function client:join(...)
  local args = {...}

  local roomName = args[1]
  local options = args[2] or {}

  self.joinRequestId = self.joinRequestId + 1
  options.requestId = self.joinRequestId;

  local room = Room.create(roomName);

  -- remove references on leaving
  room:on("leave", function()
    self.rooms[room.id] = nil
    self.connectingRooms[options.requestId] = nil
  end)

  self.connectingRooms[options.requestId] = room

  self.connection:send({ protocol.JOIN_ROOM, roomName, options });

  return room
end

function client:on_batch_message(messages)
  for _, message in msgpack.unpacker(messages) do
    self:on_message(message)
  end
end

function client:on_message(message)

  if type(message[1]) == "number" then
    local roomId = message[2]

    if message[1] == protocol.USER_ID then
      utils.set_colyseus_id(message[2])

      self.id = message[2]
      self:emit('open')

    elseif (message[1] == protocol.JOIN_ROOM) then
      local requestId = message[3]
      local room = self.connectingRooms[requestId]

      if not room then
        print("colyseus.client: client left room before receiving session id.")
        return
      end

      room.id = roomId;
      room:connect( Connection.new(self.hostname .. "/" .. room.id .. "?colyseusid=" .. self.id) );

      self.rooms[room.id] = room
      self.connectingRooms[ requestId ] = nil;

    elseif (message[1] == protocol.JOIN_ERROR) then
      self:emit("error", message[3])
      table.remove(self.rooms, roomId)

    else
      self:emit('message', message)

    end
  end
end

return client
