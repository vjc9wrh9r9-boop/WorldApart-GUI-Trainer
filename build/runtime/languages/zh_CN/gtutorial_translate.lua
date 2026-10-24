-- gtutorial-x86_64.exe / gtutorial-i386.exe 绘制层和标题栏汉化。
-- 通过 Hook 目标进程内的 OpenGL 文字纹理生成函数和标题设置函数替换参数，不改游戏原始字符串。

if _G.__zhCNGTutorialTranslateLoaded then return end

local GT_TARGET_X64 = {
  processName = 'gtutorial-x86_64.exe',
  is64 = true,
  preferredImageBase = 0x100000000,
  textureTextRva = 0x3E370,
  setTextBufRva = 0x138E00,
}

local GT_TARGET_X86 = {
  processName = 'gtutorial-i386.exe',
  is64 = false,
  preferredImageBase = 0x400000,
  textureTextRva = 0x36130,
  setTextBufRva = 0x10DCF0,
  integrityCompareRva = 0x34037,
}

local GT_DRAW_TEXT_DATA_SIZE = 524288
local GT_DRAW_TEXT_MAX_SOURCE_LEN = 768

local STATE_KEY = '__zhCNGTutorialTranslateState'
local STATE = rawget(_G, STATE_KEY)
if type(STATE) ~= 'table' then
  STATE = {}
  rawset(_G, STATE_KEY, STATE)
end

-- 共享工具函数回退
local function zhCNNativeHooksEnabled()
  if _G.zhCNEnableNativeHooks == false then return false end
  return _G.zhCNGTutorialEnableNativeHooks ~= false
end

-- 共享工具函数回退
local checkedCall = (_G.zhCNUtil and _G.zhCNUtil.checkedCall) or function(fn, ...)
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then return true, a, b, c, d end
  return false, nil
end

