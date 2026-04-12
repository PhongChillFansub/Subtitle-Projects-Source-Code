script_name = "[Level 2] funcdraw_shapelib"
script_description = "[Phòng Chill Fansub] Thư viện hình vẽ bằng lệnh vẽ của funcdraw fx"
script_author = "Phòng Chill Fansub"
script_version = "beta 3.2.1.04"
--[[fm6 b3.2.1.04 12apr26]]
--[[Sử dụng funcdraw]]

--[[Các hàm funcdraw:]]
--[[fd3m(x,y): lệnh đặt điểm vẽ gốc mới (lệnh vẽ 'm'). đầu ra {'m',x,y}]]
--[[fd3n(x,y): lệnh vẽ line 'n'. đầu ra {'l',x,y}]]
--[[fd3b(x1,y1,x2,y2,x3,y3): lệnh vẽ bezier 'b'. đầu ra {'b',x1,y1,x2,y2,x3,y3}]]
--[[bezierMagicNumber(radang): hệ số Bezier của góc rad, dùng cho vẽ cung tròn. (ko làm tròn)]]
--[[findDist(x1,y1,x2,y2): tính khoảng cách (ko làm tròn)]]
--[[findRad(x0,y0,x1,y1): (2-point-to-angle) tìm góc rad giữa vector A(x0,y0)B(x1,y1) và Ox (ko làm tròn)]]
--[[findPosRad(x0,y0,r0,a0,mode): tính điểm từ gốc, bán kính, góc rad cho trước. (ko làm tròn)]]
--[[Chế độ đầu ra: 1:x, 2:y, nil:table {x,y}, khác:string 'x,y']]
--[[precisionDraw(precision,allTable): vẽ có làm tròn]]
--[[circleRad(r0,a0,a1): vẽ cung tròn bất kì (không lớn hơn 360 độ), từ pha a0, kéo góc a1.]]
--[[zoom(scale(x-y),originPos,allTable)]]
--[[revDir(allTable)]]
--[[rotate(radianAngle,originPos,allTable): xoay hình theo trục z, quanh tâm (originPos {x,y})]]
--[[stretch(stretchAngle,scale,originPos,allTable[,postAngle]): kéo hình theo tỉ lệ*góc kéo từ mốc,]]
--[[(postAngle là góc xoay mới (coi như 1 lệnh rotate phía sau.)]]

function shapeCircle(centerPos,radius,drawDirection) 
    --[[Vẽ hình tròn, centerPos dạng {x,y}, radius]] 
    return tableMerges({ 
        fd3m(centerPos[1]-radius,centerPos[2]), 
        circleRad(radius, math.rad(180), math.rad((drawDirection or 1)*360))
    }) 
end

function shapeRoundRectangle(topLeftCornerPos,bottomRightCornerPos,radius) 
    --[[Vẽ hình vuông bo tròn (phần bo tròn là gọt bớt của hình chữ nhật thường có cùng kích thước)]] 
    return tableMerges({ 
        fd3m(topLeftCornerPos[1]+radius,topLeftCornerPos[2]), 
        fd3n(bottomRightCornerPos[1]-radius,topLeftCornerPos[2]), 
        circleRad(radius,math.rad(-90),math.rad(90)), 
        fd3n(bottomRightCornerPos[1],bottomRightCornerPos[2]-radius), 
        circleRad(radius,math.rad(0),math.rad(90)), 
        fd3n(topLeftCornerPos[1]+radius,bottomRightCornerPos[2]), 
        circleRad(radius,math.rad(90),math.rad(90)),
        fd3n(topLeftCornerPos[1],topLeftCornerPos[2]+radius), 
        circleRad(radius,math.rad(180),math.rad(90)) 
    }) 
end


--[[demo1: hình vẽ từ tệp phát triển (trước khi làm pj 45a, 45c)]]
demo1 = { 
    stretch(0,1.9,{0,-2},{ 
            shapeCircle({0,-2},150)
        }, math.rad(-21)
    ), 
    zoom(
        {1.11,1.11},{0,0},
        { 
            stretch(0,1.9,{0,0},{ 
                    shapeCircle({0,0}, 149 ,-1) 
                }, math.rad(-21)
            ) 
        }
    ), 
    shapeCircle({-13,-63},194,-1), 
    shapeCircle({-66,-114},147) 
};;;;; 
--[[Vẽ 4 hình tròn (cùng 1 lần vẽ), trong đó 2 hình tròn trước có kéo giãn+xoay]]
--[[4 hình tròn lần lượt có chiều vẽ là 1,-1,-1,1.]]

demo2_ring = { 
    stretch( 
        0,1.9,{0,0},
        { 
            shapeCircle({0,-2},150), 
            shapeCircle({0,0},165,-1) 
        }, 
        math.rad(-21)
    ) 
};;;;;
--[[Vẽ 2 hình tròn (cùng 1 lần vẽ), rồi kéo giãn cả 2 thành elip]]
--[[Hình vẽ thử nghiệm cho pj 45]]

moon1_dev = function(j0,maxj0) 
    if j0==nil or maxj0==nil or j0<0 then 
        return nil 
    end 
    local startingPoint = {-45,-120} 
    local ease = {1-(1-_G.clamp(j0/maxj0,0,1))^2.8} 
    local movingOffset = {-1*startingPoint[1]*(-1+ease[1] ),-1*startingPoint[2]*(-1+ease[1])} 
    return { 
        rotate(
            aconv(-7,1),
            {-13+movingOffset[1],-63+movingOffset[2]},{ 
                fd3m(-13-194+movingOffset[1],-63+movingOffset[2]), 
                circleRad(194,math.rad(-180),math.rad(-257)) 
            }
        ), 
        fd3n(_G.table.unpack( findPos(
            -66+movingOffset[1],
            -114+movingOffset[2],
            148,
            math.rad(-62)
        ))), 
        circleRad(148,math.rad(-62),math.rad(214)) 
    }
end
--[[Hình moon1 của tệp phát triển v3.1 và pj 45a]]

ring1_dev = function(j0,maxj0) 
    if j0==nil or maxj0==nil or j0<0 then 
        return nil 
    end 
    local ease = {1-(1-_G.clamp(j0/maxj0,0,1))^1.7} 
    local angleRange = {232,360} 
    return stretch(0,1.9,{0,0},{
        fd3m(_G.table.unpack(findPos(
            0,-2,149,
            math.rad(-55-angleRange[1]-(angleRange[2]-angleRange[1])*ease[1])
        ))), 
        circleRad(
            149,
            math.rad(-55-angleRange[1]-(angleRange[2]-angleRange[1])*ease[1]),
            math.rad(angleRange[1]+(angleRange[2]-angleRange[1])*ease[1])
        ), 
        fd3n(_G.table.unpack(findPos(
            0,0,165,math.rad(-55)
        ))), 
        circleRad(
            165,
            math.rad(-55),
            math.rad(-angleRange[1]-(angleRange[2]-angleRange[1])*ease[1])
        )
    }, math.rad(-21) ) 
end
--[[Hình ring1 của tệp phát triển v3.1 và pj 45a]]

function moon1(j0,maxj0) 
    if j0==nil or maxj0==nil or j0<0 then return nil end 
    local startingPoint = {-45,-120} 
    local ease = {1-(1-_G.clamp(j0/maxj0,0,1))^2} 
    local movingOffset = {-1*startingPoint[1]*(-1+ease[1] ),-1*startingPoint[2]*(-1+ease[1])} 
    return _G.table.unpack({ rotate(aconv(-7,1),{-13+movingOffset[1],-63+movingOffset[2]},{ fd3m(-13-194+movingOffset[1],-63+movingOffset[2]), circleRad(194,aconv(-180,1),aconv(-257,1)) }), fd3n(_G.table.unpack( findPosRad(-66+movingOffset[1],-114+movingOffset[2],148,aconv(-62,1),0))), circleRad(148,aconv(-62,1),aconv(214,1)) }) end;;;;; function ring1(j0,maxj0) if j0==nil or maxj0==nil or j0<0 then return nil end local ease = {1-(1-_G.clamp(j0/maxj0,0,1))^1.3} local angleRange = {220,360} return stretch( aconv(0,1) ,1.9,{0,0},{ fd3m( _G.table.unpack( findPosRad(0,-2,149,aconv(-55-angleRange[1]-(angleRange[2]-angleRange[1])*ease[1],1),0)) ), circleRad(149,aconv(-55-angleRange[1]-(angleRange[2]-angleRange[1])*ease[1],1),aconv(angleRange[1]+(angleRange[2]-angleRange[1])*ease[1],1)), fd3n( _G.table.unpack( findPosRad(0,0,165,aconv(-55,1),0)) ), circleRad(165,aconv(-55,1),aconv(-angleRange[1]-(angleRange[2]-angleRange[1])*ease[1],1)) }, aconv(-21,1)) end;;;;;

