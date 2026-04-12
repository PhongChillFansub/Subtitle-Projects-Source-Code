script_name = "[Level 2] vcfx"
script_description = "[Phòng Chill Fansub] Effect màu vector (vector color, \\vc) với VSFilter (không dùng VSFilterMod)"
script_author = "Phòng Chill Fansub"
script_version = "beta 2.0.1.1"
--[[fm5 b2.0.1.1 12apr26]]
--[[Cập nhật vcfx v2.0: cho phép áp dụng nhiều bảng màu 2x2 trong 1 mục tiêu.]]
--[[Sử dụng independentCounter, interpolate_color_2d của lib 1]]
vcfx_debug = 5
vcfxV2_lod_const = nil

function vcFallback(vc_input) 
    --[[Hàm làm đầy dữ liệu màu vector trong trường hợp đầu vào (vc_input) không đủ số lượng màu]]
    --[[Cấu trúc đầu vào bảng màu đơn vc_input[i]: i: stt màu (1-4) theo tag \an (7,9,1,3), tương tự \vc]] 
    --[[Cấu trúc đầu ra vc_input[i] đã điền đủ hợp lệ]] 
    --[[Phần làm đầy dữ liệu. Kiểu dữ liệu "trống" hợp lệ: '', nil. vd: {'','','',''}]] 
    local check_result = {0,0,0,0}
    --[[Cấu trúc kết quả kiểm tra check_result: i: theo màu]]
    for i=1,4 do
        --[[Tiến hành kiểm tra]]
        if (vc_input[i] or '') ~= '' then 
            check_result[1] = check_result[1]+10^(4-i)
            --[[i=1: Kết quả kiểm tra (1 nếu có, 0 nếu trống)]]
            check_result[2] = check_result[2]+1
            --[[i=2: Số lượng màu được cấp trong bảng đầu vào]]
            check_result[3] = i
            --[[i=3: Màu cuối cùng không trống]]
        else
            check_result[4] = i
            --[[i=4: Màu cuối cùng trống]]
        end
    end
    
    if check_result[2] == 1 then
        --[[TH1: chỉ có 1/4 màu. Xử lí cho 4 màu như màu này]]
        for i=1,4 do
            vc_input[i] = vc_input[check_result[3]]
        end
    elseif check_result[1] == 1100 then
        --[[TH2a: có 2 màu an7 và an9 (màu vector 1 chiều: ngang). Xử lí an1=an7, an3=an9]]
        vc_input[3] = vc_input[1]
        vc_input[4] = vc_input[2]
    elseif check_result[1] == 1010 then 
        --[[TH2b: có 2 màu an7 và an1 (màu vector 1 chiều: dọc). Xử lí an9=an7, an3=an1]] 
        vc_input[2] = vc_input[1]
        vc_input[4] = vc_input[3]
    elseif check_result[1] == 1001 then 
        --[[TH2c: có 2 màu an7 và an3 (vector chiều chéo xuống/dấu huyền). Xử lí an9=an1=trung bình 2 màu kia]] 
        vc_input[2] = _G.interpolate_color(0.5,vc_input[1],vc_input[4]) 
        vc_input[3] = vc_input[2] 
    elseif check_result[1] == 110 then 
        --[[TH2d: có 2 màu an9 và an1 (vector chiều chéo lên/dấu sắc). Xử lí an7=an3=trung bình 2 màu kia--]] 
        vc_input[1] = _G.interpolate_color(0.5,vc_input[2],vc_input[3]); 
        vc_input[4] = vc_input[1]
    elseif check_result[2] == 3 then 
        --[[TH3: có 3 màu. màu còn thiếu bằng màu ở góc đối diện--]] 
        local opposite = (check_result[4]+1)%4+1
        --[[Màu đối diện (bộ 4) = stt+2 (nếu lớn hơn 4 thì trừ đi 4, ở đây là mod 4). Đưa +1 ra sau do stt đếm từ 1 (mod từ 0)]] 
        vc_input[check_result[4]] = vc_input[opposite] 
    end  
    return vc_input 
end
--[[vcFallback() về cơ bản không thay đổi so với smartVectorColorCheck() của v1.4]]

