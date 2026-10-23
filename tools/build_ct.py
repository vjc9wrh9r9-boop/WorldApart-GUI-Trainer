# -*- coding: utf-8 -*-
"""给 CT 注入 BWF 无界面 Lua 模式"""
import sys, os

_DEF_CT = r"E:/360MoveData/Users/新建文件夹/不问凡尘/不问凡尘-缤纷颜色-bilibili-2026-10-17更V1.CT"
CT_SRC = os.environ.get('CT_SRC') or _DEF_CT
CT_OUT = sys.argv[1] if len(sys.argv) > 1 else "build/runtime/BWF_不问凡尘_V1.CT"

LUA = r"""
-- ================= BWF 启动器集成（无界面模式 v2） =================
local BWF = {}
BWF.tmp    = os.getenv('TEMP') or os.getenv('TMP') or 'C:/Windows/Temp'
BWF.cmd    = BWF.tmp .. '/bwf_cmd.txt'
BWF.status = BWF.tmp .. '/bwf_status.txt'
BWF.log    = BWF.tmp .. '/bwf_lua.log'
BWF.lastRaw = ''
BWF.lastSeq = 0

BWF.att = 0
local function report(s)
  local f = io.open(BWF.status, 'w')
  if f then f:write(string.format('S|att=%d|%s', BWF.att, s)) f:close() end
end

local function logln(s)
  local f = io.open(BWF.log, 'a')
  if f then f:write(os.date('[%H:%M:%S] ') .. s .. '\n') f:close() end
end

local function getAL()
  local a = _G.addresslist
  if not a then
    local ok, v = pcall(getAddressList)
    if ok then a = v end
  end
  return a
end

local function hideAll()
  pcall(function() hideAllCEWindows() end)
  pcall(function()
    local n = getFormCount()
    if n then
      for i = 0, n - 1 do
        local f = getForm(i)
        if f then pcall(function() f.Visible = false end) end
      end
    end
  end)
end

local function handleLine(line)
  local p = {}
  for x in string.gmatch(line, '[^|]+') do p[#p + 1] = x end
  if #p == 0 then return end
  local seq = tonumber(p[#p])
  if seq and not (seq > BWF.lastSeq) then return end
  if seq then BWF.lastSeq = seq end
  local op = p[1]
  if op == 'PING' then report('PONG') return end
  if op == 'PID' then
    local pid = tonumber(p[2])
    if pid and pid > 0 then
      local ok2, e2 = pcall(function() openProcess(pid) end)
      if ok2 then
        BWF.att = pid
        report('ATTACHED|' .. pid)
        logln('attached pid=' .. pid)
      else
        report('ERR|open process: ' .. tostring(e2))
      end
    end
    return
  end
  if op == 'LOAD' then
    local fn = tostring(p[2])
    if fn and fn ~= '' then
      local la = os.getenv('LOCALAPPDATA') or 'C:'
      local full = la .. [[\\BWFMod\\runtime\\]] .. fn
      local okl, e = pcall(function() loadTable(full) end)
      if okl then
        report('LOADED|' .. fn)
        logln('loadTable ' .. fn)
      else
        report('ERR|loadTable: ' .. tostring(e))
      end
    end
    return
  end
  if op == 'WHO' then
    local pidnow = 0
    pcall(function() pidnow = getOpenedProcessID() end)
    report('WHO|' .. tostring(pidnow))
    return
  end
  if op == 'OFFALL' then
    local list3 = getAL()
    local n3 = 0
    if list3 then
      local m3 = list3.Count
      for i = 0, m3 - 1 do
        local ok6, mr6 = pcall(function() return list3.getMemoryRecord(i) end)
        if ok6 and mr6 then
          local act = false
          pcall(function() act = mr6.Active end)
          if act then
            pcall(function() mr6.Active = false end)
            n3 = n3 + 1
          end
        end
      end
    end
    report('OFFALL|' .. n3)
    return
  end
  if op == 'DUMP' then
    local list2 = getAL()
    if not list2 then report('ERR|no addresslist') return end
    local lines = {}
    local n = list2.Count
    for i = 0, n - 1 do
      local ok5, mr5 = pcall(function() return list2.getMemoryRecord(i) end)
      if ok5 and mr5 then
        local okv, vv = pcall(function() return mr5.Value end)
        lines[#lines + 1] = tostring(mr5.ID) .. '\t' .. tostring(mr5.Description) ..
                            '\t' .. tostring(mr5.Active) .. '\t' ..
                            (okv and tostring(vv) or 'READERR')
      end
    end
    local df = io.open(BWF.tmp .. '/bwf_dump.txt', 'w')
    if df then df:write(table.concat(lines, '\r\n')) df:close() end
    report('DUMPED|' .. #lines)
    return
  end
  local id = tonumber(p[2])
  if not id then report('ERR|bad id') return end
  local list = getAL()
  if not list then report('ERR|no addresslist') return end
  local mr = list.getMemoryRecordByID(id)
  if not mr then report('ERR|memrec ' .. id .. ' missing') return end
  if op == 'ON' then
    local ok3, e3 = pcall(function() mr.Active = true end)
    if ok3 then report('OK|' .. id .. '|ON') logln('ON ' .. id)
    else report('ERR|' .. tostring(e3)) logln('ON-FAIL ' .. id .. ' ' .. tostring(e3)) end
  elseif op == 'OFF' then
    pcall(function() mr.Active = false end)
    report('OK|' .. id .. '|OFF')
  elseif op == 'SET' then
    local v = p[3] and tostring(p[3]) or '0'
    local ok4, e4 = pcall(function() mr.Value = v end)
    if ok4 then
      report('OK|' .. id .. '|' .. tostring(mr.Value))
      logln('SET ' .. id .. ' = ' .. tostring(mr.Value))
    else
      report('ERR|' .. tostring(e4))
      logln('SET-FAIL ' .. id .. ' : ' .. tostring(e4))
    end
  elseif op == 'GET' then
    local v = '?'
    pcall(function() v = mr.Value end)
    report('VAL|' .. id .. '|' .. tostring(v))
  end
end

hideAll()
logln('BOOT v2')

local t = createTimer(nil, true)
t.Enabled = true
t.Interval = 200
t.OnTimer = function()
  hideAll()
  local ok, err = pcall(function()
    local f = io.open(BWF.cmd, 'r')
    if not f then return end
    local s = f:read('*a')
    f:close()
    if not s or s == BWF.lastRaw then return end
    BWF.lastRaw = s
    for line in string.gmatch(s, '[^\r\n]+') do
      handleLine(line)
    end
  end)
  if not ok then
    report('LUAERR|' .. tostring(err))
    logln('LUAERR ' .. tostring(err))
  end
end
"""

