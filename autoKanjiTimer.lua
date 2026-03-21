script_name = "[Misc] autoKanjiTimer"
script_description = "[Phòng Chill Fansub] Các hàm xử lí tự động cho Kanji Timer"
script_author = "Phòng Chill Fansub"
script_version = "2.0"
--[[v2.0 alpha 0.2 21/3/2026]]



--[[Phần v1 part 3]]
--[[1.0 part 3. Chuyển đổi line {\k1}<kanji> thành {\k<rom_time>}<kanji>]]
--[[Tuy nhiên, hiệu suất phụ thuộc vào độ chính xác của part 1 và 2 (gemini)]]
LR2TLv3data = {} 
function LR2TLv3(ctrlSignal) 
    --[[Hàm copy dữ liệu từ LR sang TL (fx giải thích nghĩa) hoặc JP (auto Kanji Timer).]]
    if ctrlSignal == 0 and (LR2TLv3data[#LR2TLv3data] == nil or LR2TLv3data[#LR2TLv3data].start_time ~= line.start_time) then 
        LR2TLv3data[#LR2TLv3data+1] = orgline 
    end 
    return '' 
end

function autoKanjiTimerV1() 
    local output = '' 
    --[[Hàm chạy tại phần template của style cần timing kanji--]] 
    --[[Mục đích: tạo ra dòng có text của kanji/furigana, kara của romaji--]] 
    --[[Cơ chế: dựa trên khớp số lượng syl--]] 
    --[[--]] 
    --[[Kiểm tra câu LR tương ứng của JP--]] 
    gotLRIndex = 0 
    for i0 = 1,#LR2TLv3data, 1 do 
        --[[Kiểm tra trong các câu--]] 
        if line.start_time*1 == LR2TLv3data[i0].start_time*1 then 
            --[[Lấy thời điểm khởi đầu làm chuẩn để so sánh--]] 
            gotLRIndex = i0 
            break 
            --[[Đặt gotLRIndex là thứ tự câu romaji tương ứng--]] 
        end 
    end 
    if gotLRIndex == 0 then 
        --[[Nếu không tìm được câu tương ứng--]] 
        _G.aegisub.log(3,'[autoKanjiTimer_v1] Câu này không tìm được câu romaji tương ứng:\n%d\nĐã tự động bỏ trống để tránh gián đoạn.\n',line.start_time) 
        return '' 
    end 
    JPdata = {{},{}} 
    --[[Bảng lưu 1: ND kanji-furigana - 2: dữ liệu timing--]] 
    nextdata = {} 
    local offsetJPdata = 0 
    for i0 = 1,#line.kara,1 do 
        --[[Xét JP--]] 
        for i1 = 1,_G.math.max(#line.kara[i0].furi,1) do 
            --[[Xét các furi trong syl (nếu ko có furi thì xét 1 lần)--]] 
            checkIndex = #JPdata[1]+1-offsetJPdata 
            if checkIndex <= #LR2TLv3data[gotLRIndex].kara then 
                checkData = LR2TLv3data[gotLRIndex].kara[checkIndex] 
                if #line.kara[i0].furi == 0 then 
                    nextdata = {line.kara[i0].text_stripped,checkData.duration/10} 
                    --[[syl kanji ko có furigana--]]
                else 
                    nextdata = {(i1>1 and '#' or line.kara[i0].text_stripped)..'|'..(i1>1 and '' or '<')..line.kara[i0].furi[i1].text_stripped,checkData.duration/10} 
                    --[[syl kanji có furigana--]] 
                end 
                if (checkData.text_stripped == '') then 
                    --[[Nếu syl LR tương ứng là syl trống, thì thêm syl trống đó vào trước khi thêm nextdata--]] 
                    JPdata[2][#JPdata[1]+1] = checkData.duration/10 
                    JPdata[1][#JPdata[1]+1] = ''
                end 
            end 
            JPdata[2][#JPdata[1]+1]= nextdata[2] 
            JPdata[1][#JPdata[1]+1]= nextdata[1] 
        end 
        if line.kara[i0].duration == 0 then 
            offsetJPdata = (offsetJPdata or 0)+1 
            JPdata[2][#JPdata[2]] = 0 
        end 
        --[[Nếu gặp syl JP trống thì offsetJPdata+1 và sửa timing lại theo timing JP (về 0ms)--]] 
    end 
    --[[Kiểm tra khớp số lượng syl giữa JP và LR--]] 
    if #JPdata[1]-offsetJPdata ~= #LR2TLv3data[gotLRIndex].kara then 
        --[[Khi #JPdata[1]=syl JP+JP trống+LR trống, offsetJP=JP trống, không khớp với #LRdata.kara: syl LR + LR trống, thì tức là không khớp--]]
        --[[đầu ra báo không trùng khớp--]] 
        return 'không trùng khớp, JP: '..#JPdata[1]..' '..offsetJPdata..' '..'LR: '..#LR2TLv3data[gotLRIndex].kara 
    end 
    --[[--]] 
    --[[Nếu khớp số lượng syl--]] 
    --[[2. Tiến hành hợp nhất dữ liệu--]] 
    --[[2a. Lập mẫu cơ sở, sử dụng string.format()--]] 
    sylUnit = '{\\k%d}%s' 
    for i0= 1,#JPdata[1],1 do 
        output = output..string.format(sylUnit,JPdata[2][i0],JPdata[1][i0]) 
    end 
    return output 
end

--[[Phần viết mới]]
function get_char_type(char)
    --[[vibe coding (chatgpt, gemini), đã sửa]]
    --[[Lấy mã Unicode (decimal) của ký tự]] 
    local cp = _G.unicode.codepoint(char)
    if (cp >= 0x4E00 and cp <= 0x9FAF) or cp == 0x3005 then
        return "kanji"
    elseif (cp == 0x3083 or cp == 0x3085 or cp == 0x3087) then
        --[[youon hiragana (ゃ ゅ ょ), các kí tự gộp với chữ trước tạo thành âm.]] 
        return "hiragana_youon"
    elseif cp >= 0x30E3 and cp <= 0x30E7 and (cp % 2 == 1) then
        return "katakana_youon"
    elseif cp >= 0x3040 and cp <= 0x309F then
        return "hiragana"
    elseif cp >= 0x30A0 and cp <= 0x30FF then
        return "katakana"
    elseif cp >= 0x0020 and cp <= 0x007E then
        return "romaji_basic"
        --[[Bao gồm chữ cái Latin, số và ký hiệu cơ bản]]
    else
        return "other"
    end
end

function kanji_prepare_v2p2(input_line)
    --[[Hàm chuẩn bị đầu vào cho Kanji Timer]]
    --[[Đầu vào input_line (câu Kanji (có sẵn hiragana), stripped)]]
    --[[Cấu trúc đơn vị đầu vào: <1 chữ kanji>(<các chữ furigana của nó>). vd: '君(きみ)']]
    --[[Do yêu cầu đầu vào kanji có furigana, nên phải phụ thuộc part 1 lấy furigana (dùng AI)]]
    --[[Hoặc 1 chữ katakana/hiragana. vd: 優(やさ)しい gồm 3 đơn vị 優(やさ), し, い]]
    --[[Đầu ra: vd: 優(やさ)しい -> {\k1}優|や{\k1}#|さ{\k1}し{\k1}い]]
    local output, new_line, concat = {}, string.char(10), _G.table.concat
    local using_kanji, last_char, furigana_mode = '','', false
    for char,index in _G.unicode.chars(input_line) do
        local ctype = get_char_type(char)
        if ctype=='kanji' then
            --[[char là kanji]]
            if using_kanji ~= '' then
                if using_kanji==last_char then
                    --[[Nhiều kanji liên tiếp]]
                    using_kanji=concat({using_kanji,char})
                else
                    --[[chuyển sang kan mới khi đang dùng kan cũ?]]
                    local msg = '[KanPrep2] L:%d, chuyển sang kan mới %s (i:%d) khi còn kan cũ %s?%s'
                    _G.aegisub.log(3,msg, line.i,char,index,using_kanji,new_line)
                end
            end
            using_kanji=char
        elseif char=='(' then
            --[[char là char mở khối furigana]]
            furigana_mode = true
            if index==1 or last_char ~= using_kanji then
                --[[trước dấu '(' không có chữ nào, hoặc chữ khác với using_kanji?]]
                local msg = '[KanPrep2] L:%d, đặt dấu \'%s\' (i:%d) bất thường (đầu câu, hoặc không liền sau kanji)?%sCâu: %s%sVị trí: sau %s%s'
                _G.aegisub.log(3,msg, line.i,char,index,new_line,input_line,new_line,last_char,new_line)
            end
        elseif char==')' then
            --[[char là char đóng khối furigana]]
            furigana_mode = false
            using_kanji = ''
        elseif ctype=='hiragana' or ctype=='katakana' then
            --[[char là kana]]
            if furigana_mode then
                --[[Chữ nằm trong 1 khối furigana của using_kanji]]
                --[[Thêm đơn vị đầu ra mới: <using_kanji>|<char> hoặc #|<char> nếu ko phải char đầu của khối (liền sau dấu '(')]]
                output[#output+1]= concat({last_char=='(' and using_kanji or '#','|',char})
            else
                --[[Chữ nằm riêng lẻ, không trong khối furigana]]
                output[#output+1]= char
            end
        elseif ctype=='katakana_youon' or 'hiragana_youon' then
            --[[char là youon, gộp với char trước để tạo thành âm]]
            output[#output] = concat({output[#output],char})
        elseif ctype=='romaji_basic' then
            if get_char_type(last_char)~='romaji_basic' then
                output[#output+1]=char
            else
                output[#output]=concat({output[#output],char})
            end
        elseif ctype=='other' then
            _G.aegisub.log(3,'[KanPrep2] L:%d, kí tự i:%d là gì?%s',line.i,index,new_line)
        end
        last_char=char
    end
    return concat(output)
end