script_name = "[Level 2] funcdraw_shapelib"
script_description = "[Phòng Chill Fansub] Thư viện hình vẽ bằng lệnh vẽ của funcdraw fx"
script_author = "Phòng Chill Fansub"
script_version = "beta 3.2.2.0"
--[[fm6 b3.2.2.0 02may26]]
--[[Sử dụng funcdraw v3.2.2.0. độc lập khỏi lib 1]]

--[[Các hàm funcdraw:]]
--[[fd3m(x,y): lệnh đặt điểm vẽ gốc mới (lệnh vẽ 'm'). đầu ra {'m',x,y}]]
--[[fd3n(x,y): lệnh vẽ line 'n'. đầu ra {'l',x,y}]]
--[[fd3b(x1,y1,x2,y2,x3,y3): lệnh vẽ bezier 'b'. đầu ra {'b',x1,y1,x2,y2,x3,y3}]]
--[[bezierMagicNumber(radang): hệ số Bezier của góc rad, dùng cho vẽ cung tròn. (ko làm tròn)]]
--[[findDist(x1,y1,x2,y2): tính khoảng cách (ko làm tròn)]]
--[[findRad(x0,y0,x1,y1): (2-point-to-angle) tìm góc rad giữa vector A(x0,y0)B(x1,y1) và Ox (ko làm tròn)]]
--[[findPos(x0,y0,r0,a0,mode): tính điểm từ gốc, bán kính, góc rad cho trước. (ko làm tròn)]]
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

moon2=function(t,pow,originPos,rotateAngle,cir1,cir2)
    --[[Hàm moon2 cho pj 45c v1.1b2]]
    --[[Dữ liệu của moon1 (pj 45c a1 và v1b1): pow=2]]
    --[[Dữ liệu của moon1_dev (pj 45a): pow=2.8]]
    if not _G.tonumber(t) then 
        return nil 
    end
    local t=_G.clamp(_G.tonumber(t),0,1)
    local ease = {(1-t)^pow}
    --[[Xử lí đầu vào t trong 0..1]] 
    local dymorgPos = {-45*ease[1],-120*ease[1]}
    return { 
        rotate(
            math.rad(-7),
            {dymorgPos[1]-13,dymorgPos[2]-63} ,
            { 
                fd3m(dymorgPos[1]-13-194,dymorgPos[2]-66), 
                circleRad(194,math.rad(-180),math.rad(-257)) 
            }
        ), 
        fd3n(
            _G.table.unpack( 
                findPos(dymorgPos[1]-66,dymorgPos[1]-114,148,math.rad(cir2[4]))
            )
        ), 
        circleRad(148,math.rad(-62),math.rad(214)) 
    }
end

ring2=function(t,pow,angleRange)
    --[[Hàm ring2 cho pj 45c v1.1b2]]
    --[[Dữ liệu của ring1 (pj 45c a1 và v1b1): pow=1.3, angleRange={220,360}]]
    --[[Dữ liệu của ring1_dev (pj 45a): pow=1.7, angleRange={232,360}]]
    if not _G.tonumber(t) then 
        return nil 
    end
    local t=_G.clamp(_G.tonumber(t),0,1)
    local ease = {1-(1-t)^pow}
    --[[Xử lí đầu vào t trong 0..1]]
    local angle = _G.interpolate(ease[1],220,360)
    --[[stretch(stretchAngle,scale,originPos,allTable[,postAngle]): kéo hình theo tỉ lệ*góc kéo từ mốc,]]
    --[[(postAngle là góc xoay mới (coi như 1 lệnh rotate phía sau.)]]
    return stretch( 
        0,1.9,{0,0},
        { 
            fd3m(_G.table.unpack( 
                findPos(0,-2,149,math.rad(-55-angle),0)
            )), 
            circleRad(149,math.rad(-55-angle),math.rad(angle)), 
            fd3n(_G.table.unpack(
                findPos(0,0,165,aconv(-55,1))
            )), 
            circleRad(
                165,math.rad(-55),math.rad(-angle)
            ) 
        }, 
        math.rad(-21)
    ) 
end

--[[Phần hình vẽ cũ]]
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



    


