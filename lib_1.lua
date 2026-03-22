script_name = "[Level 1] Lib"
script_description = "[Phòng Chill Fansub] Thư viện hàm áp dụng cho hiệu ứng Aegisub."
script_author = "Phòng Chill Fansub"
script_version = "1.0"
--[[beta 14.10 22/3/2026]]

function cmt()
  return ''
end
--[[cmt(): ẩn đầu ra của bất kì biến/hàm nào bên trong nó.]]

function cnfv4(value,precision)
  value = (precision or -1)<0 and value or string.format('%.'..precision..'f',value)
  return string.format('%g',value)
end
--[[cnfv4(): làm tròn số. Tuy nhiên phải rút gọn kết quả khi giá trị chính xác hơn precision cho trước. vd: cnfv4(10,1) thì không ghi "10.0" mà chỉ ghi "10"]]
--[[Do đó sử dụng string.format('%g') thay vì '%f' và tính phức tạp như bản cũ v3.]]

function UTFv2(char_input,index_set)
  if index_set == nil or index_set == 0 then
    return _G.unicode.len(char_input)
  end
  index_wrap = (index_set+(index_set<0 and 0 or -1))%_G.unicode.len(char_input)+1
  for char,index in _G.unicode.chars(char_input) do
    if index == index_wrap then return char end
  end
  return ''
end
--[[UTFv2(): tìm chữ thứ N (có xử lí wrap), (hoặc số thứ tự nếu index_set = nil hoặc 0) của xâu UTF-8.]]
--[[wrap ở đây tức là cho phép cả các giá trị nằm ngoài đoạn [1,len], ví dụ như len+2 -> 2 (chữ thứ 2 từ trái sang); -4 -> len-4 (chữ thứ 4 từ phải sang)]]

