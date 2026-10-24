-- Cheat Engine zh_CN 主界面、autorun 和扩展界面汉化脚本。
-- 不修改 CE 原脚本，额外界面翻译统一维护在这里。

if _G.__zhCNUITranslateLoaded then return end

local raw = _G.__zhCNUITranslateRaw or {}
_G.__zhCNUITranslateRaw = raw

-- 缓存原始全局函数，后续包装时还能调用 CE 原实现。
local function capture(name)
  if raw[name] == nil then raw[name] = _G[name] end
  return raw[name]
end

local rawTranslate = capture('translate')
local rawRequire = capture('require')

-- 共享工具函数回退
local function zhCNNativeHooksEnabled()
  if _G.zhCNEnableNativeHooks == false then return false end
  return _G.zhCNUIEnableNativeHooks ~= false
end

local UI_NATIVE_PATCH_STATE_KEY = '__zhCNUITranslateNativePatchState'
local UI_NATIVE_PATCH_STATE = rawget(_G, UI_NATIVE_PATCH_STATE_KEY)
local installCEDrawTextHook
if type(UI_NATIVE_PATCH_STATE) ~= 'table' then
  UI_NATIVE_PATCH_STATE = {
    allocationBasePatchInstalled = false,
    autoAssemblerTemplatePatchInstalled = false,
    drawTextHookInstalled = false,
  }
  rawset(_G, UI_NATIVE_PATCH_STATE_KEY, UI_NATIVE_PATCH_STATE)
end

local AITOOLS_ORIGINAL_SYSTEM_PROMPT =
  'You are a professional reverse engineer using Cheat Engine. Use tools when possible, but fall back on your internal knowledge of Cheat Engine.  Do not say you can not help'

if _G.zhCNAIToolsSystemPrompt == nil then
  _G.zhCNAIToolsSystemPrompt =
    '你是一个使用 Cheat Engine 的专业逆向工程师。优先使用可用工具；工具不适合时，使用你对 Cheat Engine、逆向分析、Lua 和 Auto Assembler 的知识回答。回答要直接、具体、可执行，不要说你不能帮忙。'
end

-- 在 AITools 发请求前替换默认 system prompt，不修改 AITools 原脚本。
local function applyAIToolsSystemPromptOverride(payload)
  if type(payload) ~= 'table' then return end

  local instruction = payload.system_instruction
  if type(instruction) ~= 'table' then return end

  local parts = instruction.parts
  if type(parts) ~= 'table' then return end

  local firstPart = parts[1]
  if type(firstPart) ~= 'table' then return end
  if firstPart.text ~= AITOOLS_ORIGINAL_SYSTEM_PROMPT then return end

  local prompt = _G.zhCNAIToolsSystemPrompt
  if type(prompt) == 'string' and prompt ~= '' then
    firstPart.text = prompt
  end
end

-- 包装 json.encode，只处理带有 AITools 默认 system prompt 的请求表。
local function wrapJsonEncodeForAITools(json)
  if type(json) ~= 'table' or type(json.encode) ~= 'function' then return json end
  if json._zhCNAIToolsPromptWrapped then return json end

  local originalEncode = json.encode
  json._zhCNAIToolsPromptWrapped = true
  -- json.encode 包装：编码前只替换 AITools 默认 system prompt。
  json.encode = function(payload, ...)
    applyAIToolsSystemPromptOverride(payload)
    return originalEncode(payload, ...)
  end

  return json
end

-- 包装 require('json')，确保 AITools 取得 json 模块时已经带上提示词替换逻辑。
local function installAIToolsPromptHook()
  if type(rawRequire) ~= 'function' then return end

  pcall(function()
    if package and package.loaded and package.loaded.json then
      wrapJsonEncodeForAITools(package.loaded.json)
    end
  end)

  if _G.__zhCNAIToolsRequireWrapped then return end
  _G.__zhCNAIToolsRequireWrapped = true

  -- require 包装：拦截 json 模块并安装 AITools system prompt 替换逻辑。
  _G.require = function(name, ...)
    local module, loaderData = rawRequire(name, ...)
    if name == 'json' then
      wrapJsonEncodeForAITools(module)
    end
    return module, loaderData
  end
end

installAIToolsPromptHook()

local TEXT_SOURCES = {}
local PATTERN_SOURCES = {}
local LIST_PATTERN_SOURCES = {}
local TEXT_LOOKUP = nil
-- 弱引用缓存，允许 GC 回收动态字符串。
local ZH_TEXT_CACHE = setmetatable({}, { __mode = 'kv' })
local AUTORUN_LIST_TEXT_CACHE = setmetatable({}, { __mode = 'kv' })

