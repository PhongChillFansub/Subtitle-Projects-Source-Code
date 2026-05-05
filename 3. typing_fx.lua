script_name = "[Level 2] typing_fx"
script_description = "[Phòng Chill Fansub] Effect tách cụm từ và đánh chữ (tiếng Việt có dấu) theo quy tắc Telex"
script_author = "Phòng Chill Fansub"
script_version = "alpha 5.0.0.39"
--[[fm3 a5.0.0.39 05may26]]
--[[sửa lỗi UTFstring2table]]
--[[Cập nhật v5.0: lấy dữ liệu trực tiếp từ _G.aegisub.text_extents, thay vì phải sử dụng 1 dòng template char]]
--[[Mục tiêu: lấy dữ liệu chỉ bằng 1 hàm trên dòng template line (template phổ biến cho trans không kara)]]
--[[to-do: xóa code cũ v4 và viết typingfxV5()]]
--[[Yêu cầu các hàm của lib 1: cnfv4]]

function UTFstring2table(text_input,separateStr,mode,index_start,index_end)
    --[[Hàm string->table, tương tự d2t()/draw2table() của lib 1, nhưng dành cho UTF-8 và typing fx, cho phép tách \ N]]
    --[[mode: =nil thì không chứa kí tự ngắt, mode ~= nil thì chứa kí tự ngắt]]
    local table_output,word_sep,concat = {},{}, _G.table.concat
    index_start, index_end = index_start or 1, index_end or _G.unicode.len(text_input)
    --[[Fallback cho start và end]]
    local last_char, last_second_char='', ''
    for char,index in _G.unicode.chars(text_input) do
        if (index>=index_start and index<=index_end) then
            --[[Nếu không có index_start và index_end, hoặc index nằm trong vùng start..end thì hợp lệ, chạy]]
            if last_second_char:match('\\') or char:match('\\') or char==(separateStr or ' ') then
                --[[Nếu char đang xét là kí tự ngắt (mặc định ' ') thì lưu từ hiện tại, tách sang từ mới]]
                --[[Hoặc là '\\' và kí tự thứ 2 sau nó]]
                if (not (char:match('\\') or last_second_char:match('\\'))) and mode then
                    --[[Nếu mode~=nil (nhận kí tự ngắt ở cuối) và không phải '\\' hay kí tự thứ 2 sau nó, thì thêm cả kí tự ngắt]] 
                    word_sep[#word_sep+1]=char
                end
                table_output[#table_output+1]=concat(word_sep)
                --[[Thêm từ mới]]
                word_sep=( (last_second_char:match('\\') and char~=(separateStr or ' ')) or char:match('\\') ) and {char} or {}
                --[[Nếu là '\\' hoặc là kí tự thứ 2 sau nó thì thêm char đó vào từ hiện tại (dù ở trên coi như kí tự ngắt)]]
                --[[Nếu ko thì ko thêm.]]
            else
                --[[Nếu char đang xét không là kí tự ngắt, không là '\\' hay kí tự thứ 2 sau nó]]
                word_sep[#word_sep+1]=char
            end
            --[[index không hợp lệ thì thôi]]
            last_second_char = last_char
            last_char = char
        end
    end
    --[[Thêm từ cuối cùng còn sót lại, trừ khi #word_sep=0, tức kí tự cuối là kí tự ngắt và mode=nil]]
    if #word_sep>0 then table_output[#table_output+1]=concat(word_sep) end
    return table_output
end

function getDataV5(mode)
    if not mode then return '' end
    --[[Hàm lấy dữ liệu chữ bằng hàm aegisub.text_extents()]]
    --[[Đầu vào: line.styleref, line.text_stripped (tự động)]]
    wordV5 = {}
    --[[Đầu ra trực tiếp: #wordV5]]
    --[[Đầu ra gián tiếp: wordV5[<số từ>]={text,text_stripped,width,height,descent,extlead,... ]]
    --[[..., left,center,right,top,middle,bottom,offsetan(X/Y). }]]
    --[[]]
    --[[Cấu trúc hàm: width, height, descent, extlead = aegisub.text_extents(style, text)]]
    --[[Đầu ra width, height: chiều dài, rộng của chữ (text). Ở đây height = line.height=line.styleref.fontsize]]
    --[[Đầu ra descent: chiều cao đường kéo nét xuống của font, phụ thuộc vào kiểu font và tỉ lệ thuận với cỡ font]]
    --[[descent = font_descent_constant*fontsize]]
    --[[Đầu ra: extlead: khoảng cách (chiều cao) giữa các dòng đặc trưng, chỉ phụ thuộc vào kiểu font]]
    --[[]]
    --[[Đầu vào style: ở đây là bảng line.styleref, hoặc tương tự]]
    --[[Đầu vào text: string chữ cụ thể, không nhận kí tự đặc biệt như tag, xuống dòng,...]]
    text_inputdata = UTFstring2table(line.text_stripped,nil,0)
    --[[Strip đầu vào line.text ngay từ đầu, đồng thời tách từ ()]]
    --[[Chú ý: nhận cả kí tự tách, và có tách các kí tự]]
    local extents = function(text0) return _G.aegisub.text_extents(line.styleref, text0) end
    --[[Đặt word_num, extents để tối ưu hóa]]
    local word_left, word_bottom, last_offsetanX = 0, line.height, 0
    local last_newline_index, new_line, new_line_width = 0, '\\'..'N', extents('\\'..'N')
    --[[Đặt word_left, top, offset để tính toán, new_line để nhận diện, tránh bị xóa khi copy vào file sub]]
    for word_index = 1,#text_inputdata do
        if text_inputdata[word_index]~=new_line then
            --[[Nếu không phải kí tự xuống dòng, xử lí như bình thường]]
            local word_stripped = text_inputdata[word_index]:gsub(' ','')
            local ex1,ex2,ex3,ex4 = extents(word_stripped)
            --[[ex1: width; ex2: height; ex3: descent, ex4: ext_lead]]
            wordV5[#wordV5+1]={
                text=text_inputdata[word_index], 
                text_stripped=word_stripped, 
                width=ex1, 
                height=ex2, 
                descent=ex3, 
                extlead=ex4, 
                left=word_left, 
                center=word_left+ex1/2, 
                right=word_left+ex1, 
                top=word_bottom-ex2,
                middle=word_bottom-ex2/2,  
                bottom=word_bottom,
                offsetanX=line.width-last_offsetanX,
                offsetanY=word_bottom,
                absleft=0,
                abscenter=0,
                absright=0,
                abstop=0,
                absmiddle=0,
                absbottom=0
            }
            --[[offsetanX-Y đóng vai trò kích thước khung dòng chữ, sử dụng khi có tag \an]]
            local ex0 = extents(text_inputdata[word_index])
            word_left = word_left+ex0
            --[[Chú ý: width từ extents có tính đến dấu cách (vd: 'hello ' dài hơn 'hello')]]
        else
            --[[Nếu là kí tự xuống dòng]]
            word_bottom = word_bottom+line.height
            --[[bottom dòng dưới tăng thêm 1 dòng]]
            --[[]]
            --[[Thay đổi khung dòng chữ các từ mới]]
            local msg='[typingfxV5] new_line %d: %f= %f + %f + %f.%s'
            _G.aegisub.log(3,msg,word_index ,last_offsetanX + word_left + new_line_width, last_offsetanX, word_left, new_line_width,string.char(10))
            last_offsetanX = last_offsetanX + word_left + new_line_width
            --[[last_offsetanX là phần chiều dài từ kí tự xuống dòng trở về trước]]
            for change_index = 1,#wordV5 do
                if change_index > last_newline_index then 
                    wordV5[change_index].offsetanX=word_left
                end
                --[[Chiều dài khung mới: chiều dài liền trước kí tự xuống dòng]]
                wordV5[change_index].offsetanY=word_bottom
                --[[Chiều cao khung mới: bổ sung thêm dòng mới từ kí tự xuống dòng về sau]]
            end
            word_left = 0
            --[[Reset word_left]]
            last_newline_index=#wordV5
            --[[Reset last_newline_index]]
        end
    end

    --[[Phần tính abs-pos]]
    local an0=line.styleref.align
    --[[tag \an, và quy định trong style]]
    local applyan = {(an0-1)%3,-1*(math.floor((an0-1)/3)-2)}
    --[[từ trái sang thì [1] là 0,1,2. từ trên xuống thì [2] là 0,1,2]]
    local applykey={{'left','center','right'},{'top','middle','bottom'}}
    local applyoff={'offsetanX','offsetanY'}
    local pos0={line.center, line.middle}
    local concat=_G.table.concat
    for word_index=1,#wordV5 do
        for dim=1,2 do
            for key_index=1,3 do
                local key=applykey[dim][key_index]
                local newkey=concat({'abs',key})
                wordV5[word_index][newkey]=cnfv4(pos0[dim]+wordV5[word_index][key]-applyan[dim]/2*wordV5[word_index][applyoff[dim]],0)
            end
        end
    end
    return mode=='loop' and maxloop(#wordV5) or #wordV5
end

fw=function(index)
    --[[fastword: tối giản truy nhập wordV5]]
    return wordV5[index or j] 
end

--[[lib 1 cũ (update typing fx v4, prev: pj 44M7): thư viện hàm. {;;;;;} cmt() {;;;;;} div(<>,<>) {;;;;;} cnfv3(value, precision) {;;;;;} UTFp(string, index) {;;;;;} decode1(index,max1,mode) {;;;;;} table2string(tablein) {;;;;;} tableConcat(table1,table2) {;;;;;} t2d(tablein,separateStr) {;;;;;} aconv(angle,mode) {;;;;;} tableConcs({ {table1}, ... , {tableN} }) {;;;;;} maxfromTable(table) {;;;;;} res[1;2] {;;;;;} fpsget(1;2) {;;;;;} decode2(index,maxTable,plane) {;;;;;} multiLoop(tableInput) {;;;;;} jm(a,b) {;;;;;} polarPos(x0,y0,r0,a0,precision) {;;;;;} reportError(text) {;;;;;} d2t(tablein,separateStr)]]
--[[cmt(){;;;;;} div(2) chia lấy nguyên, trước/sau{;;;;;} cnfv3(value, precision): string.format("%.<precision>f",value) (trống = 0){;;;;;} UTFp(string, index) trả string UTF-8 thứ index*. index 0 trả độ dài string. index*: nếu index > độ dài hoặc index < 0 thì lặp lại theo chu kì. VD: chữ "Người" (độ dài 5), index 5,10,15,v.v. và -1,-6,-11,v.v. đều trả về index 5 ("i"), index -2 trả về index 4 ("ờ"){;;;;;} decode1(index,max1,mode): chia dãy 1 chiều thành mảng 2 chiều (a,b) với 1 <= a <= max1; 1 <= b; đầu ra theo mode: 1: a, 2: b.{;;;;;}table2string(tablein): đầu ra từ bảng thành xâu kí tự, thứ tự theo số.{;;;;;} tableConcat(table1,table2): hợp nhất bảng 2 vào sau bảng 1.{;;;;;} t2d(tablein,separateStr): tách phần tử bằng dấu cách (mặc định, hoặc separateStr) (mặc định: dấu cách, tức table sang dạng lệnh vẽ){;;;;;} aconv(angle,mode): đổi góc theo chế độ: 0: deg -> deg / rad -> rad, 1: deg -> rad, 2: n -> n*pi, 3: rad -> deg {;;;;;} tableConcs({ {table1}, ... , {tableN} }): Hợp nhất các bảng table1, ... , tableN. (tableConcat nhưng rộng hơn) {;;;;;} maxfromTable(table): lấy số lớn nhất trong bảng số table. {;;;;;} res[i]: độ phân giải chiều: 1: x, 2: y. {;;;;;} fpsget(mode): 1: fps, 2: spf {;;;;;} decode2(index,maxTable,plane): như decode1 nhưng nhiều chiều hơn, tổng quát hơn. {;;;;;} multiLoop({maxj_1,maxj_2,...,maxj_n}): đầu ra lặp lại theo chiều (sử dụng hàm decode2()). Đầu ra: jm[j][plane] hoặc recall.j[j][plane]{;;;;;} jm(a,b): đầu ra jm[j][plane], dạng jm(j,plane) {;;;;;} polarPos(x0,y0,r0,a0,precision): tọa độ cực, {góc deg} (đầu ra dạng "pos1,pos2", dùng hàm cnfv3() nên có yêu cầu precision) {;;;;;} reportError(text): báo lỗi {;;;;;} d2t(tablein,separateStr): trái ngược với table2string(t2d()) từ bảng thành string có phân cách; d2t() nhận string có phân cách, biến thành table. {;;;;;}]]
remember('applyStart',string.format('%.3f',_G.os.clock())); 
function cmt() return '' end; 

function div(i1,i2) 
    return (i1-(i1%i2))/i2 
end;;;;; 

function cnfv3(i0,i1) 
    cnfCheck = 0 
    i1 = _G.math.max((_G.tonumber(i1) or 0),0) 
    local output = string.format('%.'..i1..'f',i0) 
    while (_G.tonumber(output) == i0 and i1 >0) do 
        cnfCheck = 1 i1 = i1-1 
        output = string.format('%.'..(i1 or 0)..'f',i0) 
    end 
    return string.format('%.'..(i1+(cnfCheck or 0))..'f',i0) 
end;;;;; 

function UTFp(i1,i2) 
    local char_table = {} 
    for char in _G.unicode.chars(i1) do 
        _G.table.insert(char_table,char) 
    end 
    if i2 == 0 then 
        return #char_table 
    end 
    return char_table[(i2+(i2 > 0 and -1 or 0))%#char_table+1] 
end;;;;; 

function decode1(index,max1,mode) 
    deOutput = {(index-1)%max1+1,div(index-1,max1)+1} 
    return deOutput[mode] 
end;;;;; 
function table2string(tablein) 
    local out = '' 
    for i = 1,#tablein,1 do 
        out = out..tablein[i] 
    end 
    return out
end;;;;; 
function tableConcat(table1,table2) 
    for i0 = 1,#table2,1 do 
        _G.table.insert(table1,table2[i0]) 
    end 
    return table1 
end;;;;; 
function t2d(tablein,separateStr) 
    tableout = {} 
    for i = 1,#tablein,1 do 
        _G.table.insert(tableout,tablein[i]) 
        _G.table.insert(tableout,(separateStr or ' ')) 
    end; 
    return tableout 
end;;;;; 
function aconv(angle, mode) 
    local settings = {math.pi/180,math.pi,180/math.pi} 
    return angle*(settings[mode] or 1) 
end;;;;; 
function tableConcs(allTable) 
    tableout = {} 
    for i = 1,#allTable,1 do 
        tableout = tableConcat(tableout,allTable[i]) 
    end 
    return tableout 
end;;;;; 
function maxfromTable(table) 
    out = 0 
    for i = 1,#table,1 do 
        out = math.max(out,table[i]) 
    end 
    return out 
end;;;;; 
res = {} res[1], res[2] = _G.aegisub.video_size() 
function fpsget(mode) 
    local output = {string.format('%.2f',1000*999999/_G.aegisub.ms_from_frame(999999)),string.format('%.2f',999999/_G.aegisub.frame_from_ms(999999))}; 
    return output[mode] 
end;;;;; 
function decode2(index,maxTable,plane) 
    --[[Biến stt 1 chiều thành N chiều--]] 
    local newIndex = {} 
    local tempRemain = index-1 
    --[[Lập bảng lưu các stt và dư tạm thời--]] 
    for i0 = 1,#maxTable,1 do 
        ewIndex[i0] = tempRemain%maxTable[i0]+1 
        tempRemain = div(tempRemain,maxTable[i0]) 
    end 
    if plane == 0 then 
        return newIndex 
    end 
    return newIndex[plane] 
end;;;;; 
function multiLoop(tableInput) 
    maxjm = tableInput 
    maxjm[0] = 1 
    for i0 = 1,#tableInput,1 do 
        maxjm[0] = maxjm[0] * tableInput[i0] 
    end 
    jm = {} 
    for i1 = 1,maxjm[0],1 do 
        jm[i1] = decode2(i1,tableInput,0) 
    end 
    remember('j',jm) 
    return maxjm[0]
end;;;;; 
function jmf(a,b) 
    return jm[a][b] 
end;;;;; 
function polarPos(x0,y0,r0,a0,precision) 
    return cnfv3(x0+r0*math.cos(math.rad(a0)),precision)..','..cnfv3(y0+r0*math.sin(math.rad(a0)),precision) 
end;;;;; 
function reportError(text) 
    return _G.aegisub.log(3,text) 
end;;;;; 
function d2t(inputString,separateStr) 
    local outputTable = {} 
    for word in inputString:gmatch( '([^'..(separateStr or '%s+')..']+)' ) do 
        _G.table.insert(outputTable,word) 
    end 
    return outputTable 
end;;;;;

--[[fx typing - v4 (tệp phát triển). HDSD: maxloop( #typingV4[typingV4].kara ). {#typingV4[typingV4].kara tương tự #line.kara nhưng cho các từ của fx typing v4.}, trong đó {typingV4[i]} là các câu sử dụng fx. Bảng typingV4[].char là dữ liệu các chữ cái lấy từ hàm getCharDataV4() {ở template char}. {;;;;;} Danh sách các nội dung trường (bảng) typingV4[]: dataGetList2 = {'start_time','end_time','width','halign','valign'}, cùng với {'char', 'kara'}. (char dành cho chữ cái, tạo từ hàm getCharDataV4(). kara dành cho các từ, tạo từ hàm typingfxV4(). Quy tắc xem hàm checkCharV4().) {;;;;;} Danh sách các nội dung trường (bảng) typingV4[].char[] và typingV4[].data[]: dataGetList = {'text','left','right','width','middle','height','i','inline_fx'} và {'offsetX','offsetY','li','offsetLi'} {;;;;;}]]
liteMode = nil 
function getCharDataV4() 
    --[[--]] 
    --[[Mục tiêu: sử dụng môi trường template char để lấy dữ liệu vị trí chữ--]] 
    --[[Lập dữ liệu hàm typing v4. Cấu trúc tương tự như của line. Trước hết, đưa dữ liệu các chữ (char[]) vào theo từng câu (typingv4[].char[])--]] 
    --[[4 cấp: typingV4[], typing[].char, typing[].char[], typing[].char[].data --]] 
    workdata = {} 
    --[[Lấy dữ liệu mỗi char. Ở đây sẽ cần các dữ liệu thời gian và vị trí.--]] 
    dataGetList = {'text','left','right','width','i','inline_fx'} 
    for i0 = 1,#dataGetList,1 do 
        workdata[dataGetList[i0]] = (syl[dataGetList[i0]] or 0) 
    end 
    if syl.left==0 then 
        workchar = { workdata }
        --[[Nếu là char đầu câu thì tạo bảng workchar (.char) kèm workdata làm .char[1]--]] 
    else 
        _G.table.insert(workchar, workdata ) 
        --[[Nếu ko là char đầu câu thì thêm workdata làm .char[2+]--]] 
    end 
    if syl.right==line.width then 
        workline = {} 
        workline.char=workchar 
        dataGetList2 = {'start_time','end_time','width','halign','valign'} 
        for i0 = 1,#dataGetList2,1 do 
            workline[dataGetList2[i0]] = line[dataGetList2[i0]] 
        end 
        if typingV4 == nil then 
            typingV4 = { workline } 
            --[[Nếu là câu đầu thì tạo bảng typingV4 kèm workchar làm typingV4[1].char--]] 
        else 
            _G.table.insert(typingV4, workline ) 
            --[[Nếu ko là câu đầu thì thêm typingV4[2+].char--]] 
        end 
    end 
    return '' 
end;;;;;

function checkCharV4(inputChar,mode) 
    if liteMode ~= nil and liteMode ~= false then 
        return (inputChar:match('\\') and 4 or 1) 
    end
    --[[--]] --[[Mục tiêu: trả về kết quả số tương ứng với đặc điểm kí tự/chữ--]] 
    --[[output 1: 0: dấu cách, 1: chữ cái (ASCII, Unicode), 2: chữ số, 3: kí tự khác, 4 với "\"--]] 
    --[[output 2: 0, +0 với chữ thường/kí tự đặc biệt, +1 với chữ Unicode, +10 với chữ hoa--]] 
    local outputResult = {3,0} 
    outputResult[1] = (inputChar:match('%s') and 0 or outputResult[1]) 
    outputResult = {(inputChar:match('%w') and 1 or outputResult[1]),0} 
    outputResult = (_G.unicode.charwidth(inputChar)>1 and {1,1} or outputResult) 
    outputResult[1] = (inputChar:match('%d') and 2 or outputResult[1]) 
    outputResult[1] = (inputChar:match('\\') and 4 or outputResult[1]) 
    if inputChar ~= _G.unicode.to_fold_case(inputChar) then 
        outputResult[2] = outputResult[2] +10 
    end 
    return (mode==0 and outputResult or outputResult[mode or 1]) 
end;;;;;

function typingfxV4() 
    --[[--]] 
    --[[Mục tiêu: sử dụng bảng typingV4[].char[].data để lập phần typingV4[].kara[].data (phân lập từ, từ các chars)--]] 
    --[[Vị trí: chạy hàm này ở cuối mỗi câu (sau getCharDataV4() của char cuối mỗi câu)--]] 
    --[[Tiêu chí phân cách: phân cách các cụm gồm chữ và số (vd: "cần123" thành "cần","123". "123[]" chia làm "123", "[", "]".)--]] 
    --[[Xác định câu cần xử lí (stt của typingV4[]): do chạy ở cuối mỗi câu nên câu cần xử lí chính là #typingV4 (câu vừa mới thêm)--]] 
    --[[Tính năng mới v4: nhận dạng \ N (template char sẽ nhận là "\" và "N")--]] --[[Cách thức: checkCharV4[1] của \ là 4, của N là 1.--]] 
    --[[Ảnh hưởng: \ N sẽ reset left, right và tăng middle lên syl.height--]] 
    typingV4[#typingV4].kara = {} 
    karawork = {} 
    dataGetList = {'text','left','right','width','i','inline_fx'} 
    local debugLevel = 4 
    for i0 = 1,#typingV4[#typingV4].char,1 do 
        --[[Xét từng chữ trong câu--]] 
        firstCase = (i0==1 and 1) 
        --[[TH1: chữ đầu, hoặc--]] 
        firstCase = i0>2 and (checkCharV4(typingV4[#typingV4].char[i0-2].text)==4 and 1) or firstCase 
        --[[checkCharV4 chữ ở vị trí trước 2 chữ là "\", hoặc--]] 
        firstCase = i0>1 and (checkCharV4(typingV4[#typingV4].char[i0-1].text)~=4 and checkCharV4(typingV4[#typingV4].char[i0].text)~=checkCharV4(typingV4[#typingV4].char[i0-1].text) and 1) or firstCase 
        --[[checkCharV4 khác chữ trước (chữ trước khác "\"), hoặc--]] 
        firstCase = i0>1 and (typingV4[#typingV4].char[i0].inline_fx ~= typingV4[#typingV4].char[i0-1].inline_fx and 1) or firstCase 
        --[[inline_fx khác chữ trước, hoặc--]] 
        firstCase = i0>1 and (typingV4[#typingV4].char[i0].i ~= typingV4[#typingV4].char[i0-1].i and 1) or firstCase 
        --[[i khác chữ trước.--]] 
        if firstCase ~= nil and firstCase ~= false then 
            --[[Nếu là chữ đầu hoặc (checkCharV4 hoặc inline_fx hoặc i) khác của chữ trước (trừ TH char trước là "\"), thì lập dữ liệu mới (karawork[+1])--]] 
            _G.table.insert(karawork,{}) 
            for i1 = 1,#dataGetList,1 do 
                karawork[#karawork][dataGetList[i1]] = typingV4[#typingV4].char[i0][dataGetList[i1]] 
            end 
            karawork[#karawork].li = #karawork 
            karawork[#karawork].start_char=i0 
            karawork[#karawork].end_char=i0 
            if #karawork>1 then 
                if karawork[#karawork-1].text:match('%s+') then 
                    karawork[#karawork].offsetLi = (karawork[#karawork-1].offsetLi or 0)+1 
                else 
                    karawork[#karawork].offsetLi = (karawork[#karawork-1].offsetLi or 0) 
                end 
            else 
                karawork[#karawork].offsetLi = 0 
            end 
            karawork[#karawork].offsetX = (#karawork<=1 and 0 or karawork[#karawork-1].offsetX) 
            karawork[#karawork].offsetY = (#karawork<=1 and 0 or karawork[#karawork-1].offsetY) 
            --[[Phần áp ảnh hưởng \ N (chưa tính an5)--]] 
            if #karawork >1 and karawork[#karawork-1].text == "\\".."N" then 
                karawork[#karawork].offsetX = - karawork[#karawork-1].right 
                --[[Đặt bên phải của \ N làm mốc 0 cho các từ phía sau, tức là lấy left, right mặc định trừ cho mốc này--]] 
                karawork[#karawork].offsetY = karawork[#karawork-1].offsetY + line.height 
                --[[Mỗi lần \ N thì tăng mốc lên 1 lần syl.height--]] 
                karawork[#karawork].offsetLi = #karawork-1 
            end 
            --[[Hết phần áp ảnh hưởng \ N (chưa tính an5)--]] 
        else 
            --[[Nếu ko là chữ đầu hoặc (checkCharV4 hoặc inline_fx hoặc i) giống của chữ trước, hoặc char trước là "\", thì chèn thông tin mới--]] 
            karawork[#karawork].text = karawork[#karawork].text..typingV4[#typingV4].char[i0].text 
            karawork[#karawork].right = typingV4[#typingV4].char[i0].right 
            karawork[#karawork].width = karawork[#karawork].width+typingV4[#typingV4].char[i0].width 
            karawork[#karawork].end_char = i0 
        end 
        if i0 == #typingV4[#typingV4].char then 
            --[[Phần áp ảnh hưởng \ N với typing[#typingV4].halign=center--]] 
            if typingV4[#typingV4].halign == "center" then 
                centerAffect() 
            end 
            --[[Hết phần áp ảnh hưởng \ N với typing[#typingV4].halign=center--]] 
            --[[Phần áp ảnh hưởng \ N với typing[#typingV4].valign=center--]] 
            if typingV4[#typingV4].valign == "middle" then 
                middleAffect() 
            end 
            --[[Hết phần áp ảnh hưởng \ N với typing[#typingV4].valign=center--]] 
            for i2 = 1,#karawork,1 do 
                --[[Lọc sạch trước khi áp dữ liệu: xóa bỏ các ô chỉ chứa khoảng trắng và "\ N"--]] 
                if karawork[i2].text:match('%S+') and not (karawork[i2].text:match('\\'..'N')) then 
                    _G.table.insert(typingV4[#typingV4].kara,karawork[i2]) 
                end 
            end 
        end 
    end 
    trueTypingfxV4(enableTrueTypingFX) 
    return '' 
end;;;;;

function centerAffect(enable) 
    if enable == 0 then 
        return '' 
    end 
    --[[Ảnh hưởng: left và right của TẤT CẢ các từ phía trước "\ N" (đến "\ N" liền trước) tăng lên 1 đoạn (line.width-last.right)/2--]] 
    --[[Với last.right là right của từ cuối liền trước (theo mốc đã tính) \ N--]] 
    --[[Có thể lấy last.right = "\ N".left, hoặc nếu câu ko có \ N thì last.right=line.width (tăng lên +0)--]] 
    --[[Cách thức ảnh hưởng: tìm "\ N" từ cuối lên. Trong lúc đó, áp last.right/"\ N".left ảnh hưởng vào các giá trị--]] 
    local lastCRLF = 0 
    for i2 = #karawork,1,-1 do 
        --[[Tìm "\ N" từ cuối lên--]] 
        if (i2 == #karawork or karawork[i2+1].text:match("\\".."N")) then 
            --[[Nếu từ hiện tại là từ cuối hoặc từ sau nó là \ N--]] 
            --[[Thì left và right của các từ trước đó (tính cả nó, cho đến checkpoint tiếp) bị ảnh hưởng theo right của từ này--]] 
            lastCRLF = i2 
        end 
        --[[Áp dụng cho tất cả các từ (từ chính nó, sang bên trái, đến checkpoint tiếp)--]] 
        local affect = (typingV4[#typingV4].width-(karawork[lastCRLF].right+karawork[i2].offsetX))/2 
        karawork[i2].offsetX = karawork[i2].offsetX + affect 
    end 
    return '' 
end;;;;;
 
function middleAffect(enable) 
    if enable == 0 then 
        return '' 
    end 
    --[[Ảnh hưởng: offsetY của tất cả các từ giảm xuống (số dòng*line.height/2) tức là offset dòng cuối/2--]] 
    local maxHeight = karawork[#karawork].offsetY 
    for i2 = 1,#karawork,1 do 
        --[[Áp cho tất cả các từ--]] 
        karawork[i2].offsetY = karawork[i2].offsetY - maxHeight/2 
    end 
    return '' 
end;;;;;

function trueTypingfxV4(enableTrueTypingFX) return '' end

--Comment: 0,0:00:00.00,0:00:00.00,Default,,0,0,0,code syl,fxgroup.syln = (syl.i == #line.kara)
--Comment: 0,0:00:00.00,0:00:00.00,Default,,0,0,0,template char notext,!retime('preline',0,0)!!getCharDataV4()!!syl.right==line.width and typingfxV4() or ''!
--Comment: 0,0:00:00.00,0:00:00.00,Default,,0,0,0,template syl notext fxgroup syln,{\an5\1a&HFF&\3a&H7F&\pos(!line.center!,!line.middle!)}!line.text!
--Comment: 0,0:00:00.00,0:00:00.00,Default,typing fx v4,0,0,0,code once,function fastTypingFXv4(index) tk = {} tk.center = line.left+(typingV4[#typingV4].kara[j].left+typingV4[#typingV4].kara[j].right)/2+typingV4[#typingV4].kara[j].offsetX;;; tk.middle = line.middle+typingV4[#typingV4].kara[j].offsetY;;; tk.li = typingV4[#typingV4].kara[j].li-(typingV4[#typingV4].kara[j].offsetLi or 0);;; return '' end
--Comment: 0,0:00:00.00,0:00:00.00,Default,,0,0,0,template syl notext fxgroup syln,!maxloop(#typingV4[#typingV4].kara)!!fastTypingFXv4(j)!{\an5\bord4\b1\pos(!tk.center!,!tk.middle!)}{!typingV4[#typingV4].kara[j].li-(typingV4[#typingV4].kara[j].offsetLi)!}!typingV4[#typingV4].kara[j].text!
--Comment: 0,0:00:00.00,0:00:05.00,Default,,0,0,0,karaoke,hello123\Nchào [buổi tối] ae nha\Nhôm nay [thứ 3] khá là ảo ma\Nảo ma canada! 123
