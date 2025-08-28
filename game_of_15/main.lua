function _init()
    win=false
    pieces={}
    map=build_map()
    pieces=build_pieces()
    empty_tile=nil

    reset()
end

function _update()
    win=check_position()

    process_inputs()
end

function _draw()
    cls()
    draw_map()
    if (win==true) then
        show_win()
    end
end

function draw_map()
    for i=1,#map do
        for j=1,#map[i] do
            tile=map[i][j]
            if (tile.piece) then
                spr(tile.piece.sprite,tile.x,tile.y,4,4)
                print(tile.piece.number,tile.x+1,tile.y+1,13)
            end
        end
    end
end

function check_position()
    local prev = 0
    for row=1,#map do
        for col=1,#map[row] do
            tile=map[col][row]
            if (tile.piece) then
                if (tile.piece.number - prev != 1) return false
                prev=tile.piece.number
            elseif (prev==15) then
                return true
            end
        end
    end
    return true
end

function show_win()
    sfx(0)
    print("press X\n  to\nrestart",empty_tile.x+1,empty_tile.y+1,2)
    if (btn(5)) then
        reset()
    end
end

function reset()
    win=false
    shuffle_pieces()
end

function shuffle_pieces()
    order_pieces()

    for i=1,#map do
        for j=1,#map[i] do
            m=ceil(rnd(i))
            n=ceil(rnd(j))
            map[i][j].piece,map[m][n].piece=map[m][n].piece,map[i][j].piece
            if (map[i][j].piece==nil) then
                empty_tile=map[i][j]
            elseif (map[m][n].piece==nil) then
                empty_tile=map[m][n]
            end
        end
    end
end

function order_pieces()
    for i=1,#pieces do
        row=(i-1)\4+1
        col=i%4
        if (col==0) col=4
        map[col][row].piece=pieces[i]
    end
    map[4][4].piece=nil
    empty_tile=map[4][4]
end

function build_pieces()
    local collection = {}
    for i=1,15 do
        local piece={}
        piece.sprite=(i-1)%4*4 + ((i-1)\4)*64
        piece.number=i
        
        collection[i]=piece
    end
    return collection
end

function build_map()
    local collection = {}
    for i=1,4 do
        collection[i]={}
        for j=1,4 do
            local tile={}
            tile.col=i
            tile.row=j
            tile.x=32*(i-1)
            tile.y=32*(j-1)
            tile.piece=nil

            collection[i][j]=tile
        end
    end
    return collection
end

function process_inputs()
    local target_tile_col=nil
    local target_tile_row=nil
    if (btnp(0)) then
        -- arrow left
        log("arrow left, "..tostr(empty_tile.col)..tostr(empty_tile.row))
        if (empty_tile.col == 4) then
            return --nothing on the right to move left
        end
        target_tile_col=empty_tile.col+1
        target_tile_row=empty_tile.row
    elseif (btnp(1)) then
        log("arrow right"..tostr(empty_tile.col)..tostr(empty_tile.row))
        -- arrow right
        if (empty_tile.col == 1) then
            return --nothing on the left to move right
        end
        target_tile_col=empty_tile.col-1
        target_tile_row=empty_tile.row
    elseif (btnp(2)) then
        log("arrow up"..tostr(empty_tile.col)..tostr(empty_tile.row))
        -- arrow up
        if (empty_tile.row == 4) then
            return --nothing down to move up
        end
        target_tile_col=empty_tile.col
        target_tile_row=empty_tile.row+1
    elseif (btnp(3)) then
        log("arrow down"..tostr(empty_tile.col)..tostr(empty_tile.row))
        -- arrow down
        if (empty_tile.row == 1) then
            return --nothing up to move down
        end
        target_tile_col=empty_tile.col
        target_tile_row=empty_tile.row-1
    --cheat code for quick testing
    elseif (btnp(4)) then
        order_pieces()
    end

    -- log(""..tostr(target_tile_col)..tostr(target_tile_row))
    if (target_tile_col!=nil and target_tile_row!=nil) then
        log(""..tostr(target_tile_col)..tostr(target_tile_row))
        --swap tiles
        map[empty_tile.col][empty_tile.row].piece=map[target_tile_col][target_tile_row].piece
        map[target_tile_col][target_tile_row].piece=nil
        empty_tile=map[target_tile_col][target_tile_row]
        -- log("".tostr(empty_tile.col)..tostr(empty_tile.row)
    end
end

function log(text)
    printh(text, "debug.log")
end