function vcfxV2_ExtractColor(vcfx_color)
    --[[Hàm trích xuất chênh lệch màu (theo 2 chiều x,y)]]
    --[[Đầu vào: bảng màu vcfx_color gồm nhiều bảng màu đơn {Nx{4x<color>}}]]
    --[[Đầu ra: bảng vcfxV2_color_diff = {diff_x,diff_y}]]
    local vcfxV2_color_diff = {0,0}
    local colordiff_list = {x={},y={}}
    --[[Đặt đầu ra mặc định]]
    local extCol, abstr, max, unpack = _G.extract_color, math.abs, math.max, _G.table.unpack
    --[[Đặt các hàm sử dụng (tối ưu hóa)]]
    for pallette_index = 1,#vcfx_color do
        vcfx_color[pallette_index] = vcFallback(vcfx_color[pallette_index])
        local rgb_ext = {{0,0,0,0},{0,0,0,0},{0,0,0,0}}
        --[[rgb_ext[i0][i1]: i0=1:r, 2:g, 3:b; i1=color_index]]
        for color_index = 1,#vcfx_color[pallette_index] do
            rgb_ext[1][color_index],rgb_ext[2][color_index],rgb_ext[3][color_index] = extCol(vcfx_color[pallette_index][color_index])
        end
        for i=1,#rgb_ext do
            colordiff_list.x[#colordiff_list.x+1]=abstr(rgb_ext[i][1]-rgb_ext[i][2])
            --[[Thêm chênh lệch rgb_ext[i] (màu thành phần) của màu 1 và 2 (an7, an9) vào d.sách chiều x]]
            colordiff_list.x[#colordiff_list.x+1]=abstr(rgb_ext[i][3]-rgb_ext[i][4])
            --[[Thêm chênh lệch rgb_ext[i] (màu thành phần) của màu 3 và 4 (an1, an3) vào d.sách chiều x]]
            colordiff_list.y[#colordiff_list.y+1]=abstr(rgb_ext[i][1]-rgb_ext[i][3])
            --[[Thêm chênh lệch rgb_ext[i] (màu thành phần) của màu 1 và 3 (an7, an1) vào d.sách chiều y]]
            colordiff_list.y[#colordiff_list.y+1]=abstr(rgb_ext[i][2]-rgb_ext[i][4])
            --[[Thêm chênh lệch rgb_ext[i] (màu thành phần) của màu 2 và 4 (an9, an3) vào d.sách chiều y]]
        end
    end
    vcfxV2_color_diff[1]=max(unpack(colordiff_list.x))
    vcfxV2_color_diff[2]=max(unpack(colordiff_list.y))
    return vcfxV2_color_diff
end

function vcfxV2_Generate(vcfxV2_lod, vcfx_color)
    --[[Hàm tạo dữ liệu đầu ra vcV2]]
    --[[Cấu trúc đầu vào V2_lod: {1: x, 2: y}]]
    --[[Cấu trúc đầu vào _color: {Nx{4x<color>}}, tức N bảng màu 2x2]]
    --[[Cấu trúc đầu vào _pos: {1: left, 2: top, 3: right, 4: bottom}, trong khoảng 0..1]]
    local new_line=string.char(10)
    if vcV2 == nil then vcV2 = {} end
    --[[Khởi tạo không gian đầu ra (nếu trước đó không có)]]
    vcV2[#vcV2+1] = {color=vcfx_color, xc={}, yc={}}
    --[[Cấu trúc bảng vcV2[key] = {.xc, .yc (0..1); .color=vcfx_color {Nx{4x<color>}} }]]
    for i=1,vcfxV2_lod[1] do
        vcV2[#vcV2].xc[i]=(i-1)/(math.max(1,vcfxV2_lod[1]-1))
    end
    for i=1,vcfxV2_lod[2] do
        vcV2[#vcV2].yc[i]=(i-1)/(math.max(1,vcfxV2_lod[2]-1))
    end
    vcV2_key = #vcV2
    return string.format('[vcfxV2_Gen] Đã tạo mới vùng %d phân giải %dx%d%s',vcV2_key,vcfxV2_lod[1],vcfxV2_lod[2],new_line)
end

function vcfxV2_Base(vcfx_size, vcfx_color, vcfx_range) 
    --[[Cấu trúc bảng đầu vào vcfx_size: {1: x, 2: y}, kích thước vùng chia.]]
    --[[Cấu trúc bảng đầu vào vcfx_color: gồm nhiều bảng màu đơn {4x<color>}.]]
    --[[Cấu trúc bảng đầu vào vcfx_range: {1: left, 2: top, 3: right, 4: bottom, tất cả đều là 0..1}]]
    --[[Đầu ra gián tiếp: vcV2[key] = {.xc, .yc (0..1); .color=vcfx_color {Nx{4x<color>}} } ]]
    --[[Đầu ra trực tiếp: MxN]]
    --[[Hằng số độ phân giải (đơn vị: px) là kích thước ô phân giải với chênh lệch màu 256 đơn vị.]]
    --[[Nó tỉ lệ thuận với kích thước vùng áp dụng màu vector, chênh lệch màu,]]
    --[[tỉ lệ nghịch với độ phân giải cơ sở (độ chia  màu cho chênh lệch 256 đơn vị)]]
    vcfxV2_lod_const = vcfxV2_lod_const or 2.6
    --[[Hằng số độ phân giải mặc định là 2 pixel/ô phân giải]]
    vcfxV2_color_diff = vcfxV2_ExtractColor(vcfx_color)
    vcfxV2_lod = _G.table.copy(vcfxV2_color_diff)
    --[[Tạm đặt vcfxV2_lod = vcfxV2_color_diff (_lod hiện là chênh lệch màu)]]
    local new_line=string.char(10)
    for i=1,#vcfxV2_lod do
        vcfxV2_lod[i] = math.max(1,math.ceil( vcfx_size[i]*(vcfx_range[2+i]-vcfx_range[i])/vcfxV2_lod_const * vcfxV2_lod[i]/256 ))
        --[[v1: số lượng ô phân giải = chênh lệch màu/(256/đpg cơ sở thủ công) = đpg cơ sở thủ công*chênh lệch màu/256]]
        --[[v2: số lượng ô phân giải = kích thước vùng chia/h.số đpg * chênh lệch màu/256]]
        --[[v2: vcfxV2_lod = vcfx_size/vcfxV2_lod_const * vcfxV2_color_diff/256 ]] 
    end
    --[[Phần memoization]]
    local memo_check=0
    for check_index=1,(vcV2 and #vcV2 or 0) do
        if #vcV2[check_index].xc==vcfxV2_lod[1] and #vcV2[check_index].yc==vcfxV2_lod[2] then 
            vcV2_key = check_index
            memo_check=1
            _G.aegisub.log(vcfx_debug,'[vcfxV2_Base] Dùng lại vùng %d phân giải %dx%d%s',vcV2_key,vcfxV2_lod[1],vcfxV2_lod[2],new_line)
            break
        end
    end
    --[[Khởi tạo kết quả đầu ra]]
    if memo_check==0 then _G.aegisub.log(vcfx_debug,vcfxV2_Generate(vcfxV2_lod, vcfx_color)) end
    return vcfxV2_lod[1]*vcfxV2_lod[2]
end

function vcfxV2_MergeGen(text,vcV2_entity_count,vcV2_entity_key,vcV2_entity_range)
    --[[Hàm tạo bảng cho vcfxV2_MainMerge]]
    --[[Cấu trúc bảng đầu vào _entity_count[key]: key: area_index, value: số entity của mỗi vùng]]
    --[[Cấu trúc bảng đầu vào _entity_key[key]: area_index, value: chi tiết thuộc tính vùng (vcV2[key])]]
    --[[Cấu trúc bảng đầu vào _entity_range[key]: {left,top,right,bottom}]]
    --[[Đầu ra: vcV2_merged={entity_index -> {area_key,color,index,ix,iy,xc,yc,x0,y0,x1,y1} }]]
    local new_line=string.char(10)
    vcV2_merged = {} 
    local entity_checkpoint,max,unpack = {0},_G.math.max,_G.table.unpack
    for i=1,#vcV2_entity_count do 
        entity_checkpoint[i] = entity_checkpoint[max(i-1,1)] + vcV2_entity_count[i]
    end
    --[[checkpoint dạng {c1,c2,c3,...,cN} tăng dần.]]
    local vcV2_mergeunit = {area_key=0,color={},index=0,ix=0,iy=0,xc=0,yc=0,x0=0,y0=0,x1=1,y1=1}
    --[[Vòng lặp tính dữ liệu từng entity]]
    for entity_index=1,entity_checkpoint[#entity_checkpoint] do
        --[[reset range4unit mỗi khi sang entity mới]]
        local vcV2_range4unit = {0,0,1,1}
        --[[Cấu trúc đơn vị con của đầu ra.]]
        vcV2_mergeunit.index=independentCounter(vcV2_mergeunit.index)
        for check_area=1,#entity_checkpoint do
            --[[Lấy giá trị vùng, tính index trong vùng]]
            if entity_index<=entity_checkpoint[check_area] then
                vcV2_mergeunit.area_key=vcV2_entity_key[check_area]
                vcV2_mergeunit.index=vcV2_mergeunit.index-(entity_checkpoint[(check_area-1)] or 0)
                vcV2_range4unit = vcV2_entity_range[check_area] or vcV2_range4unit
                break
            end
        end
        --[[Có index theo vùng, lấy dữ liệu màu, lấy dữ liệu vùng để tính toán]]
        --[[Cấu trúc bảng vcV2_data = vcV2[key] = {.xc, .yc (0..1); .color=vcfx_color {Nx{4x<color>}} }]]
        vcV2_mergeunit.color =vcV2[vcV2_mergeunit.area_key].color
        local vcV2_data = vcV2[vcV2_mergeunit.area_key]
        --[[Tính toán index theo chiều (trong vùng)]]
        if vcV2_mergeunit.index==1 then
            vcV2_mergeunit.ix,vcV2_mergeunit.iy=1,1
        else
            vcV2_mergeunit.ix=independentCounter(vcV2_mergeunit.ix,#vcV2_data.xc)
            if vcV2_mergeunit.ix == 1 then 
                vcV2_mergeunit.iy=independentCounter(vcV2_mergeunit.iy,#vcV2_data.yc) 
            end
        end
        --[[Lấy dữ liệu vị trí màu (.xc, .yc)]]
        vcV2_mergeunit.xc=vcV2_data.xc[vcV2_mergeunit.ix]
        vcV2_mergeunit.yc=vcV2_data.yc[vcV2_mergeunit.iy]
        --[[Tính vị trí clip]]
        local itpl = function(x) return _G.interpolate(x/#vcV2_data.xc,vcV2_range4unit[1],vcV2_range4unit[3]) end
        vcV2_mergeunit.x0 = itpl(vcV2_mergeunit.ix-1)
        vcV2_mergeunit.x1 = itpl(vcV2_mergeunit.ix)
        local itpl = function(y) return _G.interpolate(y/#vcV2_data.yc,vcV2_range4unit[2],vcV2_range4unit[4]) end
        vcV2_mergeunit.y0 = itpl(vcV2_mergeunit.iy-1)
        vcV2_mergeunit.y1 = itpl(vcV2_mergeunit.iy)  
        
        --[[Cuối cùng, thêm mergeunit vào bảng vcV2_merged]]
        local tblcpy = _G.table.copy
        vcV2_merged[entity_index]=tblcpy(vcV2_mergeunit)
    end
    msg='[vcfxV2_Merge] Hoàn tất hợp nhất %d ô phân giải cho entity:%s"%s"%s%s'
    return string.format(msg,#vcV2_merged,new_line,text,new_line,new_line)
end

function vcfxV2_MainMerge(vcfx_entitydata,vcfx_data)
    --[[Hàm chính để tính toán hợp nhất các vùng chia vcfxV2_Base, theo dữ liệu từ biến vcfx_data]]
    --[[Cấu trúc bảng đầu vào vcfx_entitydata: {1: width, 2: height, 3: text_stripped}, kích thước vùng chia.]]
    --[[Cấu trúc đầu vào vcfx_data: .color {các bảng mẹ vcfx_color}; .range({4x<range>}: các bảng vị trí tương ứng).]]
    --[[Đầu ra: tổng số ô phân giải từ các vùng chia của vxfxV2_Base.]]
    local new_line=string.char(10)
    vcV2_entity_count,vcV2_entity_key,vcV2_entity_range = {0},{},{}
    for area_index=1,#vcfx_data.color do
        _G.aegisub.log(vcfx_debug,'[vcfxV2_Main] Đang xét vùng %d/%d.%s',area_index,#vcfx_data.color,new_line)
        vcV2_entity_count[area_index] = vcfxV2_Base({vcfx_entitydata[1],vcfx_entitydata[2]}, vcfx_data.color[area_index], vcfx_data.range[area_index])
        vcV2_entity_key[area_index] = vcV2_key
    end
    --[[Đặt các dữ liệu số lượng, key thuộc tính entity]]
    _G.aegisub.log(vcfx_debug,vcfxV2_MergeGen(vcfx_entitydata[3],vcV2_entity_count,vcV2_entity_key,vcfx_data.range))
    return #vcV2_merged
end

function vctClipS(text_data,entity_data,offset_input)
    --[[Hàm tính toán clip cho các entity của vcfxV2_MainMerge]]
    --[[Cấu trúc đầu vào line_data: {.left, .top, .right, .bottom}]]
    --[[Nếu đầu vào tùy chỉnh thì cũng sử dụng các key tương tự.]]
    --[[Cấu trúc đầu vào entity_data: vcV2_merged[i] tức vcV2_mergeunit]]
    --[[vcV2_merged={entity_index -> {area_key,color{},index,ix,iy,xc,yc,x0,y0,x1,y1} }]]
    --[[Cấu trúc bảng offset_input (v2): 1-2: tịnh tiến, 3-4: mở rộng, 5-6: mở rộng viền]]
    local new_line=string.char(10)
    local msg = '[vctClipS] (area_key=%d, index=%d, ix=%d, iy=%d,)%s'
    _G.aegisub.log(vcfx_debug,msg,entity_data.area_key,entity_data.index,entity_data.ix,entity_data.iy,new_line)
    local msg = '[vctClipS] (,c={%.2g,%.2g},0={%.2g,%.2g},1={%.2g,%.2g})%s'
    _G.aegisub.log(vcfx_debug,msg,entity_data.xc,entity_data.yc,entity_data.x0,entity_data.y0,entity_data.x1,entity_data.y1,new_line)
    local output = {0,0,0,0}
    local newbox={text_data[3]-text_data[1]+offset_input[3],text_data[4]-text_data[2]+offset_input[4]}
    --[[4 vị trí cho tag \clip dạng chữ nhật]]
    output[1]=text_data[1]-offset_input[3]/2+newbox[1]*entity_data.x0+offset_input[1] -(entity_data.xc==0 and offset_input[5] or 0)
    output[2]=text_data[2]-offset_input[4]/2+newbox[2]*entity_data.y0+offset_input[2] -(entity_data.yc==0 and offset_input[6] or 0)
    output[3]=text_data[1]-offset_input[3]/2+newbox[1]*entity_data.x1+offset_input[1] +(entity_data.xc==1 and offset_input[5] or 0)
    output[4]=text_data[2]-offset_input[4]/2+newbox[2]*entity_data.y1+offset_input[2] +(entity_data.yc==1 and offset_input[6] or 0)
    for i=1,#output do
        output[i]=cnfv4(output[i],0)
    end
    return _G.table.concat(output,',')
end

function vctColorS(vcfx_color,newrange)
    --[[Hàm thu nhỏ không gian màu theo 2 chiều (từ 0..1 đến x..y trong khoảng 0..1)]]
    --[[Đầu vào vcfx_color: 4x<màu>: \an: 7,9,1,3; tự động chuẩn hóa bằng vcFallback()]]
    --[[Đầu vào newrange: {left,top,right,bottom} mới]]
    vcfx_color = vcFallback(vcfx_color)
    local output, itplc = {'','','',''}, function (x,y) return interpolate_color_2d(x,y,vcfx_color) end
    --[[Hàm interpolate_color_2d trong lib 1]]
    output[1]=itplc(newrange[1],newrange[2])
    --[[1: \an7, left-top]]
    output[2]=itplc(newrange[3],newrange[2])
    --[[2: \an9, right-top]]
    output[3]=itplc(newrange[1],newrange[4])
    --[[3: \an1, left-bottom]]
    output[4]=itplc(newrange[3],newrange[4])
    --[[1: \an3, right-bottom]]
    return output
end