-- 把 Lua 字符串转换成字节数组，可按需追加零结尾。
local function bytesOfString(text, zeroTerminate)
  local bytes = {}
  for i = 1, #text do
    bytes[#bytes + 1] = string.byte(text, i)
  end
  if zeroTerminate then bytes[#bytes + 1] = 0 end
  return bytes
end

-- 把一组字节追加到目标字节数组末尾。
local function appendBytes(target, bytes)
  for i = 1, #bytes do
    target[#target + 1] = bytes[i]
  end
end

-- 把 32 位整数转换成小端字节序。
local function dwordBytes(value)
  value = value or 0
  if value < 0 then value = value + 0x100000000 end
  local bytes = {}
  for _ = 1, 4 do
    bytes[#bytes + 1] = value % 0x100
    value = math.floor(value / 0x100)
  end
  return bytes
end

-- 把 64 位整数转换成小端字节序。
local function qwordBytes(value)
  value = value or 0
  if value < 0 then
    return { 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF }
  end
  local lo = value % 0x100000000
  local hi = math.floor(value / 0x100000000)
  local bytes = dwordBytes(lo)
  appendBytes(bytes, dwordBytes(hi))
  return bytes
end

-- 按目标进程位数生成 FPC AnsiString 内存布局。
local function fpcAnsiStringBytes(text, target)
  local bytes
  if target and target.is64 == false then
    bytes = dwordBytes(0x10000)
    appendBytes(bytes, dwordBytes(-1))
    appendBytes(bytes, dwordBytes(#text))
  else
    bytes = qwordBytes(0x10000)
    appendBytes(bytes, qwordBytes(-1))
    appendBytes(bytes, qwordBytes(#text))
  end
  appendBytes(bytes, bytesOfString(text, true))
  return bytes
end

-- 把偏移或大小向上对齐到指定边界。
local function alignUp(value, alignment)
  alignment = alignment or 16
  return math.floor((value + alignment - 1) / alignment) * alignment
end

-- 安全获取目标进程符号地址。
local function getTargetAddressSafe(symbol)
  if type(getAddressSafe) ~= 'function' then return nil end
  local ok, value = checkedCall(function() return getAddressSafe(symbol) end)
  if ok and type(value) == 'number' then return value end
  return nil
end

-- 统一判断写内存类调用是否真正成功。
local function writeSucceeded(fn, ...)
  local ok, result = checkedCall(fn, ...)
  return ok and result ~= false
end

-- 取得当前 CE 可执行文件名，用于位数判断兜底。
local function getCEExecutableName()
  if type(getApplication) == 'function' then
    local ok, app = checkedCall(getApplication)
    local exeName = ok and app and app.ExeName
    if type(exeName) == 'string' then
      return exeName:match('[^\\/]+$') or exeName
    end
  end
  return nil
end

-- 判断当前 CE 位数，决定默认启动 x86 还是 x64 教程目标。
local function getCEIs64Bit()
  local exeName = getCEExecutableName()
  if type(exeName) == 'string' then
    local lower = exeName:lower()
    if lower:find('i386', 1, true) then
      return false
    end
    if lower:find('x86_64', 1, true) or lower:find('64', 1, true) then
      return true
    end
  end

  if type(cheatEngineIs64Bit) == 'function' then
    local ok, value = checkedCall(cheatEngineIs64Bit)
    if ok and type(value) == 'boolean' then
      return value
    end
  end

  return true
end

-- 根据当前 CE 位数选择默认图形教程目标。
local function getDefaultGTutorialTarget()
  if getCEIs64Bit() then return GT_TARGET_X64 end
  return GT_TARGET_X86
end

local GT_DRAW_TEXT_EXACT = {
  ['CE Game tutorials'] = 'CE 游戏教程',
  ['Step 1'] = '步骤 1',
  ['Step 2'] = '步骤 2',
  ['Step 3'] = '步骤 3',
  ['Level 1'] = '关卡 1',
  ['Level 2'] = '关卡 2',
  ['Level 3'] = '关卡 3',
  ['Level Select'] = '关卡选择',
  ['Select Level'] = '关卡选择',
  ['<RELOADING>'] = '<重新装填>',
  ['well done'] = '完成',
  ['!PAUSED!'] = '!暂停!',
  ['You lose instead!'] = '你反而输了!',
  ['More information like videos for this step and written tutorials'] = '更多信息，例如本步骤的视频和文字教程',
  ['@More information like videos for this step and written tutorials'] = '@更多信息，例如本步骤的视频和文字教程',
  ['This does not count as a solution for tutorial 1'] = '这不算第 1 关的解法',
  ['This does not count as a solution for tutorial 2'] = '这不算第 2 关的解法',
  ['Ammo till reload:\r\n%d'] = '剩余弹药:\r\n%d',
  ['Player Health: \r\n%d'] = '玩家生命:\r\n%d',
  ['Player Health: \r\n100'] = '玩家生命:\r\n100',
  ['You will pay for this!\r\nActivating megabombs\r\n'] = '你会付出代价！\r\n启动巨型炸弹\r\n',
  ['Level Select:\r\nDestroy the target for the specific level.\r\n \r\n(Click to hide)'] =
    '关卡选择:\r\n摧毁指定关卡的目标。\r\n \r\n(点击隐藏)',
  ['Step 1:\r\nEvery 5 shots you have to reload,\r\nafter which the target will heal\r\nTry to find a way to destroy the target\r\n \r\n(Click to hide)'] =
    '步骤 1:\r\n每 5 发子弹需要重新装填，\r\n装填后目标会恢复生命。\r\n想办法摧毁这个目标。\r\n \r\n(点击隐藏)',
  ['Step 2:\r\nThese two enemies have more health\r\nand do more damage to you than\r\nyou do to them. Destroy them\r\n \r\nTip/Warning: Enemy and player are related\r\n \r\n(Click to hide)'] =
    '步骤 2:\r\n这两个敌人的生命更多，\r\n造成的伤害也比你更高。\r\n摧毁它们。\r\n \r\n提示/警告：敌人和玩家有关联。\r\n \r\n(点击隐藏)',
  ['Step 3:\r\nMark all platforms green to\r\nunlock the door\r\n \r\nBeware: Enemies are 1 hit kill\r\n        (and bad losers)\r\n \r\n \r\nHave fun!\r\n \r\nHint: There are multiple solutions\r\n e.g: Find collisiton detect with \r\n      enemies, or teleport, or fly\r\n      or ....\r\n'] =
    '步骤 3:\r\n把所有平台变成绿色即可开门。\r\n \r\n注意：敌人会一击必杀\r\n      (而且输不起)\r\n \r\n \r\n祝你玩得开心！\r\n \r\n提示：有多种解法，\r\n例如找碰撞检测、传送、飞行，\r\n或其它办法……\r\n',
}

-- 向绘制层查找表加入一个去重后的翻译条目。
local function addEntry(entries, bySource, source, translated)
  if type(source) ~= 'string' or type(translated) ~= 'string' then return end
  if source == '' or translated == '' or source == translated then return end
  if #source > GT_DRAW_TEXT_MAX_SOURCE_LEN or #translated > GT_DRAW_TEXT_MAX_SOURCE_LEN then return end
  if bySource[source] then return end
  bySource[source] = true
  entries[#entries + 1] = { source = source, translated = translated }
end

-- 汇总固定文本和数字动态文本，生成图形教程绘制层查找表。
local function buildGTutorialDrawTextEntries()
  local entries = {}
  local bySource = {}

  for source, translated in pairs(GT_DRAW_TEXT_EXACT) do
    addEntry(entries, bySource, source, translated)
  end

  for i = 0, 99 do
    addEntry(entries, bySource, 'Ammo till reload:\r\n' .. tostring(i), '剩余弹药:\r\n' .. tostring(i))
  end

  for i = 0, 1000 do
    addEntry(entries, bySource, 'Player Health: \r\n' .. tostring(i), '玩家生命:\r\n' .. tostring(i))
  end

  table.sort(entries, function(a, b)
    if #a.source ~= #b.source then return #a.source < #b.source end
    return a.source < b.source
  end)

  return entries
end

-- 追加 64 位图形教程 FPC 字符串查找例程的 AA 代码。
local function appendGTutorialLookupAA(out)
  out[#out + 1] = 'label(zhGTDrawTextLookup)'
  out[#out + 1] = 'label(zhGTDrawTextLookupKnownLen)'
  out[#out + 1] = 'label(zhGTDrawTextLookupLenLoop)'
  out[#out + 1] = 'label(zhGTDrawTextLookupLoop)'
  out[#out + 1] = 'label(zhGTDrawTextLookupLoopStart)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCompare)'
  out[#out + 1] = 'label(zhGTDrawTextLookupNext)'
  out[#out + 1] = 'label(zhGTDrawTextLookupMatched)'
  out[#out + 1] = 'label(zhGTDrawTextLookupMiss)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawTextHookMem:'
  out[#out + 1] = 'zhGTDrawTextLookup:'
  out[#out + 1] = '  push rcx'
  out[#out + 1] = '  push rdx'
  out[#out + 1] = '  push r9'
  out[#out + 1] = '  test r8,r8'
  out[#out + 1] = '  je zhGTDrawTextLookupMiss'
  out[#out + 1] = '  mov rax,r8'
  out[#out + 1] = '  cmp r9d,FFFFFFFF'
  out[#out + 1] = '  jne zhGTDrawTextLookupKnownLen'
  out[#out + 1] = '  xor r10,r10'
  out[#out + 1] = 'zhGTDrawTextLookupLenLoop:'
  out[#out + 1] = '  cmp byte ptr [rax+r10],00'
  out[#out + 1] = '  je zhGTDrawTextLookupLoop'
  out[#out + 1] = '  inc r10'
  out[#out + 1] = '  cmp r10,' .. string.format('%X', GT_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  jb zhGTDrawTextLookupLenLoop'
  out[#out + 1] = '  jmp zhGTDrawTextLookupMiss'
  out[#out + 1] = 'zhGTDrawTextLookupKnownLen:'
  out[#out + 1] = '  movsxd r10,r9d'
  out[#out + 1] = '  cmp r10,1'
  out[#out + 1] = '  jl zhGTDrawTextLookupMiss'
  out[#out + 1] = '  cmp r10,' .. string.format('%X', GT_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  ja zhGTDrawTextLookupMiss'
  out[#out + 1] = 'zhGTDrawTextLookupLoop:'
  out[#out + 1] = '  lea r11,[zhGTDrawTextData]'
  out[#out + 1] = 'zhGTDrawTextLookupLoopStart:'
  out[#out + 1] = '  mov rcx,[r11]'
  out[#out + 1] = '  test rcx,rcx'
  out[#out + 1] = '  je zhGTDrawTextLookupMiss'
  out[#out + 1] = '  cmp rcx,r10'
  out[#out + 1] = '  ja zhGTDrawTextLookupMiss'
  out[#out + 1] = '  jne zhGTDrawTextLookupNext'
  out[#out + 1] = '  movzx edx,byte ptr [rax]'
  out[#out + 1] = '  cmp dl,byte ptr [r11+8]'
  out[#out + 1] = '  jne zhGTDrawTextLookupNext'
  out[#out + 1] = '  mov rdx,[r11+10]'
  out[#out + 1] = '  xor ecx,ecx'
  out[#out + 1] = 'zhGTDrawTextLookupCompare:'
  out[#out + 1] = '  cmp rcx,r10'
  out[#out + 1] = '  jae zhGTDrawTextLookupMatched'
  out[#out + 1] = '  mov r9b,byte ptr [rax+rcx]'
  out[#out + 1] = '  cmp r9b,byte ptr [rdx+rcx]'
  out[#out + 1] = '  jne zhGTDrawTextLookupNext'
  out[#out + 1] = '  inc rcx'
  out[#out + 1] = '  jmp zhGTDrawTextLookupCompare'
  out[#out + 1] = 'zhGTDrawTextLookupNext:'
  out[#out + 1] = '  add r11,28'
  out[#out + 1] = '  jmp zhGTDrawTextLookupLoopStart'
  out[#out + 1] = 'zhGTDrawTextLookupMatched:'
  out[#out + 1] = '  mov r8,[r11+18]'
  out[#out + 1] = '  mov r9,[r11+20]'
  out[#out + 1] = '  add rsp,8'
  out[#out + 1] = '  pop rdx'
  out[#out + 1] = '  pop rcx'
  out[#out + 1] = '  ret'
  out[#out + 1] = 'zhGTDrawTextLookupMiss:'
  out[#out + 1] = '  pop r9'
  out[#out + 1] = '  pop rdx'
  out[#out + 1] = '  pop rcx'
  out[#out + 1] = '  ret'
end

-- 追加 32 位图形教程 FPC 字符串查找例程的 AA 代码。
local function appendGTutorialLookupAA32(out)
  out[#out + 1] = 'label(zhGTDrawTextLookup)'
  out[#out + 1] = 'label(zhGTDrawTextLookupLoop)'
  out[#out + 1] = 'label(zhGTDrawTextLookupLoopStart)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCompare)'
  out[#out + 1] = 'label(zhGTDrawTextLookupNext)'
  out[#out + 1] = 'label(zhGTDrawTextLookupMatched)'
  out[#out + 1] = 'label(zhGTDrawTextLookupMiss)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawTextHookMem:'
  out[#out + 1] = 'zhGTDrawTextLookup:'
  out[#out + 1] = '  push eax'
  out[#out + 1] = '  push ebx'
  out[#out + 1] = '  push ecx'
  out[#out + 1] = '  push esi'
  out[#out + 1] = '  push edi'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  test edx,edx'
  out[#out + 1] = '  je zhGTDrawTextLookupMiss'
  out[#out + 1] = '  mov esi,edx'
  out[#out + 1] = '  mov ecx,[esi-4]'
  out[#out + 1] = '  cmp ecx,1'
  out[#out + 1] = '  jl zhGTDrawTextLookupMiss'
  out[#out + 1] = '  cmp ecx,' .. string.format('%X', GT_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  ja zhGTDrawTextLookupMiss'
  out[#out + 1] = 'zhGTDrawTextLookupLoop:'
  out[#out + 1] = '  mov edi,zhGTDrawTextData'
  out[#out + 1] = 'zhGTDrawTextLookupLoopStart:'
  out[#out + 1] = '  mov eax,[edi]'
  out[#out + 1] = '  test eax,eax'
  out[#out + 1] = '  je zhGTDrawTextLookupMiss'
  out[#out + 1] = '  cmp eax,ecx'
  out[#out + 1] = '  ja zhGTDrawTextLookupMiss'
  out[#out + 1] = '  jne zhGTDrawTextLookupNext'
  out[#out + 1] = '  mov al,[esi]'
  out[#out + 1] = '  cmp al,[edi+8]'
  out[#out + 1] = '  jne zhGTDrawTextLookupNext'
  out[#out + 1] = '  mov ebx,[edi+10]'
  out[#out + 1] = '  xor eax,eax'
  out[#out + 1] = 'zhGTDrawTextLookupCompare:'
  out[#out + 1] = '  cmp eax,ecx'
  out[#out + 1] = '  jae zhGTDrawTextLookupMatched'
  out[#out + 1] = '  mov dl,[esi+eax]'
  out[#out + 1] = '  cmp dl,[ebx+eax]'
  out[#out + 1] = '  jne zhGTDrawTextLookupNext'
  out[#out + 1] = '  inc eax'
  out[#out + 1] = '  jmp zhGTDrawTextLookupCompare'
  out[#out + 1] = 'zhGTDrawTextLookupNext:'
  out[#out + 1] = '  add edi,28'
  out[#out + 1] = '  jmp zhGTDrawTextLookupLoopStart'
  out[#out + 1] = 'zhGTDrawTextLookupMatched:'
  out[#out + 1] = '  add esp,4'
  out[#out + 1] = '  mov edx,[edi+18]'
  out[#out + 1] = '  pop edi'
  out[#out + 1] = '  pop esi'
  out[#out + 1] = '  pop ecx'
  out[#out + 1] = '  pop ebx'
  out[#out + 1] = '  pop eax'
  out[#out + 1] = '  ret'
  out[#out + 1] = 'zhGTDrawTextLookupMiss:'
  out[#out + 1] = '  pop edx'
  out[#out + 1] = '  pop edi'
  out[#out + 1] = '  pop esi'
  out[#out + 1] = '  pop ecx'
  out[#out + 1] = '  pop ebx'
  out[#out + 1] = '  pop eax'
  out[#out + 1] = '  ret'
end

-- 追加 32 位标题 C 字符串查找例程的 AA 代码。
local function appendGTutorialCStringLookupAA32(out)
  out[#out + 1] = 'label(zhGTDrawTextLookupCString)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringLenLoop)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringLoop)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringLoopStart)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringCompare)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringNext)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringMatched)'
  out[#out + 1] = 'label(zhGTDrawTextLookupCStringMiss)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawTextLookupCString:'
  out[#out + 1] = '  push eax'
  out[#out + 1] = '  push ebx'
  out[#out + 1] = '  push ecx'
  out[#out + 1] = '  push esi'
  out[#out + 1] = '  push edi'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  test edx,edx'
  out[#out + 1] = '  je zhGTDrawTextLookupCStringMiss'
  out[#out + 1] = '  mov esi,edx'
  out[#out + 1] = '  xor ecx,ecx'
  out[#out + 1] = 'zhGTDrawTextLookupCStringLenLoop:'
  out[#out + 1] = '  cmp byte ptr [esi+ecx],00'
  out[#out + 1] = '  je zhGTDrawTextLookupCStringLoop'
  out[#out + 1] = '  inc ecx'
  out[#out + 1] = '  cmp ecx,' .. string.format('%X', GT_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  jb zhGTDrawTextLookupCStringLenLoop'
  out[#out + 1] = '  jmp zhGTDrawTextLookupCStringMiss'
  out[#out + 1] = 'zhGTDrawTextLookupCStringLoop:'
  out[#out + 1] = '  cmp ecx,1'
  out[#out + 1] = '  jl zhGTDrawTextLookupCStringMiss'
  out[#out + 1] = '  mov edi,zhGTDrawTextData'
  out[#out + 1] = 'zhGTDrawTextLookupCStringLoopStart:'
  out[#out + 1] = '  mov eax,[edi]'
  out[#out + 1] = '  test eax,eax'
  out[#out + 1] = '  je zhGTDrawTextLookupCStringMiss'
  out[#out + 1] = '  cmp eax,ecx'
  out[#out + 1] = '  ja zhGTDrawTextLookupCStringMiss'
  out[#out + 1] = '  jne zhGTDrawTextLookupCStringNext'
  out[#out + 1] = '  mov al,[esi]'
  out[#out + 1] = '  cmp al,[edi+8]'
  out[#out + 1] = '  jne zhGTDrawTextLookupCStringNext'
  out[#out + 1] = '  mov ebx,[edi+10]'
  out[#out + 1] = '  xor eax,eax'
  out[#out + 1] = 'zhGTDrawTextLookupCStringCompare:'
  out[#out + 1] = '  cmp eax,ecx'
  out[#out + 1] = '  jae zhGTDrawTextLookupCStringMatched'
  out[#out + 1] = '  mov dl,[esi+eax]'
  out[#out + 1] = '  cmp dl,[ebx+eax]'
  out[#out + 1] = '  jne zhGTDrawTextLookupCStringNext'
  out[#out + 1] = '  inc eax'
  out[#out + 1] = '  jmp zhGTDrawTextLookupCStringCompare'
  out[#out + 1] = 'zhGTDrawTextLookupCStringNext:'
  out[#out + 1] = '  add edi,28'
  out[#out + 1] = '  jmp zhGTDrawTextLookupCStringLoopStart'
  out[#out + 1] = 'zhGTDrawTextLookupCStringMatched:'
  out[#out + 1] = '  add esp,4'
  out[#out + 1] = '  mov edx,[edi+18]'
  out[#out + 1] = '  pop edi'
  out[#out + 1] = '  pop esi'
  out[#out + 1] = '  pop ecx'
  out[#out + 1] = '  pop ebx'
  out[#out + 1] = '  pop eax'
  out[#out + 1] = '  ret'
  out[#out + 1] = 'zhGTDrawTextLookupCStringMiss:'
  out[#out + 1] = '  pop edx'
  out[#out + 1] = '  pop edi'
  out[#out + 1] = '  pop esi'
  out[#out + 1] = '  pop ecx'
  out[#out + 1] = '  pop ebx'
  out[#out + 1] = '  pop eax'
  out[#out + 1] = '  ret'
end

-- 构建在教程进程恢复前安装的纹理文本和标题 Hook AA 脚本。
local function buildGTutorialEarlyTextureHookAA(target, imageBase)
  if target and target.is64 == false then
    local textureEntry = imageBase + target.textureTextRva
    local setTextBufEntry = imageBase + target.setTextBufRva
    local integrityCompare = imageBase + target.integrityCompareRva
    local out = {}
    out[#out + 1] = 'define(zhGTDrawText_TextureTextEntry,' .. string.format('%X', textureEntry) .. ')'
    out[#out + 1] = 'define(zhGTDrawText_SetTextBufEntry,' .. string.format('%X', setTextBufEntry) .. ')'
    out[#out + 1] = 'define(zhGTDrawText_IntegrityCompare,' .. string.format('%X', integrityCompare) .. ')'
    out[#out + 1] = 'assert(zhGTDrawText_TextureTextEntry,55 89 E5 8D A4 24 50 FF FF FF 53 56 57)'
    out[#out + 1] = 'assert(zhGTDrawText_SetTextBufEntry,55 89 E5 8D A4 24 EC FE FF FF)'
    out[#out + 1] = 'assert(zhGTDrawText_IntegrityCompare,3B 43 38)'
    out[#out + 1] = 'alloc(zhGTDrawTextHookMem,8192,zhGTDrawText_TextureTextEntry)'
    out[#out + 1] = 'alloc(zhGTDrawTextData,' .. tostring(GT_DRAW_TEXT_DATA_SIZE) .. ',zhGTDrawText_TextureTextEntry)'
    out[#out + 1] = 'alloc(zhGTDrawTextTextureHookMem,1024,zhGTDrawText_TextureTextEntry)'
    out[#out + 1] = 'alloc(zhGTDrawTextTitleHookMem,1024,zhGTDrawText_TextureTextEntry)'
    out[#out + 1] = 'label(zhGTDrawTextTextureHook)'
    out[#out + 1] = 'label(zhGTDrawTextTitleHook)'
    out[#out + 1] = ''
    appendGTutorialLookupAA32(out)
    out[#out + 1] = ''
    appendGTutorialCStringLookupAA32(out)
    out[#out + 1] = ''
    out[#out + 1] = 'zhGTDrawTextTextureHookMem:'
    out[#out + 1] = 'zhGTDrawTextTextureHook:'
    out[#out + 1] = '  db 55 89 E5 8D A4 24 50 FF FF FF 53 56 57'
    out[#out + 1] = '  push eax'
    out[#out + 1] = '  push ebx'
    out[#out + 1] = '  push ecx'
    out[#out + 1] = '  push esi'
    out[#out + 1] = '  push edi'
    out[#out + 1] = '  call zhGTDrawTextHookMem'
    out[#out + 1] = '  pop edi'
    out[#out + 1] = '  pop esi'
    out[#out + 1] = '  pop ecx'
    out[#out + 1] = '  pop ebx'
    out[#out + 1] = '  pop eax'
    out[#out + 1] = '  jmp zhGTDrawText_TextureTextEntry+0D'
    out[#out + 1] = ''
    out[#out + 1] = 'zhGTDrawTextTitleHookMem:'
    out[#out + 1] = 'zhGTDrawTextTitleHook:'
    out[#out + 1] = '  call zhGTDrawTextLookupCString'
    out[#out + 1] = '  db 55 89 E5 8D A4 24 EC FE FF FF'
    out[#out + 1] = '  jmp zhGTDrawText_SetTextBufEntry+0A'
    out[#out + 1] = ''
    out[#out + 1] = 'zhGTDrawText_TextureTextEntry:'
    out[#out + 1] = '  jmp zhGTDrawTextTextureHookMem'
    out[#out + 1] = '  nop 8'
    out[#out + 1] = ''
    out[#out + 1] = 'zhGTDrawText_SetTextBufEntry:'
    out[#out + 1] = '  jmp zhGTDrawTextTitleHookMem'
    out[#out + 1] = '  nop 5'
    out[#out + 1] = ''
    out[#out + 1] = 'zhGTDrawText_IntegrityCompare:'
    out[#out + 1] = '  cmp eax,eax'
    out[#out + 1] = '  nop'
    out[#out + 1] = 'registersymbol(zhGTDrawTextData)'
    out[#out + 1] = 'registersymbol(zhGTDrawTextHookMem)'
    out[#out + 1] = 'registersymbol(zhGTDrawTextTextureHookMem)'
    out[#out + 1] = 'registersymbol(zhGTDrawTextTitleHookMem)'
    return table.concat(out, '\n')
  end

  target = target or GT_TARGET_X64
  local textureEntry = imageBase + target.textureTextRva
  local setTextBufEntry = imageBase + target.setTextBufRva
  local out = {}
  out[#out + 1] = 'define(zhGTDrawText_TextureTextEntry,' .. string.format('%X', textureEntry) .. ')'
  out[#out + 1] = 'define(zhGTDrawText_SetTextBufEntry,' .. string.format('%X', setTextBufEntry) .. ')'
  out[#out + 1] = 'assert(zhGTDrawText_TextureTextEntry,55 48 89 E5 48 8D A4 24 A0 FE FF FF)'
  out[#out + 1] = 'assert(zhGTDrawText_SetTextBufEntry,55 48 89 E5 48 8D A4 24 30 FE FF FF)'
  out[#out + 1] = 'alloc(zhGTDrawTextHookMem,8192,zhGTDrawText_TextureTextEntry)'
  out[#out + 1] = 'alloc(zhGTDrawTextData,' .. tostring(GT_DRAW_TEXT_DATA_SIZE) .. ',zhGTDrawText_TextureTextEntry)'
  out[#out + 1] = 'alloc(zhGTDrawTextTextureHookMem,1024,zhGTDrawText_TextureTextEntry)'
  out[#out + 1] = 'alloc(zhGTDrawTextTitleHookMem,1024,zhGTDrawText_TextureTextEntry)'
  out[#out + 1] = 'label(zhGTDrawTextTextureHook)'
  out[#out + 1] = 'label(zhGTDrawTextTitleHook)'
  out[#out + 1] = ''
  appendGTutorialLookupAA(out)
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawTextTextureHookMem:'
  out[#out + 1] = 'zhGTDrawTextTextureHook:'
  out[#out + 1] = '  db 55 48 89 E5 48 8D A4 24 A0 FE FF FF'
  out[#out + 1] = '  push r8'
  out[#out + 1] = '  push r9'
  out[#out + 1] = '  mov r8,rdx'
  out[#out + 1] = '  mov r9d,FFFFFFFF'
  out[#out + 1] = '  call zhGTDrawTextHookMem'
  out[#out + 1] = '  mov rdx,r8'
  out[#out + 1] = '  pop r9'
  out[#out + 1] = '  pop r8'
  out[#out + 1] = '  jmp zhGTDrawText_TextureTextEntry+0C'
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawTextTitleHookMem:'
  out[#out + 1] = 'zhGTDrawTextTitleHook:'
  out[#out + 1] = '  push r8'
  out[#out + 1] = '  push r9'
  out[#out + 1] = '  mov r8,rdx'
  out[#out + 1] = '  mov r9d,FFFFFFFF'
  out[#out + 1] = '  call zhGTDrawTextHookMem'
  out[#out + 1] = '  mov rdx,r8'
  out[#out + 1] = '  pop r9'
  out[#out + 1] = '  pop r8'
  out[#out + 1] = '  db 55 48 89 E5 48 8D A4 24 30 FE FF FF'
  out[#out + 1] = '  jmp zhGTDrawText_SetTextBufEntry+0C'
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawText_TextureTextEntry:'
  out[#out + 1] = '  jmp zhGTDrawTextTextureHookMem'
  out[#out + 1] = '  nop 7'
  out[#out + 1] = ''
  out[#out + 1] = 'zhGTDrawText_SetTextBufEntry:'
  out[#out + 1] = '  jmp zhGTDrawTextTitleHookMem'
  out[#out + 1] = '  nop 7'
  out[#out + 1] = 'registersymbol(zhGTDrawTextData)'
  out[#out + 1] = 'registersymbol(zhGTDrawTextHookMem)'
  out[#out + 1] = 'registersymbol(zhGTDrawTextTextureHookMem)'
  out[#out + 1] = 'registersymbol(zhGTDrawTextTitleHookMem)'
  return table.concat(out, '\n')
end

-- 把图形教程翻译查找表写入目标进程的 AA 数据区。
local function populateGTutorialDrawTextData(entries, target)
  if type(writeBytes) ~= 'function' or type(getAddressSafe) ~= 'function' then
    return false, 'missing target memory helpers'
  end

  local base = getTargetAddressSafe('zhGTDrawTextData')
  if type(base) ~= 'number' then return false, 'missing zhGTDrawTextData symbol' end

  local entrySize = 0x28
  local entryAreaSize = alignUp((#entries + 1) * entrySize, 16)
  local cursor = base + entryAreaSize

  if not writeSucceeded(function() return writeBytes(base + (#entries * entrySize), qwordBytes(0)) end) then
    return false, 'write failed at terminator entry'
  end

  for i, entry in ipairs(entries) do
    local entryAddress = base + ((i - 1) * entrySize)
    local sourceAddress = cursor
    local sourceBytes = bytesOfString(entry.source, false)
    if not writeSucceeded(function() return writeBytes(sourceAddress, sourceBytes) end) then
      return false, 'write failed at source ' .. tostring(entry.source)
    end
    cursor = base + alignUp((sourceAddress + #sourceBytes) - base, 16)

    local targetHeaderAddress = cursor
    local targetHeaderSize = (target and target.is64 == false) and 0x0C or 0x18
    local targetAddress = targetHeaderAddress + targetHeaderSize
    local targetBytes = fpcAnsiStringBytes(entry.translated, target)
    if not writeSucceeded(function() return writeBytes(targetHeaderAddress, targetBytes) end) then
      return false, 'write failed at target ' .. tostring(entry.source)
    end
    cursor = base + alignUp((targetHeaderAddress + #targetBytes) - base, 16)

    local entryBytes = qwordBytes(#entry.source)
    appendBytes(entryBytes, dwordBytes(string.byte(entry.source, 1) or 0))
    appendBytes(entryBytes, dwordBytes(0))
    appendBytes(entryBytes, qwordBytes(sourceAddress))
    appendBytes(entryBytes, qwordBytes(targetAddress))
    appendBytes(entryBytes, qwordBytes(#entry.translated))

    if not writeSucceeded(function() return writeBytes(entryAddress, entryBytes) end) then
      return false, 'write failed at entry ' .. tostring(entry.source)
    end

    if cursor - base > GT_DRAW_TEXT_DATA_SIZE then
      return false, 'data block too small: ' .. tostring(cursor - base)
    end
  end

  return true, cursor - base
end

local GT_SYMBOLS = {
  'zhGTDrawTextData',
  'zhGTDrawTextHookMem',
  'zhGTDrawTextTextureHookMem',
  'zhGTDrawTextTitleHookMem',
}

-- 注销图形教程 Hook 使用的 AA 符号，避免跨进程复用旧地址。
local function unregisterGTSymbols()
  if type(unregisterSymbol) ~= 'function' then return end
  for _, symbol in ipairs(GT_SYMBOLS) do
    checkedCall(function() unregisterSymbol(symbol) end)
  end
end

-- 在已打开的图形教程进程中安装纹理文本和标题 Hook。
local function installGTutorialTextureHook(imageBase, target)
  if not zhCNNativeHooksEnabled() then return false, 'native hooks disabled' end
  target = target or getDefaultGTutorialTarget()
  if type(imageBase) ~= 'number' or imageBase == 0 then
    return false, 'missing pre-resume image base'
  end
  if type(getOpenedProcessID) ~= 'function' or getOpenedProcessID() == 0 then
    return false, 'no opened process'
  end
  if type(autoAssemble) ~= 'function' or type(getAddressSafe) ~= 'function' then
    return false, 'missing auto assembler helpers'
  end

  local pid = getOpenedProcessID()
  if STATE.pid ~= pid then
    unregisterGTSymbols()
    STATE.pid = pid
  end

  local entries = buildGTutorialDrawTextEntries()
  if not getTargetAddressSafe('zhGTDrawTextHookMem') then
    local aa = buildGTutorialEarlyTextureHookAA(target, imageBase)
    local ok, result, detail = checkedCall(function() return autoAssemble(aa) end)
    if not ok or result == false then
      return false, detail or result or 'early hook autoAssemble failed'
    end
  end

  if not getTargetAddressSafe('zhGTDrawTextTextureHookMem') or not getTargetAddressSafe('zhGTDrawTextTitleHookMem') then
    return false, 'early hook symbol missing'
  end

  local dataOk, dataResult = populateGTutorialDrawTextData(entries, target)
  return dataOk == true, dataResult
end

-- 共享工具函数回退
local joinPath = (_G.zhCNUtil and _G.zhCNUtil.joinPath) or function(folder, name)
  if type(folder) ~= 'string' or folder == '' then return name end
  local last = folder:sub(-1)
  if last == '\\' or last == '/' then return folder .. name end
  return folder .. '\\' .. name
end

-- 从完整路径中取出所在目录。
local function getFolderFromPath(path)
  if type(path) ~= 'string' then return nil end
  local folder = path:match('^(.*[\\/])')
  if folder == '' then return nil end
  return folder
end

-- 查找当前 CE 目录下匹配位数的图形教程可执行文件。
local function getGTutorialExecutablePath(target)
  target = target or getDefaultGTutorialTarget()
  local base = nil
  if type(getCheatEngineDir) == 'function' then
    local ok, value = checkedCall(getCheatEngineDir)
    if ok and type(value) == 'string' and value ~= '' then base = value end
  end
  if (not base or base == '') and type(getApplication) == 'function' and type(extractFilePath) == 'function' then
    local ok, value = checkedCall(function() return extractFilePath(getApplication().ExeName) end)
    if ok and type(value) == 'string' and value ~= '' then base = value end
  end

  local candidates = {
    joinPath(base, target.processName),
    joinPath(joinPath(joinPath(base, 'Tutorial'), 'graphical'), target.processName),
  }

  if type(fileExists) == 'function' then
    for _, path in ipairs(candidates) do
      local ok, exists = checkedCall(fileExists, path)
      if ok and exists then return path end
    end
  end

  return candidates[1]
end

local CREATE_SUSPENDED = 0x00000004
local STARTUPINFOW_SIZE_X64 = 104
local STARTUPINFOW_SIZE_X86 = 68
local x86CreateProcessStubAddress = nil

-- 返回当前 CE 进程的指针宽度。
local function getLocalPointerSize()
  if getCEIs64Bit() then return 8 end
  return 4
end

-- 返回当前 CE 位数对应的 STARTUPINFOW 结构大小。
local function getStartupInfoWSize()
  if getLocalPointerSize() == 8 then return STARTUPINFOW_SIZE_X64 end
  return STARTUPINFOW_SIZE_X86
end

-- 安全获取 CE 本进程符号地址，必要时刷新 self symbol handler。
local function getLocalAddressSafe(symbol)
  if type(getAddressSafe) ~= 'function' then return nil end
  local ok, value = checkedCall(function() return getAddressSafe(symbol, true) end)
  if ok and type(value) == 'number' then return value end
  checkedCall(function()
    if type(reinitializeSelfSymbolhandler) == 'function' then
      reinitializeSelfSymbolhandler(true)
    end
  end)
  ok, value = checkedCall(function() return getAddressSafe(symbol, true) end)
  if ok and type(value) == 'number' then return value end
  return nil
end

-- 清零 CE 本进程中的临时内存块。
local function zeroLocalMemory(address, size)
  if type(writeBytesLocal) ~= 'function' then return false end
  local bytes = {}
  for i = 1, size do bytes[i] = 0 end
  local ok, result = checkedCall(function() return writeBytesLocal(address, bytes) end)
  return ok and result ~= false
end

-- 从挂起进程的 PEB 中读取主模块 image base，供恢复前按 RVA 安装 Hook。
local function getSuspendedProcessImageBase(processHandle, target)
  if not processHandle or processHandle == 0 or type(executeCodeLocalEx) ~= 'function' or type(allocateSharedMemoryLocal) ~= 'function' then
    return nil, 'invalid process handle'
  end
  target = target or getDefaultGTutorialTarget()

  local ntQueryInformationProcess = getLocalAddressSafe('ntdll.NtQueryInformationProcess')
  local readProcessMemory = getLocalAddressSafe('kernel32.ReadProcessMemory') or getLocalAddressSafe('kernelbase.ReadProcessMemory')
  if not ntQueryInformationProcess then return nil, 'NtQueryInformationProcess not found' end
  if not readProcessMemory then return nil, 'ReadProcessMemory not found' end

  local blockName = 'zhCN_gtutorial_pbi'
  local ok, block = checkedCall(function() return allocateSharedMemoryLocal(blockName, 128) end)
  if not ok or type(block) ~= 'number' or block == 0 then
    return nil, 'allocate pbi block failed'
  end
  zeroLocalMemory(block, 128)

  local processBasicInformation = block
  local readBuffer = block + 64
  local localPointerSize = getLocalPointerSize()
  local pbiSize = localPointerSize == 8 and 48 or 24
  local pebOffset = localPointerSize == 8 and 8 or 4
  local imageBaseOffset = target.is64 and 0x10 or 0x08
  local result
  ok, result = checkedCall(function()
    return executeCodeLocalEx(ntQueryInformationProcess, processHandle, 0, processBasicInformation, pbiSize, 0)
  end)
  if not ok or result ~= 0 then
    return nil, 'NtQueryInformationProcess failed'
  end

  local readOk, peb = checkedCall(function() return readPointerLocal(processBasicInformation + pebOffset) end)
  if not readOk then return nil, 'read PBI PEB failed: ' .. tostring(peb) end
  if type(peb) ~= 'number' or peb == 0 then return nil, 'PEB not found' end

  zeroLocalMemory(readBuffer, 16)
  ok, result = checkedCall(function()
    return executeCodeLocalEx(readProcessMemory, processHandle, peb + imageBaseOffset, readBuffer, localPointerSize, 0)
  end)
  if not ok or result == nil or result == 0 then
    return nil, 'ReadProcessMemory image base failed'
  end

  local imageBase
  readOk, imageBase = checkedCall(function() return readPointerLocal(readBuffer) end)
  if not readOk then return nil, 'read image base buffer failed: ' .. tostring(imageBase) end
  if type(imageBase) ~= 'number' or imageBase == 0 then
    return nil, 'image base is zero'
  end

  return imageBase
end

-- 关闭 CE 本进程持有的 Win32 handle。
local function closeLocalHandle(handle)
  if not handle or handle == 0 then return end
  local closeHandle = getLocalAddressSafe('kernel32.CloseHandle') or getLocalAddressSafe('kernelbase.CloseHandle')
  if closeHandle then
    if type(executeCodeLocalEx) == 'function' and getLocalPointerSize() == 8 then
      checkedCall(function() executeCodeLocalEx(closeHandle, handle) end)
    elseif type(executeCodeLocal) == 'function' then
      checkedCall(function() executeCodeLocal(closeHandle, handle) end)
    end
  end
end

-- 终止还未恢复运行的临时教程进程，避免 Hook 安装失败时留下未汉化实例。
local function terminateLocalProcess(processHandle)
  if not processHandle or processHandle == 0 then return false end
  local terminateProcess = getLocalAddressSafe('kernel32.TerminateProcess') or getLocalAddressSafe('kernelbase.TerminateProcess')
  if not terminateProcess then return false end

  local ok, result
  if type(executeCodeLocalEx) == 'function' then
    ok, result = checkedCall(function() return executeCodeLocalEx(terminateProcess, processHandle, 1) end)
  end

  return ok and result ~= nil and result ~= 0
end

-- 恢复通过 CREATE_SUSPENDED 创建的主线程。
local function resumeSuspendedThread(threadHandle)
  if not threadHandle or threadHandle == 0 then return false end
  local resumeThread = getLocalAddressSafe('kernel32.ResumeThread') or getLocalAddressSafe('kernelbase.ResumeThread')
  if resumeThread then
    local ok, result
    if type(executeCodeLocalEx) == 'function' and getLocalPointerSize() == 8 then
      ok, result = checkedCall(function() return executeCodeLocalEx(resumeThread, threadHandle) end)
    elseif type(executeCodeLocal) == 'function' then
      ok, result = checkedCall(function() return executeCodeLocal(resumeThread, threadHandle) end)
    end
    if ok and result ~= nil and result ~= -1 and result ~= 0xFFFFFFFF then return true end
  end

  if getLocalPointerSize() ~= 8 or type(executeCodeLocalEx) ~= 'function' then return false end
  local ntResumeThread = getLocalAddressSafe('ntdll.NtResumeThread')
  if not ntResumeThread then return false end
  local ok, result = checkedCall(function() return executeCodeLocalEx(ntResumeThread, threadHandle, 0) end)
  return ok and result == 0
end

-- 在 32 位 CE 中生成本地 CreateProcessW 调用桩，用于创建挂起教程进程。
local function ensureX86CreateProcessStub()
  if getLocalPointerSize() ~= 4 then return nil, 'local CE is not 32-bit' end
  if type(allocateSharedMemoryLocal) ~= 'function' or type(writeBytesLocal) ~= 'function' then
    return nil, 'missing local executable memory helpers'
  end
  if type(x86CreateProcessStubAddress) == 'number' and x86CreateProcessStubAddress ~= 0 then
    return x86CreateProcessStubAddress
  end

  local createProcessW = getLocalAddressSafe('kernel32.CreateProcessW') or getLocalAddressSafe('kernelbase.CreateProcessW')
  local getLastError = getLocalAddressSafe('kernel32.GetLastError') or getLocalAddressSafe('kernelbase.GetLastError')
  if not createProcessW then return nil, 'CreateProcessW not found' end
  if not getLastError then return nil, 'GetLastError not found' end

  local blockName = 'zhCN_gtutorial_createprocess_stub'
  local ok, address = checkedCall(function() return allocateSharedMemoryLocal(blockName, 256) end)
  if not ok or type(address) ~= 'number' or address == 0 then
    return nil, 'allocate local stub failed'
  end
  zeroLocalMemory(address, 256)

  local bytes = {
    0x55,                                           -- push ebp
    0x8B, 0xEC,                                     -- mov ebp,esp
    0x56,                                           -- push esi
    0x8B, 0x75, 0x08,                               -- mov esi,[ebp+08]
    0xC7, 0x46, 0x0C, 0x00, 0x00, 0x00, 0x00,       -- mov dword ptr [esi+0C],0
    0x8D, 0x86, 0x80, 0x00, 0x00, 0x00,             -- lea eax,[esi+80]
    0x50,                                           -- push eax
    0x8D, 0x46, 0x20,                               -- lea eax,[esi+20]
    0x50,                                           -- push eax
    0x8B, 0x46, 0x08,                               -- mov eax,[esi+08]
    0x50,                                           -- push eax
    0x6A, 0x00,                                     -- push 0
    0x6A, 0x04,                                     -- push CREATE_SUSPENDED
    0x6A, 0x00,                                     -- push 0
    0x6A, 0x00,                                     -- push 0
    0x6A, 0x00,                                     -- push 0
    0x6A, 0x00,                                     -- push 0
    0x8B, 0x46, 0x04,                               -- mov eax,[esi+04]
    0x50,                                           -- push eax
  }

  -- 向本地调用桩追加一条相对 call 指令。
  local function appendRelativeCall(targetAddress)
    local nextInstruction = address + #bytes + 5
    bytes[#bytes + 1] = 0xE8
    appendBytes(bytes, dwordBytes(targetAddress - nextInstruction))
  end

  appendRelativeCall(createProcessW)
  appendBytes(bytes, {
    0x89, 0x06,                                     -- mov [esi],eax
    0x85, 0xC0,                                     -- test eax,eax
    0x75, 0x08,                                     -- jne done
  })
  appendRelativeCall(getLastError)
  appendBytes(bytes, {
    0x89, 0x46, 0x0C,                               -- mov [esi+0C],eax
    0x5E,                                           -- pop esi
    0x5D,                                           -- pop ebp
    0xC2, 0x04, 0x00,                               -- ret 4
  })

  if not writeSucceeded(writeBytesLocal, address, bytes) then
    return nil, 'write local stub failed'
  end

  x86CreateProcessStubAddress = address
  return address
end

-- 32 位 CE 路径下创建挂起的图形教程进程。
local function createGTutorialSuspendedX86Local(path, target)
  if type(allocateSharedMemoryLocal) ~= 'function' or type(executeCodeLocal) ~= 'function' then
    return false, 'missing executeCodeLocal helpers'
  end
  if type(writeIntegerLocal) ~= 'function' or type(writePointerLocal) ~= 'function' or type(writeStringLocal) ~= 'function' then
    return false, 'missing local memory writers'
  end
  target = target or getDefaultGTutorialTarget()

  local stub, stubError = ensureX86CreateProcessStub()
  if not stub then
    return false, stubError
  end

  local blockName = 'zhCN_gtutorial_createprocess_x86'
  local blockSize = 4096
  local ok, block = checkedCall(function() return allocateSharedMemoryLocal(blockName, blockSize) end)
  if not ok or type(block) ~= 'number' or block == 0 then
    return false, 'allocateSharedMemoryLocal failed'
  end

  zeroLocalMemory(block, blockSize)
  local appPath = block + 0x100
  local currentDirectory = getFolderFromPath(path)
  local currentDirectoryAddress = 0
  if type(currentDirectory) == 'string' and currentDirectory ~= '' then
    currentDirectoryAddress = block + 0x800
    if not writeSucceeded(writeStringLocal, currentDirectoryAddress, currentDirectory, true) then
      return false, 'write current directory failed'
    end
  end

  if not writeSucceeded(writeStringLocal, appPath, path, true) then
    return false, 'write application path failed'
  end
  if not writeSucceeded(writePointerLocal, block + 0x04, appPath)
    or not writeSucceeded(writePointerLocal, block + 0x08, currentDirectoryAddress)
    or not writeSucceeded(writeIntegerLocal, block + 0x20, STARTUPINFOW_SIZE_X86) then
    return false, 'write context failed'
  end

  local callOk = checkedCall(function() return executeCodeLocal(stub, block) end)
  local readResultOk, createResult = checkedCall(function() return readIntegerLocal(block) end)
  local readErrorOk, lastError = checkedCall(function() return readIntegerLocal(block + 0x0C) end)
  if not callOk or not readResultOk or createResult == 0 then
    return false, 'CreateProcessW failed' .. (readErrorOk and lastError and (': ' .. tostring(lastError)) or '')
  end

  local processInfo = block + 0x80
  local readOk, hProcess = checkedCall(function() return readPointerLocal(processInfo) end)
  local readThreadOk, hThread = checkedCall(function() return readPointerLocal(processInfo + 4) end)
  local readPidOk, pid = checkedCall(function() return readIntegerLocal(processInfo + 8) end)
  if not readOk or not readThreadOk or not readPidOk then
    resumeSuspendedThread(hThread)
    closeLocalHandle(hThread)
    closeLocalHandle(hProcess)
    return false, 'read PROCESS_INFORMATION failed'
  end
  if type(pid) ~= 'number' or pid == 0 or type(hThread) ~= 'number' or hThread == 0 then
    resumeSuspendedThread(hThread)
    closeLocalHandle(hThread)
    closeLocalHandle(hProcess)
    return false, 'invalid PROCESS_INFORMATION'
  end

  local imageBase = target.preferredImageBase

  return true, {
    processHandle = hProcess,
    threadHandle = hThread,
    pid = pid,
    imageBase = imageBase,
  }
end

-- 创建挂起的图形教程进程，并返回进程、线程和 image base 信息。
local function createGTutorialSuspended(path, target)
  target = target or getDefaultGTutorialTarget()
  if getLocalPointerSize() == 4 then
    return createGTutorialSuspendedX86Local(path, target)
  end

  if type(allocateSharedMemoryLocal) ~= 'function' or type(executeCodeLocalEx) ~= 'function' then
    return false, 'missing local WinAPI helpers'
  end

  local createProcessW = getLocalAddressSafe('kernel32.CreateProcessW') or getLocalAddressSafe('kernelbase.CreateProcessW')
  if not createProcessW then
    return false, 'CreateProcessW not found'
  end

  local blockName = 'zhCN_gtutorial_createprocess'
  local blockSize = 256
  local ok, block = checkedCall(function() return allocateSharedMemoryLocal(blockName, blockSize) end)
  if not ok or type(block) ~= 'number' or block == 0 then
    return false, 'allocateSharedMemoryLocal failed'
  end

  zeroLocalMemory(block, blockSize)
  local startupInfo = block
  local processInfo = block + 128
  if not writeSucceeded(writeIntegerLocal, startupInfo, getStartupInfoWSize()) then
    return false, 'write STARTUPINFO failed'
  end

  local currentDirectory = getFolderFromPath(path) or 0
  if currentDirectory ~= 0 then
    currentDirectory = { type = 4, value = currentDirectory }
  end

  local result
  ok, result = checkedCall(function()
    return executeCodeLocalEx(
      createProcessW,
      { type = 4, value = path },
      0,
      0,
      0,
      0,
      CREATE_SUSPENDED,
      0,
      currentDirectory,
      startupInfo,
      processInfo
    )
  end)

  if not ok or result == nil or result == 0 then
    return false, 'CreateProcessW failed'
  end

  local localPointerSize = getLocalPointerSize()
  local readOk, hProcess = checkedCall(function() return readPointerLocal(processInfo) end)
  local readThreadOk, hThread = checkedCall(function() return readPointerLocal(processInfo + localPointerSize) end)
  local readPidOk, pid = checkedCall(function() return readIntegerLocal(processInfo + (localPointerSize * 2)) end)
  if not readOk or not readThreadOk or not readPidOk then
    resumeSuspendedThread(hThread)
    closeLocalHandle(hThread)
    closeLocalHandle(hProcess)
    return false, 'read PROCESS_INFORMATION failed'
  end
  if type(pid) ~= 'number' or pid == 0 or type(hThread) ~= 'number' or hThread == 0 then
    resumeSuspendedThread(hThread)
    closeLocalHandle(hThread)
    closeLocalHandle(hProcess)
    return false, 'invalid PROCESS_INFORMATION'
  end

  local imageBaseOk, imageBase = checkedCall(function()
    return getSuspendedProcessImageBase(hProcess, target)
  end)
  if not imageBaseOk then
    imageBase = nil
  end
  if not imageBase then
    imageBase = target.preferredImageBase
  end

  return true, {
    processHandle = hProcess,
    threadHandle = hThread,
    pid = pid,
    imageBase = imageBase,
  }
end

-- 安全读取 CE 当前打开的目标进程 ID。
local function getOpenedProcessIDSafe()
  if type(getOpenedProcessID) ~= 'function' then return nil end
  local ok, value = checkedCall(getOpenedProcessID)
  if ok and type(value) == 'number' then return value end
  return nil
end

-- 判断 CE 是否已经打开指定的图形教程进程。
local function openedProcessIs(pid, target)
  local openedPid = getOpenedProcessIDSafe()
  if openedPid == pid then return true end
  if type(openedPid) == 'number' then return false end

  local processName = rawget(_G, 'process')
  if target and type(processName) == 'string' then
    local lower = processName:lower()
    if lower:find(target.processName, 1, true) then return true end
  end

  return false
end

-- 推动 CE 消息循环，必要时刷新符号表，让 openProcess 状态稳定下来。
local function pumpCEOpenProcessMessages(pid, target, forceSymbolRefresh)
  checkedCall(function()
    if type(processMessagesPaintOnly) == 'function' then
      processMessagesPaintOnly()
    elseif type(processMessages) == 'function' then
      processMessages()
    end
  end)
  if forceSymbolRefresh and not openedProcessIs(pid, target) then
    checkedCall(function()
      if type(reinitializeSymbolhandler) == 'function' then
        reinitializeSymbolhandler(true)
      end
    end)
  end
end

-- 重试打开刚创建的教程进程，处理 CE 内部异步附加延迟。
local function openCreatedGTutorialProcess(pid, target)
  if type(openProcess) ~= 'function' then return false, 'missing openProcess' end

  local lastError = nil
  for attempt = 1, 20 do
    local ok, result = checkedCall(openProcess, pid)
    if ok and result ~= false and openedProcessIs(pid, target) then
      return true
    end
    pumpCEOpenProcessMessages(pid, target, attempt >= 3)
    if ok and result ~= false and openedProcessIs(pid, target) then
      return true
    end
    lastError = result

    if target and type(getProcessIDFromProcessName) == 'function' then
      local pidOk, foundPid = checkedCall(getProcessIDFromProcessName, target.processName)
      if pidOk and foundPid == pid then
        ok, result = checkedCall(openProcess, target.processName)
        if ok and result ~= false and openedProcessIs(pid, target) then
          return true
        end
        pumpCEOpenProcessMessages(pid, target, attempt >= 3)
        if ok and result ~= false and openedProcessIs(pid, target) then
          return true
        end
        lastError = result
      end
    end

    checkedCall(function()
      if type(sleep) == 'function' then sleep(25) end
    end)
  end

  local errorText = 'openProcess did not attach to ' .. tostring(target and target.processName or pid) ..
    ' pid=' .. tostring(pid) .. ' opened=' .. tostring(getOpenedProcessIDSafe()) ..
    ' error=' .. tostring(lastError)
  return false, errorText
end

-- 在恢复教程主线程前切换到目标进程并安装 Hook。
local function installGTutorialHookBeforeResume(pid, imageBase, target)
  target = target or getDefaultGTutorialTarget()

  local openOk, openError = openCreatedGTutorialProcess(pid, target)
  if not openOk then
    return false, openError
  end

  local installOk, installError = installGTutorialTextureHook(imageBase, target)
  if installOk then
    return true
  end

  return false, installError or 'install returned false'
end

-- 创建挂起教程进程，安装 Hook 后再恢复运行。
local function launchGTutorialWithSuspendedHook()
  local target = getDefaultGTutorialTarget()

  local path = getGTutorialExecutablePath(target)

  local ok, info = createGTutorialSuspended(path, target)
  if not ok then
    return false, info
  end

  local installCallOk, installOk, installError = checkedCall(function()
    return installGTutorialHookBeforeResume(info.pid, info.imageBase, target)
  end)

  if not installCallOk or installOk ~= true then
    local reason = installCallOk and installError or installOk
    terminateLocalProcess(info.processHandle)
    if info.threadHandle then closeLocalHandle(info.threadHandle) end
    if info.processHandle then closeLocalHandle(info.processHandle) end
    return false, reason or 'install returned false'
  end

  local resumeOk = resumeSuspendedThread(info.threadHandle)
  if not resumeOk then
    terminateLocalProcess(info.processHandle)
  end
  if info.threadHandle then closeLocalHandle(info.threadHandle) end
  if info.processHandle then closeLocalHandle(info.processHandle) end

  if installOk and not resumeOk then
    return false, 'ResumeThread failed'
  end

  return true
end

-- 安全取得主窗体上的命名组件。
local function getMainFormComponent(name)
  if not MainForm then return nil end
  if MainForm.findComponentByName then
    local ok, component = checkedCall(function() return MainForm.findComponentByName(name) end)
    if ok and component then return component end
  end
  local ok, component = checkedCall(function() return MainForm[name] end)
  if ok and component then return component end
  return nil
end

-- 兼容不同 CE/Lazarus 绑定方式设置菜单点击回调。
local function setMenuItemClick(menuItem, fn)
  if not menuItem then return false end
  local assigned = false
  if type(menuItem.setOnClick) == 'function' then
    local ok = checkedCall(function() menuItem.setOnClick(fn) end)
    assigned = assigned or ok
  end
  local ok = checkedCall(function() menuItem.OnClick = fn end)
  assigned = assigned or ok
  return assigned
end

-- 兼容不同 CE/Lazarus 绑定方式读取菜单点击回调。
local function getMenuItemClick(menuItem)
  if not menuItem then return nil end
  local ok, value = checkedCall(function() return menuItem.OnClick end)
  if ok and type(value) == 'function' then return value end
  if type(menuItem.getOnClick) == 'function' then
    ok, value = checkedCall(function() return menuItem.getOnClick() end)
    if ok and type(value) == 'function' then return value end
  end
  return nil
end

-- 安全取得组件 Name。
local function getComponentName(component)
  if not component then return nil end
  local ok, value = checkedCall(function() return component.Name end)
  if ok and value then return tostring(value) end
  if type(component.getName) == 'function' then
    ok, value = checkedCall(function() return component.getName() end)
    if ok and value then return tostring(value) end
  end
  return nil
end

-- 安全取得菜单项 Caption。
local function getMenuItemCaption(menuItem)
  if not menuItem then return nil end
  local ok, value = checkedCall(function() return menuItem.Caption end)
  if ok and value then return tostring(value) end
  if type(menuItem.getCaption) == 'function' then
    ok, value = checkedCall(function() return menuItem.getCaption() end)
    if ok and value then return tostring(value) end
  end
  return nil
end

-- 安全取得菜单项子项数量。
local function getMenuItemCount(menuItem)
  if not menuItem then return 0 end
  local ok, value = checkedCall(function() return menuItem.Count end)
  if ok and type(value) == 'number' then return value end
  if type(menuItem.getCount) == 'function' then
    ok, value = checkedCall(function() return menuItem.getCount() end)
    if ok and type(value) == 'number' then return value end
  end
  return 0
end

-- 安全取得菜单项的指定子项。
local function getMenuItemChild(menuItem, index)
  local ok, value = checkedCall(function() return menuItem[index] end)
  if ok and value then return value end
  ok, value = checkedCall(function() return menuItem.Item[index] end)
  if ok and value then return value end
  if type(menuItem.getItem) == 'function' then
    ok, value = checkedCall(function() return menuItem.getItem(index) end)
    if ok and value then return value end
  end
  return nil
end

-- 去重收集可能的图形教程菜单项。
local function addGTutorialMenuCandidate(items, seen, item)
  if not item then return end
  local key = tostring(item)
  if seen[key] then return end

  local name = getComponentName(item)
  local caption = getMenuItemCaption(item)
  local lowerCaption = type(caption) == 'string' and caption:lower() or ''
  if name == 'MenuItem15'
    or lowerCaption:find('tutorial games', 1, true)
    or lowerCaption:find('作弊教学', 1, true)
  then
    seen[key] = true
    items[#items + 1] = item
  end
end

-- 在主菜单树中查找图形教程入口菜单项。
local function collectGTutorialMenuItems()
  local items = {}
  local seen = {}
  addGTutorialMenuCandidate(items, seen, getMainFormComponent('MenuItem15'))

  local menu = nil
  if MainForm then
    local ok, value = checkedCall(function() return MainForm.Menu end)
    if ok then menu = value end
    if not menu and type(MainForm.getMenu) == 'function' then
      ok, value = checkedCall(function() return MainForm.getMenu() end)
      if ok then menu = value end
    end
  end

  local root = nil
  if menu then
    local ok, value = checkedCall(function() return menu.Items end)
    if ok then root = value end
    if not root and type(menu.getItems) == 'function' then
      ok, value = checkedCall(function() return menu.getItems() end)
      if ok then root = value end
    end
  end

  local walked = {}
  -- 递归遍历菜单树，兼容菜单项名称或标题变化。
  local function walk(item)
    if not item then return end
    local key = tostring(item)
    if walked[key] then return end
    walked[key] = true
    addGTutorialMenuCandidate(items, seen, item)
    local count = getMenuItemCount(item)
    for i = 0, count - 1 do
      walk(getMenuItemChild(item, i))
    end
  end
  walk(root)

  return items
end

-- 包装图形教程菜单点击，优先走挂起启动和预安装 Hook 流程。
local function installGTutorialMenuClickHook()
  if not zhCNNativeHooksEnabled() then return false end
  local menuItems = collectGTutorialMenuItems()
  if #menuItems == 0 then
    return false
  end

  if type(STATE.originalGTutorialMenuClicks) ~= 'table' then
    STATE.originalGTutorialMenuClicks = {}
  end

  local installed = 0
  for _, menuItem in ipairs(menuItems) do
    local key = tostring(menuItem)
    if not STATE.originalGTutorialMenuClicks[key] then
      STATE.originalGTutorialMenuClicks[key] = getMenuItemClick(menuItem) or false
    end

    local previous = STATE.originalGTutorialMenuClicks[key]
    -- 菜单点击包装：优先启动已预装 Hook 的教程，失败时回退原点击逻辑。
    local wrapper = function(sender, ...)
      local callOk, launchOk = checkedCall(function() return launchGTutorialWithSuspendedHook() end)
      if callOk and launchOk then return end

      if previous then
        checkedCall(previous, sender, ...)
      end
    end

    if setMenuItemClick(menuItem, wrapper) then
      installed = installed + 1
    end
  end

  STATE.menuHookInstalled = installed > 0
  if installed > 0 then
    return true
  end

  return false
end

-- 主菜单尚未创建时定时重试安装图形教程菜单 Hook。
local function installGTutorialMenuHookRetry()
  if not zhCNNativeHooksEnabled() or STATE.menuHookInstalled == true or type(createTimer) ~= 'function' then return end

  checkedCall(function()
    local attempts = 0
    local timer = createTimer(MainForm or nil, false)
    timer.Interval = 100
    -- 定时器回调：等待 CE 菜单创建完成后安装 Hook，并在完成或超时后销毁。
    timer.OnTimer = function(t)
      attempts = attempts + 1
      if installGTutorialMenuClickHook() or attempts >= 50 then
        checkedCall(function() t.destroy() end)
      end
    end
    timer.Enabled = true
  end)
end

if not installGTutorialMenuClickHook() then
  installGTutorialMenuHookRetry()
end

_G.__zhCNGTutorialTranslateLoaded = true
