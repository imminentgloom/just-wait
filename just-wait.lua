-- just-wait
-- play just friends with MIDI
-- delay just friends
-- just-play v2.1.0 by:@midouest
-- delayyyyyyyyy by: @cfd90
-- just-wait by: @imminent_gloom

CrowControl = include("lib/crow-control")
GridControl = include("lib/grid-control")
Helpers = include("lib/helpers")
JustFriends = include("lib/just-friends")
MidiControl = include("lib/midi-control")
Synth = include("lib/synth")
WSyn = include("lib/wsyn")


engine.name = "just_wait"
initial_monitor_level = 0
is_alt_held = false
persistence = true



-- Synth instance
s = nil

function init()
    
  setup_levels()
  setup_params()
  
  
  setup_defaults()

  if persistence == true then
  	params:read('/home/we/dust/data/just-wait/state.pset')
  end

  params:add_separator('just play')

  params:add{
    type = 'option',
    id = 'jp_module',
    name = 'module',
    options = {'just friends', 'wsyn'},
    action = init_synth,
  }

  params:add{
    type = 'number',
    id = 'jp_num_modules',
    name = 'num modules',
    min = 1,
    max = 2,
    default = 1,
    action = init_synth,
  }

  MidiControl.init {
    on_device = init_synth,
    on_channel = init_synth,
    on_event = midi_to_synth,
  }
  GridControl.init {on_key = grid_to_synth}
  CrowControl.init {
    on_input1 = function(v)
      local semi = Helpers.v2n(v)
      s:transpose(semi)
    end,
  }

  JustFriends.init_params()
  WSyn.init_params()

  params:bang()

  redraw()
end

function setup_levels()
  -- Turn off monitoring, since the engine has a dry/wet knob.
  -- Saves the level at script launch to restore at cleanup() time.
  initial_monitor_level = params:get("monitor_level")
  params:set("monitor_level", -math.huge)
end

function setup_params()
  params:add_separator("delayyyyyyy")
  
  params:add_control("time", "time", controlspec.new(0.0001, 2, 'exp', 0, 0.3, "s"))
  params:set_action("time", function(x) engine.time(x) end)
  
  params:add_control("feedback", "feedback", controlspec.new(0, 100, 'lin', 1, 0, '%'))
  params:set_action("feedback", function(x) engine.feedback(x / 100) end)
  
  params:add_control("sep", "mod/sep", controlspec.new(0, 100, 'lin', 1, 0, '%'))
  params:set_action("sep", function(x) engine.sep(x / 100 / 100) end)
  
  params:add_control("mix", "mix", controlspec.new(0, 100, 'lin', 1, 0, '%'))
  params:set_action("mix", function(x) engine.mix(((x / 100) * 2) - 1) end)
  
  params:add_control("send", "send", controlspec.new(0, 100, 'lin', 1, 0, '%'))
  params:set_action("send", function(x) engine.delaysend(x / 100)  end)
  
  params:add_control("hp", "hp", controlspec.new(20, 10000, 'exp', 0, 400, "Hz"))
  params:set_action("hp", function(x) engine.highpass(x) end)
  
  params:add_control("lp", "lp", controlspec.new(20, 10000, 'exp', 0, 5000, "Hz"))
  params:set_action("lp", function(x) engine.lowpass(x) end)
end

function setup_defaults()
  params:set("time", 0.2)
  params:set("feedback", 75)
  params:set("sep", 10)
  params:set("mix", 40)
  params:set("send", 20)
  params:set("hp", 400)
  params:set("lp", 5000)
end


function cleanup()
  s:cleanup()
  
  if persistence == true then
	params:write('/home/we/dust/data/just-wait/state.pset')
  end
  params:set("monitor_level", initial_monitor_level)

end

function init_synth()
  if s then
    s:cleanup()
  end

  local module = params:get('jp_module') == 1 and JustFriends or WSyn
  local num_modules = params:get('jp_num_modules')
  s = Synth.new(module, num_modules)
end

function midi_to_synth(data)
  local msg = midi.to_msg(data)

  local ch = params:get('midi_channel')
  if ch ~= 0 and msg.ch ~= ch then
    return
  end

  local cc = params:get('midi_cc')

  if msg.type == 'note_on' then
    s:note_on(msg.note, msg.note, msg.vel)
  elseif msg.type == 'note_off' then
    s:note_off(msg.note, msg.note)
  elseif msg.type == 'pitchbend' then
    local pb = params:get('midi_pitchbend')
    local semi = util.linlin(0, 16383, -pb, pb, msg.val)
    s:pitchbend(semi)
  elseif msg.type == 'cc' and msg.cc == cc then
    s:cc(msg.val)
  end
end

function grid_to_synth(x, y, z)
  local id = tostring(x) .. tostring(y)
  local note = GridControl.to_note(x, y)

  if z == 1 then
    local vel = params:get('grid_velocity')
    s:note_on(id, note, vel)
  else
    s:note_off(id, note)
  end
end

function enc(n, d)
  if n == 1 then
    if is_alt_held then
      params:delta("mix", d)
    else
      params:delta("time", d)
    end
  elseif n == 2 then
    if is_alt_held then
      params:delta("lp", d)
    elseif is_k2_held then
      params:delta("feedback_reducer", d)
    else
      params:delta("feedback", d)
    end
  elseif n == 3 then
    if is_alt_held then
      params:delta("sep", d)
    else
      params:delta("send", d)
    end
  end
  
  redraw()
end

function key(n, z)
  if n == 1 then
    is_alt_held = z == 1
  end
  if n == 2 then
    is_k2_held = z == 1
    if z == 1 then
      current_feedback = params:get("feedback")
      params:set("feedback", current_feedback * 0.8)
    else
      params:set("feedback", current_feedback)
    end
  end
  if n == 3 then
    is_k3_held = z == 1
    if z == 1 then
      current_send = params:get("send")
      params:set("send", 100)
    else
      params:set("send", current_send)
    end
  end
  redraw()
end

function redraw()
  screen.clear()
  draw_logo()
  draw_params()
  screen.update()
end

function draw_logo()
  screen.font_face(1)
  screen.font_size(16)
  screen.level(15)
  screen.move(0, 20)
  screen.text("Just wait")

  levels = {12, 10, 8, 6, 4, 3, 2, 1}

  for i=1,#levels do
    screen.level(levels[i])
    screen.text(".")
  end
end

function draw_params()
  screen.font_size(8)
  screen.font_face(1)
  local l1 = 50
  local l2 = 60
  local p1 = 0
  local p2 = 65
  
  if is_alt_held then
    screen.move(p1, l1)
    draw_param("Mix", "mix")
    
    screen.move(p2, l2)
    draw_param("<->", "sep")
    
    screen.move(p1, l2)
    draw_param("LP", "lp")
  else
    screen.move(p1, l1)
    draw_param("Time", "time")
    
    screen.move(p2, l2)
    draw_param("Send", "send")
    
    screen.move(p1, l2)
    draw_param("FB", "feedback")
  end
end

function draw_param(display_name, name)
  screen.level(15)
  screen.text(display_name .. ": ")
  screen.level(3)
  screen.text(params:string(name))
end

