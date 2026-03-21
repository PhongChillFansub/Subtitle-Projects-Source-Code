script_name = "[Misc] autoKanjiTimer"
script_description = "[Phòng Chill Fansub] Các hàm xử lí tự động cho Kanji Timer"
script_author = "Phòng Chill Fansub"
script_version = "1.0"
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
