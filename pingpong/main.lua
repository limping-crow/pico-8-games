function _init()
    -- consts, enums etc
    bools = {true,false}
    modes = {SINGLE=1, DOUBLE=2}
    pad_types = {horizontal="horizontal", vertical="vertical"}
    pads_per_mode = {}
    pads_per_mode[modes.SINGLE] = {pad_types.vertical}
    pads_per_mode[modes.DOUBLE] = {pad_types.vertical, pad_types.horizontal}
    coords = {"x", "y"}
    player_codes = {0, 1}

    -- states
    mode = modes.SINGLE
    is_started = false
    is_mode_chosen = false

    -- actors/objects
    players = nil
    ball = nil
end

function _update()
    -- players must choose mode first
    if (not is_mode_chosen) then
        if (btnp(2) or btnp(3)) then
            if (mode == modes.SINGLE) then 
                mode = modes.DOUBLE 
            else
                mode = modes.SINGLE
            end
        elseif (btnp(5)) then
            is_mode_chosen = true
            players = create_players(mode)
            ball = create_ball()
        end
        return

    -- in game, let players start new sets
    elseif (btnp(5) and not is_started) then
        is_started = true
        ball = create_ball()
    end

    move_players(players)

    if (is_started) then 
        detect_collisions(ball)
        move_ball(ball)
    end
end

function _draw()
    cls(5)
    if (not is_mode_chosen) then
        draw_mode_menu()
    else
        draw_players(players)
        draw_ball(ball)
    end
end

function create_players(mode)
    local players = {}
    for code in all(player_codes) do
        local player = {}
        player.code = code
        player.score = 0
        player.pads = {}

        -- one player centered around 0,0, another - 127,127
        -- it's convoluted, I know
        player.along_side = abs(code - 1) * 127
        
        -- I have no idea what I'm doing
        player.score_x = abs(player.along_side - 16)
        player.score_y = abs(player.along_side -  16)

        players[code] = player
        
        -- add pads 
        for p_type in all(pads_per_mode[mode]) do 
            if (p_type == pad_types.horizontal) then
                dynamic_coord = "x"
            else
                dynamic_coord = "y"
            end
            player.pads[p_type] = create_pad(dynamic_coord, player.along_side)
        end
    end

    return players
end

function create_pad(dynamic_coord, along_side)
    local pad = {}

    pad.color = 1
    pad.thickness = 2
    pad.length = 24
    pad.dynamic_coord = dynamic_coord
    pad.along_side = along_side

    for coord in all(coords) do
        if (coord == dynamic_coord) then
            -- place the pad in the middle of screen side
            pad[coord] = 50  
        else
            -- set static coordinate once and for all
            pad[coord] = abs(along_side - pad.thickness)
        end
    end

    --movement
    pad.base_velocity = 1
    pad.velocity = 0
    pad.acceleration = 1.1

    return pad
end

function create_ball()
    local ball = {}
    ball.x = 64
    ball.y = 64
    ball.radius = 7
    ball.color = 12

    ball.velocity_x = 1 * random_direction()
    ball.velocity_y = (0.4 + rnd(0.9)) * random_direction()
    ball.acceleration = 1.001
    return ball
end

function draw_players(players)
    for _, player in pairs(players) do
        for _, pad in pairs(player.pads) do
            -- lame and crud, but works
            if (pad.dynamic_coord == "x") do
                end_x = pad.x + pad.length
                end_y = pad.along_side
            else
                end_y = pad.y + pad.length
                end_x = pad.along_side
            end
            rectfill(pad.x, pad.y, end_x, end_y, pad.color)
            print(player.score, player.score_x, player.score_y, 0)
        end
    end
end

function draw_ball(ball)
    circfill(ball.x, ball.y, ball.radius, ball.color)
end

function draw_mode_menu()
    -- maybe add more state to modes???
    local highlight_clr = 0
    local background_clr = 13
    rectfill(31, 31, 96, 96, background_clr)
    print("choose mode\nand press X", 42, 32, highlight_clr)
    if (mode == modes.SINGLE) then
        s_clr = background_clr
        d_clr = highlight_clr
        selector_y = 59
    else
        s_clr = highlight_clr
        d_clr = background_clr
        selector_y = 69
    end
    rectfill(47, selector_y, 80, selector_y + 7, highlight_clr)
    print("single", 53, 60, s_clr)
    print("double", 53, 70, d_clr)