# ---------- 去广告：删除 B 站视频 / 署名等广告条目 ----------
AD_MARKS = ('哔哩哔哩', '缤纷颜色', '配套演示视频', 'bilibili.com', 'bilibili',
            'BV1beJY6oExx', 'ShellExecute')


def strip_ads(xml):
    """整块删除含广告标记的 <CheatEntry>（按深度匹配，避免破坏嵌套结构）"""
    out, i, removed = [], 0, []
    while True:
        s = xml.find('<CheatEntry>', i)
        if s < 0:
            out.append(xml[i:])
            break
        out.append(xml[i:s])
        depth, j, end = 0, s, -1
        while True:
            a = xml.find('<CheatEntry>', j)
            b = xml.find('</CheatEntry>', j)
            if b < 0:
                break
            if 0 <= a < b:
                depth += 1
                j = a + len('<CheatEntry>')
            else:
                depth -= 1
                j = b + len('</CheatEntry>')
                if depth == 0:
                    end = j
                    break
        if end < 0:
            out.append(xml[s:])
            break
        block = xml[s:end]
        if any(m in block for m in AD_MARKS):
            desc = ''
            k = block.find('<Description>')
            if k >= 0:
                desc = block[k + 13:block.find('</Description>', k)][:40]
            removed.append(desc)
            while end < len(xml) and xml[end] in '\r\n':
                end += 1
            i = end
        else:
            out.append(block)
            i = end
    return ''.join(out), removed


data = open(CT_SRC, encoding='utf-8').read()
data, ads = strip_ads(data)
print("去广告条目 %d 个:" % len(ads))
for a in ads:
    print("   -", a)
assert len(ads) == 3, "广告条目数量异常，检查 CT 是否改版"
assert 'bilibili' not in data.lower()
assert 'ShellExecute' not in data
assert "<LuaScript>" not in data
# 在 </UserdefinedSymbols> 后插入 LuaScript 节点
needle = "<UserdefinedSymbols/>"
assert needle in data
repl = "<UserdefinedSymbols/>\r\n  <LuaScript>\r\n" + LUA + "\r\n  </LuaScript>\r\n"
data = data.replace(needle, repl, 1)
open(CT_OUT, 'w', encoding='utf-8').write(data)
print("written:", CT_OUT, os.path.getsize(CT_OUT))