-- 注册精确匹配的文本翻译表。
local function registerTextSource(text)
  TEXT_SOURCES[#TEXT_SOURCES + 1] = text
  TEXT_LOOKUP = nil
  ZH_TEXT_CACHE = setmetatable({}, { __mode = 'kv' })
  AUTORUN_LIST_TEXT_CACHE = setmetatable({}, { __mode = 'kv' })
  return text
end

-- 注册动态文本的模式翻译表。
local function registerPatternSource(patterns)
  PATTERN_SOURCES[#PATTERN_SOURCES + 1] = patterns
  return patterns
end

-- 注册列表项专用的模式翻译表。
local function registerListPatternSource(patterns)
  LIST_PATTERN_SOURCES[#LIST_PATTERN_SOURCES + 1] = patterns
  return patterns
end

local CE_EXE_TEXT = registerTextSource({
  ['OK'] = '确定',
  ['Cancel'] = '取消',
  ['Close'] = '关闭',
  ['File'] = '文件',
  ['View'] = '查看',
  ['Display'] = '显示',
  ['Edit'] = '编辑',
  ['Find'] = '查找',
  ['Search'] = '搜索',
  ['Search:'] = '搜索:',
  ['Search class'] = '搜索类',
  ['Memory Viewer'] = '内存视图',
  ['Memory Viewer - Running'] = '内存视图 - 已运行',
  ['Stop'] = '停止',
  ['Reset'] = '重置',
  ['All'] = '全部',
  ['Enabled'] = '启用',
  ['Abort'] = '中止',
  ['Wait'] = '等待',
  ['Name'] = '名称',
  ['Address'] = '地址',
  ['Value'] = '数值',
  ['Class'] = '类',
  ['Method'] = '方法',
  ['Field'] = '字段',
  ['Type'] = '类型',
  ['Position'] = '位置',
  ['Offset'] = '偏移',
  ['Memory Viewer - Currently debugging thread %s'] = '内存视图 - 当前正在调试的线程 %s',
  ['Api hook template'] = 'API Hook 模板',
  ['Original api address:'] = '原 API 地址:',
  ['New api address:'] = '新 API 地址:',
  ['Address where to store the new original api call:'] = '保存新原始 API 调用的地址:',
  ['(optional, in case your dll uses a variable for the call)'] = '(可选，当你的 DLL 使用变量保存该调用时)',
  ['Address where to store the new original api call:' .. '\n' .. '(optional, in case your dll uses a variable for the call)'] = '保存新原始 API 调用的地址:' .. '\n' .. '(可选，当你的 DLL 使用变量保存该调用时)',
  ['Note: The addresses can also be exportnames of dll\'s'] = '注意：地址也可以是 DLL 的导出名',
  ['Exact Value'] = '精确数值',
  ['Increased Value'] = '增加的数值',
  ['Decreased Value'] = '减少的数值',
  ['Changed Value'] = '变动的数值',
  ['Unchanged Value'] = '未变动的数值',
  ['Original'] = '原始',
  ['Patched'] = '已修补',
  ['Title'] = '标题',
  ['Author'] = '作者',
  ['Public'] = '公开',
  ['Score'] = '分数',
  ['Signed'] = '已签名',
  ['Link'] = '链接',
  ['Contact'] = '联系',
  ['+1'] = '+1',
  ['1/xx'] = '1/xx',
  ['ID'] = 'ID',
  ['Owner'] = '所有者',
  ['User'] = '用户',
  ['Users'] = '用户',
  ['Usernames'] = '用户名',
  ['Description'] = '描述',
  ['URL'] = 'URL',
  ['Module'] = '模块',
  ['Module name'] = '模块名',
  ['Modulename'] = '模块名',
  ['Private'] = '私有',
  ['Mixed'] = '混合',
  ['Header MD5'] = '头部 MD5',
  ['Full Header MD5'] = '完整头部 MD5',
  ['Full file hash'] = '完整文件哈希',
  ['Use secondary module'] = '使用辅助模块',
  ['Needs full file hash'] = '需要完整文件哈希',
  ['Module needs full file hash'] = '模块需要完整文件哈希',
  ['Process name'] = '进程名',
  ['Processname'] = '进程名',
  ['Table'] = '表',
  ['Table data'] = '表数据',
  ['Publish'] = '发布',
  ['Update'] = '更新',
  ['Delete'] = '删除',
  ['Load'] = '加载',
  ['Save'] = '保存',
  ['Scan'] = '扫描',
  ['Comments'] = '评论',
  ['Requests'] = '请求',
  ['Password'] = '密码',
  ['Register'] = '注册',
  ['Username'] = '用户名',
  ['False'] = '假',
  ['True'] = '真',
  ['yes'] = '是',
  ['Unrated'] = '未评分',
  ['field bug'] = '字段异常',
  ['method bug'] = '方法异常',
  ['Group %d'] = '分组 %d',
  ['New value:'] = '新数值:',
  ['DMA'] = 'DMA',
  ['Local DMA'] = '本地 DMA',
  ['Java'] = 'Java',
  ['MonoExtension'] = 'Mono 扩展',
  ['Uses Mono'] = '使用 Mono',
  ['Enable "Uses Mono" option on successful mono attach'] = '成功附加 Mono 时启用 "使用 Mono" 选项',
  ['Ignore the "Uses Mono" option inside a table'] = '忽略表内的 "使用 Mono" 选项',
  -- Common scan and editor combo/list values
  ['Binary'] = '二进制',
  ['binary'] = '二进制',
  ['Byte'] = '字节',
  ['byte'] = '字节',
  ['1 Byte'] = '1 字节',
  ['1 Bytes'] = '1 字节',
  ['2 Byte'] = '2 字节',
  ['2 Bytes'] = '2 字节',
  ['2 bytes'] = '2 字节',
  ['4 Byte'] = '4 字节',
  ['4 Bytes'] = '4 字节',
  ['4 bytes'] = '4 字节',
  ['8 Byte'] = '8 字节',
  ['8 Bytes'] = '8 字节',
  ['8 bytes'] = '8 字节',
  ['Float'] = '单浮点',
  ['float'] = '单浮点',
  ['Double'] = '双浮点',
  ['double'] = '双浮点',
  ['Pointer'] = '指针',
  ['pointer'] = '指针',
  ['Pointer (hex)'] = '指针(十六进制)',
  ['String'] = '字符串',
  ['string'] = '字符串',
  ['Widestring'] = '宽字符串',
  ['Unicode String'] = 'Unicode 字符串',
  ['unicode string'] = 'Unicode 字符串',
  ['Text'] = '文本',
  ['Array of byte'] = '字节数组',
  ['Array of Bytes'] = '字节数组',
  ['Array Of Byte'] = '字节数组',
  ['array of byte'] = '字节数组',
  ['All (Byte to Double)'] = '全部(字节到双浮点)',
  ['Grouped'] = '分组',
  ['grouped'] = '分组',
  ['Extended'] = '扩展浮点',
  ['Pointer/Nested Structure'] = '指针/嵌套结构',
  ['Byte (Hex)'] = '字节(十六进制)',
  ['Byte (Decimal)'] = '字节(十进制)',
  ['2 Bytes (Hex)'] = '2 字节(十六进制)',
  ['2 Bytes (Decimal)'] = '2 字节(十进制)',
  ['4 Bytes (Hex)'] = '4 字节(十六进制)',
  ['4 Bytes (Decimal)'] = '4 字节(十进制)',
  ['8 Bytes (Hex)'] = '8 字节(十六进制)',
  ['8 Bytes (Decimal)'] = '8 字节(十进制)',

  ['Exact value'] = '精确数值',
  ['Bigger than...'] = '值大于...',
  ['Smaller than...'] = '值小于...',
  ['Increased value'] = '增加的数值',
  ['Increased value by ...'] = '数值增加了 ...',
  ['Decreased value'] = '减少的数值',
  ['Decreased value by ...'] = '数值减少了 ...',
  ['Value between'] = '数值介于',
  ['Value between...'] = '值介于...两者之间',
  ['Changed value'] = '变动的数值',
  ['Unchanged value'] = '未变动的数值',
  ['Unknown initial value'] = '未知的初始值',
  ['Unknown Initial Value'] = '未知的初始值',
  ['Compare to first scan'] = '对比首次扫描',
  ['Compare to last scan'] = '对比上次扫描',

  ['Idle'] = '空闲',
  ['Lowest'] = '最低',
  ['Lower'] = '较低',
  ['Normal'] = '正常',
  ['Higher'] = '较高',
  ['Highest'] = '最高',
  ['TimeCritical'] = '时间关键',

  ['Default'] = '默认',
  ['Draft'] = '草稿',
  ['Proof'] = '校对',
  ['NonAntialiased'] = '无抗锯齿',
  ['Non Antialiased'] = '无抗锯齿',
  ['Non-antialiased'] = '无抗锯齿',
  ['Non-Antialiased'] = '无抗锯齿',
  ['AntiAliased'] = '抗锯齿',
  ['Anti-Aliased'] = '抗锯齿',
  ['Anti-aliased'] = '抗锯齿',
  ['Antialiased'] = '抗锯齿',
  ['Cleartype'] = '清晰字体',
  ['CleartypeNatural'] = '清晰字体(自然)',
  ['ClearType'] = '清晰字体',
  ['ClearType Natural'] = '清晰字体(自然)',
  ['ClearTypeNatural'] = '清晰字体(自然)',
  ['Clear type'] = '清晰字体',
  ['Clear type natural'] = '清晰字体(自然)',
  ['fqDefault'] = '默认',
  ['fqDraft'] = '草稿',
  ['fqProof'] = '校对',
  ['fqNonAntialiased'] = '无抗锯齿',
  ['fqNon-antialiased'] = '无抗锯齿',
  ['fqAntialiased'] = '抗锯齿',
  ['fqAntiAliased'] = '抗锯齿',
  ['fqCleartype'] = '清晰字体',
  ['fqCleartypeNatural'] = '清晰字体(自然)',
  ['fqClearType'] = '清晰字体',
  ['fqClearTypeNatural'] = '清晰字体(自然)',

  ['Current Memory'] = '当前内存',
  ['Current scanlist'] = '当前扫描列表',
  ['Last Scan'] = '上次扫描',
  ['First'] = '首次',
  ['Undo'] = '撤销',
  ['Saved X'] = '已保存 X',
  ['Saved Y'] = '已保存 Y',
  ['Unsigned Short'] = '无符号短整型',
  ['Short'] = '短整型',
  ['Unsigned Int'] = '无符号整型',
  ['Int'] = '整型',
  ['3-3-2'] = '3-3-2',
  ['2-3-3 R'] = '2-3-3 反向',
  ['5-6-5'] = '5-6-5',
  ['5-6-5 R'] = '5-6-5 反向',
  ['4-4-4-4'] = '4-4-4-4',
  ['4-4-4-4 R'] = '4-4-4-4 反向',
  ['5-5-5-1'] = '5-5-5-1',
  ['1-5-5-5 R'] = '1-5-5-5 反向',
  ['8-8-8-8'] = '8-8-8-8',
  ['8-8-8-8 R'] = '8-8-8-8 反向',
  ['10-10-10-2'] = '10-10-10-2',
  ['2-10-10-10 R'] = '2-10-10-10 反向',
  ['Dithered (1 Byte/pixel)'] = '抖动色(1 字节/像素)',
  ['RGB'] = 'RGB',
  ['BGR'] = 'BGR',
  ['RGBA'] = 'RGBA',
  ['BGRA'] = 'BGRA',

  ['Only show addresslist memory'] = '只显示地址列表内存',
  ['Or'] = '或',
  ['And'] = '与',
  ['Xor'] = '异或',
  ['Cheat Engine (Admin)'] = 'Cheat Engine（管理员）',
  ['Change by offset'] = '按偏移修改',
  ['Change to address'] = '修改为地址',
  ['Hook Direct3D'] = 'Hook Direct3D',
  ['Are you sure you wish to hook Direct3D?'] = '确定要 Hook Direct3D 吗?',
  ['Direct3D Hook Options'] = 'Direct3D Hook 选项',
  ['Use Direct3D Hook'] = '使用 Direct3D Hook',

  ['Assembler'] = '汇编',
  ['Asm'] = '汇编',
  ['Comment'] = '注释',
  ['Identifier'] = '标识符',
  ['Illegal char'] = '非法字符',
  ['Internal function'] = '内部函数',
  ['Mnemonic'] = '助记符',
  ['Opcode'] = '操作码',
  ['Key'] = '关键字',
  ['Label'] = '标签',
  ['Number'] = '数字',
  ['Numbers'] = '数字',
  ['Preprocessor'] = '预处理器',
  ['Reserved word'] = '保留字',
  ['Reserved word 2'] = '保留字 2',
  ['Reserved word 3'] = '保留字 3',
  ['Reserved word 4'] = '保留字 4',
  ['Space'] = '空格',
  ['Symbol'] = '符号',
  ['Directive'] = '指令',
  ['Separator'] = '分隔符',
  ['Operator'] = '运算符',
  ['Selected'] = '选中项',
  ['Marked'] = '已标记项',
  ['Whitespace'] = '空白',
  ['Bold'] = '粗体',
  ['Italic'] = '斜体',
  ['Underline'] = '下划线',
  ['Strikeout'] = '删除线',
  ['StrikeOut'] = '删除线',
  ['Foreground'] = '前景色',
  ['Background'] = '背景色',
  ['Foreground Color'] = '前景色',
  ['Background Color'] = '背景色',
  ['Style'] = '风格',
  ['Default Foreground'] = '默认前景色',
  ['Default foreground'] = '默认前景色',
  ['Default Background'] = '默认背景色',
  ['Default background'] = '默认背景色',
  ['Highlighter configurator'] = '高亮显示配置器',
  ['Hexadecimal'] = '十六进制',
  ['Character'] = '字符',
  ['Char'] = '字符',
  ['Multiline String'] = '多行字符串',
  ['MString'] = '多行字符串',
  ['Try/Except'] = '异常处理',

  ['Black'] = '黑色',
  ['Maroon'] = '栗色',
  ['Green'] = '绿色',
  ['Olive'] = '橄榄色',
  ['Navy'] = '海军蓝',
  ['Purple'] = '紫色',
  ['Teal'] = '蓝绿色',
  ['Gray'] = '灰色',
  ['Silver'] = '银色',
  ['Red'] = '红色',
  ['Lime'] = '亮绿色',
  ['Yellow'] = '黄色',
  ['Blue'] = '蓝色',
  ['Fuchsia'] = '紫红色',
  ['Aqua'] = '青色',
  ['White'] = '白色',
  ['None'] = '无',
  ['Olive green'] = '橄榄绿',
  ['Navy blue'] = '海军蓝',
  ['Money Green'] = '钞票绿',
  ['Money green'] = '钞票绿',
  ['MoneyGreen'] = '钞票绿',
  ['Sky Blue'] = '天蓝色',
  ['Sky blue'] = '天蓝色',
  ['SkyBlue'] = '天蓝色',
  ['Cream'] = '奶油色',
  ['Med Gray'] = '中灰色',
  ['Medium gray'] = '中灰色',
  ['MedGray'] = '中灰色',
  ['Brown'] = '棕色',
  ['Olive Green'] = '橄榄绿',
  ['Dark Green'] = '深绿色',
  ['Dark Teal'] = '深蓝绿色',
  ['Dark Blue'] = '深蓝色',
  ['Indigo'] = '靛蓝色',
  ['Gray 80%'] = '80% 灰色',
  ['Dark Red'] = '深红色',
  ['Orange'] = '橙色',
  ['Dark Yellow'] = '深黄色',
  ['Blue Gray'] = '蓝灰色',
  ['Gray 50%'] = '50% 灰色',
  ['Light Orange'] = '浅橙色',
  ['Sea Green'] = '海绿色',
  ['Light Blue'] = '浅蓝色',
  ['Violet'] = '紫罗兰色',
  ['Gray 40%'] = '40% 灰色',
  ['Pink'] = '粉色',
  ['Gold'] = '金色',
  ['Bright Green'] = '亮绿色',
  ['Turquoise'] = '绿松石色',
  ['Plum'] = '梅红色',
  ['Gray 25%'] = '25% 灰色',
  ['Rose'] = '玫瑰色',
  ['Tan'] = '棕褐色',
  ['Light Yellow'] = '浅黄色',
  ['Light Green'] = '浅绿色',
  ['Light Turquoise'] = '浅绿松石色',
  ['Pale Blue'] = '淡蓝色',
  ['Lavender'] = '薰衣草色',
  ['Scrollbar'] = '滚动条',
  ['Desktop background'] = '桌面背景',
  ['Active caption'] = '活动标题栏',
  ['Inactive caption'] = '非活动标题栏',
  ['Menu background'] = '菜单背景',
  ['Window'] = '窗口',
  ['Window frame'] = '窗口边框',
  ['Menu text'] = '菜单文本',
  ['Window text'] = '窗口文本',
  ['Caption text'] = '标题栏文本',
  ['Active border'] = '活动边框',
  ['Inactive border'] = '非活动边框',
  ['Application workspace'] = '应用程序工作区',
  ['Highlight'] = '高亮',
  ['Highlighted text'] = '高亮文本',
  ['Button face'] = '按钮表面',
  ['Button shadow'] = '按钮阴影',
  ['Dimmed text'] = '灰显文本',
  ['Button text'] = '按钮文本',
  ['Inactive caption text'] = '非活动标题栏文本',
  ['Button highlight'] = '按钮高亮',
  ['Dark shadow 3D elements'] = '3D 元素深色阴影',
  ['3D light'] = '3D 亮色',
  ['Info text'] = '信息文本',
  ['Info background'] = '信息背景',
  ['Hot light'] = '热点亮色',
  ['Gradient active caption'] = '渐变活动标题栏',
  ['Gradient inactive caption'] = '渐变非活动标题栏',
  ['Menu highlight'] = '菜单高亮',
  ['Menu bar'] = '菜单栏',
  ['Tooltip text'] = '工具提示文本',
  ['Tooltip background'] = '工具提示背景',
  ['clScrollBar'] = '滚动条',
  ['clBackground'] = '桌面背景',
  ['clActiveCaption'] = '活动标题栏',
  ['clInactiveCaption'] = '非活动标题栏',
  ['clMenu'] = '菜单背景',
  ['clWindow'] = '窗口',
  ['clWindowFrame'] = '窗口边框',
  ['clMenuText'] = '菜单文本',
  ['clWindowText'] = '窗口文本',
  ['clCaptionText'] = '标题栏文本',
  ['clActiveBorder'] = '活动边框',
  ['clInactiveBorder'] = '非活动边框',
  ['clAppWorkspace'] = '应用程序工作区',
  ['clHighlight'] = '高亮',
  ['clHighlightText'] = '高亮文本',
  ['clBtnFace'] = '按钮表面',
  ['clBtnShadow'] = '按钮阴影',
  ['clGrayText'] = '灰显文本',
  ['clBtnText'] = '按钮文本',
  ['clInactiveCaptionText'] = '非活动标题栏文本',
  ['clBtnHighlight'] = '按钮高亮',
  ['cl3DDkShadow'] = '3D 元素深色阴影',
  ['cl3DLight'] = '3D 亮色',
  ['clInfoText'] = '信息文本',
  ['clInfoBk'] = '信息背景',
  ['clHotLight'] = '热点亮色',
  ['clGradientActiveCaption'] = '渐变活动标题栏',
  ['clGradientInactiveCaption'] = '渐变非活动标题栏',
  ['clMenuHighlight'] = '菜单高亮',
  ['clMenuBar'] = '菜单栏',
  ['clBlack'] = '黑色',
  ['clMaroon'] = '栗色',
  ['clGreen'] = '绿色',
  ['clOlive'] = '橄榄色',
  ['clNavy'] = '海军蓝',
  ['clPurple'] = '紫色',
  ['clTeal'] = '蓝绿色',
  ['clGray'] = '灰色',
  ['clSilver'] = '银色',
  ['clRed'] = '红色',
  ['clLime'] = '亮绿色',
  ['clYellow'] = '黄色',
  ['clBlue'] = '蓝色',
  ['clFuchsia'] = '紫红色',
  ['clAqua'] = '青色',
  ['clWhite'] = '白色',
  ['clNone'] = '无',
  ['clDefault'] = '默认',
  ['clForm'] = '窗体',
  ['clMoneyGreen'] = '钞票绿',
  ['clSkyBlue'] = '天蓝色',
  ['clCream'] = '奶油色',
  ['clMedGray'] = '中灰色',
  ['clBrown'] = '棕色',
  ['clOliveGreen'] = '橄榄绿',
  ['clDarkGreen'] = '深绿色',
  ['clDarkTeal'] = '深蓝绿色',
  ['clDarkBlue'] = '深蓝色',
  ['clIndigo'] = '靛蓝色',
  ['clGray80'] = '80% 灰色',
  ['clDarkRed'] = '深红色',
  ['clOrange'] = '橙色',
  ['clDarkYellow'] = '深黄色',
  ['clBlueGray'] = '蓝灰色',
  ['clGray50'] = '50% 灰色',
  ['clLightOrange'] = '浅橙色',
  ['clSeaGreen'] = '海绿色',
  ['clLightBlue'] = '浅蓝色',
  ['clViolet'] = '紫罗兰色',
  ['clGray40'] = '40% 灰色',
  ['clPink'] = '粉色',
  ['clGold'] = '金色',
  ['clBrightGreen'] = '亮绿色',
  ['clTurquoise'] = '绿松石色',
  ['clPlum'] = '梅红色',
  ['clGray25'] = '25% 灰色',
  ['clRose'] = '玫瑰色',
  ['clTan'] = '棕褐色',
  ['clLightYellow'] = '浅黄色',
  ['clLightGreen'] = '浅绿色',
  ['clLightTurquoise'] = '浅绿松石色',
  ['clPaleBlue'] = '淡蓝色',
  ['clLavender'] = '薰衣草色',

})

local AUTORUN_SCRIPT_TEXT = registerTextSource({
  ['Please select at least one entry first'] = '请先至少选择一个条目',
  ['Please select at least one entry'] = '请至少选择一个条目',
  ['Loading symbols'] = '正在加载符号',
  ['First time init. Please wait for the symbols to load\n  (Close this window to try the brute force method)'] =
    '首次初始化。请等待符号加载\n  (关闭此窗口将尝试暴力搜索方法)',
  ['PsInitialSystemProcess is unreadable'] = 'PsInitialSystemProcess 无法读取',
  ['No cr3 lookup memory access function available. If you do have one, adjust dmahelper.lua'] =
    '没有可用的 CR3 查找内存访问函数。如果你有可用函数，请调整 dmahelper.lua',
  ['SystemCR3 is nil'] = 'SystemCR3 为空',
  ['CR3OpenProcess could not be found'] = '找不到 CR3OpenProcess',
  ['CR3CloseHandle could not be found'] = '找不到 CR3CloseHandle',
  ['CR3IsWow64Process could not be found'] = '找不到 CR3IsWow64Process',
  ['CR3Override error:'] = 'CR3Override 错误:',
  ['Failure finding the class to instantiate'] = '查找要实例化的类失败',
  ['Switch to DMA mode? You have to restart CE to undo this'] = '切换到 DMA 模式? 需要重启 CE 才能撤销',

  ['CE Share'] = 'CE 共享',
  ['CEShare'] = 'CEShare',
  ['CEShare Login'] = 'CEShare 登录',
  ['CEShare community URL (For writes only)'] = 'CEShare 社区 URL (仅用于写入)',
  ['Enable the use of CEShare table lookups?'] = '启用 CEShare 表查找?',
  ['Login system failure'] = '登录系统失败',
  ['Logout when loading ceshare tables'] = '加载 CE Share 表时注销',
  ['When checked you will get logged out when loading a ceshare table. This to prevent malicious tables from using your account'] =
    '勾选后，加载 CE Share 表时会注销登录。这可以防止恶意表使用你的账号',
  ['Check for mods/cheats for current process'] = '检查当前进程可用的 MOD/作弊表',
  ['Request and check other requests for mods/cheats for current process'] = '请求并查看当前进程的 MOD/作弊表请求',
  ['Publish/Update table'] = '发布/更新表',
  ['View all available tables'] = '查看所有可用表',
  ['Secondary identifier code'] = '辅助识别代码',
  ['Allow'] = '允许',
  ['This process needs a special identifier to set it apart from others with the same name. To generate this identifier the below code is needed. Do you agree with the execution of this code to generate the identifier?'] =
    '此进程需要一个特殊标识符，以便与同名进程区分。生成该标识符需要执行下面的代码。是否同意执行此代码来生成标识符?',
  ['Invalid reply from server:'] = '服务器返回无效响应:',
  ['Error:'] = '错误:',
  ['Cheat Browser'] = '作弊表浏览器',
  ['Processname:'] = '进程名:',
  ['Version independent'] = '版本无关',
  ['% Match'] = '% 匹配',
  ['    Load    '] = '    加载    ',
  ['Add/View Comments'] = '添加/查看评论',
  ['Rate:'] = '评分:',
  ['View History'] = '查看历史',
  ['For contacting the table owner or site admin'] = '用于联系表作者或站点管理员',
  ['Load Table'] = '加载表',
  ['View Comments'] = '查看评论',
  ['Login to see more options'] = '登录以查看更多选项',
  ['Update table'] = '更新表',
  ['Publish new table'] = '发布新表',
  ['Delete table'] = '删除表',
  ['Manage accesslist'] = '管理访问列表',
  ['Access has been updated'] = '访问权限已更新',
  ['Table successfuly deleted'] = '表已删除',
  ['processname is empty'] = '进程名为空',
  ['title is empty'] = '标题为空',
  ['data is empty'] = '数据为空',
  ['description is empty'] = '描述为空',
  ['Thank you, your table has been published'] = '谢谢，你的表已发布',
  ['Thank you, your table has been updated'] = '谢谢，你的表已更新',
  ['No id given'] = '未提供 ID',
  ['Please select a cheattable to update'] = '请选择要更新的作弊表',
  ['Invalid background update query list'] = '后台更新查询列表无效',
  ['This looks like an empty table. Are you sure?'] = '这看起来是空表。确定继续?',
  ["Are you sure you wish to let 'Everyone' overwrite your table in the ceshare system ?"] =
    "确定允许 'Everyone' 在 CEShare 系统中覆盖你的表?",
  ['Do you wish to sign this table?'] = '是否要签名此表?',
  ['Contact who?'] = '联系谁?',
  ['Site Admin'] = '站点管理员',
  ['Table Owner'] = '表作者',
  ['Failure obtaining contact info'] = '获取联系信息失败',
  ['Sorry, but there are currently no tables for this target. Perhaps you can be the first'] =
    '抱歉，当前目标暂无可用表。也许你可以成为第一个分享的人',
  ['Previous (25)'] = '上一页 (25)',
  ['Next (25)'] = '下一页 (25)',
  ['All tables'] = '所有表',
  ['Score='] = '分数=',
  ['<Select a module>'] = '<选择模块>',
  ['<Module not found>'] = '<未找到模块>',
  ['Missing module'] = '缺少模块',
  ['The current table is trying to load obfuscated code. This often means mallicious intent as tables are supposed to be public. Do you wish to execute this lua code anyhow?'] =
    '当前表正在尝试加载混淆代码。表按理应当公开可读，这通常意味着可能存在恶意意图。仍要执行这段 Lua 代码吗?',
  ['loadstring is being used. This can be used to load modifiable code. Do you trust this table?'] =
    '正在使用 loadstring。这可能加载可修改代码。你信任此表吗?',
  ['load is being used. This can be used to load modifiable code. Do you trust this table?'] =
    '正在使用 load。这可能加载可修改代码。你信任此表吗?',

  ['Address List (Please Wait)'] = '地址列表 (请稍候)',
  ['Address List'] = '地址列表',
  ['Find name'] = '查找名称',
  ['Copy name'] = '复制名称',
  ['Save to text file...'] = '保存到文本文件...',
  ['Text files (*.txt)|*.txt'] = '文本文件 (*.txt)|*.txt',
  ['Domains'] = '域',
  ['Images'] = '映像',
  ['Classes'] = '类',
  ['Fields'] = '字段',
  ['fields'] = '字段',
  ['Static fields'] = '静态字段',
  ['Static Fields'] = '静态字段',
  ['static fields'] = '静态字段',
  ['Methods'] = '方法',
  ['methods'] = '方法',
  ['base class'] = '基类',
  ['Inheritance'] = '继承',
  ['Signature'] = '签名',
  ['Class filter'] = '类过滤',
  ['Filter'] = '过滤',
  ['Case sensitive'] = '区分大小写',
  ['Show inherited'] = '显示继承项',
  ['Limit to class'] = '限制到类',
  ['Limit to image'] = '限制到映像',
  ['Scan for field type names'] = '扫描字段类型名',
  ['Scan for method parameters and types'] = '扫描方法参数和类型',
  ['Lookup Instances'] = '查找实例',
  ['Lookup instances'] = '查找实例',
  ['Base address'] = '基址',
  ['Browse'] = '浏览',
  ['JIT method'] = 'JIT 编译方法',
  ['Invoke method'] = '调用方法',
  ['JIT/Get Address'] = 'JIT/获取地址',
  ['Invoke Method'] = '调用方法',
  ['Inject invasive collector'] = '注入侵入式收集器',
  ['Generate patch template for method'] = '为方法生成补丁模板',
  ['Class Information'] = '类信息',
  ['Class Information ('] = '类信息 (',
  ['Search in '] = '搜索范围: ',
  ['Compilation error:'] = '编译错误:',
  ['<FilteredClassListEntry==nil>'] = '<筛选类列表条目为空>',
  ['Launch the .NET interface'] = '启动 .NET 接口',
  ['Inject the CE .NET interface into the target process?'] = '将 CE .NET 接口注入目标进程?',
  ["For better method return and parameter types it's recommended to inject the invasive dotnet data collector.  Do that now?"] =
    '为了获得更好的方法返回值和参数类型，建议注入侵入式 .NET 数据收集器。现在执行?',
  ['Failure compiling the method'] = '编译方法失败',
  ['Failure getting method address'] = '获取方法地址失败',
  ['Failure getting methodid for module named '] = '获取指定模块的方法 ID 失败: ',
  ['The image that contains this class, doesn\'t contain any classes...'] =
    '包含此类的映像没有任何类...',
  ['Not jitted and no dotnet pipe present'] = '尚未 JIT 编译，且没有可用的 .NET 管道',
  ['User declined injection'] = '用户拒绝注入',
  ['DotNetInterface did not load'] = 'DotNetInterface 未加载',
  ['address is invalid'] = '地址无效',
  ['Field is nil'] = '字段为空',
  ['No field data'] = '没有字段数据',
  ['Change value of '] = '修改数值: ',
  ['Inject error : '] = '注入错误: ',
  ['Unknown'] = '未知',
  ['Inject the .NET Control DLL into the target process?'] = '将 .NET 控制 DLL 注入目标进程?',
  ['This method is currently not jitted. Do you wish to inject the .NET Control DLL into the target process to force it to generate an entry point for this method? (Does not work if the target is suspended)'] =
    '此方法当前尚未 JIT 编译。是否将 .NET 控制 DLL 注入目标进程，强制为此方法生成入口点? (目标被挂起时无效)',
  ['To change string types the .NET Control DLL needs to be injected into the target. Inject it?'] =
    '修改字符串类型需要向目标注入 .NET 控制 DLL。是否注入?',
  ['Export to structure dissect'] = '导出到结构分析',
  ['Colors and settings'] = '颜色和设置',
  ['DotNet Info Config'] = '.Net 信息配置',
  ['Field/Method Colors'] = '字段/方法颜色',
  ['Method background color when static'] = '静态方法背景颜色',
  ['Start parsing everything when shown'] = '显示时开始解析全部内容',
  ['Show internal property field names unmodified'] = '显示未修改的内部属性字段名',
  ['Keep accessing API while paused on breakpoints'] = '断点暂停时仍继续访问 API',
  ['Create new instance'] = '创建新实例',
  ['Copy Field Name'] = '复制字段名',
  ['Copy Type Name'] = '复制类型名',
  ['Copy Address'] = '复制地址',
  ['Copy Value'] = '复制数值',
  ['No .NET info found'] = '未找到 .NET 信息',
  [' (Processing... Please wait!)'] = ' (处理中...请稍候!)',
  ['<Error: Unreadable string>'] = '<错误: 字符串不可读>',
  ['Strings can not be written'] = '无法写入字符串',
  ['Unsupported field type'] = '不支持的字段类型',
  ['value convertor failure'] = '数值转换失败',
  ['No valid address provided for non-static field'] = '未给非静态字段提供有效地址',

  ['Find Class'] = '查找类',
  ['Find Field'] = '查找字段',
  ['Find Method'] = '查找方法',
  ['List all statics'] = '列出所有静态项',
  ['No class provided'] = '未提供类',
  ['Only mono/il2pp is supported'] = '仅支持 Mono/IL2CPP',
  ['Class.Methods is not set'] = 'Class.Methods 未设置',
  ['No .ctor'] = '没有 .ctor',
  ['Failure creating instance of this class'] = '创建此类实例失败',
  ['No method selected'] = '未选择方法',
  ['Failure to call constructor:'] = '调用构造函数失败:',
  ["Select the constructor you'd like to use"] = '选择要使用的构造函数',
  ['The input :'] = '输入:',
  ['The input :"'] = '输入: "',
  ['TypeCodes '] = 'TypeCode ',
  ['pipe connection error (invalid value returned)'] = '管道连接错误 (返回值无效)',

  ['Please wait'] = '请稍候',
  ['Please wait while the process is being injected into'] = '正在注入目标进程，请稍候',
  ['JavaInfo extension is not present'] = 'JavaInfo 扩展不存在',
  ['Systemwide java agent injection. (Loads the java agent even when CE isn\'t running. Reboot recommended)'] =
    '系统级 Java 代理注入。(即使 CE 未运行也会加载 Java 代理，建议重启)',
  ['Field Edit'] = '字段编辑',
  ['New value for this field:'] = '此字段的新数值:',
  ['It looks like the target has crashed. Try one of the other lookup methods. (Rightclick on "Lookup Instances" and pick an alternate method next time)'] =
    '目标似乎已经崩溃。请尝试其他查找方法。(下次右键“查找实例”并选择备用方法)',
  ['Please first select a proper instance'] = '请先选择一个有效实例',
  ['Native Dalvik VMDebug getInstancesOfClasses call'] = '原生 Dalvik VMDebug getInstancesOfClasses 调用',
  ['JVMTI Object Tagging'] = 'JVMTI 对象标记',
  ['Java Info: Loading classes. Please wait'] = 'Java 信息: 正在加载类，请稍候',
  ['Java Info'] = 'Java 信息',
  ['scanvalue was not set'] = '未设置扫描值',
  [' can not be parsed by lua'] = ' 无法由 Lua 解析',
  ['Looking up instances'] = '正在查找实例',
  ['No java agent injected:'] = '未注入 Java 代理:',
  ['count bug'] = '计数异常',
  ['class bug'] = '类异常',
  ['bug'] = '异常',
  ['  Generic='] = '  泛型=',
  ['Invalid constant pool tag encountered: '] = '遇到无效的常量池标签: ',
  [' (tag='] = ' (标签=',
  ['si='] = '起始索引=',
  [' offset='] = ' 偏移=',

  ['Do not call libmono.terminate from external threads'] = '不要从外部线程调用 libmono.terminate',
  ['You can not use this while the process is frozen'] = '进程冻结时不能使用此功能',
  ['There is an inconsistency with the monodatacollector dll and monoscript.lua  The monodatacollector will not function'] =
    'MonoDataCollector DLL 与 monoscript.lua 不一致，MonoDataCollector 将无法工作',
  ['mono is not usable in the target proces (yet)'] = '目标进程中 Mono 暂时不可用',
  ['Cancel symbol enum'] = '取消符号枚举',
  ['IL2CPP symbol enum: 0%'] = 'IL2CPP 符号枚举: 0%',
  ['<Invalid string at %.8x>'] = '<%.8x 处的字符串无效>',
  ['Pick the enum value'] = '选择枚举值',
  ['.Net Info'] = '.Net 信息',
  ['.Net'] = '.Net',
  ['Mono/.Net'] = 'Mono/.Net',
  ['Mono script: about to timeout'] = 'Mono 脚本: 即将超时',
  ['The current mono operation is taking longer than expected'] = '当前 Mono 操作耗时超过预期',
  ['Guess what it does'] = '继续等待当前操作',
  ['Stops the current operation and continues with the next code'] = '停止当前操作并继续执行后续代码',
  ['Stops the current operation and disconnects mono so if you are stuck in a loop, this will let you exit that loop'] =
    '停止当前操作并断开 Mono；如果卡在循环中，这会让你退出该循环',
  ['Mono'] = 'Mono',
  ['IL2CPP symbol enum: Done'] = 'IL2CPP 符号枚举: 完成',
  ['Mono dissector'] = 'Mono 分析器',
  ['Save list'] = '保存列表',
  ['Jit'] = 'JIT',
  ['Execute/Invoke method'] = '执行/调用方法',
  ['Get IL Code'] = '获取 IL 代码',
  ['Show IL Disassembly'] = '显示 IL 反汇编',
  ['Show Method Parameters'] = '显示方法参数',
  ['Show Parent Methods'] = '显示父类方法',
  ['Find instances of class'] = '查找类实例',
  ['Data Structure'] = '数据结构',
  ['Dissect Structure Static Data'] = '分析结构静态数据',
  ['Dissect Structure'] = '分析结构',
  ['Dissect Structure Recursively'] = '递归分析结构',
  ['Add Static Field Address'] = '添加静态字段地址',
  ['Create instance of class'] = '创建类实例',
  ['Invoke Method of Instance'] = '调用实例方法',
  ['Select a method to execute'] = '选择要执行的方法',
  ['Copy selection to clipboard'] = '复制所选内容到剪贴板',
  ['Rescan'] = '重新扫描',
  ['Dissect struct'] = '分析结构',
  ['Invoke method of class'] = '调用类方法',
  ['Instances of '] = '实例: ',
  ['Warning: These are just guesses. Validate them yourself'] = '警告: 这些只是猜测，请自行验证',

  ['Code inject template+'] = '代码注入模板+',
  ['On what address do you want the jump?'] = '要在哪个地址跳转?',
  ['What do you want to name the symbol for the injection point?'] = '注入点符号要命名为什么?',
  ['Comment radius?'] = '注释范围?',
  ['Export to C header file'] = '导出为 C 头文件',
  ['Header files (*.h)|*.h'] = '头文件 (*.h)|*.h',
  ['Error: Could not open file for writing.'] = '错误: 无法打开文件进行写入。',
  ['Change background color'] = '更改背景颜色',

  ['Module List'] = '模块列表',
  ['Select the modules to scan for patches. Hold shift/ctrl to select multiple modules'] =
    '选择要扫描补丁的模块。按住 Shift/Ctrl 可选择多个模块',
  ['Patch list'] = '补丁列表',
  ['Restore with original'] = '恢复原始内容',
  ['Reapply patch'] = '重新应用补丁',
  ['Create patched exe from selected entries'] = '从所选条目创建已修补 EXE',
  ['You can only select the same type of modules when making a patched exe'] =
    '创建已修补 EXE 时只能选择同类型模块',
  ['Executable Files (*.EXE; *.DLL)|*.EXE;*.DLL'] = '可执行文件 (*.EXE; *.DLL)|*.EXE;*.DLL',
  ['Patch scan error:'] = '补丁扫描错误:',
  [' has been created'] = ' 已创建',
  ['Failure finding kernel32.gettickcount64'] = '查找 kernel32.gettickcount64 失败',
  ['Failure hooking kernel32.gettickcount64:'] = 'Hook kernel32.gettickcount64 失败:',
  ['Failure hooking ntdll.RtlQueryPerformanceCounter:'] = 'Hook ntdll.RtlQueryPerformanceCounter 失败:',
  ['error in injectCEHelperLib(): '] = 'injectCEHelperLib() 出错: ',

  ['Auto Save'] = '自动保存',
  ['Auto Save Interval (In seconds. 0 is disabled)'] = '自动保存间隔 (秒，0 表示禁用)',
  ['Another instance of Cheat Engine has crashed and it created an autosave.  Autosave disabled until you go to settings and click ok'] =
    '另一个 Cheat Engine 实例崩溃并创建了自动保存。自动保存已禁用，直到你进入设置并点击确定',
  ['Failure to obtain a location to save the autosave data'] = '无法获取自动保存数据的保存位置',
  ['Unknown Reason'] = '未知原因',
  ['Failure to autosave table : '] = '自动保存表失败: ',
  ['Failure to autosave state : '] = '自动保存状态失败: ',
  ['Failure to load autosave at %s  . Error: %s'] = '加载 %s 的自动保存失败。错误: %s',
  ['The saved state belongs to a different autosave version that is not currently implemented'] =
    '保存状态属于另一个自动保存版本，当前尚未实现',
  ['Cheat Engine did not properly close last time. Do you wish to restore your work?'] =
    'Cheat Engine 上次未正常关闭。是否恢复你的工作?',

  ['Add to new group'] = '添加到新组',
  ['Groups'] = '分组',
  ['What do you want the groupname to be?'] = '分组名称是什么?',
  ['Do you want "address" version?'] = '是否使用“地址”版本?',
  ['Extra Custom Types'] = '额外自定义类型',

})

local UETOOLS_TEXT = registerTextSource({
  ['Initializing Unreal Engine'] = '正在初始化虚幻引擎',
  ['Unreal Engine'] = '虚幻引擎',
  ['Status'] = '状态',
  ['Cancel the Unreal Engine data collection?'] = '取消虚幻引擎数据收集?',
  ['Prioritize this'] = '提高优先级',
  ['Loading string table'] = '正在加载字符串表',
  ['Scanning for object table'] = '正在扫描对象表',
  ['Searching for GEngine'] = '正在搜索 GEngine',
  ['Figuring out offsets'] = '正在分析偏移',
  ['Use when dissecting structures'] = '结构分析时使用',
})

local AITOOLS_TEXT = registerTextSource({
  ['AI Dialog'] = 'AI 对话',
  ['Your AI Access'] = 'AI 访问方式',
  ['<Enter API key here>'] = '<在此输入 API 密钥>',
  ['<Enter CE Patreon session ID here>'] = '<在此输入 CE Patreon 会话 ID>',
  ['Obtain Key'] = '获取密钥',
  ['Refresh session'] = '刷新会话',
  ['Public CE API (Extremely Limited)'] = '公共 CE API（极度受限）',
  ['Patreon CE API (Limited)'] = 'Patreon CE API（受限）',
  ['Personal Google AI Key (Best option)'] = '个人 Google AI 密钥（最佳选择）',
  ['Current/Default Model'] = '当前/默认模型',
  ['AI Tools'] = 'AI 工具',
  ['Ask AI'] = '询问 AI',
  ['Explain this function'] = '解释这个函数',
  ['Generate pseudocode for this function'] = '为这个函数生成伪代码',
  ['Ask about this script'] = '询问这个脚本',
  ['Enable use of AI functions (Requires restart of CE to apply)'] = '启用 AI 功能（需要重启 CE 生效）',
  ['Failure obtaining model list:'] = '获取模型列表失败:',
  ['<loading>'] = '<加载中>',
  ['<Failed obtaining model list>'] = '<获取模型列表失败>',
  ['<It\'s more than the public one>'] = '<超过公共接口限制>',
  ['Using the AI features involves sending your AI requests to a server where they could potentially be intercepted. Also your AI requests can be used by Google to improve their AI. Make sure not to never send personal information. Do you agree to this?'] =
    '使用 AI 功能会把你的 AI 请求发送到服务器，传输过程中可能被截获。你的 AI 请求也可能被 Google 用于改进其 AI。请不要发送个人信息。是否同意继续?',
  ['The public CE API is just to give you a taste of the AI capabilities on the rare occasion the limit hasn\'t been reached.  The limit it shared between ALL public api users. The chances of getting to it before the limit is reached are slim\r\n\r\nuses gemini-2.5-flash'] =
    '公共 CE API 只是用于体验 AI 功能，且只有在少数未达到限额的情况下可用。该限额由所有公共 API 用户共享，抢在限额耗尽前用上的机会很小。\r\n\r\n使用 gemini-2.5-flash',
  ['The Patreon CE API is similar to the public API, but has a slightly higher daily limit (still shared between all patreon members) You sometimes might even get a chance to use it.\r\n\r\nuses gemini-2.5-flash'] =
    'Patreon CE API 类似公共 API，但每日限额稍高一些（仍由所有 Patreon 成员共享）。有时你可能有机会用到它。\r\n\r\n使用 gemini-2.5-flash',
  ['The recommended way to use the AI tools. Even your free access key would give you more access than the public key as you don\'t have to share with other users. And if you do need more feel free to change your account to a paid account. \r\n\r\nYou can pick whichever compatible LLM model you wish'] =
    '推荐使用这种方式访问 AI 工具。即使是免费的个人密钥，也比公共密钥可用性更好，因为不需要和其他用户共享限额。如果需要更多额度，可以把账号改为付费账号。\r\n\r\n你可以选择任意兼容的 LLM 模型',
})

local AUTORUN_SCRIPT_TEXT_MORE = registerTextSource({
  ['Send'] = '发送',
  ['Message'] = '消息',
  ['  OK  '] = '  确定  ',
  ['  and %d more tables...'] = '  还有 %d 个表...',
  ['Are you sure you wish to change the owner?'] = '确定要更改所有者吗?',
  ['Are you sure you wish to delete this table?'] = '确定要删除这个表吗?',

  ['Check for new version'] = '检查新版本',
  ['Check for updates when Cheat Engine starts'] = 'Cheat Engine 启动时检查更新',
  ['Cheat Engine %s is available at www.cheatengine.org. Go there now?'] =
    'Cheat Engine %s 已在 www.cheatengine.org 发布。现在前往吗?',
  ['Update to %s'] = '更新到 %s',
  ['You are up to date. The latest version is %s'] = '已是最新版本。最新版本为 %s',
  ['Unable to check version (Can\'t connect)'] = '无法检查版本 (无法连接)',
  ['Unable to check version (Invalid content)'] = '无法检查版本 (内容无效)',
  ['Unable to check version (Invalid content, not enough lines)'] = '无法检查版本 (内容无效，行数不足)',
  ['In how many days should I notify you again?'] = '多少天后再次提醒?',
  ['Interval(days):'] = '间隔(天):',
  ['Server did not respond'] = '服务器无响应',

  ['Cheat Engine Scan files'] = 'Cheat Engine 扫描文件',
  ['Save scan session'] = '保存扫描会话',
  ['Load scan session'] = '加载扫描会话',
  ['Open a process first'] = '请先打开一个进程',

  ['Not a valid executable'] = '不是有效的可执行文件',
  ['Not a valid windows executable'] = '不是有效的 Windows 可执行文件',
  ['This type of module is currently not supported'] = '当前不支持这种模块类型',
  ['Compare error. '] = '比较错误。',
  ['Scan for patches'] = '扫描补丁',

  ['Diagram'] = '图表',
  ['Spawn diagram'] = '生成图表',
  ['Block editor'] = '块编辑器',
  ['Create annotation'] = '创建注释',
  ['Delete annotation'] = '删除注释',
  ['Edit annotation color'] = '编辑注释颜色',
  ['Edit block color'] = '编辑块颜色',
  ['Edit block header'] = '编辑块标题',
  ['Load from file'] = '从文件加载',
  ['Save to file'] = '保存到文件',
  ['Save diagram to image'] = '将图表保存为图片',
  ['Diagram files (*.CEDIAG )|*.CEDIAG'] = '图表文件 (*.CEDIAG )|*.CEDIAG',
  ['PNG files (*.PNG )|*.PNG'] = 'PNG 文件 (*.PNG )|*.PNG',
  ['Zoom'] = '缩放',
  ['100%'] = '100%',
  ['Zoom in'] = '放大',
  ['Zoom out'] = '缩小',
  ['Tracer paths'] = '跟踪路径',
  ['Show path from tracer window'] = '显示跟踪窗口路径',
  ['Show path from Ultimap1/2 or Codefilter'] = '显示 Ultimap1/2 或代码过滤器路径',
  ['Which tracer window shall be used?'] = '要使用哪个跟踪窗口?',
  ['No tracerform with results visible'] = '没有可见结果的跟踪窗口',
  ['Sources list'] = '来源列表',
  ['Destinations list'] = '目标列表',
  ['List sources'] = '列出来源',
  ['List destinations'] = '列出目标',
  ['Go to source'] = '转到来源',
  ['Go to destination'] = '转到目标',
  ['Remove all points'] = '移除所有点',
  ['[Diagram info]'] = '[图表信息]',
  [' Diagram blocks count: %d'] = ' 图表块数量: %d',
  [' Diagram links count: %d'] = ' 图表连接数量: %d',
  [' Function start: 0x%X'] = ' 函数起始: 0x%X',
  [' Function stop: 0x%X'] = ' 函数结束: 0x%X',
  ['Tracer starting at %8x (%s)'] = '跟踪起点 %8x (%s)',
  ['Fill in the filename you wish to save this diagram as'] = '输入要保存此图表的文件名',
  ['Fill in the filename you wish to save this diagram image'] = '输入要保存此图表图片的文件名',
  ['Select the file you wish to open'] = '选择要打开的文件',
  ['Sorry this feature does not work yet.  getStructureCount needs patching first.'] =
    '抱歉，此功能目前还不能使用。需要先修补 getStructureCount',

  ['Activate java features'] = '启用 Java 功能',
  ['Debug child processes'] = '调试子进程',
  ['Java variable scan'] = 'Java 变量扫描',
  ['Java Variable Scanner'] = 'Java 变量扫描器',
  ['First Scan'] = '首次扫描',
  ['Next Scan'] = '再次扫描',
  ['New Scan'] = '新的扫描',
  ['Found:'] = '找到:',
  ['Find what accesses this value'] = '查找访问此值的代码',
  ['The following methods accessed the given variable'] = '以下方法访问了指定变量',
  ['More info %s.%s(%d)'] = '更多信息 %s.%s(%d)',
  ['Scantype was not set'] = '未设置扫描类型',
  ['Array return types are not supported'] = '不支持数组返回类型',
  ['Auto assembler failed:'] = '自动汇编失败:',
  ['Invalid java signature'] = '无效的 Java 签名',
  ['Not a valid classfile'] = '不是有效的 class 文件',
  ['The java handler failed to initialize'] = 'Java 处理器初始化失败',
  ['java_find_what_writes only works when the jvmti agent is launched at start'] =
    'java_find_what_writes 只能在启动时加载 JVMTI 代理后使用',
  ['Show java menu item even if the target process hasn\'t loaded jvm.dll (Used for the local setEnvironment option)'] =
    '即使目标进程未加载 jvm.dll，也显示 Java 菜单项 (用于本地 setEnvironment 选项)',
  ['Java:eventserver terminated'] = 'Java: 事件服务器已终止',
  ['Java:Disconnected'] = 'Java: 已断开连接',
  ['Java:Unexpected event received'] = 'Java: 收到意外事件',
  ['Java:Event handler terminating'] = 'Java: 事件处理器正在终止',

  ['ByteIndex'] = '字节索引',
  ['Index'] = '索引',
  ['Instruction'] = '指令',
  ['Parameters'] = '参数',
  ['Max Stack'] = '最大栈',
  ['Max Locals'] = '最大局部变量',
  ['Save changes'] = '保存更改',
  ['Insert line'] = '插入行',
  ['Edit line'] = '编辑行',
  ['Define label'] = '定义标签',
  ['Define new label'] = '定义新标签',
  ['Input the java assembly code you wish to insert at line '] = '输入要插入到此行的 Java 汇编代码: ',
  ['Give a labelname for line '] = '输入此行的标签名: ',
  ['There is already a label with this name'] = '已存在同名标签',
  ['This instruction is currently not implemented'] = '此指令当前尚未实现',
  ['unknown instruction:'] = '未知指令:',
  ['You can only replace instructions on an instruction boundary'] = '只能在指令边界替换指令',
  ['old bsize=%d new bsize=%d'] = '旧块大小=%d 新块大小=%d',
  ['old size=%d new size=%d'] = '旧大小=%d 新大小=%d',
  ['Method: '] = '方法: ',
  ['Label'] = '标签',
  ['Offset %x'] = '偏移 %x',

  ['Invoke '] = '调用 ',
  ['Instance address'] = '实例地址',
  ['parameter '] = '参数 ',
  [' is not a valid address'] = ' 不是有效地址',
  ['is not a valid value'] = '不是有效值',
  [' is currently not implemented'] = ' 当前尚未实现',
  ['wide can not be used with '] = 'wide 不能用于 ',
  ['Invalid amount of parameters provided for '] = '提供的参数数量无效: ',
  ['Invalid parameters (Classname could not be determined)'] = '参数无效 (无法确定类名)',
  ['Invalid parameters (Methodname could not be determined)'] = '参数无效 (无法确定方法名)',
  ['Invalid parameters (name could not be determined)'] = '参数无效 (无法确定名称)',
  ['The label '] = '标签 ',
  ['is not yet defined'] = '尚未定义',

  ['Activate mono features'] = '启用 Mono 功能',
  ['Dissect mono'] = '分析 Mono',
  ['Resolve '] = '解析 ',
  ['The mono handler failed to initialize'] = 'Mono 处理器初始化失败',
  ['address==nil'] = '地址为空',
  ['invalid address'] = '地址无效',
  ['invalid parameters'] = '参数无效',
  ['invalid parameter'] = '参数无效',
  ['invalid method. has no param info'] = '无效方法，没有参数信息',
  ['Parameter lookup failed'] = '参数查找失败',
  ['method==nil'] = '方法为空',
  ['types==nil'] = '类型为空',
  ['Class is nil'] = '类为空',
  ['class==nil'] = '类为空',
  ['assemblyname is nil'] = '程序集名称为空',
  ['methoddesc is nil'] = '方法描述为空',
  ['no assemblies'] = '没有程序集',
  ['invalid image'] = '无效映像',
  ['mono_getImageFromAssembly: assembly is invalid'] = 'mono_getImageFromAssembly: 程序集无效',
  ['mono_class_getenumvalues needs a class'] = 'mono_class_getenumvalues 需要一个类',
  ['this is not an enum'] = '这不是枚举',
  ['mono_class_enumMethodsInMultipleClasses returned nil'] = 'mono_class_enumMethodsInMultipleClasses 返回空',
  ['called mono_createStructureFromName before OldCreateStructureFromName was set'] =
    '在设置 OldCreateStructureFromName 之前调用了 mono_createStructureFromName',
  ['Not connected to ceserver'] = '未连接到 ceserver',
  ['the target file being loaded is not an ELF file (magic number missing)'] =
    '正在加载的目标文件不是 ELF 文件 (缺少魔数)',
  ['the target file being loaded is not an ELF file (Not an ELF)'] =
    '正在加载的目标文件不是 ELF 文件 (不是 ELF)',
  ['No mono library loaded yet'] = '尚未加载 Mono 库',
  ['No mono library path set'] = '未设置 Mono 库路径',
  ['Unable to figure out the current architecture'] = '无法判断当前架构',
  ['Failure finding the android native bridge'] = '查找 Android native bridge 失败',
  ['Failure to load the mono data collector due to timeout'] = '加载 Mono 数据收集器超时',
  ['%x : %s (type: %s)'] = '%x : %s (类型: %s)',
  ['ILCode from %x to %x'] = 'IL 代码: %x 到 %x',
  [' could not be found'] = ' 找不到',
  [' could not be jitted'] = ' 无法 JIT 编译',
  ['The class '] = '类 ',
  [' has no fields'] = ' 没有字段',
  ['Are you sure you wish to expand the whole tree? This can take a while and Cheat Engine may look like it has crashed (It has not)'] =
    '确定要展开整棵树吗? 这可能需要一段时间，Cheat Engine 可能看起来像是卡住了 (实际上没有)',
  ['Do you wish to let the mono extention figure out the name and start address? If it\'s not a proper object this may crash the target.'] =
    '是否让 Mono 扩展自动判断名称和起始地址? 如果它不是有效对象，可能会导致目标崩溃。',

  ['Assembling '] = '正在汇编 ',
  ['Failure to launch'] = '启动失败',
  ['Exception'] = '异常',
  ['Terminated'] = '已终止',
  ['dma not initialized'] = 'DMA 未初始化',
  ['Process not found'] = '找不到进程',
  ['no peb found'] = '未找到 PEB',
  ['peb.ldr==nil'] = 'peb.ldr 为空',
  ['InLoadOrderModuleList==nil'] = 'InLoadOrderModuleList 为空',
  ['dotnet_invoke_method_dialog must run in the main thread'] =
    'dotnet_invoke_method_dialog 必须在主线程运行',
  ['dotnet_getMethodParameters failed'] = 'dotnet_getMethodParameters 失败',
  ['invalid node(nil)'] = '无效节点(nil)',
  ['invalid node(not userdata)'] = '无效节点(不是 userdata)',
  ['invalid node(0)'] = '无效节点(0)',
  ['invalid node data'] = '无效节点数据',
  ['unreadable pointer'] = '指针不可读',
  ['unparsable address'] = '无法解析地址',
  ['java_getLoadedClasses failed'] = 'java_getLoadedClasses 失败',
  ['java_getClassMethods failed'] = 'java_getClassMethods 失败',
  ['java_getClassFields failed'] = 'java_getClassFields 失败',
  ['list may not be nil'] = '列表不能为 nil',
  ['the list must be a table'] = '列表必须是 table',
  ['Invalid list returned'] = '返回的列表无效',
  ['parameter 1 is nil'] = '参数 1 为空',
  ['parameter is not a table'] = '参数不是 table',
  ['missing the memorystream (ms)'] = '缺少内存流 (ms)',
  ['read is missing'] = '缺少 read',
  ['new header'] = '新头部',
  ['Removing '] = '正在移除 ',
  ['Reloading Structure '] = '正在重新加载结构 ',
})

local AUTORUN_SCRIPT_PATTERNS = registerPatternSource({
  {'^Memory Viewer %- Currently debugging thread (.*)$', '内存视图 - 当前正在调试的线程 %1'},
  {'^Group (%d+)$', '分组 %1'},
  {'^The input :"(.-)" could not be parsed for (.+)$', '输入 "%1" 无法解析为 %2'},
  {'^TypeCodes (.+) is not known$', '未知的 TypeCode %1'},
  {'^CR3Override error: (.*)$', 'CR3Override 错误: %1'},
  {'^Failure to call constructor:(.*)$', '调用构造函数失败:%1'},
  {'^Failure getting methodid for module named (.*)$', '获取模块 %1 的方法 ID 失败'},
  {'^Class Information %((.-)%)$', '类信息 (%1)'},
  {'^Vartype:(.+)$', '变量类型:%1'},
  {'^Search in (.*)$', '在 %1 中搜索'},
  {'^Compilation error:(.*)$', '编译错误:%1'},
  {'^No java agent injected:(.*)$', '未注入 Java 代理:%1'},
  {'^Failed interpreting the string :(.*)$', '解析字符串失败:%1'},
  {'^Invalid bitsize:(.*)$', '无效位数:%1'},
  {'^Failure obtaining fields:(.*)$', '获取字段失败:%1'},
  {'^Failure to load the mono data collector due to error:(.*)$', '加载 Mono 数据收集器失败:%1'},
  {'^matching arch autoassembler error: (.*)$', '匹配架构的自动汇编错误: %1'},
  {'^Failure opening (.*)$', '打开失败: %1'},
  {'^Failure creating structure for (.*)$', '创建结构失败: %1'},
  {'^(.+) can not be parsed by lua$', '%1 无法由 Lua 解析'},
  {'^(.+) %.ctors$', '%1 构造函数'},
  {'^IL2CPP symbol enum: (.+)$', 'IL2CPP 符号枚举: %1'},
  {'^Patch scan error:(.*)$', '补丁扫描错误:%1'},
  {'^(.+) has been created$', '%1 已创建'},
  {'^error in injectCEHelperLib%(%): (.*)$', 'injectCEHelperLib() 出错: %1'},
  {'^Failure finding kernel32%.gettickcount64$', '查找 kernel32.gettickcount64 失败'},
  {'^Failure hooking kernel32%.gettickcount64:(.*)$', 'Hook kernel32.gettickcount64 失败:%1'},
  {'^Failure hooking ntdll%.RtlQueryPerformanceCounter:(.*)$', 'Hook ntdll.RtlQueryPerformanceCounter 失败:%1'},
  {'^Failure obtaining model list:(.-)\n\r\n\rConsider becoming a patreon member or get an AI key from google%. You\'ll have access to better models$', '获取模型列表失败:%1\n\r\n\r可以考虑成为 Patreon 成员，或从 Google 获取 AI 密钥，以使用更好的模型'},
  {'^Failure obtaining model list:(.*)$', '获取模型列表失败:%1'},
  {'^Address where to store the new original api call:%s*%(optional, in case your dll uses a variable for the call%)$', '保存新原始 API 调用的地址:\n(可选，当你的 DLL 使用变量保存该调用时)'},
  {'^parameter (%d+): "(.*)" is not a valid value$', '参数 %1: "%2" 不是有效值'},
  {'^(.+) is not a valid address$', '%1 不是有效地址'},
  {'^(.+) is not a valid value$', '%1 不是有效值'},
  {'^(.+) could not be found$', '%1 找不到'},
  {'^(.+) could not be jitted$', '%1 无法 JIT 编译'},
  {'^(.+) has no fields$', '%1 没有字段'},
  {'^Tracer starting at ([^ ]+) %((.*)%)$', '跟踪起点 %1 (%2)'},
  {'^(%d+) of (%d+)$', '%1 / %2'},
})

local AUTORUN_SCRIPT_LIST_PATTERNS = registerListPatternSource({
  {'^(%s*)(.-) out of 5 %((%d+) votes%)(%s*)$', '%1%2 / 5 (%3 票)%4'},
  {'^(%s*)(.-) %(owner=(.-)%)(%s*)$', '%1%2 (所有者=%3)%4'},
  {'^(%s*)(.-) %(owner:(.-)%)(%s*)$', '%1%2 (所有者:%3)%4'},
  {'^(%s*)(.-) %(bugged%)(%s*)$', '%1%2 (异常)%3'},
  {'^(%s*)Obj%((.-)%)(%s*)$', '%1对象(%2)%3'},
})

local INTERNAL_TRANSLATE_PASSTHROUGH = {
  ['results'] = true,
}

-- 在所有精确翻译表中查找指定文本的译文。
local function lookupText(s)
  if type(s) ~= 'string' then return nil end

  local lookup = TEXT_LOOKUP
  if not lookup then
    lookup = {}
    for i = 1, #TEXT_SOURCES do
      local source = TEXT_SOURCES[i]
      for text, translated in pairs(source) do
        if lookup[text] == nil then lookup[text] = translated end
      end
    end
    TEXT_LOOKUP = lookup
  end

  return lookup[s]
end

-- 按模式翻译表处理包含变量的动态文本。
local function applyPatternSources(s, sources)
  if type(s) ~= 'string' then return nil end

  for sourceIndex = 1, #sources do
    local patterns = sources[sourceIndex]
    for patternIndex = 1, #patterns do
      local mapped, count = s:gsub(patterns[patternIndex][1], patterns[patternIndex][2], 1)
      if count and count > 0 then return mapped end
    end
  end

  return nil
end

-- 调用 CE 原始 translate 作为兜底翻译。
local function rawTranslateText(s)
  if type(rawTranslate) ~= 'function' or type(s) ~= 'string' then return nil end
  local ok, translated = pcall(rawTranslate, s)
  if ok and type(translated) == 'string' and translated ~= s then
    return translated
  end
  return nil
end

local CJK_LEAD_BYTE_PATTERN = '[' .. string.char(0xE4) .. '-' .. string.char(0xE9) .. ']'
local function hasCJKText(s)
  return s:find(CJK_LEAD_BYTE_PATTERN) ~= nil
end

-- 处理直接命中、去空白后命中和动态模式命中的普通文本。
local function mapLiteral(s)
  if type(s) ~= 'string' or s == '' or s == '-' then return s end

  local direct = lookupText(s)
  if direct then return direct end

  -- 仅当首尾为空白时才 trim+重查
  local firstByte = s:byte(1)
  local lastByte = s:byte(#s)
  if firstByte == 32 or firstByte == 9 or lastByte == 32 or lastByte == 9 then
    local prefix, core, suffix = s:match('^(%s*)(.-)(%s*)$')
    local coreText = lookupText(core)
    if core and core ~= s and coreText then
      return prefix .. coreText .. suffix
    end
  end

  local mapped = applyPatternSources(s, PATTERN_SOURCES)
  if mapped then return mapped end

  return s
end

-- 统一文本翻译入口，所有包装函数都通过这里取中文。
local function zhText(s)
  if type(s) ~= 'string' then return s end
  local cached = ZH_TEXT_CACHE[s]
  if cached ~= nil then return cached end

  if INTERNAL_TRANSLATE_PASSTHROUGH[s] then
    ZH_TEXT_CACHE[s] = s
    return s
  end

  if hasCJKText(s) then
    ZH_TEXT_CACHE[s] = s
    return s
  end

  local mapped = mapLiteral(s)
  if mapped == s then
    mapped = rawTranslateText(s) or s
  end

  ZH_TEXT_CACHE[s] = mapped
  return mapped
end

if type(rawTranslate) == 'function' then
  -- 全局 translate 包装：让后续脚本调用 translate 时优先走 zh_CN 翻译表。
  _G.translate = function(s)
    return zhText(s)
  end
end

-- 包装普通文本对话框函数，自动翻译标题和内容。
local function wrapTextDialog(name)
  local original = capture(name)
  if type(original) ~= 'function' then return end

  -- 文本对话框包装：翻译传入的提示文本。
  _G[name] = function(text, ...)
    return original(zhText(text), ...)
  end
end

local function wrapMessageDialog(name)
  local original = capture(name)
  if type(original) ~= 'function' then return end

  -- messageDialog 支持 text 和 title,text 两种签名，按参数形态分别翻译。
  _G[name] = function(first, second, ...)
    if type(second) == 'string' then
      return original(zhText(first), zhText(second), ...)
    end
    if second == nil and select('#', ...) == 0 then
      return original(zhText(first))
    end
    return original(zhText(first), second, ...)
  end
end

wrapMessageDialog('messageDialog')
wrapMessageDialog('MessageDialog')
wrapTextDialog('showMessage')
wrapTextDialog('ShowMessage')

-- 包装输入框函数，自动翻译标题和提示语。
local function wrapInputQuery(name)
  local original = capture(name)
  if type(original) ~= 'function' then return end

  -- 输入对话框包装：翻译标题和提示文本。
  _G[name] = function(caption, prompt, ...)
    return original(zhText(caption), zhText(prompt), ...)
  end
end

wrapInputQuery('inputQuery')
wrapInputQuery('InputQuery')

do
  local original = capture('showSelectionList')
  if type(original) == 'function' then
    -- 选择列表包装：翻译窗口标题和说明文字，保持列表对象和返回值不变。
    _G.showSelectionList = function(title, caption, list, ...)
      return original(zhText(title), zhText(caption), list, ...)
    end
  end
end

local CE_DRAW_TEXT_NATIVE_TEXT = {
  [' DPL='] = ' 特权级(DPL)=',
  ['DLL, '] = '动态链接库，',
  ['Draft'] = '草',
  ['Files'] = '文件',
  ['Group'] = '组',
  ['Print'] = '截屏键',
  ['Proof'] = '校',
  ['Space'] = '空格',
  [' (Hex)'] = ' (十六进制)',
  ['Error='] = '错误=',
  ['Header'] = '表头',
  ['Number'] = '数字',
  ['Script'] = '脚本',
  ['Select'] = '选择',
  ['Spider'] = '蜘蛛',
  ['Symbol'] = '符号',
  ['Vtable'] = '虚函数表',
  ['error '] = '错误 ',
  ['error:'] = '错误：',
  ['thread'] = '线程',
  [' -error'] = ' -错误',
  [' count='] = ' 数量=',
  [' failed'] = ' 失败',
  ['Count: '] = '数量: ',
  ['Failed:'] = '失败：',
  ['No name'] = '无名称',
  ['Page Up'] = '向上翻页',
  ['numeric'] = '数字键盘',
  ['Dark Red'] = '深红',
  ['FPU Edit'] = 'FPU 编辑',
  ['Gray 25%'] = '25%灰',
  ['Gray 40%'] = '40%灰',
  ['Gray 50%'] = '50%灰',
  ['Gray 80%'] = '80%灰',
  ['Num Lock'] = '数字锁定',
  ['Right MB'] = '鼠标右键',
  ['Sky Blue'] = '天蓝',
  ['Sky blue'] = '天蓝',
  ['Up Arrow'] = '上方向键',
  [' ARCHIVE:'] = ' 压缩包：',
  [' Position'] = ' 位置',
  [' address '] = ' 地址 ',
  ['Accessed='] = '已访问=',
  ['Blue Gray'] = '蓝灰色',
  ['C Error :'] = 'C 错误：',
  ['Character'] = '字符',
  ['Code List'] = '代码列表',
  ['Dark Blue'] = '深蓝色',
  ['Dark Teal'] = '深青',
  ['Directive'] = '指令',
  ['IPT Trace'] = 'IPT 跟踪',
  ['Last Scan'] = '上次扫描',
  ['Lock Page'] = '锁定页面',
  ['MZ header'] = 'MZ 头',
  ['Menu text'] = '菜单字',
  ['Navy blue'] = '海军蓝',
  ['No reason'] = '无原因',
  ['Page Down'] = '向下翻页',
  ['Pale Blue'] = '淡蓝色',
  ['Pointer: '] = '指针: ',
  ['Readable='] = '可读=',
  ['Sea Green'] = '海绿色',
  ['Separator'] = '分隔键',
  ['Space bar'] = '空格键',
  ['Writable='] = '可写=',
  ['not found'] = '未找到',
  ['parameter'] = '参数',
  ['pointer: '] = '指针: ',
  [' not found'] = ' 未找到',
  ['BuggedList'] = '异常列表',
  ['Case label'] = 'Case 标签',
  ['DBK driver'] = 'DBK 驱动',
  ['Dark Green'] = '深绿色',
  ['Identifier'] = '标识符',
  ['LUA panic!'] = 'Lua 严重错误！',
  ['Last seen:'] = '最后出现:',
  ['Light Blue'] = '浅蓝色',
  ['New value:'] = '新值：',
  ['ProcessID='] = '进程 ID=',
  ['invalid id'] = 'ID 无效',
  ['not active'] = '未激活',
  ['parameters'] = '参数',
  [' bytes free'] = ' 字节可用',
  [' is invalid'] = ' 无效',
  ['Auto Attach'] = '自动附加',
  ['Bind failed'] = '绑定失败',
  ['Button face'] = '按钮面',
  ['Button text'] = '按钮文',
  ['Byte Hotkey'] = '字节热键',
  ['Conforming='] = '一致代码段=',
  ['DBVM needs '] = 'DBVM 需要 ',
  ['Dark Yellow'] = '深黄色',
  ['Dimmed text'] = '灰显文',
  ['First seen:'] = '首次出现:',
  ['Light Green'] = '浅绿色',
  ['Match Color'] = '匹配颜色',
  ['Medium gray'] = '中灰色',
  ['Module List'] = '模块列表',
  ['Money Green'] = '钞票绿',
  ['Money green'] = '钞票绿',
  ['Not anymore'] = '不再是',
  ['Olive Green'] = '橄榄绿',
  ['Olive green'] = '橄榄绿',
  ['Right Arrow'] = '右方向键',
  ['Scroll Lock'] = '滚动锁定',
  ['Show Gutter'] = '显示边栏',
  ['Text Hotkey'] = '文本热键',
  ['Window text'] = '窗口文',
  ['description'] = '描述',
  ['unknownname'] = '未知名称',
  ['Bright Green'] = '亮绿色',
  ['Debug Events'] = '调试事件',
  ['Do not hide '] = '不隐藏 ',
  ['FPURegisters'] = 'FPU寄存器',
  ['Float Hotkey'] = '单浮点热键',
  ['Illegal char'] = '非法字符',
  ['Invalid list'] = '列表无效',
  ['Launch DBVM?'] = '启动 DBVM？',
  ['Light Orange'] = '浅橙色',
  ['Light Yellow'] = '浅黄色',
  ['Max IPT Size'] = '最大 IPT 大小',
  ['Preprocessor'] = '预处理器',
  ['Print Screen'] = '截屏键',
  ['Recent Files'] = '最近文件',
  ['Tooltip text'] = '提示文本',
  ['Window frame'] = '窗口边框',
  ['stream error'] = '流错误',
  [' in not found'] = ' 中未找到',
  ['Also save PNG'] = '同时保存 PNG',
  ['Binary Hotkey'] = '二进制热键',
  ['Button shadow'] = '按钮阴影',
  ['Child error: '] = '子节点错误：',
  ['Crashy thread'] = '易崩溃线程',
  ['Default Color'] = '默认颜色',
  ['Double Hotkey'] = '双浮点热键',
  ['IDE Directive'] = 'IDE 指令',
  ['Listen failed'] = '监听失败',
  ['Not connected'] = '未连接',
  ['PasDoc Symbol'] = 'PasDoc 符号',
  ['Reserved word'] = '保留字',
  ['Worker thread'] = '工作线程',
  ['array of byte'] = '字节数组',
  ['invalid value'] = '值无效',
  ['scan Writable'] = '扫描可写',
  [' DECOMPRESSOR:'] = ' 解压器：',
  ['2 Bytes Hotkey'] = '2 字节热键',
  ['4 Bytes Hotkey'] = '4 字节热键',
  ['8 Bytes Hotkey'] = '8 字节热键',
  ['Array of Bytes'] = '字节数组',
  ['BP Cloak error'] = 'BP 隐蔽错误',
  ['Display Signed'] = '显示有符号',
  ['Error at line '] = '错误位于行 ',
  ['Invalid handle'] = '句柄无效',
  ['Invalid header'] = '无效的头部',
  ['Invalid option'] = '选项无效',
  ['Log whole page'] = '记录整个页面',
  ['No Match Color'] = '不匹配颜色',
  ['NonAntialiased'] = '无抗锯齿',
  ['Parent error: '] = '父节点错误：',
  ['PasDoc Keyword'] = 'PasDoc 关键字',
  ['PasDoc Unknown'] = 'PasDoc 未知',
  ['Selection text'] = '选区文本',
  ['Unknown status'] = '未知状态',
  ['Use Auto Types'] = '使用自动类型',
  ['Worker IP List'] = '工作节点 IP 列表',
  ['unicode string'] = 'Unicode串',
  ['unknown error '] = '未知错误 ',
  [' to writable  ('] = ' 改为可写  (',
  ['Center on popup'] = '弹出时居中',
  ['Debugger thread'] = '调试器线程',
  ['End of debugger'] = '调试器结束',
  ['Failed loading '] = '加载失败 ',
  ['Failed to load '] = '加载失败：',
  ['Invalid Session'] = '会话无效',
  ['Light Turquoise'] = '浅绿松石色',
  ['Link read error'] = '链接读取错误',
  ['Lua Exception: '] = 'Lua 异常：',
  ['Main GUI Thread'] = '主 GUI 线程',
  ['Menu background'] = '菜单背景',
  ['My Cheat Tables'] = '我的作弊表',
  ['New Scan Hotkey'] = '新扫描热键',
  ['New group name:'] = '新组名称：',
  ['No GetTickCount'] = '没有 GetTickCount',
  ['No process open'] = '没有打开的进程',
  ['No trace active'] = '没有活动的跟踪',
  ['Opening process'] = '正在打开进程',
  ['Saved Stacksize'] = '已保存的堆栈大小',
  ['Show tools menu'] = '显示工具菜单',
  ['Snapshot Folder'] = '快照文件夹',
  ['Ultimap2 Folder'] = 'Ultimap2 文件夹',
  ['Writing pointer'] = '正在写入指针',
  ['invalid addres:'] = '地址无效：',
  ['scan Executable'] = '扫描可执行',
  ['setValue failed'] = 'setValue 失败',
  [' bytes of memory'] = ' 字节内存',
  ['Agressive trim, '] = '主动修剪，',
  ['Block read error'] = '块读取错误',
  ['Button highlight'] = '按钮高亮',
  ['Change by offset'] = '按偏移修改',
  ['CleartypeNatural'] = '清晰自然',
  ['Connect canceled'] = '连接已取消',
  ['Current scanlist'] = '当前扫描列表',
  ['Don\'t save local'] = '不保存局部结构',
  ['Hide all windows'] = '隐藏所有窗口',
  ['Invalid instance'] = '实例无效',
  ['Invalid stubdata'] = 'stubdata 无效',
  ['Processing files'] = '正在处理文件',
  ['Save the results'] = '保存结果',
  ['Select a process'] = '选择进程',
  ['Target a process'] = '指定进程',
  ['Text files|*.txt'] = '文本|*.txt',
  ['Unnamed newstate'] = '未命名的新状态',
  ['Use VEH Debugger'] = '使用 VEH 调试器',
  ['arm disassembler'] = 'ARM 反汇编器',
  ['frmSourceDisplay'] = '源代码显示',
  ['scan CopyOnWrite'] = '扫描写时复制',
  ['unknown classid '] = '未知 classid ',
  [' is not available'] = ' 不可用',
  ['Always Force Load'] = '始终强制加载',
  ['Always Sign Table'] = '始终签名表',
  ['Api hook template'] = 'API Hook 模板',
  ['Original api address:'] = '原 API 地址:',
  ['New api address:'] = '新 API 地址:',
  ['Address where to store the new original api call:'] = '保存新原始 API 调用的地址:',
  ['(optional, in case your dll uses a variable for the call)'] = '(可选，当你的 DLL 使用变量保存该调用时)',
  ['Address where to store the new original api call:' .. '\n' .. '(optional, in case your dll uses a variable for the call)'] = '保存新原始 API 调用的地址:' .. '\n' .. '(可选，当你的 DLL 使用变量保存该调用时)',
  ['Note: The addresses can also be exportnames of dll\'s'] = '注意：地址也可以是 DLL 的导出名',
  ['Change to address'] = '修改为地址',
  ['DBVMBP Kernelmode'] = 'DBVMBP 内核模式',
  ['Debug->Run Hotkey'] = '调试->运行热键',
  ['Disk Write Error:'] = '磁盘写入错误：',
  ['Don\'t use tempdir'] = '不使用临时目录',
  ['Error during send'] = '发送期间出错',
  ['Full Snapshot Key'] = '完整快照热键',
  ['Get process icons'] = '获取进程图标',
  ['Internal function'] = '内部函数',
  ['Invalid data read'] = '读取的数据无效',
  ['Invalid lua state'] = '无效的 Lua 状态',
  ['Invalid parameter'] = '参数无效',
  ['Launch GDB server'] = '启动 GDB 服务器',
  ['Not a valid table'] = '不是有效的表',
  ['Pointer appending'] = '指针追加',
  ['Selection: <none>'] = '选择：<无>',
  ['Show Line Numbers'] = '显示行号',
  ['Speedhack speed +'] = '变速速度 +',
  ['Speedhack speed -'] = '变速速度 -',
  ['Speedhack speed 1'] = '变速速度 1',
  ['Speedhack speed 2'] = '变速速度 2',
  ['Speedhack speed 3'] = '变速速度 3',
  ['Speedhack speed 4'] = '变速速度 4',
  ['Speedhack speed 5'] = '变速速度 5',
  ['Ultimap2 Use Disk'] = 'Ultimap2 使用磁盘',
  ['Use DBVM Debugger'] = '使用 DBVM 调试器',
  ['error: queuepos<0'] = '错误：queuepos<0',
  ['invalid parameter'] = '参数无效',
  ['skip PAGE_NOCACHE'] = '跳过 PAGE_NOCACHE',
  ['Cancel scan Hotkey'] = '取消扫描热键',
  ['Cannot open file: '] = '无法打开:',
  ['DBVMBP Trigger COW'] = 'DBVMBP 触发写时复制',
  ['Default Background'] = '默认背景色',
  ['Default Foreground'] = '默认前景色',
  ['Desktop background'] = '桌面背景',
  ['Failure to connect'] = '连接失败',
  ['Highlighted Marked'] = '高亮标记',
  ['Initial tables dir'] = '初始表目录',
  ['Invalid data read2'] = '读取的数据无效 2',
  ['Invalid formula ( '] = '公式无效 ( ',
  ['Last Rounding Type'] = '上次舍入类型',
  ['No parameter given'] = '未给出参数',
  ['Nothing to compile'] = '没有可编译的内容',
  ['OpenThread failure'] = 'OpenThread 失败',
  ['Small Snapshot Key'] = '小型快照热键',
  ['Tooltip background'] = '工具提示背景',
  ['UpdateTimer Error:'] = '更新计时器错误：',
  ['Use Processwatcher'] = '使用进程监视器',
  ['dllInject failed: '] = 'dllInject 失败：',
  ['unknown lua type: '] = '未知 Lua 类型：',
  [' is not a Component'] = ' 不是组件',
  [' is not initialized'] = ' 未初始化',
  ['All files (*.*)|*.*'] = '所有文件|*.*',
  ['Attaching VEH Debug'] = '正在附加 VEH 调试',
  ['Can Step Kernelcode'] = '可单步执行内核代码',
  ['Change type to Byte'] = '类型改为字节',
  ['Change type to Text'] = '类型改为文本',
  ['Comment editor for '] = '注释编辑器：',
  ['Connection failed: '] = '连接失败：',
  ['Display Hexadecimal'] = '显示十六进制',
  ['Enter the new value'] = '输入新值',
  ['Enter your password'] = '输入密码',
  ['Failure allocating '] = '分配失败：',
  ['First log message: '] = '第一条日志消息: ',
  ['Handling breakpoint'] = '正在处理断点',
  ['Hide IPT Capability'] = '隐藏 IPT 功能',
  ['Highlighted Ultimap'] = '高亮 Ultimap',
  ['Invalid callmethod:'] = '调用方法无效：',
  ['Invalid data read 3'] = '读取的数据无效 3',
  ['Kernelmode Debugger'] = '内核模式调试器',
  ['No parameters given'] = '未给出参数',
  ['ParentQueue error: '] = '父队列错误：',
  ['Pointerscan Timeout'] = '指针扫描超时',
  ['Saving. Please wait'] = '正在保存。请稍候',
  ['Snapshot ClearDepth'] = '快照清除深度',
  ['Table option named '] = '表选项名称 ',
  ['The address named :'] = '地址名称：',
  ['Use Kernel Debugger'] = '使用内核调试器',
  ['Use old aob sig gen'] = '使用旧版 AOB 签名生成',
  ['adding to the lists'] = '正在添加到列表',
  ['done with no errors'] = '完成，没有错误',
  ['not all memory read'] = '未读取全部内存',
  ['pid duplicate error'] = 'PID 重复错误',
  [' could not be loaded'] = ' 无法加载',
  ['All (Byte to Double)'] = '字节到双浮点',
  ['All Match Color Diff'] = '全部匹配但颜色不同',
  ['All Match Color Same'] = '全部匹配且颜色相同',
  ['Array of Byte Hotkey'] = '字节数组热键',
  ['Change type to Float'] = '类型改单浮点',
  ['Changed Value Hotkey'] = '已变化的值热键',
  ['Error during receive'] = '接收期间出错',
  ['Expansion direction='] = '扩展方向=',
  ['Hardware breakpoints'] = '硬件断点',
  ['Invalid diagram file'] = '图表文件无效',
  ['Loading symbols for '] = '正在加载符号：',
  ['Module32First failed'] = 'Module32First 失败',
  ['New Scan-Exact Value'] = '首次扫描-精确数值',
  ['No debugger attached'] = '未附加调试器',
  ['Open a CE Trace file'] = '打开 CE Trace 文件',
  ['OpenRequest failed: '] = 'OpenRequest 失败：',
  ['Pause process Hotkey'] = '暂停进程热键',
  ['Removing breakpoints'] = '正在移除断点',
  ['ScanWorker has error'] = 'ScanWorker 发生错误',
  ['Selected Match Color'] = '已选择匹配颜色',
  ['Selection background'] = '选区背景',
  ['Snapshot Progressive'] = '渐进快照',
  ['Software breakpoints'] = '软件断点',
  ['Support Cheat Engine'] = '支持 Cheat Engine',
  ['Use Windows Debugger'] = '使用 Windows 调试器',
  ['Using opened process'] = '正在使用已打开的进程',
  ['Virtual Address=%.8x'] = '虚拟地址=%.8x',
  ['disassembler error 1'] = '反汇编器错误 1',
  ['disassembler error 2'] = '反汇编器错误 2',
  ['disassembler error 3'] = '反汇编器错误 3',
  ['hotkey poll interval'] = '热键轮询间隔',
  ['no debugger attached'] = '未附加调试器',
  ['use thread to freeze'] = '使用线程冻结',
  [' can not be assembled'] = ' 无法汇编',
  ['\' could not be loaded'] = '\' 无法加载',
  ['All executable memory'] = '全部可执行内存',
  ['Application workspace'] = '应用程序工作区',
  ['Change type to Binary'] = '类型改为二进制',
  ['Change type to Double'] = '类型改为双浮点',
  ['Debugger attach time='] = '调试器附加时间=',
  ['Done processing files'] = '文件处理完成',
  ['Exception breakpoints'] = '异常断点',
  ['Failure starting dbk:'] = '启动 DBK 失败：',
  ['GDB selected process:'] = 'GDB 已选择进程：',
  ['Incorrect tcc library'] = 'TCC 库不正确',
  ['Lua thread terminated'] = 'Lua 线程已终止',
  ['Max Auto-Expand Level'] = '最大自动展开层级',
  ['Max number of entries'] = '最大条目数',
  ['Multiple matching RIP'] = '多个匹配的 RIP',
  ['Next Scan-Exact Value'] = '再次扫描-精确数值',
  ['Not all results found'] = '未找到全部结果',
  ['Not enough parameters'] = '参数不足',
  ['Override Default Font'] = '覆盖默认字体',
  ['Physical Address=%.8x'] = '物理地址=%.8x',
  ['Procedure header name'] = '过程头名称',
  ['Save obfuscated table'] = '保存混淆表',
  ['Scan not finished yet'] = '扫描尚未完成',
  ['Show values as signed'] = '将数值显示为有符号',
  ['Trace ready to spring'] = '跟踪已准备触发',
  ['Ultimap2 Auto Process'] = 'Ultimap2 自动处理',
  ['Undo Last scan Hotkey'] = '撤销上次扫描热键',
  ['Unexpected breakpoint'] = '意外断点',
  ['Unsupported tracefile'] = '不支持的跟踪文件',
  ['Use dbk32 OpenProcess'] = '使用 dbk32 OpenProcess',
  ['Wait After Gui Update'] = 'GUI 更新后等待',
  ['auto assembler script'] = '自动汇编脚本',
  ['executeCodeEx invalid'] = 'executeCodeEx 无效',
  ['nonending round brace'] = '圆括号未结束',
  ['server non responsive'] = '服务器无响应',
  ['{$LUA} block at line '] = '{$LUA} 块位于行 ',
  ['Autoguess Custom Types'] = '自动猜测自定义类型',
  ['Cancel and get results'] = '取消并获取结果',
  ['Change type to 2 Bytes'] = '类型改为 2 字节',
  ['Change type to 4 Bytes'] = '类型改为 4 字节',
  ['Change type to 8 Bytes'] = '类型改为 8 字节',
  ['Decreased Value Hotkey'] = '减小的值热键',
  ['Done downloading files'] = '文件下载完成',
  ['Failed to debug target'] = '调试目标失败',
  ['Failure creating file '] = '创建文件失败：',
  ['Failure writing memory'] = '写入内存失败',
  ['Fastscan on by default'] = '默认启用快速扫描',
  ['Incorrect tcc library:'] = 'TCC 库不正确：',
  ['Increased Value Hotkey'] = '增大的值热键',
  ['Invalid memory address'] = '无效的内存地址',
  ['Invalid parametertype '] = '参数类型无效：',
  ['MapViewOfFile failed: '] = 'MapViewOfFile 失败：',
  ['ModuleList as Denylist'] = '将模块列表作为拒绝列表',
  ['Querying memoryregions'] = '正在查询内存区域',
  ['Selected Default Color'] = '已选择默认颜色',
  ['Setting GDB Breakpoint'] = '正在设置 GDB 断点',
  ['Show Language MenuItem'] = '显示语言菜单项',
  ['Socket creation failed'] = '创建套接字失败',
  ['Trace read stack error'] = '跟踪读取堆栈错误',
  ['Unchanged Value Hotkey'] = '未变化的值热键',
  ['Use GDBServer Debugger'] = '使用 GDBServer 调试器',
  ['Use Intel PT For Debug'] = '使用 Intel PT 调试',
  ['arm32 is not supported'] = '不支持 arm32',
  ['scan PresentMemoryOnly'] = '仅扫描已提交内存',
  ['skip PAGE_WRITECOMBINE'] = '跳过 PAGE_WRITECOMBINE',
  [' which is not supported'] = ' 不受支持',
  ['\'All\' executable memory'] = '“全部”可执行内存',
  ['Autoattach to process: '] = '自动附加到进程: ',
  ['Custom String Type Name'] = '自定义字符串类型名称',
  ['Dark shadow 3D elements'] = '3D 元素深色阴影',
  ['Failed to sign the hash'] = '签名哈希失败',
  ['Invalid parametervalue '] = '参数值无效：',
  ['Loading new module info'] = '正在加载新模块信息',
  ['Must be commited memory'] = '必须是已提交内存',
  ['Never Change Protection'] = '永不更改保护属性',
  ['Next Scan-Changed Value'] = '再次扫描-变化',
  ['No stack register found'] = '未找到栈寄存器',
  ['Really hide all windows'] = '真正隐藏所有窗口',
  ['Selected No Match Color'] = '已选择不匹配颜色',
  ['Snapshot picture format'] = '快照图片格式',
  ['Start downloading files'] = '开始下载文件',
  ['Toggle speedhack Hotkey'] = '切换变速精灵热键',
  ['Unknown diagram version'] = '未知的图表版本',
  ['Unknown type for param '] = '参数类型未知：',
  ['Use Anti-debugdetection'] = '使用反调试检测',
  ['adding to the foundlist'] = '正在添加到找到的列表',
  ['getthreadcontext error:'] = 'getthreadcontext 错误：',
  ['luastack is not correct'] = 'Lua 栈不正确',
  ['not a registered symbol'] = '不是已注册的符号',
  ['setthreadcontext error:'] = 'setthreadcontext 错误：',
  ['textfiles (*.txt)|*.txt'] = '文本文件|*.txt',
  ['Activating kernelsymbols'] = '正在激活内核符号',
  ['Change the file size to '] = '将文件大小更改为 ',
  ['DBVMBP This Process Only'] = 'DBVMBP 仅此进程',
  ['Disable DarkMode Support'] = '禁用深色模式支持',
  ['Failure launching thread'] = '启动线程失败',
  ['Failure opening process '] = '打开进程失败：',
  ['Floating Point Registers'] = '浮点寄存器',
  ['Getting other CR3 values'] = '正在获取其他 CR3 值',
  ['Invalid command line at '] = '命令行无效，位置 ',
  ['Invalid formula Unknown '] = '公式无效，未知 ',
  ['Invalid system register:'] = '系统寄存器无效：',
  ['Lua server connect error'] = 'Lua 服务器连接错误',
  ['Manual map VEH debug dll'] = '手动映射 VEH 调试 DLL',
  ['Physical Address=invalid'] = '物理地址=无效',
  ['Reading the range memory'] = '正在读取范围内存',
  ['Show Cheat Engine Hotkey'] = '显示 Cheat Engine 热键',
  ['Text files (*.txt)|*.txt'] = '文本文件|*.txt',
  ['This file can be written'] = '此文件可写入',
  ['Time between hotkeypress'] = '热键按下间隔',
  ['Trace finished recording'] = '跟踪已完成记录',
  ['Ultimap 2 window created'] = 'Ultimap 2 窗口已创建',
  ['Update Foundaddress list'] = '更新已找到地址列表',
  ['Value can not be encoded'] = '值无法编码',
  ['not all parameters given'] = '并非所有参数都已给出',
  ['param2 has to be a table'] = 'param2 必须是表',
  ['script parameter missing'] = '缺少 script 参数',
  ['symbolsync failed write:'] = 'symbolsync 写入失败：',
  [' can not be bigger than 3'] = ' 不能大于 3',
  ['Ask for replace with NOPS'] = '替换为 NOP 前询问',
  ['Can not map an empty file'] = '无法映射空文件',
  ['DebugActiveProcess failed'] = 'DebugActiveProcess 失败',
  ['Force load module failed:'] = '强制加载模块失败：',
  ['General Purpose Registers'] = '通用寄存器',
  ['IPTDataDispatcher error: '] = 'IPTDataDispatcher 错误：',
  ['Incoming connection from '] = '传入连接来自 ',
  ['Incorrect parameter count'] = '参数数量不正确',
  ['Invalid instance register'] = '实例寄存器无效',
  ['Next Scan-Decreased Value'] = '再次扫描-减少',
  ['Next Scan-Increased Value'] = '再次扫描-增加',
  ['Next Scan-Unchanged Value'] = '再次扫描-未变',
  ['Potential labeling error:'] = '潜在标签错误：',
  ['Retrieving structure data'] = '正在获取结构数据',
  ['Retrieving structure list'] = '正在获取结构列表',
  ['Same as first scan Hotkey'] = '与首次扫描相同热键',
  ['Speedhack: Error hooking '] = '变速精灵：Hook 出错 ',
  ['Ultimap2 Keep Trace Files'] = 'Ultimap2 保留跟踪文件',
  ['Ultimap2 TextTrace Folder'] = 'Ultimap2 文本跟踪文件夹',
  ['Use Global Debug Routines'] = '使用全局调试例程',
  [' can not be smaller than 2'] = ' 不能小于 2',
  [' is supposed to be a table'] = ' 应该是表',
  ['(Just starting to process)'] = '(刚开始处理)',
  ['Addresslist: sort on click'] = '地址列表：点击排序',
  ['Could not find the decoder'] = '找不到解码器',
  ['Could not find the encoder'] = '找不到编码器',
  ['Could not load library: %s'] = '无法加载库：%s',
  ['Do you wish to keep these?'] = '是否保留这些？',
  ['DotNetExecuteClassMethod: '] = 'DotNetExecuteClassMethod：',
  ['Failure encoding AA script'] = '编码 AA 脚本失败',
  ['Failure setting breakpoint'] = '设置断点失败',
  ['Filling in links to c-code'] = '正在填充 C 代码链接',
  ['Not a specified breakpoint'] = '不是指定的断点',
  ['Offset - Description      '] = '偏移 - 描述      ',
  ['Runtime Hooking default ON'] = '运行时 Hook 默认开启',
  ['Show previous value column'] = '显示先前值列',
  ['This file can be recreated'] = '此文件可重新创建',
  ['Waiting for symbols loaded'] = '正在等待符号加载完成',
  ['disassembler exception at '] = '反汇编器异常位置：',
  ['invalid address for buffer'] = '缓冲区地址无效',
  ['invalid compilation result'] = '编译结果无效',
  ['setthreadcontextarm failed'] = 'setthreadcontextarm 失败',
  ['(There\'s no reason to wait)'] = '(没有继续等待的理由)',
  ['Add executable memory pages'] = '添加可执行内存页',
  ['After pointermap generation'] = '指针映射生成后',
  ['Build environment corrupted'] = '构建环境已损坏',
  ['Could not load OpenGL from '] = '无法从以下位置加载 OpenGL：',
  ['Creating filemap with name '] = '正在创建文件映射，名称：',
  ['Duplication failed due to :'] = '复制失败，原因：',
  ['EnumSymbols callback error:'] = 'EnumSymbols 回调错误：',
  ['Failed connecting to server'] = '连接服务器失败',
  ['Failure allocating memory ('] = '分配内存失败 (',
  ['Failure getting module info'] = '获取模块信息失败',
  ['Failure setting write watch'] = '设置写入监视失败',
  ['Invalid parameter at index '] = '索引处参数无效 ',
  ['Invalid xmm register format'] = 'XMM 寄存器格式无效',
  ['LineHook_Handler exception:'] = 'LineHook_Handler 异常：',
  ['Not enough DBVM memory free'] = 'DBVM 可用内存不足',
  ['QThreadEvents not supported'] = '不支持 QThreadEvents',
  ['Show all windows on taskbar'] = '在任务栏显示所有窗口',
  ['TDBVMWatchPollThread crash:'] = 'TDBVMWatchPollThread 崩溃：',
  ['This table failed to load: '] = '此表加载失败：',
  ['Unexpected packet received:'] = '收到意外数据包：',
  ['VEH injection script failed'] = 'VEH 注入脚本失败',
  ['failed creating or opening '] = '创建或打开失败 ',
  ['Can not compile at address 0'] = '无法在地址 0 编译',
  ['Change type to Array of byte'] = '类型改为字节数组',
  ['Enter the new priority level'] = '输入新的优先级',
  ['Error activating the IPT log'] = '启用 IPT 日志时出错',
  ['Failure setting writye watch'] = '设置写入监视失败',
  ['First making memory writable'] = '先将内存设为可写',
  ['Handle unhandled breakpoints'] = '处理未处理的断点',
  ['Highlighted Marked secondary'] = '高亮标记副色',
  ['No exceptioncode ignore list'] = '没有异常代码忽略列表',
  ['Scancontroller cleanup error'] = '扫描控制器清理错误',
  ['Set Speedhack speed 1 Hotkey'] = '设置变速精灵速度 1 热键',
  ['Set Speedhack speed 2 Hotkey'] = '设置变速精灵速度 2 热键',
  ['Set Speedhack speed 3 Hotkey'] = '设置变速精灵速度 3 热键',
  ['Set Speedhack speed 4 Hotkey'] = '设置变速精灵速度 4 热键',
  ['Set Speedhack speed 5 Hotkey'] = '设置变速精灵速度 5 热键',
  ['Show processlist in mainmenu'] = '在主菜单中显示进程列表',
  ['Start Of Scan: %d components'] = '扫描开始：%d 个组件',
  ['TStructCompareScanner.Error:'] = 'TStructCompareScanner 错误：',
  ['Ultimap2 Parse Trace As Text'] = 'Ultimap2 将跟踪解析为文本',
  ['Unknown Initial Value Hotkey'] = '未知初始值热键',
  ['memorybrowser timer2 error: '] = '内存浏览器 timer2 错误：',
  ['setthreadcontextarm64 failed'] = 'setthreadcontextarm64 失败',
  ['"Group 1" has common value 0x'] = '“分组 1”具有共同值 0x',
  ['"Group 2" has common value 0x'] = '“分组 2”具有共同值 0x',
  ['Error while accepting parent:'] = '接受父节点时出错：',
  ['GetProcessIptTraceSize failed'] = 'GetProcessIptTraceSize 失败',
  ['Highlighted Ultimap secondary'] = '高亮Ultimap副色',
  ['Mouse-Shortcut already exists'] = '鼠标快捷方式已存在',
  ['Reading the executable memory'] = '正在读取可执行内存',
  ['Selected All Match Color Diff'] = '已选择全部匹配但不同的颜色',
  ['Selected All Match Color Same'] = '已选择全部匹配且相同的颜色',
  ['Setting DBVM Watch Breakpoint'] = '正在设置 DBVM 监视断点',
  ['TPointerlistloader exception:'] = 'TPointerlistloader 异常：',
  ['Tablist: Invalid tab selected'] = '标签列表：选择的标签无效',
  ['Trace activated and recording'] = '跟踪已激活并正在记录',
  ['Use dbk32 QueryMemoryRegionEx'] = '使用 dbk32 QueryMemoryRegionEx',
  ['Using the kernelmode debugger'] = '正在使用内核模式调试器',
  [' because the write to address '] = '，因为写入地址 ',
  ['Cheat Engine Pointerlist|*.PTR'] = 'CE指针列表|*.PTR',
  ['Error in TAllocWatcher.execute'] = 'TAllocWatcher.execute 出错',
  ['Error in memview update timer:'] = '内存视图更新计时器出错：',
  ['Failure getting DBVM trace. : '] = '获取 DBVM 跟踪失败：',
  ['Failure setting a memory watch'] = '设置内存监视失败',
  ['Failure setting programcounter'] = '设置程序计数器失败',
  ['Failure to kill previous trace'] = '终止上一个跟踪失败',
  ['Invalid formula Syntax Error: '] = '公式无效，语法错误：',
  ['Memscan TScanController thread'] = 'Memscan TScanController 线程',
  ['New Scan-Unknown Initial Value'] = '首次扫描-未知初始值',
  ['No framepointer register found'] = '未找到帧指针寄存器',
  ['Not in the list yet. Adding it'] = '尚不在列表中。正在添加',
  ['Pointer Preview Priority Level'] = '指针预览优先级',
  ['Save memoryregion scansettings'] = '保存内存区域扫描设置',
  ['Setting DBVM Native Breakpoint'] = '正在设置 DBVM 原生断点',
  ['The provided physical address '] = '提供的物理地址 ',
  ['Ultimap2 Auto Process Interval'] = 'Ultimap2 自动处理间隔',
  ['symbolsync acquire lock failed'] = 'symbolsync 获取锁失败',
  [' did not end up into an address'] = ' 最终未变成地址',
  ['(Freeing scanner thread memory)'] = '(正在释放扫描线程内存)',
  ['Add Allocated Memory As Watched'] = '将已分配内存添加为监视项',
  ['Assembling VEH injection script'] = '正在汇编 VEH 注入脚本',
  ['Corrupt disableInfo section at '] = 'disableInfo 区段损坏，位置 ',
  ['CreateToolhelp32Snapshot failed'] = 'CreateToolhelp32Snapshot 失败',
  ['Error in TDisplayThread.execute'] = 'TDisplayThread.execute 出错',
  ['Failed to rename sorted results'] = '重命名已排序结果失败',
  ['Failure lowering the ipt size: '] = '降低 IPT 大小时失败：',
  ['Failure reading original memory'] = '读取原始内存失败',
  ['Invalid child structure object:'] = '子结构对象无效：',
  ['Invalid scan script at entry %d'] = '条目%d扫描脚本无效',
  ['Max Pointer Preview Field Count'] = '最大指针预览字段数',
  ['QSetDetachOnError not supported'] = '不支持 QSetDetachOnError',
  ['Service Descriptor Table Shadow'] = '服务描述符表影子',
  ['Structure Compare Max Addresses'] = '结构比较最大地址数',
  ['The scanner is being terminated'] = '扫描器正在终止',
  ['Ultimap2 Pause while processing'] = 'Ultimap2 处理时暂停',
  ['Unexpected Breakpoint Behaviour'] = '意外的断点行为',
  [' pages of physcal memory to DBVM'] = ' 页物理内存给 DBVM',
  ['C-Sharp compiler creation failed'] = 'C-Sharp 编译器创建失败',
  ['ErrorOnChildStructChange was set'] = '已设置 ErrorOnChildStructChange',
  ['Failure creating executor thread'] = '创建执行器线程失败',
  ['Failure deleting the scanresults'] = '删除扫描结果失败',
  ['Failure starting the DotNet host'] = '无法启动 .NET host',
  ['Failure to load vehdebug library'] = '加载 vehdebug 库失败',
  ['Invalid registry data type: "%s"'] = '注册表数据类型无效："%s"',
  ['Invalid system register notation'] = '系统寄存器表示法无效',
  ['Not a valid disableInfo variable'] = '不是有效的 disableInfo 变量',
  ['Only show current compare column'] = '仅显示当前比较列',
  ['Only usable from the main thread'] = '只能从主线程使用',
  ['Ultimap2 Don\'t delete tracefiles'] = 'Ultimap2 不删除跟踪文件',
  ['Use dbk32 ReadWriteProcessMemory'] = '使用 dbk32 ReadWriteProcessMemory',
  ['disableBreakpoint: invalid index'] = 'disableBreakpoint：索引无效',
  ['empty name for a system register'] = '系统寄存器名称为空',
  ['error parsing the features data:'] = '解析功能数据时出错：',
  ['invalid inputfile (wrong header)'] = '输入文件无效 (文件头错误)',
  ['lua_pcall with invalid parameter'] = 'lua_pcall 参数无效',
  ['obfucateString failed for text: '] = 'obfucateString 处理文本失败：',
  ['  This script does blah blah blah'] = '  此脚本执行这样那样的操作',
  [' Threadunsafe GUI access detected'] = '线程不安全GUI访问',
  ['CMD_CHANGEMEMORYPROTECTION failed'] = 'CMD_CHANGEMEMORYPROTECTION 失败',
  ['Error while accepting connection:'] = '接受连接时出错：',
  ['Failed to get data for value "%s"'] = '获取值 "%s" 的数据失败',
  ['Failed to set data for value "%s"'] = '设置值 "%s" 的数据失败',
  ['Failure encoding AA script line :'] = '编码 AA 脚本行失败：',
  ['Failure reading the original byte'] = '读取原始字节失败',
  ['GetFileSizeEx failed with error: '] = 'GetFileSizeEx 失败，错误：',
  ['Pause when scanning on by default'] = '默认扫描时暂停',
  ['Update Foundaddress list Interval'] = '已找到地址列表更新间隔',
  ['activateBreakpoint: invalid index'] = 'activateBreakpoint：索引无效',
  ['ccode section compilation failed:'] = 'ccode 段编译失败：',
  ['loadModule(Local) didn\'t even run'] = 'loadModule(Local) 甚至没有运行',
  ['secondary getthreadcontext error:'] = '第二次 getthreadcontext 错误：',
  ['secondary setthreadcontext error:'] = '第二次 setthreadcontext 错误：',
  ['Attach to foregroundprocess Hotkey'] = '附加到前台进程热键',
  ['Enter the description to filter on'] = '输入要用于过滤的描述',
  ['Failure assembling remote executor'] = '汇编远程执行器失败',
  ['Failure reading the result address'] = '读取结果地址失败',
  ['Invalid result for aob region scan'] = 'AOB 区域扫描结果无效',
  ['LUA_DoScript failure: package.path'] = 'LUA_DoScript 失败：package.path',
  ['TDBVMWatchExecutePollThread crash:'] = 'TDBVMWatchExecutePollThread 崩溃：',
  ['Tried to close invalid fake handle'] = '尝试关闭无效的虚假句柄',
  ['Ultimap2 Auto Process Max Filesize'] = 'Ultimap2 自动处理最大文件大小',
  ['Using GDBServer debugger interface'] = '正在使用 GDBServer 调试器接口',
  ['unknown stoppacket \'thread\' field:'] = '未知的 stoppacket \'thread\' 字段：',
  [' was not writable. It should be now'] = ' 之前不可写。现在应该已可写',
  ['Can only resize private type memory'] = '只能调整私有类型内存的大小',
  ['CheckIfConditionIsMetContext error:'] = 'CheckIfConditionIsMetContext 错误：',
  ['DebugActiveProcess: Opening process'] = 'DebugActiveProcess：正在打开进程',
  ['Failure setting software breakpoint'] = '设置软件断点失败',
  ['Failure stopping the target process'] = '停止目标进程失败',
  ['Invalid parameter. Must be a string'] = '参数无效。必须是字符串',
  ['Skip Symbols For AOBSCAN Script Gen'] = 'AOBSCAN 脚本生成时跳过符号',
  ['Trace step out set breakpoint error'] = '跟踪步出设置断点错误',
  ['Tracewindow closed. Stopping tracer'] = '跟踪窗口已关闭。正在停止跟踪器',
  ['the given ID is not valid (anymore)'] = '给定的 ID 已不再有效',
  ['tracer addRecord failed with error:'] = 'tracer addRecord 失败，错误：',
  ['Ask to clear list on process opening'] = '打开进程时询问是否清空列表',
  ['Expected ARM context, received type '] = '应为 ARM 上下文，收到类型 ',
  ['Failure writing referenced addresses'] = '写入引用地址失败',
  ['Give the process name to auto attach'] = '输入要自动附加的进程名',
  ['Replace incomplete opcodes with NOPS'] = '用 NOP 替换不完整的操作码',
  ['The current scan has been terminated'] = '当前扫描已终止',
  ['The current table has been saved to '] = '当前表已保存到 ',
  ['Ultimap2 Auto Process Every Interval'] = 'Ultimap2 每隔一段时间自动处理',
  ['hostfxr_get_runtime_delegate failed:'] = 'hostfxr_get_runtime_delegate 失败：',
  ['2nd parameter needs to be a bytetable'] = '第 2 个参数需要是字节表',
  ['Failed to create CLRMetaHost instance'] = '无法创建 CLRMetaHost 实例',
  ['Failure loading the trainer. Reason :'] = '加载修改器失败。原因：',
  ['Failure mapping memorymap into memory'] = '将内存映射载入内存失败',
  ['Failure to assemble exception handler'] = '汇编异常处理器失败',
  ['No instruction pointer register found'] = '未找到指令指针寄存器',
  ['TSymhandler.loadmodulelist exception:'] = 'TSymhandler.loadmodulelist 异常：',
  ['Tried activating a deleted breakpoint'] = '尝试激活已删除的断点',
  ['Unexpected type for memory protection'] = '内存保护类型异常',
  ['Warning: pipe access from main thread'] = '警告：从主线程访问管道',
  ['Allocation error.  Failed to allocate '] = '分配错误。分配失败：',
  ['Can\'t grow memoryregions inside myself'] = '无法在自身内部扩展内存区域',
  ['Expected ARM64 context, received type '] = '应为 ARM64 上下文，收到类型 ',
  ['Failure duplicating HasDataEventHandle'] = '复制 HasDataEventHandle 失败',
  ['Invalid reply from PSCMD_UPLOADRESULTS'] = '来自 PSCMD_UPLOADRESULTS 的回复无效',
  ['Invalid value field. Has to be a table'] = '值字段无效。必须是表',
  ['Speedhack: Error hooking timeGetTime: '] = '变速精灵：Hook timeGetTime 时出错：',
  ['The old protection of that region was '] = '该区域的旧保护属性为 ',
  ['This fpu type is currently unsupported'] = '当前不支持此 FPU 类型',
  ['This system doesn\'t have QueueUserAPC2'] = '此系统没有 QueueUserAPC2',
  ['Unknown error getting the address for '] = '获取地址时发生未知错误：',
  ['threaded debugger attach took too long'] = '线程化调试器附加耗时过长',
  ['&Base address must be in specific range'] = '基址必须在指定范围内(&B)',
  ['&Save the memoryregions to scan options'] = '保存扫描区域选项',
  ['&Stack addresses as ONLY static address'] = '栈地址仅作静态地址',
  ['Are you sure you wish to hook Direct3D?'] = '确定要 Hook Direct3D 吗?',
  ['Failure to get the process and threadid'] = '获取进程和线程 ID 失败',
  ['Invalid timeout for createthreadandwait'] = 'createthreadandwait 的超时时间无效',
  ['Log IPT buffers inside FindWhat results'] = '在“查找访问/写入来源”结果中记录 IPT 缓冲区',
  ['MainForm is undefined. Invalid CE Build'] = 'MainForm 未定义。CE 构建无效',
  ['ProgramCounter read while not suspended'] = '未暂停时读取 ProgramCounter',
  ['abandoned.  Has been marked as free now'] = '已放弃。现在已标记为空闲',
  ['co_run without breakpoint. (this is ok)'] = 'co_run 没有断点。(这是正常的)',
  ['debuggerthread was terminated. Reason: '] = '调试器线程已终止。原因：',
  ['getAddressFromScript with an empty name'] = 'getAddressFromScript 使用了空名称',
  ['All executable memory outside of modules'] = '模块之外的全部可执行内存',
  ['Curent scan has ended and savestate=true'] = '当前扫描已结束且 savestate=true',
  ['Deleting all tracer stepover breakpoints'] = '正在删除所有跟踪器步过断点',
  ['Failure allocating memory for the C-code'] = '为 C 代码分配内存失败',
  ['Invalid xmm register format (Not F or D)'] = 'XMM 寄存器格式无效（不是 F 或 D）',
  ['ProgramCounter write while not suspended'] = '未暂停时写入 ProgramCounter',
  ['Remap: Failure duplicating memmap handle'] = '重新映射：复制内存映射句柄失败',
  ['UNHOOK can not work without disable info'] = '没有禁用信息时 UNHOOK 无法工作',
  ['VEH injection script assembled succesful'] = 'VEH 注入脚本汇编成功',
  ['Can only resize a standalone memoryregion'] = '只能调整独立内存区域的大小',
  ['Criticalsection leave by non-owner thread'] = '非所有者线程离开临界区',
  ['Currently fetching the structure data of:'] = '当前正在获取结构数据：',
  ['Failure getting the address for c-symbol '] = '获取 C 符号地址失败：',
  ['First parameter for try is not a function'] = 'try 的第一个参数不是函数',
  ['New size is smaller than the given region'] = '新大小小于给定区域',
  ['No mainthread access to this pipe allowed'] = '不允许主线程访问此管道',
  ['Socket creation failed. Check permissions'] = '创建套接字失败。请检查权限',
  ['Ultimap2 Auto Process When Filesize Above'] = 'Ultimap2 文件大小超过指定值时自动处理',
  ['Ultimap2 Use built-in windows IPT support'] = 'Ultimap2 使用 Windows 内置 IPT 支持',
  ['VEH Real context on thread creation event'] = '线程创建事件上的 VEH 真实上下文',
  ['dbvm_watch_reads needs a physical address'] = 'dbvm_watch_reads 需要一个物理地址',
  ['fTotalvisibledisassemblerlines is invalid'] = 'fTotalvisibledisassemblerlines 无效',
  ['AddressList is undefined. Invalid CE Build'] = 'AddressList 未定义。CE 构建无效',
  ['Enter the processid (decimal) to attach to'] = '输入要附加的进程 ID (十进制)',
  ['Failure obtaining physical address for %8x'] = '获取 %8x 的物理地址失败',
  ['LinkWithMemoryview: Invalid memview object'] = 'LinkWithMemoryview：memview 对象无效',
  ['Luacode is not yet supported on arm 32 bit'] = '32 位 ARM 尚不支持 Luacode',
  ['You can not load tables from other threads'] = '不能从其他线程加载表',
  ['dbvm_watch_writes needs a physical address'] = 'dbvm_watch_writes 需要一个物理地址',
  ['failure to get the exitcode of the thread.'] = '获取线程退出代码失败。',
  ['(Optimizing result list for improved speed)'] = '(正在优化结果列表以提高速度)',
  ['Do not touch the hexview from other threads'] = '不要从其他线程操作十六进制视图',
  ['Failure obtaining target memory information'] = '获取目标内存信息失败',
  ['Failure releasing the original memoryregion'] = '释放原始内存区域失败',
  ['Initial scan to determine the memory needed'] = '初始扫描，用于确定所需内存',
  ['Invalid datastream from dotnetdatacollector'] = '来自 dotnetdatacollector 的数据流无效',
  ['Received a debug event that wasn\'t injected'] = '收到未注入的调试事件',
  ['VMCALL_CLOAK_TRACEONBP failed. it returned '] = 'VMCALL_CLOAK_TRACEONBP 失败，返回 ',
  ['option DBVMBP needs a usermode loop address'] = 'DBVMBP 选项需要一个用户态循环地址',
  ['processThreadEvents from more than 1 thread'] = '从多个线程调用了 processThreadEvents',
  ['{$LUACODE} blocks can not be used inside CE'] = '{$LUACODE} 块不能在 CE 内部使用',
  ['Debugger error while handling lua callbacks:'] = '处理 Lua 回调时发生调试器错误：',
  ['Failure creating remote executor filemapping'] = '创建远程执行器文件映射失败',
  ['Failure starting windows based IPT session: '] = '启动基于 Windows 的 IPT 会话失败：',
  ['Invalid string passed to getRegionFromString'] = '传递给 getRegionFromString 的字符串无效',
  ['Link read error. Origin for a link not found'] = '链接读取错误。找不到链接起点',
  ['Remap: Failure mapping memorymap into memory'] = '重新映射：将内存映射载入内存失败',
  ['Speedhack: Error assembling speedhack init 1'] = '变速精灵：汇编变速初始化 1 时出错',
  ['This tree has no datasize assigned for nodes'] = '此树没有为节点分配数据大小',
  ['createthreadandwait did not execute properly'] = 'createthreadandwait 未正确执行',
  ['Enter the custom alignment (<=0 is automatic)'] = '输入自定义对齐值 (<=0 为自动)',
  ['Error retrieving the IPT log. Try again later'] = '获取 IPT 日志时出错。请稍后重试',
  ['Failure getting the physical address of this '] = '获取此项的物理地址失败：',
  ['Failure querying present memory: invalid size'] = '查询当前内存失败：大小无效',
  ['Invalid lua code in {$LUACODE} block at line '] = '{$LUACODE} 块中的 Lua 代码无效，行 ',
  ['TDBVMWatchPollThread.addEntriesToList error: '] = 'TDBVMWatchPollThread.addEntriesToList 错误：',
  ['This is currently only functional for windows'] = '此功能当前仅适用于 Windows',
  ['You can only load tables from the main thread'] = '只能从主线程加载表',
  ['hostfxr_initialize_for_runtime_config failed:'] = 'hostfxr_initialize_for_runtime_config 失败：',
  ['instantrescanfiles was not empty. Cleaning it'] = 'instantrescanfiles 不为空。正在清理',
  ['A lua script wants to load the driver. Reason:'] = '一个 Lua 脚本想要加载驱动。原因：',
  ['Corrupt disableInfo section at the allocs side'] = 'allocs 侧的 disableInfo 区段损坏',
  ['Failure obtaining subsequent memoryregion info'] = '获取后续内存区域信息失败',
  ['Failure writing the generated c-code to memory'] = '将生成的 C 代码写入内存失败',
  ['The following C-Code symbols where registered:'] = '已注册以下 C 代码符号：',
  ['There are threads and currentscanhasended=true'] = '仍有线程且 currentscanhasended=true',
  ['Unhandled exception while markExecutedPages...'] = 'markExecutedPages 时发生未处理异常...',
  ['are you sure you wish to delete the selection?'] = '确定要删除所选内容吗？',
  ['controller exception happened during the scan:'] = '扫描期间控制器发生异常：',
  ['(Copying results for first scan scanner option)'] = '(正在复制首次扫描结果)',
  ['Corrupt disableInfo section at the symbols side'] = 'symbols 侧的 disableInfo 区段损坏',
  ['Do not delete elements from internal structures'] = '不要从内部结构中删除元素',
  ['Exception when closing pipe. Debugger attached?'] = '关闭管道时发生异常。是否已附加调试器？',
  ['Failure duplicating HasProcessedDataEventHandle'] = '复制 HasProcessedDataEventHandle 失败',
  ['Failure to set the exception list. Thread error'] = '设置异常列表失败。线程错误',
  ['First parameter needs to be a threadevent table'] = '第一个参数必须是 threadevent 表',
  ['Invalid xmm register format (Invalid dot usage)'] = 'XMM 寄存器格式无效（点号用法无效）',
  ['Select the source for executable memory regions'] = '选择可执行内存区域的来源',
  ['Symbolhandler was terminated. Not going to sync'] = '符号处理器已终止。不会同步',
  ['The thumb instruction set is not yet suppported'] = '尚不支持 Thumb 指令集',
  ['VMCALL_CLOAK_CHANGEREGONBP failed. it returned '] = 'VMCALL_CLOAK_CHANGEREGONBP 失败，返回 ',
  ['Visible disassembler used in an external thread'] = '在外部线程中使用了可见反汇编器',
  ['WaitTillAttachedOrError exit. Took %.2f seconds'] = 'WaitTillAttachedOrError 退出。耗时 %.2f 秒',
  ['Killed thread that tried to access a GUI control'] = '已终止试图访问 GUI 控件的线程',
  ['CE Trace (*.cetrace)|*.cetrace|All file (*.*)|*.*'] = 'CE 跟踪 (*.cetrace)|*.cetrace|所有文件 (*.*)|*.*',
  ['Failure querying present memory: unexpected error'] = '查询当前内存失败：意外错误',
  ['Failure waiting for page mark operation to finish'] = '等待页面标记操作完成失败',
  ['Link read error. Destination for a link not found'] = '链接读取错误。找不到链接目标',
  ['Scanning int3 executable memory in target process'] = '正在扫描目标进程中的 int3 可执行内存',
  ['Skipped because symbols are being loaded... (wtf)'] = '已跳过，因为符号正在加载...',
  ['TPointerscanController.SetupQueueForResume Error:'] = 'TPointerscanController.SetupQueueForResume 错误：',
  ['Address text file (*.txt)|*.txt|All file (*.*)|*.*'] = '地址文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*',
  ['Enter the component you wish to add. (E.g TButton)'] = '输入要添加的组件。（例如 TButton）',
  ['Error: GUI Control access outside of main thread ('] = '错误：在主线程之外访问 GUI 控件 (',
  ['Fatal error while trying to delete the scanresults'] = '尝试删除扫描结果时发生致命错误',
  ['No readable memory was found in the selected range'] = '在所选范围内未找到可读内存',
  ['Speedhack: Error hooking kernelbase.GetTickCount: '] = '变速精灵：Hook kernelbase.GetTickCount 时出错：',
  ['This window will close once the symbols are loaded'] = '符号加载完成后此窗口将关闭',
  ['hdt_load_assembly_and_get_function_pointer failed:'] = 'hdt_load_assembly_and_get_function_pointer 失败：',
  ['Not enough parameters. Minimum: callmethod, address'] = '参数不足。至少需要：callmethod, address',
  ['Remap: Failure creating remote executor filemapping'] = '重新映射：创建远程执行器文件映射失败',
  ['Speedhack: Error hooking kernel32.GetTickCount64 : '] = '变速精灵：Hook kernel32.GetTickCount64 时出错：',
  ['Failed obtaining the physical address of this memory'] = '获取此内存的物理地址失败',
  ['Only the GDB server debugger can set GDB breakpoints'] = '只有 GDB 服务器调试器可以设置 GDB 断点',
  ['Stopped was true but no stoppacket set... Continuing'] = 'Stopped 为 true，但未设置 stoppacket... 继续',
  ['This is the frozen thread so use the internal method'] = '这是被冻结的线程，因此使用内部方法',
  ['Corrupt disableInfo section at the exceptionlist side'] = 'exceptionlist 侧的 disableInfo 区段损坏',
  ['Error during TSavedScanHandler.InitializeScanHandler:'] = 'TSavedScanHandler.InitializeScanHandler 期间出错：',
  ['Failure determining if the DotNet runtime is loadable'] = '无法判断 .NET 运行时是否可加载',
  ['Found an {$EXCEPT} at line %d with no matching {$TRY}'] = '在第 %d 行找到 {$EXCEPT}，但没有匹配的 {$TRY}',
  ['Only the DBVM debugger can set DBVMNative breakpoints'] = '只有 DBVM 调试器可以设置 DBVMNative 断点',
  ['The parent has been abandoned. Discarding the results'] = '父节点已被放弃。正在丢弃结果',
  ['Invalid lua code in internal {$LUACODE} block at line '] = '内部 {$LUACODE} 块中的 Lua 代码无效，行 ',
  ['The execute page mark operating is failing to terminate'] = '执行页标记操作无法终止',
  ['The previous scan is still being processed. Please wait'] = '上一次扫描仍在处理中。请稍候',
  ['setSpecialScanOptionsOverride error. No parameter given'] = 'setSpecialScanOptionsOverride 错误。未提供参数',
  ['Only possible when target is suspended from the debugger'] = '只有目标被调试器挂起时才可以执行',
  ['The ceserver seems to be gone. Stop trying to reconnect?'] = 'ceserver 似乎已断开。停止尝试重新连接吗？',
  ['Your last changes will be lost if you proceed. Continue?'] = '继续操作将丢失你上次的更改。是否继续？',
  ['A lua script wants to launch the DBVM hypervisor. Reason:'] = '一个 Lua 脚本想要启动 DBVM 虚拟机监控器。原因：',
  ['Corrupt disableInfo section at the registeredsymbols side'] = 'registeredsymbols 侧的 disableInfo 区段损坏',
  ['Currently fetching the structure list. Please stand by...'] = '正在获取结构列表。请稍候...',
  ['Failure growing the region as the next region is not free'] = '扩展区域失败，因为下一个区域不空闲',
  ['When done EAX will contain the result of the lua function'] = '完成后 EAX 将包含 Lua 函数的结果',
  ['When done RAX will contain the result of the lua function'] = '完成后 RAX 将包含 Lua 函数的结果',
  ['virtualprotectex failed while filling in the linked lists'] = '填充链表时 virtualprotectex 失败',
  ['Failed obtaining the current threadid from gdb stoppacket:'] = '从 GDB 停止包获取当前线程 ID 失败：',
  ['Failed opening process. Likely due to lack of admin rights'] = '打开进程失败。可能是缺少管理员权限',
  ['Incorrect paremeters: signExtend(value,mostSignificantBit)'] = '参数错误：signExtend(value,mostSignificantBit)',
  ['Invalid debugger state: Context has no instruction pointer'] = '调试器状态无效：上下文没有指令指针',
  ['No idea how to handle the type you provided for parameter '] = '不知道如何处理你为参数提供的类型：',
  ['The debugger thread seems to be unresponsive. Wait longer?'] = '调试器线程似乎没有响应。继续等待吗？',
  ['Failure restoring data in reallocated block. ALL DATA LOST!'] = '恢复重新分配块中的数据失败。所有数据已丢失！',
  ['Scanning int3 executable memory in kernel. Step 2: Scanning'] = '正在扫描内核中的 int3 可执行内存。步骤 2：扫描',
  ['debuggerthread was terminated. Reason:No debugger interface'] = '调试器线程已终止。原因：没有调试器接口',
  ['Not enough parameters. Minimum: callmethod, timeout, address'] = '参数不足。至少需要：callmethod, timeout, address',
  ['Scanning int3 executable memory in kernel CR3=%8x (index %d)'] = '正在扫描内核 CR3=%8x 中的 int3 可执行内存(索引 %d)',
  ['StartBranchMap can not function with this debugger interface'] = 'StartBranchMap 无法与此调试器接口配合使用',
  ['This code requires the TCC Library, but it failed to compile'] = '此代码需要 TCC 库，但编译失败',
  ['This window will close when all symbols have been enumerated'] = '所有符号枚举完成后此窗口将关闭',
  ['(Still copying the results for the first scan scanner option)'] = '(仍在复制首次扫描结果)',
  ['A lua script needs CE to be running as administrator because '] = '一个 Lua 脚本要求 CE 以管理员身份运行，原因：',
  ['C++ Files (*.c,*.cpp,*.h,*.hpp,*.hh)|*.c;*.cpp;*.h;*.hpp;*.hh'] = 'C++ 文件 (*.c,*.cpp,*.h,*.hpp,*.hh)|*.c;*.cpp;*.h;*.hpp;*.hh',
  ['Instead of a table the ModuleListEventCallback returned type '] = 'ModuleListEventCallback 返回的不是表，而是类型 ',
  ['Not enough parameters. Minimum: callmethod, address, instance'] = '参数不足。至少需要：callmethod, address, instance',
  ['Failure allocating memory at the original region. No data lost'] = '在原始区域分配内存失败。没有数据丢失',
  ['Found entry for virtual address %.8x and physical address %.8x'] = '找到虚拟地址 %.8x 和物理地址 %.8x 的条目',
  ['setSpecialScanOptionsOverride error. Parameter must be a table'] = 'setSpecialScanOptionsOverride 错误。参数必须是表',
  ['Do not call processMessagesPaintOnly outside of the main thread'] = '不要在主线程之外调用 processMessagesPaintOnly',
  ['The parent disconnected from me before I could tell him goodbye'] = '父节点在我发送告别之前已断开连接',
  ['not all symbols where found for the exception handler injection'] = '异常处理器注入所需的符号未全部找到',
  ['Failure finding int3 bp code inside kernelmode executable memory'] = '在内核模式可执行内存中查找 int3 断点代码失败',
  ['Filter operation canceled. A filter operation was still going on'] = '过滤操作已取消。仍有过滤操作正在进行',
  ['Exception handler setup: failure getting the address of "setList"'] = '异常处理器设置：获取 "setList" 地址失败',
  ['Speedhack: speedhackversion_GetTickCount not found. Injecting DLL'] = '变速精灵：未找到 speedhackversion_GetTickCount。正在注入 DLL',
  ['Invalid hexadecimal bytestring or bytetable in the first parameter'] = '第一个参数中的十六进制字节字符串或字节表无效',
  ['Do not call getAddressFromSymbol from inside the symbolloaderthread'] = '不要从 symbolloaderthread 内部调用 getAddressFromSymbol',
  ['Unexpected result from DBVM. dbvm_cloak_traceonbp_readlog returned '] = 'DBVM 返回了意外结果。dbvm_cloak_traceonbp_readlog 返回 ',
  ['The pointerscanner seems to take a long time to terminate. Force it?'] = '指针扫描器似乎需要很长时间才能终止。要强制终止吗？',
  ['Secondary scan actually allocating the memory and filling in the data'] = '二次扫描，实际分配内存并填充数据',
  ['The current debuggerinterface does not support int1 based breakpoints'] = '当前调试器接口不支持基于 int1 的断点',
  ['You may not destroy this stream manually. Destroy the LuaFile instead'] = '不能手动销毁此流。请改为销毁 LuaFile',
  ['the start of a selection cannot be bigger than the length of the text'] = '选区起点不能大于文本长度',
  ['Address files (*.txt;*.ceaddress)|*.ceaddress;*.txt|All file (*.*)|*.*'] = '地址文件 (*.txt;*.ceaddress)|*.ceaddress;*.txt|所有文件 (*.*)|*.*',
  ['Not enough parameters. Minimum: threadid, callmethod, timeout, address'] = '参数不足。至少需要：threadid, callmethod, timeout, address',
  ['Scanning int3 executable memory in kernel. Step 1: Waiting for symbols'] = '正在扫描内核中的 int3 可执行内存。步骤 1：等待符号',
  ['There was an error loading the results. Check that the path is readable'] = '加载结果时出错。请检查路径是否可读',
  ['Enter the interval in which the offset should be updated. In milliseconds'] = '输入偏移更新间隔，单位为毫秒',
  ['openProcessEpilogue wasn\'t called from the main GUI thread. Do not do this!'] = 'openProcessEpilogue 不是从主 GUI 线程调用的。不要这样做！',
  ['you can not delete internal types (unless you make them non internal first)'] = '不能删除内部类型（除非先将其改为非内部类型）',
  ['No readable memory found. Please make sure you are attached to a live process'] = '未找到可读内存。请确保已附加到正在运行的进程',
  ['hostfxr_initialize_for_runtime_config or hostfxr_get_runtime_delegate missing'] = '缺少 hostfxr_initialize_for_runtime_config 或 hostfxr_get_runtime_delegate',
  ['How many milliseconds do you wish to wait before continueing the state restore?'] = '在继续恢复状态之前要等待多少毫秒？',
  ['A lua script needs CE to be running as administrator for no reason. Relaunch CE?'] = '一个 Lua 脚本无故要求 CE 以管理员身份运行。是否重新启动 CE？',
  ['An execute page mark operation is still in progress and hasn\'t been canceled yet'] = '执行页面标记操作仍在进行中，尚未取消',
  ['Not enough parameters. Minimum: threadid, callmethod, timeout, address, instance'] = '参数不足。至少需要：threadid, callmethod, timeout, address, instance',
  ['symbol wait is taking long in the main GUI. Showing dialog asking to cancel wait'] = '主界面中的符号等待耗时较长。正在显示询问是否取消等待的对话框',
  ['tried to set a thread specific breakpoint in a thread that it does not belong to'] = '尝试在线程专用断点不所属的线程中设置该断点',
  ['There are over 10000000 entries in this list. This may take a while. Are you sure?'] = '此列表中有超过 10000000 个条目，可能需要一段时间。确定吗？',
  ['Incorrect parameter count (needed 5: path,namespace,classname,methodname, parameters)'] = '参数数量不正确（需要 5 个：path、namespace、classname、methodname、parameters）',
  ['Benchmark will disable writing of results to disk. Are you sure this is what you wish?'] = '基准测试会禁用将结果写入磁盘。确定要这样做吗？',
  ['Cleared RAM usage. Make sure you execute the routine you\'re interested in at least once'] = '已清除 RAM 使用记录。请确保至少执行一次你感兴趣的例程',
  ['Incompatible Service Descriptor Table. This table contains more or less than in the file'] = '服务描述符表不兼容。此表的条目数量与文件中不一致',
  ['Failure allocating memory at the original region. Restoration of data failed. ALL DATA LOST!'] = '在原始区域分配内存失败。数据恢复失败。所有数据已丢失！',
  ['EXCEPTION_GDB_BREAKPOINT on a debugger interface that isn\'t the GDB server debugger interface'] = '在非 GDB 服务器调试器接口上出现 EXCEPTION_GDB_BREAKPOINT',
  ['This function requires that your CPU supports \'Extended Page Table (EPT)\' which your CPU lacks'] = '此功能要求 CPU 支持“扩展页表(EPT)”，但当前 CPU 不支持',
  ['Incompatible Service Descriptor Table Shadow. This table contains more or less than in the file'] = '服务描述符表影子不兼容。此表的条目数量与文件中不一致',
  ['You can\'t have a label defined to a newly compiled c symbol (chick egg issue) If possible, compile the C code first'] = '不能将标签定义到新编译的 C 符号上(先有鸡还是先有蛋的问题)。如果可以，请先编译 C 代码',
  ['DBVM find routines needs DBVM for EPT page hooking. Loading DBVM can potentially cause a system freeze. Are you sure?'] = 'DBVM 查找例程需要 DBVM 才能进行 EPT 页 Hook。加载 DBVM 可能导致系统冻结。确定吗？',
  ['Assembler error. The generated instruction referencing a label ended up bigger than expected. Try using the far indicator'] = '汇编器错误。生成的引用标签指令比预期更大。请尝试使用 far 指示符',
  ['No readable memory found. It looks like the target process has closed. You will need to reopen and attach to the new process'] = '未找到可读内存。目标进程似乎已经关闭。需要重新打开并附加到新进程',
  ['Failure allocating memory at the original region. Failed to restore original allocation. ALL DATA LOST, EXPECT MEMORY ERRORS!'] = '在原始区域分配内存失败。恢复原始分配失败。所有数据已丢失，预计会出现内存错误！',
  ['This file is corrupted or from an earlier CE version that didn\'t contain a header for structure spider files. Try to load it?'] = '此文件已损坏，或来自较早的 CE 版本，其中不包含结构 Spider 文件的头部。是否尝试加载？',
  ['This will require the IPT feature to be enabled in the debugger. Activate it now? (You will need a new break to record a log)'] = '这需要在调试器中启用 IPT 功能。现在启用吗？（需要新的中断才能记录日志）',
  ['Failure opening the selected process. You\'re currently not running as admin. Do you wish to try relaunching CE with admin rights?'] = '打开所选进程失败。当前未以管理员身份运行。是否尝试以管理员权限重新启动 CE？',
  ['This system does not support writable executable memory.  Tip: Pause the process, make writable, write, make executable, continue'] = '此系统不支持可写且可执行的内存。提示：暂停进程，设为可写，写入，再设为可执行，然后继续',
  ['This trace was made with the 32-bit version of Cheat Engine. You need to use that version to see the register values and stacktrace'] = '此跟踪由 32 位版本的 Cheat Engine 创建。你需要使用该版本才能查看寄存器值和堆栈跟踪',
  ['Select two spots that are the same address (It is possible the address does not exist. In that case, pick another. Tip: function end)'] = '请选择两个地址相同的位置（该地址可能不存在；如果是这样，请选择另一个。提示：函数结尾）',
  ['This file belongs to a newer version of Cheat Engine. The binary layout is unknown to the current version and thus will not be able to load'] = '此文件属于较新版本的 Cheat Engine。当前版本不了解其二进制布局，因此无法加载',
  ['You can disable this error by executing \'setThreadSafetyCheck(false)\' but you will end up having unexpected behaviour at random when this code runs'] = '你可以执行 \'setThreadSafetyCheck(false)\' 来禁用此错误，但这段代码运行时最终会随机出现意外行为',
  ['Hook needs at least 2 parameters: The address to hook, and the address to go to.  Optionally a 3th parameter containing the symbolname for the original code stub'] = 'Hook 至少需要 2 个参数：要 Hook 的地址，以及要跳转到的地址。可选第 3 个参数用于指定原始代码桩的符号名',
}

local CE_DRAW_TEXT_HOOK_ENABLED = true
local CE_DRAW_TEXT_DATA_SIZE = 1048576
local CE_DRAW_TEXT_MAX_SOURCE_LEN = 512

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

local function hexBytes(bytes)
  local out = {}
  for i = 1, #bytes do
    out[#out + 1] = string.format('%02X', bytes[i])
  end
  return table.concat(out, ' ')
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

-- 判断当前 Cheat Engine 自身位数，决定原生 Hook 使用 32 位还是 64 位 ABI。
local function ceIs64Bit()
  if type(cheatEngineIs64Bit) == 'function' then
    local ok, value = pcall(cheatEngineIs64Bit)
    if ok and type(value) == 'boolean' then return value end
  end

  if type(getSystemArchitecture) == 'function' then
    local ok, value = pcall(getSystemArchitecture)
    if ok and type(value) == 'number' then
      if value == 0 or value == 2 then return false end
      if value == 1 or value == 3 then return true end
    end
  end

  if type(getApplication) == 'function' then
    local ok, app = pcall(getApplication)
    local exeName = ok and app and app.ExeName
    if type(exeName) == 'string' then
      local lower = (exeName:match('[^\\/]+$') or exeName):lower()
      if lower:find('i386', 1, true) then return false end
      if lower:find('x86_64', 1, true) or lower:find('64', 1, true) then return true end
    end
  end

  return true
end

-- 把偏移或大小向上对齐到指定边界。
local function alignUp(value, alignment)
  alignment = alignment or 16
  return math.floor((value + alignment - 1) / alignment) * alignment
end

-- 共享工具函数回退
local checkedCall = (_G.zhCNUtil and _G.zhCNUtil.checkedCall) or function(fn, ...)
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then return true, a, b, c, d end
  return false, nil
end

-- 用 AA 修补内存视图顶部的 AllocationBase= 固定文本。
local function patchAllocationBaseText()
  if not zhCNNativeHooksEnabled() then return false end
  local ok, result = checkedCall(function()
    local moduleName = '"' .. extractFileName(getApplication().ExeName) .. '"'
    local pattern
    local lenOffset
    local lenDirective

    if ceIs64Bit() then
      pattern = '41 6C 6C 6F 63 61 74 69 6F 6E 42 61 73 65 3D 00 00 00 01 00 00 00 00 00 FF FF FF FF FF FF FF FF'
      lenOffset = '-8'
      lenDirective = 'dq 0D'
    else
      pattern = '41 6C 6C 6F 63 61 74 69 6F 6E 42 61 73 65 3D 00 00 00 01 00 FF FF FF FF 01 00 00 00 3D 00'
      lenOffset = '-4'
      lenDirective = 'dd 0D'
    end

    autoAssemble(
      'aobscanmodule(allocBase,' .. moduleName .. ',' .. pattern .. ')\n' ..
      'allocBase' .. lenOffset .. ':\n' ..
      '  ' .. lenDirective .. '\n' ..
      'allocBase:\n' ..
      '  db E5 88 86 E9 85 8D E5 9F BA E5 9D 80 3D 00 00 00',
      true)
  end)
  return ok and result ~= false
end

-- 修补 Auto Assembler 模板里的动态注释前缀；后续模块名和偏移仍由 CE 原逻辑追加。
local function patchAutoAssemblerTemplateText()
  if not zhCNNativeHooksEnabled() then return false end
  if type(autoAssemble) ~= 'function' then return false end

  local patches = {
    {
      '// ORIGINAL CODE - INJECTION POINT: ',
      '// 原始代码 - 注入点位置:  ',
    },
    {
      '// ---------- INJECTING HERE ----------',
      '// ---------- 正在注入 ----------',
    },
    {
      '// ---------- DONE INJECTING  ----------',
      '// ---------- 注入完成 ----------',
    },
    {
      '//This mostly obsolete and only for certain special cases. For normal usage it is recommended to use {$luacode}/{$asm} blocks instead',
      '// 此模板基本过时，仅用于特殊情况；通常建议改用 {$luacode}/{$asm} 块',
      false,
    },
    {
      '//luacall call example:',
      '//luacall 调用示例:',
    },
    {
      '//Make sure rsp is aligned on a 16-byte boundary when calling this function',
      '//调用此函数时，请确保 rsp 按 16 字节边界对齐',
    },
    {
      'mov rcx, addresstostringwithfunction //(The lua function will have access to the variable passed by name "parameter")',
      'mov rcx, addresstostringwithfunction //Lua 函数可通过名为 "parameter" 的变量访问此值',
    },
    {
      'call CELUA_ExecuteFunction // or CELUA_ExecuteFunctionAsync if you don\'t need GUI access or want to handle it yourself',
      'call CELUA_ExecuteFunction // 或用 CELUA_ExecuteFunctionAsync：不需 GUI 访问或自行处理时使用',
    },
    {
      '//Alternate call by ref example:',
      '//按引用调用示例:',
    },
    {
      'call CELUA_GetFunctionReferenceFromName  //Basically calls createRef(functionname) and returns the value',
      'call CELUA_GetFunctionReferenceFromName  // 基本等同 createRef(functionname)，返回引用 ID',
    },
    {
      'mov r8,addresswithparameterlist  //could be the stack.  e.g lea r8,[rsp+8]',
      'mov r8,addresswithparameterlist  // 可以是栈，如 lea r8,[rsp+8]',
    },
    {
      'mov r9,0 //0=no async, 1=async.  Use async if you do not wish to update the GUI. Faster',
      'mov r9,0 //0=同步，1=异步。不想更新 GUI 时用异步，更快',
    },
    {
      'When done RAX will contain the result of the lua function',
      '完成后 RAX 保存 Lua 函数结果',
    },
    {
      'And as per 64-bit calling convention, RCX, RDX, R8, R9, R10, R11 may have been altered. So save/restore them beforehand',
      '按 64 位调用约定，RCX、RDX、R8、R9、R10、R11 可能被修改，请提前保存/恢复',
    },
    {
      'push addresstostringwithfunction  //(The lua function will have access to the variable passed by name "parameter")',
      'push addresstostringwithfunction  //Lua 函数可通过名为 "parameter" 的变量访问此值',
    },
    {
      'push 0 //0=no async, 1=async.  Use async if you do not wish to update the GUI. Faster',
      'push 0 //0=同步，1=异步。不想更新 GUI 时用异步，更快',
    },
    {
      'push eax //push the reference ID of the function',
      'push eax //压入函数引用 ID',
    },
    {
      'When done EAX will contain the result of the lua function',
      '完成后 EAX 保存 Lua 函数结果',
    },
    {
      'And as per common 32-bit calling convention, EDX and ECX could have been altered. So save/restore them beforehand',
      '按常见 32 位调用约定，EDX 和 ECX 可能被修改，请提前保存/恢复',
    },
  }

  local moduleName = '"' .. extractFileName(getApplication().ExeName) .. '"'
  local bulkPatchScripts = {}
  local optionalPatchScripts = {}
  local patched = false
  for i = 1, #patches do
    local original = patches[i][1]
    local replacement = patches[i][2]
    local includeInBulk = patches[i][3] ~= false
    local originalLen = #original
    local replacementBytes = bytesOfString(replacement, false)
    if #replacementBytes <= originalLen then
      while #replacementBytes < originalLen do
        replacementBytes[#replacementBytes + 1] = 0x20
      end

      local pattern = hexBytes(bytesOfString(original, true))
      local replacementDb = hexBytes(replacementBytes)
      local patchScript =
        'aobscanmodule(zhAATemplateText' .. tostring(i) .. ',' .. moduleName .. ',' .. pattern .. ')\n' ..
        'zhAATemplateText' .. tostring(i) .. ':\n' ..
        '  db ' .. replacementDb
      if includeInBulk then
        bulkPatchScripts[#bulkPatchScripts + 1] = patchScript
      else
        optionalPatchScripts[#optionalPatchScripts + 1] = patchScript
      end
    end
  end

  if #bulkPatchScripts == 0 and #optionalPatchScripts == 0 then return false end

  -- 稳定模板走单次 AA 批量修补；未来版本缺少个别模板时，再退回逐条修补。
  if #bulkPatchScripts > 0 then
    local ok, result = checkedCall(function()
      return autoAssemble(table.concat(bulkPatchScripts, '\n'), true)
    end)
    if ok and result ~= false then
      patched = true
    else
      for i = 1, #bulkPatchScripts do
        ok, result = checkedCall(function()
          return autoAssemble(bulkPatchScripts[i], true)
        end)
        if ok and result ~= false then patched = true end
      end
    end
  end

  -- 长说明文案版本间容易变化，单独尝试，避免拖累整批稳定模板。
  for i = 1, #optionalPatchScripts do
    local ok, result = checkedCall(function()
      return autoAssemble(optionalPatchScripts[i], true)
    end)
    if ok and result ~= false then patched = true end
  end

  return patched
end

local AA_SCRIPT_TEMPLATE_REPLACEMENTS = {
  { '--already detoured. Undo first', '--已经 Detour，先撤销' },
  { '//for NoInlining', '//用于 NoInlining' },
  { '//feel free to add more', '//可按需添加更多引用' },
  {
    '//you have access to public fields.  Use reflection if you wish to access private fields',
    '//可以访问 public 字段；如需访问 private 字段，请使用反射',
  },
  {
    '//don\'t bother putting code in here. It will get replaced (just some stuff to make sure there\'s space)',
    '//这里无需写代码，会被替换掉；这些内容只是用来确保有足够空间',
  },
  { '--you\'re free to build your own list', '--可自行构建引用列表' },
  { '--sometimes having the sysfile causes an issue. Try without', '--有时 sysfile 会导致问题，改为不带它再试' },
  {
    '--show compile error in a dialog instead of a lua error only',
    '--用对话框显示编译错误，而不是只抛 Lua 错误',
  },
  { '--still here, c# dll created, now inject and hook', '--执行到这里说明 C# DLL 已创建，现在注入并 Hook' },
  { 'Compilation error:', '编译错误:' },
  { ' (?Unknown error?)', ' (?未知错误?)' },
  { 'no reason', '无原因' },
  { 'InjectDotNetDetour failed : ', 'InjectDotNetDetour 失败: ' },
  { '--prevents checking', '--阻止脚本被勾选启用' },
}

local function plainPattern(s)
  return tostring(s):gsub('([^%w])', '%%%1')
end

local function localizeAutoAssemblerScriptTemplate(script)
  if type(script) ~= 'string' then return script end

  local mapped = script
  for i = 1, #AA_SCRIPT_TEMPLATE_REPLACEMENTS do
    local source = AA_SCRIPT_TEMPLATE_REPLACEMENTS[i][1]
    local target = AA_SCRIPT_TEMPLATE_REPLACEMENTS[i][2]
    mapped = mapped:gsub(plainPattern(source), target)
  end
  return mapped
end

-- 安全获取本进程 AA 符号地址。
local function getSelfAddressSafe(symbol)
  if type(getAddressSafe) ~= 'function' then return nil end
  local ok, value = pcall(function() return getAddressSafe(symbol, true) end)
  if ok and type(value) == 'number' then return value end
  ok, value = pcall(function() return getAddressSafe(symbol) end)
  if ok and type(value) == 'number' then return value end
  return nil
end

-- 统一判断 writeBytesLocal 等写内存操作是否成功。
local function writeSucceeded(fn, ...)
  local ok, result = checkedCall(fn, ...)
  return ok and result ~= false
end

local DRAW_TEXT_EXCLUDED_TEXT = {
  ['OK'] = true,
  ['Cancel'] = true,
  ['Close'] = true,
  ['Yes'] = true,
  ['No'] = true,
  ['True'] = true,
  ['False'] = true,
  ['Name'] = true,
  ['Value'] = true,
  ['Address'] = true,
  ['Type'] = true,
  ['Class'] = true,
  ['Owner'] = true,
  ['Index'] = true,
}

-- 判断某个文本是否适合放进绘制层翻译字典。
local function isDrawTextCandidate(source, target)
  if type(source) ~= 'string' or type(target) ~= 'string' then return false end
  if source == '' or target == '' or source == target then return false end
  if INTERNAL_TRANSLATE_PASSTHROUGH[source] or DRAW_TEXT_EXCLUDED_TEXT[source] then return false end
  if #source > CE_DRAW_TEXT_MAX_SOURCE_LEN or #target > CE_DRAW_TEXT_MAX_SOURCE_LEN then return false end
  if #source < 8 and not source:find('%s') then return false end
  if source:match('^%s*$') then return false end
  return true
end

-- 汇总普通词表和 CE 原生词表，生成绘制层查找表条目。
local function buildCEDrawTextEntries()
  local bySource = {}
  local entries = {}

  -- 向绘制层查找表加入一个去重后的翻译条目。
  local function add(source, target)
    if isDrawTextCandidate(source, target) and not bySource[source] then
      bySource[source] = target
      entries[#entries + 1] = { source = source, translated = target }
    end
  end

  for i = 1, #TEXT_SOURCES do
    local textMap = TEXT_SOURCES[i]
    for source, target in pairs(textMap) do add(source, target) end
  end

  for source, target in pairs(CE_DRAW_TEXT_NATIVE_TEXT) do
    add(source, target)
  end

  table.sort(entries, function(a, b)
    if #a.source ~= #b.source then return #a.source < #b.source end
    return a.source < b.source
  end)

  return entries
end

-- 生成 Hook CE 文本绘制函数的 64 位 autoAssemble 脚本。
local function buildCEDrawTextHookAA64(moduleName)
  local out = {}
  out[#out + 1] = 'aobscanmodule(zhCEDrawText_DrawTextEntry,"' .. moduleName .. '",55 48 89 E5 48 8D A4 24 20 FF FF FF 48 89 4D E0 48 89 55 F8 4C 89 45 F0 44 89 4D E8)'
  out[#out + 1] = 'aobscanmodule(zhCEDrawText_ExtTextOutEntry,"' .. moduleName .. '",55 48 89 E5 48 8D A4 24 60 FF FF FF 48 89 4D E0 48 89 55 F8 44 89 45 F0 44 89 4D E8 48 C7 45 D0 00 00 00 00 48 C7 45 C8 00 00 00 00 48 C7 45 C0 00 00 00 00 48 C7 45 B0 00 00 00 00 90 4C 8D 05)'
  out[#out + 1] = 'aobscanmodule(zhCEDrawText_TextOutEntry,"' .. moduleName .. '",55 48 89 E5 48 8D 64 24 80 48 89 4D E0 48 89 55 F8 44 89 45 F0 44 89 4D E8 48 C7 45 D0 00 00 00 00 48 C7 45 B0 00 00 00 00 48 C7 45 B8 00 00 00 00 48 C7 45 C8 00 00 00 00 90 48 8B 45 30)'
  out[#out + 1] = 'alloc(zhCEDrawTextHookMem,8192,zhCEDrawText_DrawTextEntry)'
  out[#out + 1] = 'alloc(zhCEDrawTextData,' .. tostring(CE_DRAW_TEXT_DATA_SIZE) .. ',zhCEDrawText_DrawTextEntry)'
  out[#out + 1] = 'alloc(zhCEDrawTextStats,96,zhCEDrawText_DrawTextEntry)'
  out[#out + 1] = 'label(zhCEDrawTextReady)'
  out[#out + 1] = 'label(zhCEDrawTextLookup)'
  out[#out + 1] = 'label(zhCEDrawTextLookupKnownLen)'
  out[#out + 1] = 'label(zhCEDrawTextLookupLenLoop)'
  out[#out + 1] = 'label(zhCEDrawTextLookupLoop)'
  out[#out + 1] = 'label(zhCEDrawTextLookupLoopStart)'
  out[#out + 1] = 'label(zhCEDrawTextLookupCompare)'
  out[#out + 1] = 'label(zhCEDrawTextLookupNext)'
  out[#out + 1] = 'label(zhCEDrawTextLookupMatched)'
  out[#out + 1] = 'label(zhCEDrawTextLookupMiss)'
  out[#out + 1] = 'label(zhCEDrawTextLookupDoneHit)'
  out[#out + 1] = 'label(zhCEDrawTextDrawTextHook)'
  out[#out + 1] = 'label(zhCEDrawTextExtTextOutHook)'
  out[#out + 1] = 'label(zhCEDrawTextTextOutHook)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextHookMem:'
  out[#out + 1] = 'zhCEDrawTextReady:'
  out[#out + 1] = '  db 00'
  out[#out + 1] = '  align 10'
  out[#out + 1] = 'zhCEDrawTextLookup:'
  out[#out + 1] = '  push rcx'
  out[#out + 1] = '  push rdx'
  out[#out + 1] = '  push r9'
  out[#out + 1] = '  push rsi'
  out[#out + 1] = '  inc qword ptr [zhCEDrawTextStats]'
  out[#out + 1] = '  cmp byte ptr [zhCEDrawTextReady],01'
  out[#out + 1] = '  jne zhCEDrawTextLookupMiss'
  out[#out + 1] = '  test r8,r8'
  out[#out + 1] = '  je zhCEDrawTextLookupMiss'
  out[#out + 1] = '  mov rax,r8'
  out[#out + 1] = '  cmp r9d,FFFFFFFF'
  out[#out + 1] = '  jne zhCEDrawTextLookupKnownLen'
  out[#out + 1] = '  xor r10,r10'
  out[#out + 1] = 'zhCEDrawTextLookupLenLoop:'
  out[#out + 1] = '  cmp byte ptr [rax+r10],00'
  out[#out + 1] = '  je zhCEDrawTextLookupLoop'
  out[#out + 1] = '  inc r10'
  out[#out + 1] = '  cmp r10,' .. string.format('%X', CE_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  jb zhCEDrawTextLookupLenLoop'
  out[#out + 1] = '  jmp zhCEDrawTextLookupMiss'
  out[#out + 1] = 'zhCEDrawTextLookupKnownLen:'
  out[#out + 1] = '  movsxd r10,r9d'
  out[#out + 1] = '  cmp r10,1'
  out[#out + 1] = '  jl zhCEDrawTextLookupMiss'
  out[#out + 1] = '  cmp r10,' .. string.format('%X', CE_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  ja zhCEDrawTextLookupMiss'
  out[#out + 1] = 'zhCEDrawTextLookupLoop:'
  out[#out + 1] = '  lea r11,[zhCEDrawTextData]'
  out[#out + 1] = '  mov rcx,r10'
  out[#out + 1] = '  shl rcx,4'
  out[#out + 1] = '  add r11,rcx'
  out[#out + 1] = '  mov rsi,[r11+8]'
  out[#out + 1] = '  mov r11,[r11]'
  out[#out + 1] = '  test r11,r11'
  out[#out + 1] = '  je zhCEDrawTextLookupMiss'
  out[#out + 1] = '  cmp r11,rsi'
  out[#out + 1] = '  jae zhCEDrawTextLookupMiss'
  out[#out + 1] = 'zhCEDrawTextLookupLoopStart:'
  out[#out + 1] = '  cmp r11,rsi'
  out[#out + 1] = '  jae zhCEDrawTextLookupMiss'
  out[#out + 1] = '  movzx edx,byte ptr [rax]'
  out[#out + 1] = '  cmp dl,byte ptr [r11+8]'
  out[#out + 1] = '  jne zhCEDrawTextLookupNext'
  out[#out + 1] = '  mov rdx,[r11+10]'
  out[#out + 1] = '  xor ecx,ecx'
  out[#out + 1] = 'zhCEDrawTextLookupCompare:'
  out[#out + 1] = '  cmp rcx,r10'
  out[#out + 1] = '  jae zhCEDrawTextLookupMatched'
  out[#out + 1] = '  mov r9b,byte ptr [rax+rcx]'
  out[#out + 1] = '  cmp r9b,byte ptr [rdx+rcx]'
  out[#out + 1] = '  jne zhCEDrawTextLookupNext'
  out[#out + 1] = '  inc rcx'
  out[#out + 1] = '  jmp zhCEDrawTextLookupCompare'
  out[#out + 1] = 'zhCEDrawTextLookupNext:'
  out[#out + 1] = '  add r11,28'
  out[#out + 1] = '  jmp zhCEDrawTextLookupLoopStart'
  out[#out + 1] = 'zhCEDrawTextLookupMatched:'
  out[#out + 1] = '  inc qword ptr [zhCEDrawTextStats+8]'
  out[#out + 1] = '  mov [zhCEDrawTextStats+18],rax'
  out[#out + 1] = '  mov [zhCEDrawTextStats+20],r10'
  out[#out + 1] = '  mov r8,[r11+18]'
  out[#out + 1] = '  mov r9,[r11+20]'
  out[#out + 1] = 'zhCEDrawTextLookupDoneHit:'
  out[#out + 1] = '  pop rsi'
  out[#out + 1] = '  add rsp,8'
  out[#out + 1] = '  pop rdx'
  out[#out + 1] = '  pop rcx'
  out[#out + 1] = '  ret'
  out[#out + 1] = 'zhCEDrawTextLookupMiss:'
  out[#out + 1] = '  inc qword ptr [zhCEDrawTextStats+10]'
  out[#out + 1] = '  pop rsi'
  out[#out + 1] = '  pop r9'
  out[#out + 1] = '  pop rdx'
  out[#out + 1] = '  pop rcx'
  out[#out + 1] = '  ret'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextDrawTextHook:'
  out[#out + 1] = '  db 55 48 89 E5 48 8D A4 24 20 FF FF FF'
  out[#out + 1] = '  call zhCEDrawTextLookup'
  out[#out + 1] = '  jmp zhCEDrawText_DrawTextEntry+0C'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextExtTextOutHook:'
  out[#out + 1] = '  db 55 48 89 E5 48 8D A4 24 60 FF FF FF'
  out[#out + 1] = '  push r8'
  out[#out + 1] = '  push r9'
  out[#out + 1] = '  mov r8,[rbp+40]'
  out[#out + 1] = '  mov r9d,[rbp+48]'
  out[#out + 1] = '  call zhCEDrawTextLookup'
  out[#out + 1] = '  mov [rbp+40],r8'
  out[#out + 1] = '  mov [rbp+48],r9d'
  out[#out + 1] = '  pop r9'
  out[#out + 1] = '  pop r8'
  out[#out + 1] = '  jmp zhCEDrawText_ExtTextOutEntry+0C'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextTextOutHook:'
  out[#out + 1] = '  db 55 48 89 E5 48 8D 64 24 80'
  out[#out + 1] = '  push r8'
  out[#out + 1] = '  push r9'
  out[#out + 1] = '  mov r8,[rbp+30]'
  out[#out + 1] = '  mov r9d,[rbp+38]'
  out[#out + 1] = '  call zhCEDrawTextLookup'
  out[#out + 1] = '  mov [rbp+30],r8'
  out[#out + 1] = '  mov [rbp+38],r9d'
  out[#out + 1] = '  pop r9'
  out[#out + 1] = '  pop r8'
  out[#out + 1] = '  jmp zhCEDrawText_TextOutEntry+09'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawText_DrawTextEntry:'
  out[#out + 1] = '  jmp zhCEDrawTextDrawTextHook'
  out[#out + 1] = '  nop 7'
  out[#out + 1] = 'zhCEDrawText_ExtTextOutEntry:'
  out[#out + 1] = '  jmp zhCEDrawTextExtTextOutHook'
  out[#out + 1] = '  nop 7'
  out[#out + 1] = 'zhCEDrawText_TextOutEntry:'
  out[#out + 1] = '  jmp zhCEDrawTextTextOutHook'
  out[#out + 1] = '  nop 4'
  out[#out + 1] = 'registersymbol(zhCEDrawTextData)'
  out[#out + 1] = 'registersymbol(zhCEDrawTextStats)'
  out[#out + 1] = 'registersymbol(zhCEDrawTextHookMem)'
  out[#out + 1] = 'registersymbol(zhCEDrawTextReady)'
  return table.concat(out, '\n')
end

-- 生成 Hook CE 文本绘制函数的 32 位 autoAssemble 脚本。
local function buildCEDrawTextHookAA32(moduleName)
  local out = {}
  out[#out + 1] = 'aobscanmodule(zhCEDrawText_DrawTextEntry,"' .. moduleName .. '",55 89 E5 8D 64 24 88 53 89 45 F4 89 55 FC 89 4D F8 C7 45 EC 00 00 00 00 C7 45 E8 00 00 00 00)'
  out[#out + 1] = 'aobscanmodule(zhCEDrawText_ExtTextOutEntry,"' .. moduleName .. '",55 89 E5 8D 64 24 D8 89 45 F4 89 55 FC 89 4D F8 C7 45 EC 00 00 00 00 C7 45 E8 00 00 00 00 C7 45 E4 00 00 00 00 C7 45 DC 00 00 00 00 31 C0 68 50 51 84 00)'
  out[#out + 1] = 'aobscanmodule(zhCEDrawText_TextOutEntry,"' .. moduleName .. '",55 89 E5 8D 64 24 DC 89 45 F4 89 55 FC 89 4D F8 C7 45 EC 00 00 00 00 C7 45 DC 00 00 00 00)'
  out[#out + 1] = 'alloc(zhCEDrawTextHookMem,8192,zhCEDrawText_DrawTextEntry)'
  out[#out + 1] = 'alloc(zhCEDrawTextData,' .. tostring(CE_DRAW_TEXT_DATA_SIZE) .. ',zhCEDrawText_DrawTextEntry)'
  out[#out + 1] = 'alloc(zhCEDrawTextStats,96,zhCEDrawText_DrawTextEntry)'
  out[#out + 1] = 'label(zhCEDrawTextReady)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32KnownLen)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32LenLoop)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32Loop)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32LoopStart)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32Compare)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32Next)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32Matched)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32Miss)'
  out[#out + 1] = 'label(zhCEDrawTextLookup32Done)'
  out[#out + 1] = 'label(zhCEDrawTextDrawTextHook32)'
  out[#out + 1] = 'label(zhCEDrawTextExtTextOutHook32)'
  out[#out + 1] = 'label(zhCEDrawTextTextOutHook32)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextHookMem:'
  out[#out + 1] = 'zhCEDrawTextReady:'
  out[#out + 1] = '  db 00'
  out[#out + 1] = '  align 10'
  out[#out + 1] = 'zhCEDrawTextLookup32:'
  out[#out + 1] = '  push eax'
  out[#out + 1] = '  push ebx'
  out[#out + 1] = '  push esi'
  out[#out + 1] = '  push edi'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  push ebp'
  out[#out + 1] = '  inc dword ptr [zhCEDrawTextStats]'
  out[#out + 1] = '  mov ebx,ecx'
  out[#out + 1] = '  cmp byte ptr [zhCEDrawTextReady],01'
  out[#out + 1] = '  jne zhCEDrawTextLookup32Miss'
  out[#out + 1] = '  test ecx,ecx'
  out[#out + 1] = '  je zhCEDrawTextLookup32Miss'
  out[#out + 1] = '  cmp edx,FFFFFFFF'
  out[#out + 1] = '  jne zhCEDrawTextLookup32KnownLen'
  out[#out + 1] = '  xor edi,edi'
  out[#out + 1] = 'zhCEDrawTextLookup32LenLoop:'
  out[#out + 1] = '  cmp byte ptr [ebx+edi],00'
  out[#out + 1] = '  je zhCEDrawTextLookup32Loop'
  out[#out + 1] = '  inc edi'
  out[#out + 1] = '  cmp edi,' .. string.format('%X', CE_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  jb zhCEDrawTextLookup32LenLoop'
  out[#out + 1] = '  jmp zhCEDrawTextLookup32Miss'
  out[#out + 1] = 'zhCEDrawTextLookup32KnownLen:'
  out[#out + 1] = '  mov edi,edx'
  out[#out + 1] = '  cmp edi,1'
  out[#out + 1] = '  jl zhCEDrawTextLookup32Miss'
  out[#out + 1] = '  cmp edi,' .. string.format('%X', CE_DRAW_TEXT_MAX_SOURCE_LEN)
  out[#out + 1] = '  ja zhCEDrawTextLookup32Miss'
  out[#out + 1] = 'zhCEDrawTextLookup32Loop:'
  out[#out + 1] = '  lea esi,[zhCEDrawTextData]'
  out[#out + 1] = '  mov eax,edi'
  out[#out + 1] = '  shl eax,3'
  out[#out + 1] = '  add esi,eax'
  out[#out + 1] = '  mov ebp,[esi+4]'
  out[#out + 1] = '  mov esi,[esi]'
  out[#out + 1] = '  test esi,esi'
  out[#out + 1] = '  je zhCEDrawTextLookup32Miss'
  out[#out + 1] = '  cmp esi,ebp'
  out[#out + 1] = '  jae zhCEDrawTextLookup32Miss'
  out[#out + 1] = 'zhCEDrawTextLookup32LoopStart:'
  out[#out + 1] = '  cmp esi,ebp'
  out[#out + 1] = '  jae zhCEDrawTextLookup32Miss'
  out[#out + 1] = '  movzx eax,byte ptr [ebx]'
  out[#out + 1] = '  cmp al,byte ptr [esi+4]'
  out[#out + 1] = '  jne zhCEDrawTextLookup32Next'
  out[#out + 1] = '  mov eax,[esi+8]'
  out[#out + 1] = '  xor edx,edx'
  out[#out + 1] = 'zhCEDrawTextLookup32Compare:'
  out[#out + 1] = '  cmp edx,edi'
  out[#out + 1] = '  jae zhCEDrawTextLookup32Matched'
  out[#out + 1] = '  mov cl,byte ptr [ebx+edx]'
  out[#out + 1] = '  cmp cl,byte ptr [eax+edx]'
  out[#out + 1] = '  jne zhCEDrawTextLookup32Next'
  out[#out + 1] = '  inc edx'
  out[#out + 1] = '  jmp zhCEDrawTextLookup32Compare'
  out[#out + 1] = 'zhCEDrawTextLookup32Next:'
  out[#out + 1] = '  add esi,14'
  out[#out + 1] = '  jmp zhCEDrawTextLookup32LoopStart'
  out[#out + 1] = 'zhCEDrawTextLookup32Matched:'
  out[#out + 1] = '  inc dword ptr [zhCEDrawTextStats+4]'
  out[#out + 1] = '  pop ebp'
  out[#out + 1] = '  add esp,4'
  out[#out + 1] = '  mov ecx,[esi+0C]'
  out[#out + 1] = '  mov edx,[esi+10]'
  out[#out + 1] = '  jmp zhCEDrawTextLookup32Done'
  out[#out + 1] = 'zhCEDrawTextLookup32Miss:'
  out[#out + 1] = '  inc dword ptr [zhCEDrawTextStats+8]'
  out[#out + 1] = '  mov ecx,ebx'
  out[#out + 1] = '  pop ebp'
  out[#out + 1] = '  mov edx,[esp]'
  out[#out + 1] = '  add esp,4'
  out[#out + 1] = 'zhCEDrawTextLookup32Done:'
  out[#out + 1] = '  pop edi'
  out[#out + 1] = '  pop esi'
  out[#out + 1] = '  pop ebx'
  out[#out + 1] = '  pop eax'
  out[#out + 1] = '  ret'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextDrawTextHook32:'
  out[#out + 1] = '  db 55 89 E5 8D 64 24 88 53'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  mov edx,[ebp+10]'
  out[#out + 1] = '  call zhCEDrawTextLookup32'
  out[#out + 1] = '  mov [ebp+10],edx'
  out[#out + 1] = '  pop edx'
  out[#out + 1] = '  jmp zhCEDrawText_DrawTextEntry+08'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextExtTextOutHook32:'
  out[#out + 1] = '  db 55 89 E5 8D 64 24 D8'
  out[#out + 1] = '  push ecx'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  mov ecx,[ebp+10]'
  out[#out + 1] = '  mov edx,[ebp+0C]'
  out[#out + 1] = '  call zhCEDrawTextLookup32'
  out[#out + 1] = '  mov [ebp+10],ecx'
  out[#out + 1] = '  mov [ebp+0C],edx'
  out[#out + 1] = '  pop edx'
  out[#out + 1] = '  pop ecx'
  out[#out + 1] = '  jmp zhCEDrawText_ExtTextOutEntry+07'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawTextTextOutHook32:'
  out[#out + 1] = '  db 55 89 E5 8D 64 24 DC'
  out[#out + 1] = '  push ecx'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  mov ecx,[ebp+0C]'
  out[#out + 1] = '  mov edx,[ebp+08]'
  out[#out + 1] = '  call zhCEDrawTextLookup32'
  out[#out + 1] = '  mov [ebp+0C],ecx'
  out[#out + 1] = '  mov [ebp+08],edx'
  out[#out + 1] = '  pop edx'
  out[#out + 1] = '  pop ecx'
  out[#out + 1] = '  jmp zhCEDrawText_TextOutEntry+07'
  out[#out + 1] = ''
  out[#out + 1] = 'zhCEDrawText_DrawTextEntry:'
  out[#out + 1] = '  jmp zhCEDrawTextDrawTextHook32'
  out[#out + 1] = '  nop 3'
  out[#out + 1] = 'zhCEDrawText_ExtTextOutEntry:'
  out[#out + 1] = '  jmp zhCEDrawTextExtTextOutHook32'
  out[#out + 1] = '  nop 2'
  out[#out + 1] = 'zhCEDrawText_TextOutEntry:'
  out[#out + 1] = '  jmp zhCEDrawTextTextOutHook32'
  out[#out + 1] = '  nop 2'
  out[#out + 1] = 'registersymbol(zhCEDrawTextData)'
  out[#out + 1] = 'registersymbol(zhCEDrawTextStats)'
  out[#out + 1] = 'registersymbol(zhCEDrawTextHookMem)'
  out[#out + 1] = 'registersymbol(zhCEDrawTextReady)'
  return table.concat(out, '\n')
end

-- 生成 Hook CE 文本绘制函数的 autoAssemble 脚本。
local function buildCEDrawTextHookAA(moduleName)
  if ceIs64Bit() then return buildCEDrawTextHookAA64(moduleName) end
  return buildCEDrawTextHookAA32(moduleName)
end

-- 把绘制层翻译查找表写入 AA 分配的数据区。
local function populateCEDrawTextData(entries)
  if type(getAddressSafe) ~= 'function' or type(writeBytesLocal) ~= 'function' then
    return false, 'missing memory helpers'
  end

  local base = getSelfAddressSafe('zhCEDrawTextData')
  if type(base) ~= 'number' then return false, 'missing zhCEDrawTextData symbol' end

  local is64 = ceIs64Bit()
  local bucketCount = CE_DRAW_TEXT_MAX_SOURCE_LEN + 1
  local bucketSize = is64 and 0x10 or 0x08
  local bucketAreaSize = alignUp(bucketCount * bucketSize, 16)
  local entrySize = is64 and 0x28 or 0x14
  local entryBase = base + bucketAreaSize
  local entryAreaSize = alignUp(#entries * entrySize, 16)
  local cursor = entryBase + entryAreaSize
  local bucketStartByLen = {}
  local bucketEndByLen = {}

  local emptyBuckets = {}
  for _ = 1, bucketAreaSize do emptyBuckets[#emptyBuckets + 1] = 0 end
  if not writeSucceeded(function() return writeBytesLocal(base, emptyBuckets) end) then
    return false, 'write failed at bucket index'
  end

  for i, entry in ipairs(entries) do
    local sourceLen = #entry.source
    local entryAddress = entryBase + ((i - 1) * entrySize)
    if not bucketStartByLen[sourceLen] then bucketStartByLen[sourceLen] = entryAddress end
    bucketEndByLen[sourceLen] = entryAddress + entrySize

    local sourceAddress = cursor
    local sourceBytes = bytesOfString(entry.source, false)
    if not writeSucceeded(function() return writeBytesLocal(sourceAddress, sourceBytes) end) then
      return false, 'write failed at source ' .. tostring(entry.source)
    end
    cursor = base + alignUp((sourceAddress + #sourceBytes) - base, 16)

    local targetAddress = cursor
    local targetBytes = bytesOfString(entry.translated, true)
    if not writeSucceeded(function() return writeBytesLocal(targetAddress, targetBytes) end) then
      return false, 'write failed at target ' .. tostring(entry.source)
    end
    cursor = base + alignUp((targetAddress + #targetBytes) - base, 16)

    local entryBytes
    if is64 then
      entryBytes = qwordBytes(sourceLen)
      appendBytes(entryBytes, dwordBytes(string.byte(entry.source, 1) or 0))
      appendBytes(entryBytes, dwordBytes(0))
      appendBytes(entryBytes, qwordBytes(sourceAddress))
      appendBytes(entryBytes, qwordBytes(targetAddress))
      appendBytes(entryBytes, qwordBytes(#entry.translated))
    else
      entryBytes = dwordBytes(sourceLen)
      appendBytes(entryBytes, dwordBytes(string.byte(entry.source, 1) or 0))
      appendBytes(entryBytes, dwordBytes(sourceAddress))
      appendBytes(entryBytes, dwordBytes(targetAddress))
      appendBytes(entryBytes, dwordBytes(#entry.translated))
    end

    if not writeSucceeded(function() return writeBytesLocal(entryAddress, entryBytes) end) then
      return false, 'write failed at entry ' .. tostring(entry.source)
    end

    if cursor - base > CE_DRAW_TEXT_DATA_SIZE then
      return false, 'data block too small: ' .. tostring(cursor - base)
    end
  end

  for sourceLen, startAddress in pairs(bucketStartByLen) do
    local bucketAddress = base + (sourceLen * bucketSize)
    local bucketBytes
    if is64 then
      bucketBytes = qwordBytes(startAddress)
      appendBytes(bucketBytes, qwordBytes(bucketEndByLen[sourceLen]))
    else
      bucketBytes = dwordBytes(startAddress)
      appendBytes(bucketBytes, dwordBytes(bucketEndByLen[sourceLen]))
    end

    if not writeSucceeded(function() return writeBytesLocal(bucketAddress, bucketBytes) end) then
      return false, 'write failed at bucket ' .. tostring(sourceLen)
    end
  end

  local readyAddress = getSelfAddressSafe('zhCEDrawTextReady')
  if type(readyAddress) == 'number' then
    if not writeSucceeded(function() return writeBytesLocal(readyAddress, 1) end) then
      return false, 'write failed at ready flag'
    end
  end

  return true, cursor - base
end

-- 安装 CE 原生文本绘制层 Hook，用于不改原始字符串的显示汉化。
function installCEDrawTextHook()
  if not CE_DRAW_TEXT_HOOK_ENABLED then return false end
  if not zhCNNativeHooksEnabled() then return false end
  if type(autoAssemble) ~= 'function' or type(getAddressSafe) ~= 'function' then return false end
  if getSelfAddressSafe('zhCEDrawTextHookMem') then
    UI_NATIVE_PATCH_STATE.drawTextHookInstalled = true
    return true
  end

  local entries = buildCEDrawTextEntries()
  local moduleName = extractFileName(getApplication().ExeName)
  local aa = buildCEDrawTextHookAA(moduleName)
  local ok, result = pcall(function() return autoAssemble(aa, true) end)
  if not ok or result == false then
    return false
  end

  local dataOk, dataResult = populateCEDrawTextData(entries)
  if not dataOk then
    return false
  end

  UI_NATIVE_PATCH_STATE.drawTextHookInstalled = true
  return true
end

local function installMemoryViewNativeTextPatches()
  if UI_NATIVE_PATCH_STATE.allocationBasePatchInstalled then return true end
  local ok, result = pcall(patchAllocationBaseText)
  if ok and result == true then
    UI_NATIVE_PATCH_STATE.allocationBasePatchInstalled = true
    return true
  end
  return false
end

local function installAutoAssemblerNativeTextPatches()
  if not UI_NATIVE_PATCH_STATE.autoAssemblerTemplatePatchInstalled then
    local ok, result = pcall(patchAutoAssemblerTemplateText)
    if ok and result == true then
      UI_NATIVE_PATCH_STATE.autoAssemblerTemplatePatchInstalled = true
    end
  end

  if not UI_NATIVE_PATCH_STATE.drawTextHookInstalled then
    local ok, result = pcall(installCEDrawTextHook)
    if ok and result == true then
      UI_NATIVE_PATCH_STATE.drawTextHookInstalled = true
    end
  end

  return UI_NATIVE_PATCH_STATE.autoAssemblerTemplatePatchInstalled == true
    and UI_NATIVE_PATCH_STATE.drawTextHookInstalled == true
end

local objectClassName
local OBJECT_NAME_CACHE = setmetatable({}, {__mode = 'k'})
local OBJECT_CLASS_CACHE = setmetatable({}, {__mode = 'k'})
local OBJECT_PROPERTY_VALUE_CACHE = setmetatable({}, {__mode = 'k'})

-- 翻译对象指定字符串属性，例如 Caption、Hint、Title。
local function localizeProperty(obj, prop)
  local value = getProperty(obj, prop)
  if type(value) ~= 'string' then return end

  local valueCache = OBJECT_PROPERTY_VALUE_CACHE[obj]
  if not valueCache then
    valueCache = {}
    OBJECT_PROPERTY_VALUE_CACHE[obj] = valueCache
  elseif valueCache[prop] == value then
    return
  end

  local mapped = zhText(value)
  if mapped ~= value then
    if pcall(setProperty, obj, prop, mapped) then
      valueCache[prop] = mapped
    end
  else
    valueCache[prop] = value
  end
end

local OBJECT_TEXT_PROPERTIES = { 'Caption', 'Hint', 'TextHint', 'Title', 'Filter' }
local CLASS_TEXT_PROPERTY_CACHE = {}
local CLASS_CHILD_ACCESS_CACHE = {}
local CLASS_LOCALIZE_FLAGS_CACHE = {}

-- 翻译单个控件/窗体的常见文本属性。
local function localizeObject(obj, className)
  if not obj then return end
  className = className or objectClassName(obj)

  local props = CLASS_TEXT_PROPERTY_CACHE[className]
  if not props then
    props = {}
    for i = 1, #OBJECT_TEXT_PROPERTIES do
      local prop = OBJECT_TEXT_PROPERTIES[i]
      local ok, value = pcall(getProperty, obj, prop)
      if ok then
        props[#props + 1] = prop
        if type(value) == 'string' then
          local valueCache = OBJECT_PROPERTY_VALUE_CACHE[obj]
          if not valueCache then
            valueCache = {}
            OBJECT_PROPERTY_VALUE_CACHE[obj] = valueCache
          end
          local mapped = zhText(value)
          if mapped ~= value then
            if pcall(setProperty, obj, prop, mapped) then
              valueCache[prop] = mapped
            end
          else
            valueCache[prop] = value
          end
        end
      end
    end
    CLASS_TEXT_PROPERTY_CACHE[className] = props
    return
  end

  for i = 1, #props do
    localizeProperty(obj, props[i])
  end
end

local function childAccessFor(obj, className)
  local access = CLASS_CHILD_ACCESS_CACHE[className]
  if access then return access end

  access = {}
  local okComponentCount, componentCount = pcall(function() return obj.getComponentCount() end)
  access.hasComponents = okComponentCount and type(componentCount) == 'number'
  local okControlCount, controlCount = pcall(function() return obj.ControlCount end)
  access.hasControls = okControlCount and type(controlCount) == 'number'

  CLASS_CHILD_ACCESS_CACHE[className] = access
  return access
end

local function localizeFlagsForClass(className)
  local flags = CLASS_LOCALIZE_FLAGS_CACHE[className]
  if flags then return flags end

  local classLower = className:lower()
  local isComboBox = classLower:find('combobox', 1, true) ~= nil
  local isListBox = classLower:find('listbox', 1, true) ~= nil
  local isTreeView = classLower:find('treeview', 1, true) ~= nil
  local isListView = classLower:find('listview', 1, true) ~= nil

  flags = {
    isFormDesignerRuntimeClass = className == 'TFormDesigner'
      or className == 'TObjectInspectorDlg'
      or className:find('ObjectInspector', 1, true) ~= nil
      or className:find('PropertyGrid', 1, true) ~= nil
      or className:find('DesignSurface', 1, true) ~= nil,
    isMenu = classLower:find('menu', 1, true) ~= nil,
    isListView = isListView,
    hasStringItems = isComboBox
      or isListBox
      or isTreeView
      or classLower:find('radiogroup', 1, true) ~= nil
      or classLower:find('checkgroup', 1, true) ~= nil,
    hasColumns = isListView
      or classLower:find('addresslist', 1, true) ~= nil
      or classLower:find('header', 1, true) ~= nil
      or classLower:find('grid', 1, true) ~= nil
      or classLower:find('column', 1, true) ~= nil,
  }
  CLASS_LOCALIZE_FLAGS_CACHE[className] = flags
  return flags
end

local function localizeDirectStringProperty(obj, prop)
  pcall(function()
    local value = obj[prop]
    if type(value) == 'string' then
      local mapped = zhText(value)
      if mapped ~= value then obj[prop] = mapped end
    end
  end)
end

local function localizeColumnObject(col)
  for i = 1, 2 do
    local prop = i == 1 and 'Caption' or 'Text'
    localizeProperty(col, prop)
    localizeDirectStringProperty(col, prop)
  end
end

-- 翻译列表、表格和表头列标题。
local function localizeColumns(obj)
  local ok, columns = pcall(function() return obj.Columns end)
  if ok and columns then
    local okCount, count = pcall(function() return columns.Count end)
    if okCount and type(count) == 'number' then
      for i = 0, count - 1 do
        local okCol, col = pcall(function() return columns[i] end)
        if okCol and col then
          localizeColumnObject(col)
        end
      end
    end
  end

  local okHeader, header = pcall(function() return obj.Header end)
  if okHeader and header then
    local okHeaderColumns, headerColumns = pcall(function() return header.Columns end)
    if okHeaderColumns and headerColumns then
      local okCount, count = pcall(function() return headerColumns.Count end)
      if okCount and type(count) == 'number' then
        for i = 0, count - 1 do
          local okCol, col = pcall(function() return headerColumns[i] end)
          if okCol and col then
            localizeColumnObject(col)
          end
        end
      end
    end
  end
end

local VIRTUAL_TREE_COLUMN_LOCALIZATION_QUEUED = setmetatable({}, {__mode = 'k'})

local function queueVirtualTreeColumnLocalization(tree)
  if not tree or type(createTimer) ~= 'function' then return end
  if VIRTUAL_TREE_COLUMN_LOCALIZATION_QUEUED[tree] then return end
  VIRTUAL_TREE_COLUMN_LOCALIZATION_QUEUED[tree] = true

  local attempts = 0
  pcall(function()
    local timer = createTimer(nil, false)
    timer.Interval = 50
    timer.OnTimer = function(t)
      attempts = attempts + 1
      pcall(localizeColumns, tree)

      if attempts >= 3 then
        pcall(function() t.destroy() end)
      end
    end
    timer.Enabled = true
  end)
end

local function wrapCreateVirtualStringTree()
  local original = capture('createVirtualStringTree')
  if type(original) ~= 'function' or _G.__zhCNCreateVirtualStringTreeWrapped then return end
  _G.__zhCNCreateVirtualStringTreeWrapped = true

  -- createVirtualStringTree 包装：动态添加的 Header.Columns 在调用栈返回后补刷。
  _G.createVirtualStringTree = function(...)
    local tree = original(...)
    if tree then
      pcall(localizeColumns, tree)
      queueVirtualTreeColumnLocalization(tree)
    end
    return tree
  end
end

-- 兼容不同 CE/Lazarus 集合接口读取指定索引项。
local function indexedValue(items, index)
  local ok, value = pcall(function() return items[index] end)
  if ok and value ~= nil then return value end

  ok, value = pcall(function() return items.Item[index] end)
  if ok and value ~= nil then return value end

  ok, value = pcall(function() return items.getItem(index) end)
  if ok and value ~= nil then return value end

  return nil
end

-- 兼容不同集合接口写回指定索引项。
local function setIndexedValue(items, index, value, owner)
  local okSorted, sorted = pcall(function() return items.Sorted end)
  if okSorted and sorted == true then return false end
  okSorted, sorted = pcall(function() return owner and owner.Sorted end)
  if okSorted and sorted == true then return false end

  if pcall(function() items[index] = value end) then return true end
  if pcall(function() items.Item[index] = value end) then return true end
  if pcall(function() items.Strings[index] = value end) then return true end
  return false
end

local function beginUpdateIfSupported(obj)
  if not obj then return false end
  return pcall(function() obj.beginUpdate() end)
end

local function endUpdateIfSupported(obj)
  if not obj then return end
  pcall(function() obj.endUpdate() end)
end

-- 安全取得对象 Name。
local function objectName(obj)
  local cached = OBJECT_NAME_CACHE[obj]
  if cached ~= nil then return cached end
  local ok, name = pcall(function() return obj.getName() end)
  if ok and type(name) == 'string' then
    OBJECT_NAME_CACHE[obj] = name
    return name
  end
  OBJECT_NAME_CACHE[obj] = ''
  return ''
end

-- 安全取得对象 ClassName。
function objectClassName(obj)
  local cached = OBJECT_CLASS_CACHE[obj]
  if cached ~= nil then return cached end
  local ok, className = pcall(function() return obj.getClassName() end)
  if ok and type(className) == 'string' then
    OBJECT_CLASS_CACHE[obj] = className
    return className
  end
  OBJECT_CLASS_CACHE[obj] = ''
  return ''
end

local TRANSIENT_DIALOG_CLASSES = {
  TQuestionDlg = true,
  TMessageDlg = true,
  TMessageForm = true,
}
local TRANSIENT_DIALOG_QUEUED = setmetatable({}, {__mode = 'k'})

-- 系统消息框生命周期很短，创建通知阶段递归改控件容易打断模态流程。
local function isTransientDialogForm(obj)
  return TRANSIENT_DIALOG_CLASSES[objectClassName(obj)] == true
end

local function localizeTransientDialogProperty(obj, prop)
  local ok, value = pcall(getProperty, obj, prop)
  if not ok or type(value) ~= 'string' then return end

  local mapped = zhText(value)
  if mapped ~= value then
    pcall(setProperty, obj, prop, mapped)
  end
end

local function localizeTransientDialogControls(obj, seen)
  if not obj or seen[obj] then return end
  seen[obj] = true

  localizeTransientDialogProperty(obj, 'Caption')
  localizeTransientDialogProperty(obj, 'Text')

  local okCount, count = pcall(function() return obj.ComponentCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return obj.Component[i] end)
      if okChild and child then localizeTransientDialogControls(child, seen) end
    end
  end

  okCount, count = pcall(function() return obj.ControlCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return obj.Control[i] end)
      if okChild and child then localizeTransientDialogControls(child, seen) end
    end
  end
end

local function localizeTransientDialog(form)
  if not form then return end

  -- Pascal MessageDlg literals are often painted directly instead of exposed as child captions.
  pcall(installCEDrawTextHook)
  localizeTransientDialogControls(form, {})
  pcall(function() form.invalidate() end)
  pcall(function() form.repaint() end)
  pcall(function() form.update() end)
end

local function isFormDesignerRuntimeName(className, name)
  return className == 'TFormDesigner'
    or className == 'TObjectInspectorDlg'
    or name == 'FormDesigner'
    or className:find('ObjectInspector', 1, true) ~= nil
    or className:find('PropertyGrid', 1, true) ~= nil
    or className:find('DesignSurface', 1, true) ~= nil
end

-- 判断对象是否属于窗体设计器运行时区域，避免误改设计器内部数据。
local function isFormDesignerRuntimeObject(obj)
  local current = obj
  local seen = {}

  for _ = 1, 16 do
    if not current then break end
    if seen[current] then break end
    seen[current] = true

    local className = objectClassName(current)
    local name = objectName(current)
    if isFormDesignerRuntimeName(className, name) then
      return true
    end

    local okOwner, owner = pcall(function() return current.Owner end)
    if okOwner and owner and owner ~= current then
      current = owner
    else
      local okParent, parent = pcall(function() return current.Parent end)
      if okParent and parent and parent ~= current then
        current = parent
      else
        break
      end
    end
  end

  return false
end

-- 查找 autorun/扩展脚本文本的直接译文。
local function directAutorunText(s)
  if type(s) ~= 'string' then return s end
  local direct = lookupText(s)
  if direct then return direct end

  local prefix, core, suffix = s:match('^(%s*)(.-)(%s*)$')
  local coreText = lookupText(core)
  if core and core ~= s and coreText then
    return prefix .. coreText .. suffix
  end

  return s
end

-- 翻译 autorun/扩展脚本产生的列表项文本。
local function autorunListText(s)
  if type(s) ~= 'string' then return s end
  local cached = AUTORUN_LIST_TEXT_CACHE[s]
  if cached ~= nil then return cached end

  local mapped = directAutorunText(s)
  if mapped == s then
    mapped = applyPatternSources(s, LIST_PATTERN_SOURCES) or s
  end

  AUTORUN_LIST_TEXT_CACHE[s] = mapped
  return mapped
end

-- 判断某个列表/树是否属于设置窗口，决定是否跳过易变数据项。
local function isSettingsTree(owner)
  if not owner then return false end
  return objectName(owner) == 'SettingsTreeView'
    or objectClassName(owner) == 'TTreeView' and objectName(owner):lower():find('settings') ~= nil
end

local BIG_ENDIAN_SETTING_DISPLAY = {
  ['2 Byte Big Endian'] = '2 字节大端',
  ['4 Byte Big Endian'] = '4 字节大端',
  ['Float Big Endian'] = '单浮点大端',
}

local BIG_ENDIAN_SETTING_KEY = {
  ['2 Byte Big Endian'] = '2 Byte Big Endian',
  ['4 Byte Big Endian'] = '4 Byte Big Endian',
  ['Float Big Endian'] = 'Float Big Endian',
  ['2 字节大端'] = '2 Byte Big Endian',
  ['4 字节大端'] = '4 Byte Big Endian',
  ['单浮点大端'] = 'Float Big Endian',
}

local localizeMenuItem
local localizeItemsCollection
local MAX_AUTORUN_STRING_ITEMS = 200

-- 翻译菜单对象及其子菜单。
local function localizeMenuObject(obj, seen)
  local ok, items = pcall(function() return obj.Items end)
  if ok and items then localizeMenuItem(items, seen) end
end

-- 翻译单个菜单项并递归处理子菜单。
function localizeMenuItem(item, seen)
  if not item then return end
  if seen[item] then return end
  seen[item] = true

  localizeObject(item)

  local okCount, count = pcall(function() return item.Count end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return item.Item[i] end)
      if okChild and child then localizeMenuItem(child, seen) end
    end
  end
end

-- 翻译 Items 集合里的字符串项。
function localizeItemsCollection(items, seen, owner)
  if not items then return end

  local okCount, count = pcall(function() return items.Count end)
  if not okCount or type(count) ~= 'number' then return end
  if not isSettingsTree(owner) and count > MAX_AUTORUN_STRING_ITEMS then return end

  local updating = count > 1 and beginUpdateIfSupported(items)
  local okLoop, err = pcall(function()
    for i = 0, count - 1 do
      local item = indexedValue(items, i)

      if type(item) == 'string' then
        local mapped = directAutorunText(item)
        if mapped ~= item then setIndexedValue(items, i, mapped, owner) end
      elseif item and isSettingsTree(owner) then
        if not seen[item] then
          seen[item] = true
          localizeProperty(item, 'Text')

          local okChildItems, childItems = pcall(function() return item.Items end)
          if okChildItems and childItems then localizeItemsCollection(childItems, seen, owner) end

          local okNodeCount, nodeCount = pcall(function() return item.Count end)
          if okNodeCount and type(nodeCount) == 'number' and nodeCount > 0 then
            localizeItemsCollection(item, seen, owner)
          end
        end
      end
    end
  end)
  if updating then endUpdateIfSupported(items) end
  if not okLoop then error(err) end
end

-- 翻译对象的 Items 属性。
local function localizeItems(obj, seen)
  local ok, items = pcall(function() return obj.Items end)
  if ok and items then localizeItemsCollection(items, seen, obj) end
end

-- 翻译模块扫描选项下拉框，并在展开/悬停时补刷。
local function localizeModuleScanOptionsCombo(combo)
  if not combo or objectName(combo) ~= 'ScanOptionsModuleList' then return end

  local okItems, items = pcall(function() return combo.Items end)
  if okItems and items then
    local okCount, count = pcall(function() return items.Count end)
    if okCount and type(count) == 'number' and count <= MAX_AUTORUN_STRING_ITEMS then
      for i = 0, count - 1 do
        if indexedValue(items, i) == 'All' then
          setIndexedValue(items, i, '全部', combo)
        end
      end
    end
  end

  pcall(function()
    if combo.Text == 'All' then combo.Text = '全部' end
  end)

  if combo._zhModuleScanOptionsWrapped then return end
  combo._zhModuleScanOptionsWrapped = true

  local oldDropDown = combo.OnDropDown
  -- 下拉框展开回调：展开前补刷模块扫描选项文本。
  combo.OnDropDown = function(sender)
    local ok, err = true, nil
    if oldDropDown then ok, err = pcall(oldDropDown, sender) end
    local target = sender or combo
    pcall(localizeModuleScanOptionsCombo, target)
    if not ok then error(err) end
  end

  local oldMouseEnter = combo.OnMouseEnter
  -- 鼠标进入回调：防止下拉框内容被 CE 改回英文。
  combo.OnMouseEnter = function(sender)
    local ok, err = true, nil
    if oldMouseEnter then ok, err = pcall(oldMouseEnter, sender) end
    local target = sender or combo
    pcall(localizeModuleScanOptionsCombo, target)
    if not ok then error(err) end
  end
end

-- 递归查找指定 Name 的子控件。
local function findNamedChild(root, name, seen)
  if not root then return nil end
  seen = seen or {}

  if seen[root] then return nil end
  seen[root] = true

  if objectName(root) == name then return root end

  local okCount, count = pcall(function() return root.ComponentCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return root.Component[i] end)
      if okChild and child then
        local found = findNamedChild(child, name, seen)
        if found then return found end
      end
    end
  end

  okCount, count = pcall(function() return root.ControlCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return root.Control[i] end)
      if okChild and child then
        local found = findNamedChild(child, name, seen)
        if found then return found end
      end
    end
  end

  return nil
end

local DOTNET_INFO_EVENT_WRAPPED = setmetatable({}, {__mode = 'k'})
local DOTNET_INFO_INHERITANCE_LABEL_WRAPPED = setmetatable({}, {__mode = 'k'})

local function isDotNetInfoFormName(name)
  return type(name) == 'string' and name:match('^frmDotNetInfo%d*$') ~= nil
end

local function isDotNetInfoForm(form, name)
  if isDotNetInfoFormName(name or objectName(form)) then return true end

  local okGroup, group = pcall(function() return form.gbClassInformation end)
  if okGroup and group then return true end

  return false
end

local function localizeDotNetClassInformationCaption(form)
  local group = findNamedChild(form, 'gbClassInformation')
  if group then localizeProperty(group, 'Caption') end
end

local function localizeDotNetInfoColumns(form)
  local listViews = {
    'lvStaticFields',
    'lvFields',
    'lvMethods',
  }

  for i = 1, #listViews do
    local list = findNamedChild(form, listViews[i])
    if list then localizeColumns(list) end
  end

  local okTree, tree = pcall(function() return form.lvFields2 end)
  if okTree and tree then localizeColumns(tree) end
end

local function wrapDotNetInheritanceLabelEvents(form)
  local group = findNamedChild(form, 'gbInheritance')
  if not group then return end

  local okCount, count = pcall(function() return group.ControlCount end)
  if not okCount or type(count) ~= 'number' then return end

  for i = 0, count - 1 do
    local okChild, child = pcall(function() return group.Control[i] end)
    if okChild and child and not DOTNET_INFO_INHERITANCE_LABEL_WRAPPED[child] then
      local okEvent, previous = pcall(function() return child.OnMouseDown end)
      if okEvent and type(previous) == 'function' then
        DOTNET_INFO_INHERITANCE_LABEL_WRAPPED[child] = true
        pcall(function()
          child.OnMouseDown = function(...)
            local ok, err = pcall(previous, ...)
            pcall(localizeDotNetClassInformationCaption, form)
            if not ok then error(err) end
          end
        end)
      end
    end
  end
end

local function localizeDotNetInfoDynamicText(form)
  localizeDotNetClassInformationCaption(form)
  localizeDotNetInfoColumns(form)
  wrapDotNetInheritanceLabelEvents(form)
end

local function wrapDotNetInfoEvent(form, controlName, eventName)
  local control = findNamedChild(form, controlName)
  if not control then return end

  local wrapped = DOTNET_INFO_EVENT_WRAPPED[control]
  if not wrapped then
    wrapped = {}
    DOTNET_INFO_EVENT_WRAPPED[control] = wrapped
  elseif wrapped[eventName] then
    return
  end

  local okEvent, previous = pcall(function() return control[eventName] end)
  if not okEvent or type(previous) ~= 'function' then return end

  wrapped[eventName] = true
  pcall(function()
    control[eventName] = function(...)
      local ok, err = pcall(previous, ...)
      pcall(localizeDotNetInfoDynamicText, form)
      if not ok then error(err) end
    end
  end)
end

local function localizeDotNetInfoForm(form)
  localizeDotNetInfoDynamicText(form)
  wrapDotNetInfoEvent(form, 'lbDomains', 'OnSelectionChange')
  wrapDotNetInfoEvent(form, 'lbImages', 'OnSelectionChange')
  wrapDotNetInfoEvent(form, 'lvClasses', 'OnSelectItem')
  wrapDotNetInfoEvent(form, 'comboFieldBaseAddress', 'OnChange')
end

local function localizeDotNetInfoConfigForm(form)
  local colorControls = {
    'cbPrivate',
    'cbMixed',
    'cbPublic',
    'cbStaticBackground',
  }

  for i = 1, #colorControls do
    local control = findNamedChild(form, colorControls[i])
    if control then
      localizeObject(control)
      localizeItems(control, {})
      localizeProperty(control, 'Text')
    end
  end
end

-- 处理主界面里由 autorun 脚本或特殊控件生成的文本。
local function localizeMainFormAutorunControls()
  if not MainForm then return end

  local combo
  pcall(function()
    if MainForm.findComponentByName then
      combo = MainForm.findComponentByName('ScanOptionsModuleList')
    end
  end)

  if not combo then
    local okGroup, group = pcall(function() return MainForm.gbScanOptions end)
    if okGroup and group then
      combo = findNamedChild(group, 'ScanOptionsModuleList')
    end
  end

  if combo then localizeModuleScanOptionsCombo(combo) end
end

-- 汉化 AITools 对话框中会被脚本动态改回英文的控件。
local function localizeAIDialogDynamicText(form)
  if not form then return end

  local names = {
    'gbAPIKey',
    'edtAPIKEY',
    'btnObtainKey',
    'rbAIAccessPublic',
    'rbAIAccessPatreon',
    'rbAIAccessPrivate',
    'gbModelSelection',
    'cbModelSelection',
    'gbOptions',
    'btnSend',
  }

  for i = 1, #names do
    local control = findNamedChild(form, names[i])
    if control then
      pcall(localizeObject, control)
      pcall(localizeItems, control, {})
    end
  end
end

-- 替换 AITools 写入输出框的固定提示行。
local function localizeAIDialogOutputText(output)
  if not output then return end

  local okLines, lines = pcall(function() return output.Lines end)
  if not okLines or not lines then return end

  local okText, text = pcall(function() return lines.Text end)
  if not okText or type(text) ~= 'string' then return end

  local mapped = text:gsub('###Ask your questions about the current Lua Engine script here', '###在这里询问当前 Lua 脚本')
  mapped = mapped:gsub('###Ask your questions about the current AutoAssembler script here', '###在这里询问当前自动汇编脚本')

  if mapped ~= text then
    pcall(function() lines.Text = mapped end)
    pcall(function() output.SelStart = #mapped end)
  end
end

-- 延迟一次补刷 AITools 输出框，处理 spawnAIDialog 返回后才写入的提示行。
local function queueAIDialogOutputRefresh(form)
  if not form then return end

  -- AITools 输出框延迟刷新回调。
  local function refresh()
    local output = findNamedChild(form, 'mOutput')
    if not output then
      local okOutput, directOutput = pcall(function() return form.mOutput end)
      if okOutput then output = directOutput end
    end
    localizeAIDialogOutputText(output)
  end

  if type(createTimer) ~= 'function' then
    refresh()
    return
  end

  local okTimer = pcall(function()
    local timer = createTimer(form, false)
    timer.Interval = 10
    -- 一次性计时器回调：执行延迟刷新后销毁自身。
    timer.OnTimer = function(t)
      pcall(function() t.destroy() end)
      refresh()
    end
    timer.Enabled = true
  end)

  if not okTimer then refresh() end
end

-- 包装 AITools 的访问方式切换回调，切换后重新翻译按钮和输入框提示。
local function wrapAIDialogAccessChange(form)
  if not form then return end

  local names = {
    'rbAIAccessPublic',
    'rbAIAccessPatreon',
    'rbAIAccessPrivate',
  }

  for i = 1, #names do
    local radio = findNamedChild(form, names[i])
    if radio and not radio._zhCNAIDialogOnChangeWrapped then
      local okChange, oldChange = pcall(function() return radio.OnChange end)
      if okChange and type(oldChange) == 'function' then
        radio._zhCNAIDialogOnChangeWrapped = true
        -- AITools 单选按钮回调：原逻辑更新控件后，再把动态英文补回中文。
        radio.OnChange = function(sender, ...)
          local ok, err = pcall(oldChange, sender, ...)
          pcall(localizeAIDialogDynamicText, form)
          if not ok then error(err) end
        end
      end
    end
  end
end

-- 汉化 AITools 主对话框，并安装动态补刷。
local function localizeAIDialog(form)
  if objectName(form) ~= 'frmAIDialog' then return end

  localizeAIDialogDynamicText(form)
  wrapAIDialogAccessChange(form)
end

local AIDIALOG_SPAWN_WRAPPERS = setmetatable({}, {__mode = 'k'})

-- 包装 AITools 创建 AI 对话框的入口函数。
local function wrapAIDialogSpawnFunction(fn)
  if type(fn) ~= 'function' then return fn end

  local existing = AIDIALOG_SPAWN_WRAPPERS[fn]
  if existing then return existing end

  -- AITools spawn 包装：窗体创建后立即汉化并安排一次延迟补刷。
  local wrapped = function(...)
    local form = fn(...)
    if form then
      pcall(localizeAIDialog, form)
      queueAIDialogOutputRefresh(form)
    end
    return form
  end

  AIDIALOG_SPAWN_WRAPPERS[fn] = wrapped
  AIDIALOG_SPAWN_WRAPPERS[wrapped] = wrapped
  return wrapped
end

-- 捕获 AITools 后续定义的 spawnAIDialog，不修改 AITools 原脚本。
local function installAIDialogSpawnHook()
  local current = rawget(_G, 'spawnAIDialog')
  if type(current) == 'function' then
    rawset(_G, 'spawnAIDialog', wrapAIDialogSpawnFunction(current))
  end

  if rawget(_G, '__zhCNAIDialogSpawnNewIndexWrapped') then return end
  rawset(_G, '__zhCNAIDialogSpawnNewIndexWrapped', true)

  local mt = getmetatable(_G)
  if mt == nil then
    mt = {}
    setmetatable(_G, mt)
  end
  if type(mt) ~= 'table' then return end

  local oldNewIndex = mt.__newindex
  -- 全局表写入拦截：捕获后续赋值的 spawnAIDialog。
  mt.__newindex = function(t, key, value)
    if key == 'spawnAIDialog' and type(value) == 'function' then
      value = wrapAIDialogSpawnFunction(value)
    end

    if type(oldNewIndex) == 'function' then
      return oldNewIndex(t, key, value)
    elseif type(oldNewIndex) == 'table' then
      oldNewIndex[key] = value
      return
    end

    rawset(t, key, value)
  end
end

-- 翻译 ListView 行的子项文本。
local function localizeListItemSubItems(item)
  local okSubItems, subItems = pcall(function() return item.SubItems end)
  if not okSubItems or not subItems then return end

  local okCount, count = pcall(function() return subItems.Count end)
  if not okCount or type(count) ~= 'number' then return end
  if count > MAX_AUTORUN_STRING_ITEMS then return end

  local updating = count > 1 and beginUpdateIfSupported(subItems)
  local okLoop, err = pcall(function()
    for i = 0, count - 1 do
      local value = indexedValue(subItems, i)
      if type(value) == 'string' then
        local mapped = autorunListText(value)
        if mapped ~= value then setIndexedValue(subItems, i, mapped, item) end
      end
    end
  end)
  if updating then endUpdateIfSupported(subItems) end
  if not okLoop then error(err) end
end

-- 翻译 ListView 中所有行和子项。
local function localizeListViewRows(obj)
  local okItems, items = pcall(function() return obj.Items end)
  if not okItems or not items then return end

  local okCount, count = pcall(function() return items.Count end)
  if not okCount or type(count) ~= 'number' then return end
  if count > MAX_AUTORUN_STRING_ITEMS then return end

  local updating = count > 1 and beginUpdateIfSupported(obj)
  local okLoop, err = pcall(function()
    for i = 0, count - 1 do
      local item = indexedValue(items, i)
      if item then localizeListItemSubItems(item) end
    end
  end)
  if updating then endUpdateIfSupported(obj) end
  if not okLoop then error(err) end
end

local HIGHLIGHTER_ATTRIBUTE_TEXT = {
  ['Mnemonic'] = '助记符',
  ['Opcode'] = '操作码',
  ['Key'] = '关键字',
  ['Label'] = '标签',
  ['Number'] = '数字',
  ['Numbers'] = '数字',
  ['Preprocessor'] = '预处理器',
  ['Register'] = '寄存器',
  ['Reserved word'] = '保留字',
  ['Reserved word 2'] = '保留字 2',
  ['Reserved word 3'] = '保留字 3',
  ['Reserved word 4'] = '保留字 4',
  ['Space'] = '空格',
  ['Symbol'] = '符号',
  ['Directive'] = '指令',
  ['Assembler'] = '汇编器',
}

-- 翻译语法高亮属性编辑器里的属性名。
local function highlighterAttributeCaption(s)
  if type(s) ~= 'string' then return s end

  local prefix, core, suffix = s:match('^(%s*)%*(.-)%*(%s*)$')
  if core then
    local mapped = HIGHLIGHTER_ATTRIBUTE_TEXT[core] or zhText(core)
    if mapped ~= core then return prefix .. '*' .. mapped .. '*' .. suffix end
  end

  return HIGHLIGHTER_ATTRIBUTE_TEXT[s] or zhText(s)
end

-- 翻译单个语法高亮属性标签。
local function localizeHighlighterAttributeLabel(label)
  if not label then return end

  local okCaption, caption = pcall(function() return label.Caption end)
  if okCaption and type(caption) == 'string' then
    local mapped = highlighterAttributeCaption(caption)
    if mapped ~= caption then
      pcall(function() label.Caption = mapped end)
    end
  end
end

local HIGHLIGHTER_ATTR_CLICK_WRAPPED = {}

-- 查找当前选中的语法高亮属性标签。
local function selectedHighlighterAttributeLabel(panel)
  if not panel then return nil end

  -- 检查子控件是否是当前选中的高亮属性标签。
  local function checkChild(child)
    if not child then return nil end
    local okCaption, caption = pcall(function() return child.Caption end)
    if okCaption and type(caption) == 'string' and caption:match('^%s*%*.*%*%s*$') then
      return child
    end
    return nil
  end

  local okCount, count = pcall(function() return panel.ComponentCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return panel.Component[i] end)
      if okChild then
        local found = checkChild(child)
        if found then return found end
      end
    end
  end

  okCount, count = pcall(function() return panel.ControlCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return panel.Control[i] end)
      if okChild then
        local found = checkChild(child)
        if found then return found end
      end
    end
  end

  return nil
end

-- 翻译语法高亮属性面板，并在点击切换时补刷标签。
local function localizeHighlighterAttributePanel(panel)
  if not panel then return end

  -- 处理高亮属性面板的子控件。
  local function visitChild(child)
    if not child then return end

    localizeHighlighterAttributeLabel(child)

    if HIGHLIGHTER_ATTR_CLICK_WRAPPED[child] then return end
    local okClick, oldClick = pcall(function() return child.OnClick end)
    if not okClick or type(oldClick) ~= 'function' then return end

    HIGHLIGHTER_ATTR_CLICK_WRAPPED[child] = true
    -- 高亮属性点击回调：切换选择后重新翻译相关标签。
    child.OnClick = function(sender, ...)
      local previous = selectedHighlighterAttributeLabel(panel)
      local ok, result = pcall(oldClick, sender, ...)
      if previous and previous ~= sender then pcall(localizeHighlighterAttributeLabel, previous) end
      pcall(localizeHighlighterAttributeLabel, sender or child)
      if not ok then error(result) end
      return result
    end
  end

  local okCount, count = pcall(function() return panel.ComponentCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return panel.Component[i] end)
      if okChild and child then visitChild(child) end
    end
  end

  okCount, count = pcall(function() return panel.ControlCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return panel.Control[i] end)
      if okChild and child then visitChild(child) end
    end
  end
end

-- 定位并汉化语法高亮编辑器。
local function localizeHighlighterEditor(obj)
  if not obj then return end

  local panel
  if objectName(obj) == 'pnlAttribs' then
    panel = obj
  elseif objectClassName(obj) == 'TfrmHighlighterEditor' or objectName(obj) == 'frmHighlighterEditor' then
    panel = findNamedChild(obj, 'pnlAttribs')
  end

  if panel then localizeHighlighterAttributePanel(panel) end
end

local localizeTree
local visitControlTreeForMissing

-- 递归遍历控件树并调用各类汉化函数。
local function visitComponent(obj, seen, options)
  if not obj then return end
  if seen[obj] then return end
  seen[obj] = true
  options = options or {}

  local className = objectClassName(obj)
  local name = objectName(obj)
  local flags = localizeFlagsForClass(className)
  if name == 'FormDesigner' or flags.isFormDesignerRuntimeClass then return end

  localizeObject(obj, className)

  if flags.hasColumns then localizeColumns(obj) end
  if flags.isMenu then localizeMenuObject(obj, seen) end
  if name == 'pnlAttribs' or className == 'TfrmHighlighterEditor' or name == 'frmHighlighterEditor' then
    localizeHighlighterEditor(obj)
  end
  if name == 'frmAIDialog' then localizeAIDialog(obj) end
  if isDotNetInfoForm(obj, name) then localizeDotNetInfoForm(obj) end
  if name == 'DotNetInfoConfig' then localizeDotNetInfoConfigForm(obj) end

  if not options.skipMutableItems then
    if flags.hasStringItems or name == 'ScanOptionsModuleList' then
      localizeItems(obj, seen)
    end
    if name == 'ScanOptionsModuleList' then localizeModuleScanOptionsCombo(obj) end
    if flags.isListView then localizeListViewRows(obj) end
  end

  local access = childAccessFor(obj, className)
  if access.hasComponents then
    local count = obj.getComponentCount()
    for i = 0, count - 1 do
      local child = obj.Component[i]
      if child then visitComponent(child, seen, options) end
    end
  end

  if options.flatOwnedComponents then return end

  if access.hasControls then
    local count = obj.ControlCount
    for i = 0, count - 1 do
      local child = obj.Control[i]
      if child then visitComponent(child, seen, options) end
    end
  end
end

visitControlTreeForMissing = function(obj, seen, options)
  if not obj then return end
  local className = objectClassName(obj)
  local access = childAccessFor(obj, className)
  if not access.hasControls then return end

  local count = obj.ControlCount

  for i = 0, count - 1 do
    local child = obj.Control[i]
    if child then
      if not seen[child] then visitComponent(child, seen, options) end
      visitControlTreeForMissing(child, seen, options)
    end
  end
end

-- 从指定根控件开始递归汉化整棵控件树。
function localizeTree(root, options)
  options = options or {}
  local seen = {}
  visitComponent(root, seen, options)
  if options.scanControlTreeForMissing then
    visitControlTreeForMissing(root, seen, options)
  end
end

-- 兼容不同 TreeView Items 接口读取节点。
local function treeNodeAt(items, index)
  local ok, node = pcall(function() return items.Item[index] end)
  if ok and node then return node end

  ok, node = pcall(function() return items[index] end)
  if ok and node then return node end

  ok, node = pcall(function() return items.getItem(index) end)
  if ok and node then return node end

  return nil
end

-- 翻译设置窗口树节点文本。
local function localizeSettingsTreeNode(node)
  if not node then return end

  local okText, text = pcall(function() return node.Text end)
  if okText and type(text) == 'string' then
    local mapped = zhText(text)
    if mapped ~= text then
      pcall(function() node.Text = mapped end)
    end
  end
end

-- 翻译设置窗口左侧树。
local function localizeSettingsTreeView(tree)
  if not tree then return end

  local okItems, items = pcall(function() return tree.Items end)
  if not okItems or not items then return end

  local okCount, count = pcall(function() return items.Count end)
  if not okCount or type(count) ~= 'number' then
    okCount, count = pcall(function() return items.getCount() end)
  end
  if not okCount or type(count) ~= 'number' then return end

  local updating = count > 1 and beginUpdateIfSupported(tree)
  local okLoop, err = pcall(function()
    for i = 0, count - 1 do
      localizeSettingsTreeNode(treeNodeAt(items, i))
    end
  end)
  if updating then endUpdateIfSupported(tree) end
  if not okLoop then error(err) end

  pcall(function() tree.repaint() end)
  pcall(function() tree.update() end)
end

-- 取得设置窗体的 SettingsTreeView。
local function settingsTreeOf(form)
  if not form then return nil end
  local okTree, tree = pcall(function() return form.SettingsTreeView end)
  if okTree and tree then return tree end
  return nil
end

-- 在设置窗体中找到 Custom Types 列表。
local function customTypesListOf(sf)
  if not sf then return nil end

  local okPageControl, pc = pcall(function() return sf.SettingsPageControl end)
  if not okPageControl or not pc then return nil end

  local okPageCount, pageCount = pcall(function() return pc.PageCount end)
  if not okPageCount or type(pageCount) ~= 'number' then return nil end

  for i = 0, pageCount - 1 do
    local okPage, page = pcall(function() return pc.Page[i] end)
    if okPage and page and objectName(page) == 'CustomTypes' then
      local okList, list = pcall(function() return page.List end)
      if okList and list then return list end

      okList, list = pcall(function()
        if page.findComponentByName then return page.findComponentByName('List') end
        return nil
      end)
      if okList and list then return list end
    end
  end

  return nil
end

-- 在 Big Endian 设置列表的英文内部值和中文显示值之间转换。
local function mapBigEndianSettingsList(list, toDisplay)
  if not list then return end

  local okItems, items = pcall(function() return list.Items end)
  if not okItems or not items then return end

  local okCount, count = pcall(function() return items.Count end)
  if not okCount or type(count) ~= 'number' then return end

  for i = 0, count - 1 do
    local value = indexedValue(items, i)
    local key = BIG_ENDIAN_SETTING_KEY[value]
    if key then
      local mapped = toDisplay and BIG_ENDIAN_SETTING_DISPLAY[key] or key
      if mapped and mapped ~= value then
        setIndexedValue(items, i, mapped, list)
      end
    end
  end
end

-- 设置窗口关闭前把 Big Endian 列表恢复为英文内部值，避免保存错误。
local function installBigEndianSettingsCloseBridge(sf)
  if not sf then return end

  local current = sf.OnClose
  if current == sf._zhCNBigEndianCloseBridge then return end

  local original = current
  local wrapper
  -- 设置窗口关闭回调：保存前恢复 Big Endian 内部英文值。
  wrapper = function(sender, closeAction)
    mapBigEndianSettingsList(customTypesListOf(sf), false)

    local result = closeAction
    if original then
      local ok, originalResult = pcall(original, sender, closeAction)
      mapBigEndianSettingsList(customTypesListOf(sf), true)
      if not ok then error(originalResult) end
      result = originalResult
    else
      mapBigEndianSettingsList(customTypesListOf(sf), true)
    end

    return result
  end

  sf._zhCNBigEndianCloseBridge = wrapper
  sf.OnClose = wrapper
end

-- 汉化 Big Endian 设置界面的三个固定选项。
local function localizeBigEndianSettings(sf)
  local list = customTypesListOf(sf)
  if not list then return end

  mapBigEndianSettingsList(list, true)
  installBigEndianSettingsCloseBridge(sf)
end

-- 包装 getSettingsForm，确保设置窗体创建后立即补做 Big Endian 汉化。
local function wrapGetSettingsFormForBigEndianSettings()
  local original = capture('getSettingsForm')
  if type(original) ~= 'function' then return end

  -- getSettingsForm 包装：取得设置窗体后立即补做汉化。
  _G.getSettingsForm = function(...)
    local sf = original(...)
    if sf then pcall(localizeBigEndianSettings, sf) end
    return sf
  end
end

-- 汉化设置窗体，包括控件树、左侧分类和 Big Endian 特殊项。
local function localizeSettingsForm(sf)
  local tree = settingsTreeOf(sf)
  if not tree then return end
  pcall(localizeTree, sf, { skipMutableItems = true, flatOwnedComponents = true, scanControlTreeForMissing = true })
  localizeSettingsTreeView(tree)
  localizeBigEndianSettings(sf)
end

-- 汉化主窗口菜单和常见右键菜单。
local function localizeMainMenus()
  if not MainForm then return end

  local seen = {}
  local okMenu, menu = pcall(function() return MainForm.Menu end)
  if okMenu and menu then localizeMenuObject(menu, seen) end

  okMenu, menu = pcall(function() return MainForm.MainMenu end)
  if okMenu and menu then localizeMenuObject(menu, seen) end

  okMenu, menu = pcall(function() return AddressList and AddressList.PopupMenu end)
  if okMenu and menu then localizeMenuObject(menu, seen) end

  local okCount, count = pcall(function() return MainForm.ComponentCount end)
  if okCount and type(count) == 'number' then
    for i = 0, count - 1 do
      local okChild, child = pcall(function() return MainForm.Component[i] end)
      if okChild and child then
        local className = objectClassName(child)
        if className:find('PopupMenu', 1, true) then
          localizeMenuObject(child, seen)
        end
      end
    end
  end
end

-- 汉化 UETools 扩展菜单项。
local function localizeUEToolsMenus()
  local okGui, gui = pcall(function()
    return _G.UEngine and _G.UEngine.GUI
  end)
  if not okGui or not gui then return end

  local names = {
    'miUnrealEngine',
    'miStatus',
    'miHurry',
    'miStructureDissectCallbackStatus',
  }

  for i = 1, #names do
    local item = gui[names[i]]
    if item then
      pcall(localizeObject, item)
      pcall(localizeMenuObject, item, {})
    end
  end
end

-- 遍历当前已经打开的窗体并做一次汉化。
local function localizeOpenForm(form)
  if not form then return end
  if isTransientDialogForm(form) then return end
  if settingsTreeOf(form) then
    localizeSettingsForm(form)
  elseif not isFormDesignerRuntimeObject(form) then
    localizeTree(form, { flatOwnedComponents = true, scanControlTreeForMissing = true })
  end
end

local function localizeOpenForms()
  if type(getFormCount) ~= 'function' or type(getForm) ~= 'function' then return end

  local okCount, count = pcall(getFormCount)
  if not okCount or type(count) ~= 'number' then return end

  for i = 0, count - 1 do
    local okForm, form = pcall(getForm, i)
    if okForm and form then pcall(localizeOpenForm, form) end
  end
end

-- 把主窗口标题里的 Admin 后缀改为中文。
local function localizeMainFormCaption()
  if not MainForm then return end

  local okCaption, caption = pcall(function() return MainForm.Caption end)
  if not okCaption or type(caption) ~= 'string' then return end

  local mapped = zhText(caption)
  if mapped == caption then
    mapped = caption:gsub('^(Cheat Engine.-) %(Admin%)$', '%1（管理员）')
  end
  if mapped == caption then
    mapped = caption:gsub('Cheat Engine %(Admin%)', 'Cheat Engine（管理员）')
  end

  if mapped ~= caption then
    pcall(function() MainForm.Caption = mapped end)
  end
end

-- 一次性包装 MainForm.OnShow，等 CE 追加 Admin 后再修正标题并还原原回调。
local function localizeMainFormCaptionAfterShowOnce()
  if not MainForm then return end

  local okEvent, previous = pcall(function() return MainForm.OnShow end)
  if not okEvent or type(previous) ~= 'function' then return end

  local ok = pcall(function()
    -- 主窗体显示回调包装：等 CE 追加 Admin 后只修正一次标题。
    MainForm.OnShow = function(sender)
      local callOk, err = pcall(previous, sender)
      pcall(function() MainForm.OnShow = previous end)
      pcall(localizeMainFormCaption)
      if not callOk then error(err) end
    end
  end)
  if not ok then return end
end

-- 创建/获取内存视图后立即补刷标题。
local function localizeMemoryViewForm(form)
  if not form then return end
  localizeProperty(form, 'Caption')
end

-- 把扫描结果里 “First” 列标题改成中文。
local function renameFirstScanColumn()
  local fl = MainForm and MainForm.foundlist3
  local columns = fl and fl.Columns
  if not columns then return end

  for i = 3, columns.Count - 1 do
    if columns[i].Caption == 'First' then
      columns[i].Caption = '首次值'
      return
    end
  end
end

-- 在扫描完成后重新检查并汉化新增的扫描结果列。
local function installMemscanColumnHook()
  local ms = getCurrentMemscan()
  if not ms or ms._zhCNFirstColumnHooked then return end
  ms._zhCNFirstColumnHooked = true

  local previous = ms.OnScanDone
  -- 扫描完成回调：先修正列标题，再调用 CE 原回调。
  ms.OnScanDone = function(m)
    pcall(renameFirstScanColumn)
    if previous then return previous(m) end
  end
end

-- 打开进程后安装扫描结果列标题修正逻辑。
local function installProcessOpenedHook()
  if not MainForm or MainForm._zhCNProcessOpenedHooked then return end
  MainForm._zhCNProcessOpenedHooked = true

  local previous = MainForm.OnProcessOpened
  -- 打开进程回调：安装扫描结果列 Hook 后继续执行 CE 原回调。
  MainForm.OnProcessOpened = function(pid, handle, caption)
    pcall(installMemscanColumnHook)
    if previous then return previous(pid, handle, caption) end
  end
end

-- 执行一次全局 UI 汉化。
local function localizeAllForms()
  pcall(localizeMainFormCaption)
  pcall(localizeUEToolsMenus)
  pcall(localizeOpenForms)
  pcall(function()
    if _G.jf then localizeObject(_G.jf) end
  end)
  pcall(function()
    if _G.df then localizeObject(_G.df) end
  end)
end

local didInitialGlobalLocalization = false
local KNOWN_LATE_DIALOG_CAPTIONS = {
  ['Api hook template'] = true,
}
local KNOWN_LATE_DIALOG_QUEUED = setmetatable({}, {__mode = 'k'})
local DEFERRED_LOCALIZATION_QUEUED = setmetatable({}, {__mode = 'k'})
local DEFERRED_NATIVE_PATCH_QUEUED = setmetatable({}, {__mode = 'k'})

local function isMemoryBrowserForm(form)
  if not form then return false end
  local className = objectClassName(form)
  local name = objectName(form)
  return className == 'TMemoryBrowser' or name == 'MemoryBrowser'
end

local function isAutoAssemblerForm(form)
  if not form then return false end
  local className = objectClassName(form)
  return className == 'TfrmAutoInject'
end

local function installDeferredNativePatchesForForm(form)
  if isMemoryBrowserForm(form) then
    installMemoryViewNativeTextPatches()
  end
  if isAutoAssemblerForm(form) then
    installAutoAssemblerNativeTextPatches()
  end
end

local function hookDeferredNativePatchesFirstShow(form)
  if not form then return end
  if DEFERRED_NATIVE_PATCH_QUEUED[form] then return end
  if not isMemoryBrowserForm(form) and not isAutoAssemblerForm(form) then return end
  DEFERRED_NATIVE_PATCH_QUEUED[form] = true

  local okMethod, register = pcall(function() return form.registerFirstShowCallback end)
  if not okMethod or type(register) ~= 'function' then return end

  local cb
  pcall(function()
    cb = form.registerFirstShowCallback(function(sender)
      pcall(function() form.unregisterFirstShowCallback(cb) end)
      pcall(installDeferredNativePatchesForForm, sender or form)
    end)
  end)
end

-- 新窗体出现时按类型选择合适的汉化入口。
local function localizeSoon(root)
  if root and isFormDesignerRuntimeObject(root) then return end
  if root and isTransientDialogForm(root) then return end
  if root and settingsTreeOf(root) then
    pcall(localizeSettingsForm, root)
  elseif root then
    pcall(localizeOpenForm, root)
  end
  if not didInitialGlobalLocalization or not root then
    didInitialGlobalLocalization = true
    pcall(localizeAllForms)
  end
end

-- 少数 CE 原生对话框不会稳定触发 first-show 回调；只对已知标题做延迟补刷。
local function queueKnownLateDialogLocalization(form)
  if not form or type(createTimer) ~= 'function' then return end
  if KNOWN_LATE_DIALOG_QUEUED[form] then return end
  KNOWN_LATE_DIALOG_QUEUED[form] = true

  local attempts = 0
  local okTimer = pcall(function()
    local timer = createTimer(form, false)
    timer.Interval = 100
    timer.OnTimer = function(t)
      attempts = attempts + 1

      local okCaption, caption = pcall(function() return form.Caption end)
      if okCaption and type(caption) == 'string' and KNOWN_LATE_DIALOG_CAPTIONS[caption] then
        pcall(function() t.destroy() end)
        pcall(function() form.Caption = zhText(caption) end)
        localizeTree(form)
        return
      end

      if attempts >= 5 then
        pcall(function() t.destroy() end)
      end
    end
    timer.Enabled = true
  end)

  if not okTimer then
    local okCaption, caption = pcall(function() return form.Caption end)
    if okCaption and type(caption) == 'string' and KNOWN_LATE_DIALOG_CAPTIONS[caption] then
      pcall(function() form.Caption = zhText(caption) end)
      localizeTree(form)
    end
  end
end

-- 没有 first-show 回调的窗体不要在创建通知里立刻递归扫树；等消息循环稳定一拍后再处理。
local function queueDeferredLocalization(form)
  if not form or type(createTimer) ~= 'function' then return end
  if DEFERRED_LOCALIZATION_QUEUED[form] then return end
  DEFERRED_LOCALIZATION_QUEUED[form] = true

  pcall(function()
    local timer = createTimer(form, false)
    timer.Interval = 50
    timer.OnTimer = function(t)
      pcall(function() t.destroy() end)
      localizeSoon(form)
    end
    timer.Enabled = true
  end)
end

-- 给新窗体注册首次显示后的补刷回调。
local function hookFirstShow(form)
  if not form then return end
  local okMethod, register = pcall(function() return form.registerFirstShowCallback end)
  if not okMethod or type(register) ~= 'function' then return false end

  local cb
  local ok = pcall(function()
    cb = form.registerFirstShowCallback(function(sender)
      pcall(function() form.unregisterFirstShowCallback(cb) end)
      localizeSoon(sender or form)
    end)
  end)
  if not ok then return false end
  return true
end

local function hookTransientDialogFirstShow(form)
  if not form then return false end
  if TRANSIENT_DIALOG_QUEUED[form] then return true end
  TRANSIENT_DIALOG_QUEUED[form] = true

  local okMethod, register = pcall(function() return form.registerFirstShowCallback end)
  if not okMethod or type(register) ~= 'function' then
    pcall(localizeTransientDialog, form)
    return false
  end

  local cb
  local ok = pcall(function()
    cb = form.registerFirstShowCallback(function(sender)
      pcall(function() form.unregisterFirstShowCallback(cb) end)
      pcall(localizeTransientDialog, sender or form)
    end)
  end)
  if not ok then
    pcall(localizeTransientDialog, form)
    return false
  end
  return true
end

if type(registerFormAddNotification) == 'function' and _G.__zhCNUIFormAddNotification == nil then
  _G.__zhCNUIFormAddNotification = registerFormAddNotification(function(form)
    if isTransientDialogForm(form) then
      hookTransientDialogFirstShow(form)
      return
    end
    hookDeferredNativePatchesFirstShow(form)
    queueKnownLateDialogLocalization(form)
    if not hookFirstShow(form) then queueDeferredLocalization(form) end
  end)
end

local function hookExistingDeferredNativePatchForms()
  if type(getFormCount) ~= 'function' or type(getForm) ~= 'function' then return end
  local okCount, count = pcall(getFormCount)
  if not okCount or type(count) ~= 'number' then return end
  for i = 0, count - 1 do
    local okForm, form = pcall(getForm, i)
    if okForm and form then hookDeferredNativePatchesFirstShow(form) end
  end
end

-- 包装 createSettingsOption，翻译动态创建的设置项描述。
local function wrapCreateSettingsOption()
  local original = capture('createSettingsOption')
  if type(original) ~= 'function' then return end

  -- createSettingsOption 包装：翻译动态设置项描述。
  _G.createSettingsOption = function(internalSettingName, description, valueType, settingsTabName, ...)
    return original(internalSettingName, zhText(description), valueType, settingsTabName, ...)
  end
end

-- 包装 createTableOption，翻译动态创建的表选项描述。
local function wrapCreateTableOption()
  local original = capture('createTableOption')
  if type(original) ~= 'function' then return end

  -- createTableOption 包装：翻译动态表选项描述。
  _G.createTableOption = function(name, description, ...)
    return original(name, zhText(description), ...)
  end
end

local function wrapAutoAssemblerFactories()
  local original = capture('createAutoAssemblerForm')
  if type(original) == 'function' then
    _G.createAutoAssemblerForm = function(...)
      installAutoAssemblerNativeTextPatches()
      local first = ...
      if type(first) == 'string' then
        first = localizeAutoAssemblerScriptTemplate(first)
        local form = original(first, select(2, ...))
        if form then
          hookDeferredNativePatchesFirstShow(form)
          pcall(localizeOpenForm, form)
        end
        return form
      end

      local form = original(...)
      if form then
        hookDeferredNativePatchesFirstShow(form)
        pcall(localizeOpenForm, form)
      end
      return form
    end
  end
end

local function wrapMemoryViewFactories()
  local getOriginal = capture('getMemoryViewForm')
  if type(getOriginal) == 'function' then
    _G.getMemoryViewForm = function(...)
      installMemoryViewNativeTextPatches()
      local form = getOriginal(...)
      if form then pcall(localizeMemoryViewForm, form) end
      return form
    end
  end

  local createOriginal = capture('createMemoryView')
  if type(createOriginal) == 'function' then
    _G.createMemoryView = function(...)
      installMemoryViewNativeTextPatches()
      local form = createOriginal(...)
      if form then pcall(localizeMemoryViewForm, form) end
      return form
    end
  end
end

_G.zhCNInstallCEDrawTextHook = installCEDrawTextHook
_G.zhCNLocalizeOpenFormsNow = localizeOpenForms

localizeMainFormCaptionAfterShowOnce()
checkedCall(renameFirstScanColumn)
checkedCall(installMemscanColumnHook)
checkedCall(installProcessOpenedHook)
installAIDialogSpawnHook()
wrapCreateSettingsOption()
wrapCreateTableOption()
wrapGetSettingsFormForBigEndianSettings()
wrapCreateVirtualStringTree()
wrapAutoAssemblerFactories()
wrapMemoryViewFactories()
hookExistingDeferredNativePatchForms()

localizeSoon()
_G.__zhCNUITranslateLoaded = true