end

function move_players(players)
    for _, player in pairs(players) do
        for p_type, pad in pairs(player.pads) do
            if (p_type == pad_types.vertical) then
                to_0_btn = 2
                to_127_btn = 3
            else
                to_0_btn = 0
                to_127_btn = 1
            end

            if (btn(to_0_btn, player.code)) then
                -- up or left button
                if (pad.velocity >= 0) then 
                    --change of direction, slow down
                    pad.velocity = -pad.base_velocity
                else
                    pad.velocity = pad.velocity * pad.acceleration
                end
            elseif (btn(to_127_btn, player.code)) then
                -- down or right button
                if (pad.velocity <= 0) then 
                    --change of direction, slow down
                    pad.velocity = pad.base_velocity
                else
                    pad.velocity = pad.velocity * pad.acceleration
                end
            else
                -- reset movement, no slow down for now
                pad.velocity = 0  --player.velocity / 1.3
            end 
            pad[pad.dynamic_coord] += pad.velocity

            -- don't let the pad out of screen boundaries
            pad[pad.dynamic_coord] = max(0, pad[pad.dynamic_coord])
            pad[pad.dynamic_coord] = min(127 - pad.length, pad[pad.dynamic_coord])
        end
    end
end

function move_ball(ball)
    if (not is_started) return

    ball.velocity_x = ball.velocity_x * ball.acceleration
    if (ball.velocity_x > 0) then
        ball.x += ball.velocity_x
    else
        ball.x += ball.velocity_x
    end

    ball.velocity_y = ball.velocity_y * ball.acceleration
    ball.y += ball.velocity_y
end

function detect_collisions(ball)
    -- idea: replace multipliers with directions (use abs to set direction correctly)
    local multipliers = {x=1, y=1} 

    -- here goes nothing
    detect_collision_with_pad(ball, player_l, multipliers)
    detect_collision_with_pad(ball, player_r, multipliers)

    detect_collision_with_walls(ball, multipliers)
    detect_out_of_field(ball, multipliers)

    if (multipliers.x == 0 or multipliers.y == 0) then 
        -- ball out of field
        is_started = false
        if (ball.x > 64) then
            player_l.score += 1
        else
            player_r.score += 1
        end
    end

    ball.velocity_x *= multipliers.x
    ball.velocity_y *= multipliers.y
end

function detect_collision_with_pad(ball, player, multipliers)
    local touch_x = false
    if (player.is_left and player.x + 1 >= ball.x - ball.radius) then 
        touch_x = true
    elseif (not player.is_left and player.x - 1 <= ball.x + ball.radius) then 
        touch_x = true
    end

    if (not touch_x) then
        return
    end

    log("touched: ")

    local pad_top = player.y
    local pad_bottom = player.y + player.height

    if (pad_top <= ball.y and ball.y <= pad_bottom) then
        -- heads-on collision
        multipliers.x = -1
    elseif (ball.y < pad_top and ball.y + ball.radius >= pad_top) then
        -- sideways collision
        multipliers.x = -1
        multipliers.y = 2
        ball.color = 4
    elseif (ball.y > pad_bottom and ball.y - ball.radius <= pad_bottom) then
        multipliers.x = -1
        multipliers.y = 0.5
        ball.color = 4
    end
end

function detect_out_of_field(ball, multipliers)
    if (ball.x + ball.radius >= 127 or ball.x - ball.radius <= 0) then
        multipliers.x = 0
        multipliers.y = 0
    end
end

function detect_collision_with_walls(ball, multipliers)
    if (ball.y + ball.radius >= 127 or ball.y - ball.radius <= 0) then
        multipliers.y = -1
    end
end

function log(txt) 
    -- usage for ints log("text, "..tostr(int_1)..tostr(int_2))
    printh(txt, "debug.log")
end

function random_direction()
    return rnd() < 0.5 and 1 or -1
end