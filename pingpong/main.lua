function _init()
    -- consts, enums etc
    modes = {SINGLE=1, DOUBLE=2}
    bools = {true,false}

    -- states
    mode = modes.SINGLE
    is_started = false
    is_mode_chosen = false

    -- actors/objects
    player_l = create_player(true)
    player_r = create_player(false)
    ball = create_ball()
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
        end
        return

    -- in game, let players start new sets
    elseif (btnp(5) and not is_started) then
        is_started = true
        ball = create_ball()
    end

    move_player(player_l)
    move_player(player_r)

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
        draw_player(player_l)
        draw_player(player_r)
        draw_ball(ball)
    end
end

function create_player(is_left)
    local player = {}
    player.is_left = is_left
    if (is_left) then
        player.x = 2
        player.width = -2
        player.code = 1
        player.score_x = 15
        player.score_y = 12
    else
        player.x = 125
        player.width = 2
        player.code = 0
        player.score_x = 111
        player.score_y = 111
    end

    --measurements
    player.y = 50
    player.height = 24

    --properties
    player.color = 1
    player.score = 0

    --movement
    player.base_velocity = 1
    player.velocity = 0
    player.acceleration = 1.1
    return player
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

function draw_player(player)
    rectfill(player.x, player.y, player.x + player.width, player.y + player.height, player.color)
    print(player.score, player.score_x, player.score_y, 0)
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

function move_player(player)
    if (btn(2, player.code)) then
        -- up button
        if (player.velocity >= 0) then 
            --change of direction, slow down
            player.velocity = -player.base_velocity
        else
            player.velocity = player.velocity * player.acceleration
        end
    elseif (btn(3, player.code)) then
        -- down button
        if (player.velocity <= 0) then 
            --change of direction, slow down
            player.velocity = player.base_velocity
        else
            player.velocity = player.velocity * player.acceleration
        end
    else
        -- reset movement, no slow down for now
        player.velocity = 0  --player.velocity / 1.3
    end 
    player.y = player.y + player.velocity

    -- don't let the player out of screen boundaries
    player.y = max(0, player.y)
    player.y = min(127 - player.height, player.y)
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