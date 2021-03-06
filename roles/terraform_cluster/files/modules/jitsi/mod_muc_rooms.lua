local jid = require("util.jid")
local it = require("util.iterators")
local json = require("util.json")
local iterators = require("util.iterators")
local array = require("util.array")

local have_async = pcall(require, "util.async")
if not have_async then
  module:log("error", "requires a version of Prosody with util.async")
  return
end

local async_handler_wrapper = module:require("util").async_handler_wrapper

local tostring = tostring
local neturl = require("net.url")
local parse = neturl.parseQuery

local get_room_from_jid = module:require("util").get_room_from_jid

local muc_domain = os.getenv("XMPP_MUC_DOMAIN") or "muc.meet.jitsi"

function get_health(event)
  return { status_code = 204 }
end

function get_rooms(event)
  local rooms = array()
  local num_rooms = 0
  local component = hosts[muc_domain]
  if component then
    local muc = component.modules.muc
    if muc and rawget(muc, "all_rooms") then
      for room in muc.all_rooms() do
        num_rooms = num_rooms + 1
        -- Hide rooms starting with the specified prefix.
        if string.sub(room.jid, 1, 1) ~= "_" then
          local room_info = get_room_info(room.jid)
          if room_info then
            rooms:push(room_info)
          end
        end
      end
    end
  end

  headers = {
    content_type = "application/json",
    access_control_allow_origin = "*"
  };
  body = {
    num_rooms = num_rooms,
    rooms = rooms
  }

  return { status_code = 200, body = json.encode(body), headers=headers }
end

function get_room_info(room_address)
  local room_name, domain_name = jid.split(room_address)

  local room = get_room_from_jid(room_address)

  local occupants = array()
  local breakout_rooms = array()

  if room then
    occupants = get_occupants(room)

    for breakout_room_jid, name in pairs(room._data.breakout_rooms or {}) do
      local breakout_room = get_room_from_jid(breakout_room_jid)
      local breakout_room_occupants = array()
      if breakout_room then
        breakout_room_occupants = get_occupants(breakout_room)
      end
      breakout_rooms:push({
        jid = breakout_room_jid,
        name = tostring(name),
        occupants = breakout_room_occupants,
      })
    end

    return {
      jid = tostring(room_address),
      name = tostring(room_name),
      occupants = occupants,
      breakoutRooms = breakout_rooms,
    }
  end
end

function get_occupants(room)
  local occupants = array()
  if room._occupants then
    for _, occupant in room:each_occupant() do
      -- filter focus as we keep it as hidden participant
      if string.sub(occupant.nick, -string.len("/focus")) ~= "/focus" then
        for _, pr in occupant:each_session() do
          local nick = pr:get_child_text("nick", "http://jabber.org/protocol/nick") or ""
          occupants:push({
            jid = tostring(occupant.jid),
            name = tostring(nick),
          })
        end
      end
    end
  end
  return occupants
end

function module.load()
  module:depends("http")
  module:provides("http", {
    default_path = "/",
    route = {
      ["GET health"] = function(event)
        return async_handler_wrapper(event, get_health)
      end,
      ["GET rooms"] = function(event)
        return async_handler_wrapper(event, get_rooms)
      end,
    },
  })
end