function decode(index,limit_table,plane)
  local floor = math.floor
	--[[Hàm tính N stt N chiều từ stt 1 chiều (ngẫu nhiên) đầu vào, quy định trong bảng limit_table.]]
	if (limit_table == nil or #limit_table <=1) then
		return index
		--[[Fallback: limit_table không tồn tại hoặc ít hơn 2 chiều. Khi đó nhanh chóng thoát để tiết kiệm thời gian]]
	end
  local index_output = {}
	local temporary_remain = index-1
	--[[Trừ 1 để thuận tiện cho tính toán index bằng %]]
	for plane_index = 1,#limit_table do
		index_output[plane_index] = temporary_remain % limit_table[plane_index] +1
    --[[Tính stt mới (index_output) theo chiều plane_index sử dụng phép mod. +1 do stt>0]]
		temporary_remain = floor(temporary_remain/limit_table[plane_index])
    --[[Sau khi tính, phần còn lại chia lấy nguyên, không sử dụng div() đã xóa để tối ưu]]
	end
	index_output[#index_output+1]=temporary_remain
	--[[Thêm chiều (plane/dimension) bổ sung, trong trường hợp stt lớn hơn giới hạn định trước]]
	if plane == nil then
		return index_output
	end
	return index_output[plane]
end
--[[decode(): thuật toán tương tự decode2() ở bản cũ. Đầu ra bảng index nếu plane == nil.]]

function lerp2d(x,y,newrange)
  --[[Hàm biến đổi tọa độ tuyến tính (linear interpolate) từ 0..1 (2 chiều) thành trong vùng mới]]
  --[[Đầu vào: x, y (0..1), vùng {x1,y1,x2,y2} mới (từ điểm A(x1,y1) đến B(x2,y2) hoặc trong hcn cạnh // trục tọa độ, có đường chéo AB)]]
  --[[Đầu ra: x, y (tọa độ trong vùng mới)]]
  local itpl = _G.interpolate
  return itpl(x,newrange[1],newrange[3]),itpl(y,newrange[2],newrange[4])
end

function unlerp2d(x,y,oldrange)
  --[[Hàm biến đổi tọa độ tuyến tính (linear interpolate) từ trong vùng cũ (2 chiều) thành 0..1 (2 chiều)]]
  --[[Đầu vào: tọa độ x, y cũ, {x1,y1,x2,y2} cũ (từ điểm A(x1,y1) đến B(x2,y2) hoặc trong hcn cạnh // trục tọa độ, có đường chéo AB)]]
  --[[Đầu ra: x,y mới (0..1)]]
  local invp = function(v,v0,v1) return (v1==v0 and (v<v0 and 0 or 1) or (v-v0)/(v1-v0)) end
  return invp(x,newrange[1],newrange[3]),invp(y,newrange[2],newrange[4])
end

function interpolate_color_2d(x,y,crange)
  --[[Hàm tìm màu (linear interpolate) của màu (&HBBGGRR&), dùng _G.interpolate_color]]
  --[[Đầu vào: x, y, {\an: 7,9,1,3}]]
  local itpl = _G.interpolate_color
  return itpl(y, itpl(x,crange[1],crange[2]), itpl(x,crange[3],crange[4]) )
end

function tableMerge(table1,table2) 
  for i = 1,#table2 do 
    table1[#table1+1]=table2[i]
  end 
  return table1 
end
--[[tableMerge(): thuật toán tương tự tableConcat() ở bản cũ.]]
--[[Tuy nhiên, đổi tên để tránh nhầm với _G.table.concat = table2string()]]

function tableMerges(allTable)
  local table_output = {}
  for i=1,#allTable do
    table_output = tableMerge(table_output,allTable[i])
  end
  return table_output
end
--[[tableMerges(): thuật toán tương tự tableConcs() ở bản cũ. Cũng đổi tên để khớp với tableMerge()]]

function table2draw(table_input,separateStr)
  return _G.table.concat(table_output,separateStr)
end
--[[table2draw(): t2d() ở bản cũ, nhưng là table->string thay vì table->table ở bản cũ. Chủ yếu để phục vụ funcdraw fx.]]

function draw2table(string_input,separateStr)
  local table_output = {}
  for word in inputString:gmatch( '([^'..(separateStr or '%s+')..']+)' ) do 
    table_output[#table_output+1]=word
  end
  return table_output
end
--[[draw2table(): d2t() ở bản cũ, vẫn là string->table.]]

function polar(pos_x,pos_y,radius,angle_deg,precision,output_mode)
  local output, cos, sin, angle_rad = {0,0}, math.cos, math.sin, math.rad(angle_deg)
  output[1]= cnfv4(pos_x+radius*cos(angle_rad)),precision)
  output[2]= cnfv4(pos_y+radius*sin(angle_rad)),precision)
  return (output_mode==nil and table2draw(output,',') or (output[output_mode] or output))
end
--[[polar(): polarPos() ở bản cũ.]]

function colorRGB2HSL(colorRGB,output_mode)
  --[[Đầu vào là mã màu RGB dạng &HBBGGRR& (cần hàm extract_color() xử lí trước)]]
  --[[Đầu ra là {H,S,L}, tất cả đều có tập giá trị [0;255].]] 
  local rgb = _G.table.pack(_G.extract_color(colorRGB)) 
  rgb[#rgb]=nil
  --[[--Loại bỏ giá trị A (alpha). Khi này rgb[] còn R,G,B.]]
  rgb[5] = math.min(_G.table.unpack(rgb))
  rgb[6] = math.max(_G.table.unpack(rgb))
  local hsl = {}
  hsl[3]=((rgb[5]+rgb[6])/2)
  --[[L = average( min(RGB),max(RGB) ) [0;255].]]
  hsl[2]= (rgb[6]-rgb[5])/( hsl[3]>0.5*255 and 2-(rgb[6]+rgb[5]) or rgb[6]+rgb[5] )
  --[[S = (max-min)/(2-max-min hoặc max+min) [0;255].]]
  if rgb[5]==rgb[6] then
    --[[Nếu max=min, tức là các màu R,G,B cùng giá trị (grayscale) thì H=0 [0;1].]]
    hsl[1]=0
  elseif rgb[6]==rgb[1] then
    --[[Nếu màu 1,r,đỏ là màu mạnh nhất]]
    hsl[1]=(rgb[2]-rgb[3])/(rgb[6]-rgb[5]) 
  elseif rgb[6]==rgb[2] then 
    --[[Nếu màu 2,g,lục là màu mạnh nhất]] 
    hsl[1]=(rgb[3]-rgb[1])/(rgb[6]-rgb[5])+2 
  else 
    --[[Nếu màu 3,b,xanh là màu mạnh nhất]] 
    hsl[1]=(rgb[1]-rgb[2])/(rgb[6]-rgb[5])+4
  end 
  hsl[1]=hsl[1]*60 
  hsl[1]=(hsl[1]<0 and hsl[1]+360 or hsl[1]) 
  --[[H = [0;360], cần chuyển về [0;255].]]
  hsl[1]=hsl[1]/360*255 

  for i=1,#hsl do
    hsl[i]=cnfv4(hsl[i],0)
  end
  --[[Làm tròn về 1 đơn vị--]]
  return (output_mode~=nil and (hsl[output_mode] or hsl) or hsl) 
end
--[[colorRGB2HSL(): như hàm cùng tên ở bản cũ.]]

function HSL2HSV(hsl,output_mode)
  --[[Đầu vào là {H,S,L} [0;255], tức là từ hàm colorRGB2HSL().]]
  --[[Đầu ra là {H [0;359], S[0;1], V[0;1]} để khớp với _G.HSV_to_RGB().]]
  for i=1,#hsl do 
    hsl[i]=hsl[i]/255 
  end
  --[[Đưa hsl từ [0;255] về [0;1] (normalize)]] 
  local hsv = _G.table.copy(hsl) 
  hsv[3] = hsl[3]+hsl[2]*_G.math.min(hsl[3],1-hsl[3])
  hsv[2] = (hsv[3]==0) and 0 or 2*(1-hsv[3]/hsv[3])
  hsv[1]=hsv[1]*359
  return (output_mode~=nil and (hsv[output_mode] or hsv) or hsv) 
end
--[[HSL2HSV(): như hàm cùng tên ở bản cũ.]]

function independentCounter(input,limit) 
  local input = (input or 0) + 1 
  if (limit~=nil and input > limit) then input = 1 end 
  return input 
end 
--[[Hàm biến đếm độc lập]]

function multiloop(limit_table)
  maxjm = 1
  for plane_index=1, #limit_table do
    maxjm = maxjm*limit_table[plane_index]
    --[[Tính toán tổng số lần lặp/tổng số entity mới. Tăng theo cấp số nhân.]]
  end
  jm = {}
  tblcpy = _G.table.copy
  --[[Thay đổi thuật toán để không sử dụng decode()]]
  --[[Sử dụng decode = sử dụng phép chia, ở đây chỉ sử dụng phép cộng]]
  for loop_index = 1, maxjm do
    jm[loop_index]=tblcpy(jm[(loop_index or 1)-1] or limit_table)
    --[[Đặt jm[loop_index] bằng bảng index liền trước hoặc limit_table]]
    for plane_index=1,#limit_table do
      jm[loop_index][plane_index]=independentCounter(jm[loop_index][plane_index], limit_table[plane_index])
      if jm[loop_index][plane_index]~=1 then break end
      --[[Nếu jm[index] đang xét khác 1 (tức không phải cộng dồn sang cấp tiếp theo) thì break.]]
      --[[Do các chỉ tăng 1 index con của các plane/chiều 1 lần mỗi index tổng (trừ cộng dồn)]]
    end
  end
  --[[Kết thúc vòng lặp maxjm]]
  return maxloop(maxjm)
end
--[[multiloop(): hàm lặp lại maxloop() theo nhiều chiều, không sử dụng decode().]]

function t4re(offset_start,offset_end,base_start,base_end,first_tag)
  --[[Hàm xử lí thời gian của tag \\t trong các entity do maxloop() và multiloop()]]
  --[[Đầu vào: offset_start-end của loop()]]
  --[[Đầu vào: base_start-end là thời gian gốc, không phụ thuộc loop()]]
  --[[Bài toán: do base_start-end nằm ngoài vùng của offset_start-end]]
  --[[Đầu ra: output_start-end (đã xử lí), interpolated_start-end]]
  --[[Thiết kế đầu ra: \t(<output>,\<tag>)]]
  --[[output_time không nằm ngoài offset_time, =0 tính từ offset_start.]]
  --[[interpolated_time là tỉ lệ của offset so với base]]
  local clamp, concat = _G.clamp, _G.table.concat
  local invp = function(v,v0,v1)
    return v1-v0==0 and (v<v0 and 0 or 1) or clamp((v-v0)/(v1-v0),0,1)
  end 
  --[[interpolate nghịch đảo, có clamp]]
  t4ro={
    s=clamp(base_start-offset_start,0,offset_end-offset_start),
    e=clamp(base_end-offset_start,0,offset_end-offset_start),
    si=invp(offset_start,base_start,base_end),
    ei=invp(offset_end,base_start,base_end)
  }
  --[[o: output. s: start, e: end, si: itpl_s, ei: itpl_e]]
  return concat({t4ro.s,t4ro.e,first_tag},',') end

function jf(index,plane) 
  return jm[index][plane] 
end 
--[[jmf(): cú pháp dạng hàm thay vì dạng cấu tử bảng, như bản cũ. Dùng trong multiloop() cùng với decode().]]

function invert_colorRGB(color) 
  local R,G,B = _G.extract_color(color) 
  R = 255-R; G = 255-G; B = 255-B 
  return _G.ass_color(R,G,B) 
end

function invert_colorHSV(color)
  local H,S,V = HSL2HSV(colorRGB2HSL(color))
  return _G.HSV_to_RGB((H+180)%360,S,V)
end
