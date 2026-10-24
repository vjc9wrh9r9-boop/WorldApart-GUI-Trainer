-- Cheat Engine 7.7 zh_CN 启动入口。

local loadErrors = _G.__zhCNScriptLoadErrors
if type(loadErrors) ~= 'table' then
  loadErrors = {}
  _G.__zhCNScriptLoadErrors = loadErrors
else
  for key in pairs(loadErrors) do
    loadErrors[key] = nil
  end
end

-- 共享工具函数
local zhCNUtil = _G.zhCNUtil or {}
_G.zhCNUtil = zhCNUtil

if type(zhCNUtil.checkedCall) ~= 'function' then
  --- pcall 包装，异常时返回 false 而非中断。
  zhCNUtil.checkedCall = function(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return true, a, b, c, d end
    return false, nil
  end
end

if type(zhCNUtil.joinPath) ~= 'function' then
  --- 拼接目录和文件名。
  zhCNUtil.joinPath = function(folder, fileName)
    if type(folder) ~= 'string' or folder == '' then return fileName end
    local last = folder:sub(-1)
    if last == '\\' or last == '/' then return folder .. fileName end
    return folder .. '\\' .. fileName
  end
end

if type(zhCNUtil.nativeHooksEnabled) ~= 'function' then
  --- 判断是否启用原生 Hook。
  zhCNUtil.nativeHooksEnabled = function(moduleFlag)
    if _G.zhCNEnableNativeHooks == false then return false end
    if moduleFlag and _G[moduleFlag] == false then return false end
    return true
  end
end

local function joinPath(folder, fileName)
  return zhCNUtil.joinPath(folder, fileName)
end

-- 加载 zh_CN 子脚本（.PO 文件由 CE 自动加载）。
local function loadZhCNScript(fileName)
  if type(getTranslationFolder) ~= 'function' then return false end

  local path = joinPath(getTranslationFolder(), fileName)
  if not path then return false end

  local ok, err = pcall(dofile, path)
  if not ok then
    loadErrors[#loadErrors + 1] = {
      file = fileName,
      path = path,
      error = tostring(err),
    }
    return false
  end

  return true
end

loadZhCNScript('ui_translate.lua')
loadZhCNScript('opcode_desc.lua')
loadZhCNScript('formdesigner_translate.lua')
loadZhCNScript('gtutorial_translate.lua')

-- 输出加载错误到调试日志。
if #loadErrors > 0 and type(outputDebugString) == 'function' then
  for i = 1, #loadErrors do
    local e = loadErrors[i]
    pcall(outputDebugString, string.format('[zhCN] %s load failed: %s', e.file or '?', e.error or '?'))
  end
end
