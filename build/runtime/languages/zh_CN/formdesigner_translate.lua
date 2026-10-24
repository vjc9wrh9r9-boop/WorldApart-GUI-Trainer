-- Cheat Engine 7.7 窗体设计器对象检查器汉化脚本。
-- 原生绘制 Hook 说明：
-- 1. 不修改对象检查器行、属性编辑器或有序列表。
-- 2. 在 TPropertyEditor.PropDrawName 调用 Canvas.TextRect 前 Hook 绘制文本。
-- 3. 只替换用于绘制属性名的字符串指针。
-- 4. 修补少量对象检查器菜单 resourcestring 指针，用于动态右键菜单标题。
-- 5. 启动时只自动安装属性名和菜单资源的原生修正；属性值和对象标题保持原始显示。

local PROP_NAME = {
  ['Name']='名称',['Caption']='标题',['Hint']='提示',['Tag']='标记',
  ['Text']='文本',['Items']='项目',['ItemIndex']='项目索引',['Checked']='选中',
  ['State']='状态',['Enabled']='启用',['Visible']='可见',['PopupMenu']='弹出菜单',
  ['ShowHint']='显示提示',['TabOrder']='Tab顺序',['TabStop']='Tab停靠',
  ['HelpContext']='帮助上下文',['HelpKeyword']='帮助关键字',['HelpType']='帮助类型',
  ['HelpFile']='帮助文件',
  ['Left']='左边距',['Top']='上边距',['Width']='宽度',['Height']='高度',
  ['Align']='对齐',['Alignment']='对齐方式',['Anchors']='锚点',
  ['akBottom']='底部',['akLeft']='左侧',['akRight']='右侧',['akTop']='顶部',
  ['AnchorSideLeft']='左锚边',['AnchorSideTop']='上锚边',
  ['AnchorSideRight']='右锚边',['AnchorSideBottom']='下锚边',
  ['BorderSpacing']='边框间距',['Around']='四周边距',['AutoSize']='自动大小',['Constraints']='约束',
  ['ChildSizing']='子控件布局',['BoundsRect']='边界矩形',
  ['ControlsPerLine']='每行控件数',['EnlargeHorizontal']='水平扩展',
  ['EnlargeVertical']='垂直扩展',['HorizontalSpacing']='水平间距',
  ['LeftRightSpacing']='左右间距',['ShrinkHorizontal']='水平收缩',
  ['ShrinkVertical']='垂直收缩',['TopBottomSpacing']='上下间距',
  ['VerticalSpacing']='垂直间距',
  ['ClientHeight']='客户区高度',['ClientWidth']='客户区宽度',
  ['Color']='颜色',['Font']='字体',['Cursor']='光标',
  ['CharSet']='字符集',['Pitch']='字体间距',['Quality']='质量',['Size']='大小',
  ['fsBold']='粗体',['fsItalic']='斜体',
  ['fsStrikeOut']='删除线',['fsUnderline']='下划线',
  ['BiDiMode']='双向显示模式',['ParentColor']='继承父颜色',
  ['ParentFont']='继承父字体',['ParentBiDiMode']='继承父双向模式',
  ['ParentDoubleBuffered']='继承父双缓冲',['ParentShowHint']='继承父显示提示',
  ['ParentBackground']='继承父背景',['ParentCtl3D']='继承父3D效果',
  ['DoubleBuffered']='双缓冲',['BorderStyle']='边框样式',
  ['BorderWidth']='边框宽度',['BorderIcons']='边框图标',
  ['biHelp']='帮助按钮',['biMaximize']='最大化按钮',
  ['biMinimize']='最小化按钮',['biSystemMenu']='系统菜单按钮',
  ['BevelEdges']='斜面边缘',['BevelInner']='内斜面',['BevelOuter']='外斜面',
  ['BevelKind']='斜面类型',['BevelWidth']='斜面宽度',['Ctl3D']='3D效果',
  ['WindowState']='窗口状态',['FormStyle']='窗体样式',
  ['AlphaBlend']='透明混合',['AlphaBlendValue']='透明度',
  ['TransparentColor']='透明色',['TransparentColorValue']='透明色值',
  ['DefaultMonitor']='默认显示器',['Position']='位置',['Scaled']='缩放',
  ['PixelsPerInch']='每英寸像素',['DesignTimePPI']='设计时PPI',
  ['UseDockManager']='使用停靠管理器',['DockSite']='停靠站点',
  ['KeyPreview']='键盘预览',['ActiveControl']='活动控件',
  ['ShowInTaskBar']='任务栏显示',['SessionProperties']='会话属性',
  ['AllowDropFiles']='允许拖放文件',['DoNotSaveInTable']='不保存到表',
  ['Icon']='图标',['Menu']='菜单',
  ['PopupMode']='弹出模式',['PopupParent']='弹出父窗体',
  ['PopupParentControl']='弹出父控件',
  ['LCLVersion']='LCL版本',['OldCreateOrder']='旧创建顺序',
  ['Monitor']='显示器',['ScreenSnap']='屏幕吸附',['SnapBuffer']='吸附距离',
  ['SnapOptions']='吸附选项',['Distance']='距离',
  ['SnapFormTarget']='吸附窗体目标',['SnapToForms']='吸附到窗体',
  ['SnapToMonitor']='吸附到显示器',
  ['DragMode']='拖拽模式',['DragKind']='拖拽类型',['DragCursor']='拖拽光标',
  ['HorzScrollBar']='水平滚动条',['VertScrollBar']='垂直滚动条',
  ['Increment']='增量',['Page']='页',['Range']='范围',['Tracking']='跟踪',
  ['AutoScroll']='自动滚动',['CharCase']='字符大小写',
  ['MaxLength']='最大长度',['ReadOnly']='只读',['PasswordChar']='密码字符',
  ['NumbersOnly']='仅数字',['EchoMode']='回显模式',['Lines']='文本行',
  ['ScrollBars']='滚动条',['WantReturns']='接受回车',
  ['WantTabs']='接受Tab',['WordWrap']='自动换行',
  ['MultiSelect']='多选',['SelCount']='选中数量',
  ['SelStart']='选择起点',['SelLength']='选择长度',['SelText']='选中文本',
  ['HideSelection']='隐藏选择',['RowSelect']='行选择',
  ['Columns']='列',['ColumnCount']='列数',['RowCount']='行数',
  ['FixedCols']='固定列',['FixedRows']='固定行',
  ['DefaultColWidth']='默认列宽',['DefaultRowHeight']='默认行高',
  ['GridLineWidth']='网格线宽',['GridLineColor']='网格线颜色',
  ['Options']='选项',['SortColumn']='排序列',['SortOrder']='排序顺序',
  ['Images']='图标',['StateImages']='状态图标',
  ['ShowButtons']='显示按钮',['ShowLines']='显示连线',['ShowRoot']='显示根节点',
  ['TreeLineColor']='树线颜色',['ExpandSignColor']='展开符号颜色',
  ['ExpandSignType']='展开符号类型',
  ['Min']='最小值',['Max']='最大值',['Step']='步长',
  ['BarShowText']='显示文本',['Orientation']='方向',['Smooth']='平滑',
  ['OnClick']='点击事件',['OnDblClick']='双击事件',
  ['OnCreate']='创建事件',['OnDestroy']='销毁事件',
  ['OnClose']='关闭事件',['OnShow']='显示事件',['OnHide']='隐藏事件',
  ['OnActivate']='激活事件',['OnDeactivate']='停用事件',
  ['OnResize']='调整大小事件',['OnPaint']='绘制事件',
  ['OnKeyDown']='按键按下事件',['OnKeyUp']='按键释放事件',
  ['OnKeyPress']='按键事件',['OnMouseDown']='鼠标按下事件',
  ['OnMouseUp']='鼠标释放事件',['OnMouseMove']='鼠标移动事件',
  ['OnMouseWheel']='鼠标滚轮事件',['OnMouseEnter']='鼠标进入事件',
  ['OnMouseLeave']='鼠标离开事件',['OnEnter']='获得焦点事件',
  ['OnExit']='失去焦点事件',['OnChange']='改变事件',
  ['OnSelect']='选择事件',['OnEditingDone']='编辑完成事件',
  ['OnCloseQuery']='关闭查询事件',['OnContextPopup']='右键菜单事件',
  ['OnChangeBounds']='边界改变事件',['OnCanResize']='允许调整大小事件',
  ['OnConstrainedResize']='受约束调整大小事件',
  ['OnDropFiles']='拖放文件事件',['OnDragDrop']='拖放事件',
  ['OnDragOver']='拖过事件',['OnStartDrag']='开始拖拽事件',
  ['OnEndDrag']='结束拖拽事件',['OnDockDrop']='停靠放下事件',
  ['OnDockOver']='停靠悬停事件',['OnStartDock']='开始停靠事件',
  ['OnEndDock']='结束停靠事件',['OnUnDock']='取消停靠事件',
  ['OnGetSiteInfo']='获取停靠信息事件',['OnHelp']='帮助事件',
  ['OnShortCut']='快捷键处理事件',['OnShowHint']='显示提示事件',
  ['OnUTF8KeyPress']='UTF8按键事件',
  ['OnWindowStateChange']='窗口状态改变事件',
  ['OnMouseWheelDown']='鼠标滚轮向下事件',
  ['OnMouseWheelUp']='鼠标滚轮向上事件',
  ['OnMouseWheelHorz']='鼠标水平滚轮事件',
  ['OnMouseWheelLeft']='鼠标滚轮向左事件',
  ['OnMouseWheelRight']='鼠标滚轮向右事件',
  ['OnDropDown']='下拉事件',['OnDrawItem']='绘制项目事件',
  ['OnMeasureItem']='测量项目事件',['OnSelectionChange']='选择改变事件',
  ['OnChanging']='正在改变事件',['OnCollapse']='折叠事件',
  ['OnExpand']='展开事件',['OnCompare']='比较事件',
  ['Action']='动作',['AutoCheck']='自动勾选',['Bitmap']='位图',
  ['Break']='分隔',['Command']='命令',['Default']='默认',
  ['GroupIndex']='分组索引',['ImageIndex']='图标索引',['RadioItem']='单选项',
  ['ShortCut']='快捷键',['ShortCutKey2']='快捷键2',
  ['SubMenuImages']='子菜单图标',['MenuIndex']='菜单索引',
  ['Picture']='图片',['Transparent']='透明',['Proportional']='等比例',
  ['Stretch']='拉伸',['Center']='居中',['AutoResize']='自动调整',
  ['KeepOriginXWhenClipped']='裁剪时保持 X 原点',
  ['KeepOriginYWhenClipped']='裁剪时保持 Y 原点',
  ['StretchOutEnabled']='允许放大拉伸',
  ['StretchInEnabled']='允许缩小拉伸',
  ['IncrementalDisplay']='增量显示',
  ['ModalResult']='模态结果',['Cancel']='取消按钮',['Kind']='类型',
  ['Glyph']='图标',['Layout']='布局',['Margin']='边距',['Spacing']='间距',
  ['Flat']='扁平',['NumGlyphs']='图标数量',
  ['Frequency']='刻度频率',['LineSize']='行大小',['PageSize']='页大小',
  ['SliderVisible']='滑块可见',['ThumbLength']='滑块长度',
  ['TickMarks']='刻度标记',['TickStyle']='刻度样式',
  ['Reversed']='反向',['ScalePos']='刻度位置',
  ['AllowGrayed']='允许灰色',['DropDownCount']='下拉数量',
  ['ItemWidth']='项目宽度',['ItemHeight']='项目高度',
  ['Sorted']='排序',['Style']='样式',
  ['ActivePage']='活动页面',['ActivePageIndex']='活动页面索引',
  ['MultiLine']='多行',['ShowTabs']='显示标签',
  ['TabHeight']='标签高度',['TabWidth']='标签宽度',
  ['TabPosition']='标签位置',['Pages']='页面',['PageCount']='页面数量',
  ['ResizeStyle']='调整大小样式',['MinSize']='最小尺寸',
  ['Interval']='间隔',['FileName']='文件名',['Filter']='过滤器',
  ['LabelPosition']='标签位置',['LabelSpacing']='标签间距',
  ['FilterIndex']='过滤器索引',['InitialDir']='初始目录',['Title']='标题',
  ['DefaultExt']='默认扩展名',['FileEditStyle']='文件编辑样式',
  ['OfOptions']='选项',['OwnerDraw']='自绘',
  ['RaggedRight']='右对齐参差',['ScrollOpposite']='反向滚动',
  ['PageControl']='页面控件',['TabVisible']='标签可见',
  ['OnTimer']='定时事件',['OnScroll']='滚动事件',
  ['OnAddition']='添加事件',['onHScroll']='水平滚动事件',
  ['onVScroll']='垂直滚动事件',
  ['OnModified']='修改事件',
  ['OnSettingsChanged']='设置改变事件',
  ['luaroutine']='Lua方法',['displayname']='显示名称',
  ['HeaderOptions']='标题选项',
}

local PROP_NAME_NATIVE = {}
for source, translated in pairs(PROP_NAME) do
  PROP_NAME_NATIVE[source] = translated
end

local PROP_NAME_SUPPLEMENT = {
  -- 常用 LCL 布局、窗体和枚举/集合项
  ['Active']='活动',['active']='活动',['align']='对齐',
  ['Control']='控件',
  ['Bottom']='底部',['Right']='右侧',['left']='左侧',['top']='顶部',
  ['AntialiasingMode']='抗锯齿模式',['AutoUseSingleIdent']='自动使用单一标识',
  ['BitmapAdv']='高级位图',['Brush']='画刷',['Button']='按钮',
  ['Canvas']='画布',['Count']='数量',['currentFrame']='当前帧',
  ['CustomDrawn']='自定义绘制',['onLastFrame']='最后一帧事件',
  ['onmousedown']='鼠标按下事件',['RoundingX']='X 圆角',
  ['RoundingY']='Y 圆角',['SelEnd']='选择结束',
  ['ShowSelRange']='显示选择范围',
  ['CaseSensitive']='区分大小写',['Charset']='字符集',
  ['Connected']='已连接',['Data']='数据',['Database']='数据库',
  ['DigitCount']='数字位数',['Down']='按下',['DragReorder']='拖拽重排',
  ['Editor']='编辑器',['EndOfTokenChr']='词元结束字符',
  ['ExecCommandID']='执行命令 ID',['FieldDefs']='字段定义',
  ['Grouped']='分组',['KeepConnection']='保持连接',
  ['LoginPrompt']='登录提示',['Option']='选项',['Params']='参数',
  ['ResizeAnchor']='调整大小锚点',['Shift']='Shift 状态',
  ['ShiftMask']='Shift 掩码',['Side']='侧边',['Strings']='字符串',
  ['TabIndex']='标签索引',['Tabs']='标签',['Transaction']='事务',
  ['MinWidth']='最小宽度',['MinHeight']='最小高度',
  ['MaxWidth']='最大宽度',['MaxHeight']='最大高度',
  ['DesignLeft']='设计左边距',['DesignTop']='设计上边距',
  ['DefaultItemHeight']='默认项目高度',['DefaultText']='默认文本',
  ['TextHeight']='文本高度',['TextHint']='文本提示',
  ['DisplayName']='显示名称',['DisplaySettings']='显示设置',
  ['DropDownRows']='下拉行数',
  ['DropDownDescription']='下拉描述',
  ['DropDownDescriptionOnly']='仅显示下拉描述',
  ['DropDownLinkedMemrec']='关联下拉内存记录',
  ['KeepBorderDistance']='保持边框距离',
  ['KeepBorderDistancePercent']='保持边框距离百分比',
  ['ScrollExtraColumns']='额外滚动列数',
  ['ScrollExtraPercent']='额外滚动百分比',
  ['ScrollExtraMax']='最大额外滚动量',
  ['DefaultValueFont']='默认值字体',['NameFont']='名称字体',
  ['ValueFont']='值字体',['PreferredSplitterX']='首选分隔位置',
  ['RowSpacing']='行间距',['ShowGutter']='显示边栏',
  ['AllowSkipGutterSeparatorDraw']='允许跳过边栏分隔线绘制',
  ['DrawHorzGridLines']='绘制水平网格线',
  ['HideClassNames']='隐藏类名',['PropNameFilter']='属性名过滤器',
  ['TIObject']='类型信息对象',['AutoFreeHook']='自动释放 Hook',
  ['SaveOnChangeTIObject']='类型信息对象改变时保存',
  ['FocusControl']='焦点控件',
  ['CheckState']='勾选状态',['CheckType']='勾选类型',
  ['CustomDraw']='自定义绘制',
  ['EndX']='结束 X',
  ['LineColor']='线条颜色',['LineThickness']='线条粗细',
  ['MarkupInfoCodeFoldingTree']='代码折叠树标记信息',
  ['MarkupInfoModifiedLine']='修改行标记信息',
  ['PopupAlignment']='弹出对齐',
  ['BalloonFlags']='气泡提示标志',['BalloonHint']='气泡提示',
  ['BalloonTimeout']='气泡提示超时',['BalloonTitle']='气泡提示标题',
  ['SelectionMode']='选择模式',
  ['DefaultSelectionMode']='默认选择模式',
  ['CaptureExceptions']='捕获异常',
  ['ExceptionDialog']='异常对话框',
  ['ElevationRequired']='需要提升权限',
  ['ExplicitLeft']='显式左边距',
  ['ExplicitTop']='显式上边距',
  ['HintColor']='提示颜色',['HintHidePause']='提示隐藏延迟',
  ['HintPause']='提示延迟',['HintShortCuts']='提示快捷键',
  ['HintShortPause']='短提示延迟',
  ['ImeName']='输入法名称',
  ['OEMConvert']='OEM 转换',
  ['ShowButtonGlyphs']='显示按钮图标',
  ['ShowMenuGlyphs']='显示菜单图标',
  ['ShowMainForm']='显示主窗体',
  ['ShowCaption']='显示标题',['ShowCaptions']='显示标题',
  ['ShowSizeDrag']='显示尺寸拖拽',['RightClickSelect']='右键选择',
  ['ShowChanges']='显示更改',
  ['ShowCodeFolding']='显示代码折叠',
  ['ShowLineNumbers']='显示行号',
  ['StartX']='起始 X',
  ['TabFont']='标签字体',
  ['ParentBidiMode']='继承父双向模式',['BidiMode']='双向显示模式',
  ['AllowAllUp']='允许全部弹起',['ShowAccelChar']='显示快捷字符',
  ['ShowPrefix']='显示前缀',['IntegralHeight']='整数高度',
  ['UseFormActivate']='使用窗体激活',
  ['UseOnChange']='使用 OnChange',
  ['WidthType']='宽度类型',
  ['invalidColor']='无效地址颜色',['validColor']='有效地址颜色',
  ['AutoSelect']='自动选择',['AutoComplete']='自动完成',
  ['AutoCompleteText']='自动完成文本',['AutoDropDown']='自动下拉',
  ['AutoCompleteList']='自动完成列表',

  -- Lazarus 4.6 LCL 属性（CE 7.5 基础集未覆盖）
  ['AccessibleName']='可访问名称',['AlignButton']='对齐按钮',
  ['AlwaysVisible']='始终可见',['Arrangement']='排列方式',
  ['ArrowKeys']='方向键',['AsFloat']='浮点值',['AsInteger']='整数值',
  ['Associate']='关联控件',['AutoArrange']='自动排列',
  ['AutoEdit']='自动编辑',['AutoEnabled']='自动启用',
  ['BandMaximize']='带区最大化',['BkColor']='背景颜色',
  ['BlendColor']='混合颜色',['BottomSpace']='底部空间',
  ['ButtonCaption']='按钮标题',['ButtonColorAutoSize']='按钮颜色自动大小',
  ['ButtonColorSize']='按钮颜色大小',['ButtonHint']='按钮提示',
  ['ButtonOrder']='按钮顺序',['ShowGlyphs']='显示图标',
  ['OKCaption']='确定按钮标题',['CancelCaption']='取消按钮标题',
  ['ButtonOnlyWhenFocused']='仅焦点时显示按钮',
  ['CalculatorLayout']='计算器布局',
  ['BeepOnError']='错误时蜂鸣',['Precision']='精度',
  ['DialogScale']='对话框缩放',
  ['ColorBtnDigits']='数字按钮颜色',
  ['ColorBtnMemory']='存储按钮颜色',
  ['ColorBtnOk']='确定按钮颜色',
  ['ColorBtnCancel']='取消按钮颜色',
  ['ColorBtnClear']='清除按钮颜色',
  ['ColorBtnOthers']='其它按钮颜色',
  ['ColorDisplayText']='显示文本颜色',
  ['ColorDisplayBack']='显示背景颜色',
  ['CaptionAlignment']='标题对齐',['CaptionText']='标题文本',
  ['CellHintPriority']='单元格提示优先级',
  ['ColRowDraggingCursor']='列行拖动光标',
  ['CommandLinkHint']='命令链接提示',['CommonButtons']='常用按钮',
  ['CustomFooterIcon']='自定义页脚图标',
  ['CustomMainIcon']='自定义主图标',
  ['DateOrder']='日期顺序',['DateTime']='日期时间',
  ['DecimalPlaces']='小数位数',['DefaultNow']='默认当前时间',
  ['DefaultToday']='默认今天',['DialogKind']='对话框类型',
  ['DialogLeft']='对话框左边距',
  ['DialogOptionsEx']='扩展对话框选项',
  ['DialogPosition']='对话框位置',['DialogTitle']='对话框标题',
  ['DialogTop']='对话框上边距',['DirectInput']='直接输入',
  ['DisableIfNoHandler']='无处理程序时禁用',
  ['DropDownWidth']='下拉宽度',['EdgeBorders']='边缘边框',
  ['EdgeInner']='内边缘',['EdgeOuter']='外边缘',
  ['EditMask']='编辑掩码',['EditorEnabled']='编辑器启用',
  ['EditStyle']='编辑样式',['Expanded']='已展开',
  ['ArrowColor']='箭头颜色',
  ['ArrowType']='箭头类型',
  ['ArrowPointerAngle']='箭头尖角',
  ['ShadowColor']='阴影颜色',
  ['ShadowType']='阴影类型',
  ['ExportMode']='导出模式',
  ['FadeUnfocusedSelection']='淡化失焦选择',
  ['FixedAreaConstraints']='固定区域约束',
  ['FixedBackground']='固定背景',['FixedColor']='固定颜色',
  ['FixedOrder']='固定顺序',['FixedSize']='固定大小',
  ['Flags']='标志',['FocusColor']='焦点颜色',
  ['FocusOnButtonClick']='点击按钮时聚焦',
  ['FooterIcon']='页脚图标',['FooterText']='页脚文本',
  ['GrabStyle']='抓取样式',['GrabWidth']='抓取宽度',
  ['GridLineStyle']='网格线样式',
  ['HorizontalIncrement']='水平增量',['HorizontalOnly']='仅水平',
  ['HotImages']='热点图标',['HotTrackColor']='热点跟踪颜色',
  ['ImageIndexSortAsc']='升序排序图标索引',
  ['ImageIndexSortDesc']='降序排序图标索引',
  ['ImageLayout']='图像布局',['ImageType']='图像类型',
  ['Indeterminate']='不确定',['KeyDesc']='键描述',
  ['KeyOptions']='键选项',['LargeChange']='大步进',
  ['List']='列表',['MainIcon']='主图标',['Marked']='已标记',
  ['MarqueeSpeed']='跑马灯速度',['Masked']='掩码',
  ['MaxSize']='最大大小',
  ['OnAcceptDate']='接受日期事件',
  ['OnAcceptDirectory']='接受目录事件',
  ['OnAcceptFileName']='接受文件名事件',
  ['OnAcceptTime']='接受时间事件',
  ['OnAcceptValue']='接受值事件',
  ['OnCanOffset']='允许偏移事件',
  ['OnCellProcess']='单元格处理事件',
  ['OnCheckboxToggled']='复选框切换事件',
  ['OnChecking']='正在勾选事件',
  ['OnColorChanged']='颜色改变事件',
  ['OnColRowMoved']='列行移动事件',
  ['OnColumnWidthDblClickResize']='列宽双击调整事件',
  ['OnCreateDragManager']='创建拖动管理器事件',
  ['OnCreateItemClass']='创建项目类事件',
  ['OnCustomDate']='自定义日期事件',
  ['OnCustomDrawArrow']='自定义绘制箭头事件',
  ['OnCustomTime']='自定义时间事件',
  ['OnDataFind']='数据查找事件',
  ['OnDataStateChange']='数据状态改变事件',
  ['OnDateRangeCheck']='日期范围检查事件',
  ['OnDragAllowed']='允许拖动事件',
  ['OnDrawNode']='绘制节点事件',
  ['OnEndOperation']='操作结束事件',
  ['OnFilterItemEx']='扩展过滤项目事件',
  ['OnGetHintKind']='获取提示类型事件',
  ['OnGetHintSize']='获取提示大小事件',
  ['OnGetNodeWidth']='获取节点宽度事件',
  ['OnGetPickList']='获取选项列表事件',
  ['OnHotChange']='热点改变事件',
  ['OnInitNode']='初始化节点事件',['OnInsert']='插入事件',
  ['OnItemEnter']='项目进入事件',['OnLoadTree']='加载树事件',
  ['OnNewText']='新文本事件',['OnNodeChanged']='节点改变事件',
  ['OnNodeClick']='节点点击事件',['OnNodeCopied']='节点已复制事件',
  ['OnNodeMoved']='节点已移动事件',
  ['OnNodeMoving']='节点移动中事件',
  ['OnPickListSelect']='选项列表选择事件',
  ['OnRemoveFromSelection']='从选择中移除事件',
  ['OnResetNode']='重置节点事件',
  ['OnSectionDrag']='分段拖动事件',
  ['OnSectionEndDrag']='分段拖动结束事件',
  ['OnSelectEditor']='选择编辑器事件',
  ['OnSetCheckboxState']='设置复选框状态事件',
  ['OnStartOperation']='操作开始事件',
  ['OnStringsChange']='字符串改变事件',
  ['OnStructureChange']='结构改变事件',
  ['OnTopleftChanged']='左上角改变事件',
  ['OnUpdate']='更新事件',['OnUpdating']='正在更新事件',
  ['Pen']='画笔',['PickList']='选项列表',['PopUpMenu']='弹出菜单',
  ['PrefixOption']='前缀选项',['QueryChoices']='查询选项',
  ['QueryItemIndex']='查询项目索引',
  ['RangeSelectMode']='范围选择模式',['ReplaceText']='替换文本',
  ['RightJustify']='右对齐',['RootDir']='根目录',
  ['RowSizingCursor']='行调整光标',['ScrollWidth']='滚动宽度',
  ['SecondaryShortCuts']='第二快捷键',
  ['SelectionFontColorUsed']='使用选择字体颜色',
  ['ShareImages']='共享图像',['ShortCut2']='快捷键2',
  ['SimpleLayout']='简单布局',['SimpleQuery']='简单查询',
  ['SimpleQueryPasswordChar']='简单查询密码字符',
  ['SizePriority']='大小优先级',['SmallChange']='小步进',
  ['SortIndicator']='排序指示器',['SplitterType']='分隔条类型',
  ['StringOptions']='字符串选项',['StyleElements']='样式元素',
  ['TabAdvance']='Tab 前进',['Themed']='使用主题',
  ['Thousands']='千位分隔',['TimeAMString']='上午字符串',
  ['TimeFormat']='时间格式',['TimePMString']='下午字符串',
  ['TimeSeparator']='时间分隔符',['TitleCaptions']='标题文字',
  ['TitleFont']='标题字体',['TitleImageList']='标题图像列表',
  ['TitleImageListWidth']='标题图像列表宽度',
  ['TitleStyle']='标题样式',['TrackButton']='跟踪按钮',
  ['UseXORFeatures']='使用 XOR 特性',
  ['ValueChecked']='选中值',['ValueUnchecked']='未选中值',
  ['VerificationText']='验证文本',['Vertical']='垂直',
  ['VerticalAlignment']='垂直对齐',
  ['VerticalIncrement']='垂直增量',['Wordwrap']='自动换行',
  ['Wrap']='换行',['Wrapable']='可换行',['WrapText']='文本换行',

  ['AutoExpand']='自动展开',['AutoFill']='自动填充',['AutoSnap']='自动吸附',
  ['AutoDock']='自动停靠',['AutoDrag']='自动拖动',
  ['AutoOptions']='自动选项',['AutoWidthLastColumn']='末列自动宽度',
  ['AutoWrap']='自动换行',['WrapAfter']='换行策略',
  ['AutoSizeIndex']='自动大小索引',
  ['ScrolledLeft']='已水平滚动',
  ['alNone']='无对齐',['alTop']='顶部对齐',['alBottom']='底部对齐',
  ['alLeft']='左对齐',['alRight']='右对齐',['alClient']='客户区填充',
  ['alCustom']='自定义对齐',
  ['bsNone']='无边框',['bsSingle']='单线边框',['bsDialog']='对话框边框',
  ['bsSizeable']='可调整边框',['bsToolWindow']='工具窗口边框',
  ['bsSizeToolWin']='可调整工具窗口边框',
  ['bvNone']='无斜面',['bvLowered']='凹陷',['bvRaised']='凸起',['bvSpace']='留空',
  ['bkNone']='无',['bkTile']='平铺',['bkSoft']='柔和',['bkFlat']='平面',
  ['beLeft']='左边缘',['beTop']='上边缘',['beRight']='右边缘',['beBottom']='下边缘',
  ['poDesigned']='设计位置',['poDefault']='默认位置',
  ['poDefaultPosOnly']='仅默认位置',['poDefaultSizeOnly']='仅默认尺寸',
  ['poScreenCenter']='屏幕居中',['poDesktopCenter']='桌面居中',
  ['poMainFormCenter']='主窗体居中',['poOwnerFormCenter']='所有者窗体居中',
  ['poWorkAreaCenter']='工作区居中',
  ['fsNormal']='普通窗体',['fsMDIChild']='MDI 子窗体',
  ['fsMDIForm']='MDI 主窗体',['fsStayOnTop']='置顶窗体',
  ['fsSystemStayOnTop']='系统置顶窗体',
  ['wsNormal']='普通窗口',['wsMinimized']='最小化窗口',
  ['wsMaximized']='最大化窗口',['wsFullScreen']='全屏窗口',
  ['bdLeftToRight']='从左到右',['bdRightToLeft']='从右到左',
  ['bdRightToLeftNoAlign']='从右到左不对齐',
  ['bdRightToLeftReadingOnly']='仅从右到左阅读',
  ['pmNone']='无弹出模式',['pmAuto']='自动弹出模式',['pmExplicit']='显式弹出模式',
  ['dmManual']='手动拖拽',['dmAutomatic']='自动拖拽',
  ['dkDrag']='拖拽',['dkDock']='停靠',
  ['ecNormal']='正常大小写',['ecUpperCase']='大写',['ecLowerCase']='小写',
  ['ssNone']='无滚动条',['ssHorizontal']='水平滚动条',
  ['ssVertical']='垂直滚动条',['ssBoth']='双向滚动条',
  ['ssAutoHorizontal']='自动水平滚动条',['ssAutoVertical']='自动垂直滚动条',
  ['ssAutoBoth']='自动双向滚动条',
  ['trHorizontal']='水平',['trVertical']='垂直',
  ['rsNone']='无',['rsLine']='线条',
  ['rsUpdate']='实时更新',['rsPattern']='图案',
  ['tpTop']='顶部标签',['tpBottom']='底部标签',
  ['tpLeft']='左侧标签',['tpRight']='右侧标签',
  ['taLeftJustify']='左对齐',['taRightJustify']='右对齐',['taCenter']='居中',
  ['tlTop']='顶部',['tlCenter']='居中',['tlBottom']='底部',
  ['blGlyphLeft']='图标在左',['blGlyphRight']='图标在右',
  ['blGlyphTop']='图标在上',['blGlyphBottom']='图标在下',
  ['tmBottomRight']='右下刻度',['tmTopLeft']='左上刻度',['tmBoth']='两侧刻度',
  ['tsNone']='无刻度',['tsAuto']='自动刻度',['tsManual']='手动刻度',
  ['tsTabs']='标签页',['tsButtons']='按钮页',['tsFlatButtons']='扁平按钮页',
  ['asrTop']='顶部锚定',['asrCenter']='居中锚定',['asrBottom']='底部锚定',
  ['crDefault']='默认光标',['crNone']='无光标',['crArrow']='箭头光标',
  ['crCross']='十字光标',['crIBeam']='文本光标',['crSize']='调整大小光标',
  ['crSizeNESW']='东北西南调整光标',['crSizeNS']='上下调整光标',
  ['crSizeNWSE']='西北东南调整光标',['crSizeWE']='左右调整光标',
  ['crUpArrow']='上箭头光标',['crHourGlass']='等待光标',
  ['crDrag']='拖拽光标',['crNoDrop']='禁止放下光标',
  ['crHSplit']='水平分割光标',['crVSplit']='垂直分割光标',
  ['crMultiDrag']='多重拖拽光标',['crSQLWait']='SQL 等待光标',
  ['crNo']='禁止光标',['crAppStart']='应用启动光标',
  ['crHelp']='帮助光标',['crHandPoint']='手形光标',

  -- 子控件布局、约束和吸附
  ['Enlarge']='扩展方式',['Shrink']='收缩方式',
  ['crsHomogenousChildResize']='均匀调整子控件',
  ['crsHomogenousSpaceResize']='均匀调整间距',
  ['crsScaleChilds']='缩放子控件',['crsSameSize']='保持相同大小',
  ['Layout']='布局',['ColCount']='列数',['RowCount']='行数',
  ['AutoFill']='自动填充',['OptimalFill']='最佳填充',
  ['LeftRightSpacing']='左右间距',['TopBottomSpacing']='上下间距',
  ['HorizontalSpacing']='水平间距',['VerticalSpacing']='垂直间距',
  ['ShowHidden']='显示隐藏项',['ShowAlwaysCheckable']='始终显示可勾选项',

  -- ListView、TreeView、Header、网格和集合属性
  ['Checkboxes']='复选框',['GridLines']='网格线',
  ['ColumnClick']='列点击排序',['ColumnLayout']='列布局',
  ['ExtendedSelect']='扩展选择',['HideSelection']='隐藏选择',
  ['HotTrack']='热跟踪',['HoverTime']='悬停时间',
  ['Allowed']='允许项',
  ['MultiSelectStyle']='多选样式',['MultiSelected']='多选项',
  ['OwnerData']='所有者数据',['Parent']='父级',
  ['ReadOnly']='只读',['RightClickSelect']='右键选择',
  ['RowSelect']='行选择',['Selected']='已选择',['Selection']='选择',
  ['StateIndex']='状态索引',['SubItems']='子项',
  ['SortType']='排序类型',
  ['SortDirection']='排序方向',['ViewStyle']='视图样式',
  ['ToolTips']='工具提示',['TopIndex']='顶部索引',
  ['ShowColumnHeaders']='显示列标题',['ShowHotkeys']='显示热键',
  ['ShowHotkey']='显示热键',['ClickOnSelChange']='选择改变时点击',
  ['DataSource']='数据源',['Dataset']='数据集',['DataSet']='数据集',
  ['FieldName']='字段名',['FixedRowsExtra']='额外固定行',
  ['GridStatus']='网格状态',['Datalink']='数据链接',
  ['OptionsExtra']='额外选项',['FixedHotColor']='固定区热点颜色',
  ['Scrollbars']='滚动条',['ShowColumnHeader']='显示列标题',
  ['AutoRedraw']='自动重绘',['CopyMode']='复制模式',
  ['Cosmetic']='装饰性画笔',['DrawStyle']='绘制风格',
  ['JoinStyle']='连接样式',['Mode']='模式',['Region']='区域',
  ['KeyboardInputBehavior']='键盘输入行为',
  ['OnCellClick']='单元格点击事件',
  ['OnChangeByUser']='用户更改事件',
  ['OnColEnter']='进入列事件',['OnColExit']='离开列事件',
  ['OnColumnMoved']='列移动事件',['OnColumnSized']='列调整大小事件',
  ['OnDrawColumnCell']='绘制列单元格事件',
  ['OnDrawColumnTitle']='绘制列标题事件',
  ['OnFieldEditMask']='字段编辑掩码事件',
  ['OnTitleClick']='标题点击事件',
  ['OnUserAddedPage']='用户添加页面事件',
  ['OnUserCheckboxState']='用户复选状态事件',
  ['ClickCount']='点击次数',['ClickDir']='点击方向',
  ['Panels']='面板',['Sections']='分段',['SimplePanel']='简单面板',
  ['AutoHint']='自动提示',['PanelClass']='面板类',
  ['SizeGrip']='尺寸手柄',
  ['Header']='标题栏',['HeaderOptions']='标题栏选项',
  ['HeaderColor']='标题颜色',
  ['ImagesWidth']='图标宽度',['ImageWidth']='图标宽度',
  ['LargeImagesWidth']='大图标宽度',['SmallImagesWidth']='小图标宽度',
  ['StateImagesWidth']='状态图标宽度',['SubMenuImagesWidth']='子菜单图标宽度',
  ['ImageMargins']='图像边距',
  ['Indent']='缩进',['ButtonHeight']='按钮高度',['ButtonWidth']='按钮宽度',
  ['TreeOptions']='树选项',['BookmarkImages']='书签图标',
  ['BookMarkOptions']='书签选项',['RightGutter']='右侧边栏',
  ['AutoExpandDelay']='自动展开延迟',
  ['AutoScrollDelay']='自动滚动延迟',
  ['AutoScrollInterval']='自动滚动间隔',
  ['AutoFillColumns']='自动填充列',
  ['AutoSizeColumns']='自动调整列宽',
  ['AutoSortIndicator']='自动排序指示器',
  ['ButtonFillMode']='按钮填充模式',['ButtonStyle']='按钮样式',
  ['CheckImageKind']='勾选图像类型',
  ['CheckBox']='复选框',
  ['DefaultNodeHeight']='默认节点高度',
  ['DefaultPasteMode']='默认粘贴模式',
  ['DefaultColumnSelectMode']='默认列选择模式',
  ['DefaultSortDirection']='默认排序方向',
  ['DragHeight']='拖动高度',['DragImageKind']='拖动图像类型',
  ['DragOperations']='拖动操作',['DragType']='拖动类型',
  ['DragWidth']='拖动宽度',['EditDelay']='编辑延迟',
  ['LineMode']='连线模式',['LineStyle']='连线样式',
  ['AnimationDuration']='动画时长',['AnimationOptions']='动画选项',
  ['ChangeDelay']='改变延迟',
  ['BackgroundOffsetX']='背景 X 偏移',
  ['BackgroundOffsetY']='背景 Y 偏移',
  ['ClipboardFormats']='剪贴板格式',
  ['Colors']='颜色集',['CustomCheckImages']='自定义勾选图标',
  ['CustomCheckImagesWidth']='自定义勾选图标宽度',
  ['DefaultHeight']='默认高度',
  ['DisplayOptions']='显示选项',
  ['DrawSelectionMode']='选择绘制模式',
  ['FilterOptions']='过滤选项',
  ['HintAnimation']='提示动画',['HintMode']='提示模式',
  ['HotCursor']='热点光标',['IncrementalSearch']='增量搜索',
  ['MainColumn']='主列',['NodeAlignment']='节点对齐',
  ['NodeDataSize']='节点数据大小',['NodeHeight']='节点高度',
  ['PaintOptions']='绘制选项',
  ['ScrollBarOptions']='滚动条选项',
  ['SelectionCurveRadius']='选择框圆角半径',
  ['TreeLinePenStyle']='树线画笔样式',
  ['TextMargin']='文本边距',['WantTabs']='接受 Tab',
  ['AlternateColor']='交替颜色',
  ['BackgroundColor']='背景颜色',
  ['DisabledColor']='禁用颜色',['DropMarkColor']='拖放标记颜色',
  ['DropTargetColor']='拖放目标颜色',
  ['DropTargetBorderColor']='拖放目标边框颜色',
  ['DisabledFontColor']='禁用字体颜色',
  ['FocusedSelectionColor']='焦点选择颜色',
  ['FocusedSelectionBorderColor']='焦点选择边框颜色',
  ['GradientDirection']='渐变方向',
  ['GradientStartColor']='渐变起始颜色',
  ['GradientEndColor']='渐变结束颜色',
  ['HeaderHotColor']='表头热点颜色',['HotColor']='热点颜色',
  ['HorizontalLineColor']='水平线颜色',
  ['IncrementColor']='增量颜色',
  ['IncrementalSearchStart']='增量搜索起始',
  ['IncrementalSearchTimeout']='增量搜索超时',
  ['SelectionRectangleBlendColor']='选择矩形混合颜色',
  ['SelectionRectangleBorderColor']='选择矩形边框颜色',
  ['SelectionBlendFactor']='选择混合系数',
  ['SelectionTextColor']='选择文本颜色',
  ['RootNodeCount']='根节点数量',
  ['RowSize']='行大小',['RowSnap']='行吸附',
  ['TextSpace']='文本间距',['TextType']='文本类型',
  ['UnfocusedColor']='失焦颜色',
  ['UnfocusedSelectionColor']='失焦选择颜色',
  ['UnfocusedSelectionBorderColor']='失焦选择边框颜色',
  ['goFixedVertLine']='固定垂直线',['goFixedHorzLine']='固定水平线',
  ['goVertLine']='垂直线',['goHorzLine']='水平线',
  ['goRangeSelect']='范围选择',['goDrawFocusSelected']='焦点选中绘制',
  ['goRowSizing']='行高调整',['goColSizing']='列宽调整',
  ['goRowMoving']='行移动',['goColMoving']='列移动',
  ['goEditing']='可编辑',['goTabs']='Tab 导航',
  ['goAlwaysShowEditor']='始终显示编辑器',
  ['goThumbTracking']='滑块跟踪',['goSmoothScroll']='平滑滚动',
  ['tvoAutoItemHeight']='自动项目高度',
  ['tvoKeepCollapsedNodes']='保留折叠节点',
  ['tvoReadOnly']='只读树',['tvoRightClickSelect']='右键选择',
  ['tvoShowButtons']='显示按钮',['tvoShowLines']='显示连线',
  ['tvoShowRoot']='显示根节点',['tvoThemedDraw']='主题绘制',
  ['tvoToolTips']='工具提示',['tvoRowSelect']='行选择',
  ['tvoHideSelection']='隐藏选择',['tvoAllowMultiselect']='允许多选',

  -- 对话框和文件选项
  ['Dialogs']='对话框',['DialogOptions']='对话框选项',
  ['CustomColors']='自定义颜色',
  ['Buttons']='按钮集合',['DefaultButton']='默认按钮',
  ['DefaultFilter']='默认过滤器',['Directory']='目录',
  ['FindText']='查找文本',['HideDirectories']='隐藏目录',
  ['OptionsEx']='扩展选项',['PreviewText']='预览文本',
  ['RadioButtons']='单选按钮集合',
  ['ToggleReplaceWhole']='切换整词替换',
  ['ofReadOnly']='只读',['ofOverwritePrompt']='覆盖提示',
  ['ofHideReadOnly']='隐藏只读',['ofNoChangeDir']='不改变目录',
  ['ofShowHelp']='显示帮助',['ofNoValidate']='不验证',
  ['ofAllowMultiSelect']='允许多选',['ofExtensionDifferent']='扩展名不同',
  ['ofPathMustExist']='路径必须存在',['ofFileMustExist']='文件必须存在',
  ['ofCreatePrompt']='创建提示',['ofShareAware']='共享感知',
  ['ofNoReadOnlyReturn']='不返回只读',['ofNoTestFileCreate']='不测试文件创建',
  ['ofNoNetworkButton']='无网络按钮',['ofNoLongNames']='禁用长文件名',
  ['ofOldStyleDialog']='旧式对话框',['ofNoDereferenceLinks']='不解析链接',
  ['ofNoResolveLinks']='不解析链接',
  ['ofEnableIncludeNotify']='启用包含通知',
  ['ofEnableSizing']='允许调整大小',['ofDontAddToRecent']='不加入最近文件',
  ['ofForceShowHidden']='强制显示隐藏文件',
  ['ofViewDetail']='详细视图',['ofAutoPreview']='自动预览',
  ['ofAllNonStorageItems']='允许所有非存储项',
  ['ofAllowsFilePackagesContents']='允许文件包内容',
  ['ofForceFileSystem']='强制文件系统',
  ['ofHidePinnedPlaces']='隐藏固定位置',
  ['ofOkButtonNeedsInteraction']='确定按钮需交互',
  ['ofPickFolders']='选择文件夹',
  ['ofShowsFilePackagesSwitch']='显示文件包切换',
  ['ofShowsFilePackageSwitch']='显示文件包切换',
  ['ofStrictFileTypes']='严格文件类型',
  ['ofUseAlternativeTitle']='使用替代标题',
  ['ofUseXPStyleAsFallBack']='使用 XP 样式兜底',
  ['ofUseXPStyleAsFallback']='使用 XP 样式兜底',
  ['Menus']='菜单集合',['MaxValue']='最大值',['MinValue']='最小值',

  -- SynEdit 和语法高亮属性/选项
  ['Beautifier']='美化器',['BlockIndent']='块缩进',
  ['Gutter']='边栏',['Highlighter']='高亮器',
  ['Keystrokes']='按键映射',['Macros']='宏',
  ['KeyStrokes']='按键映射',
  ['MarkupInfo']='标记信息',['MouseActions']='鼠标动作',
  ['MouseActionsCollapsed']='折叠区鼠标动作',
  ['MouseActionsExpanded']='展开区鼠标动作',
  ['MouseActionsForMarks']='标记鼠标动作',
  ['MouseSelActions']='选择鼠标动作',
  ['MouseTextActions']='文本鼠标动作',
  ['MouseLinkColor']='鼠标链接颜色',
  ['MoveCaret']='移动光标',['MiscOptions']='杂项选项',
  ['OffTextCursor']='文本外光标',
  ['SelectionOptions']='选择选项',['VisibleSpecialChars']='显示特殊字符',
  ['AutoCompleteOptions']='自动完成选项',
  ['ButtonUpRestrictions']='按钮弹起限制',
  ['CodeTemplSource']='代码模板源',
  ['DefaultMode']='默认模式',['DefaultPopupMenu']='默认弹出菜单',
  ['DrawBookmarksFirst']='优先绘制书签',
  ['EnableKeys']='启用按键',
  ['EnableWithColumnSelection']='列选择时启用',
  ['FullWidth']='全宽',
  ['GlyphsVisible']='图标可见',['GutterGlyph']='边栏图标',
  ['IgnoreUpClick']='忽略弹起点击',
  ['IndentToTokenStart']='缩进到词元起点',
  ['IndentType']='缩进类型',
  ['ItemsEx']='扩展项目',
  ['KeystrokesOffCell']='单元格外按键',
  ['KeystrokesSelecting']='选择时按键',
  ['LeftMargin']='左边距',['LeftOffset']='左偏移',
  ['LineOffset']='行偏移',['LineOnRight']='行在右侧',
  ['MarkHeight']='标记高度',
  ['MatchCase']='区分大小写',
  ['MatchWordBounds']='匹配单词边界',
  ['Modes']='模式',
  ['Parts']='部件',
  ['PlaybackShortCut']='播放快捷键',
  ['RecordShortCut']='录制快捷键',
  ['ReversePopMenuOrder']='反转弹出菜单顺序',
  ['RightOffset']='右偏移',
  ['SaveMarkerPos']='保存标记位置',
  ['ScanModes']='扫描模式',
  ['SearchTerm']='搜索词',
  ['StyleEx']='扩展样式',
  ['Xoffset']='X 偏移',
  ['Option2']='选项2',
  ['CodeFoldingWidth']='代码折叠宽度',
  ['CollapseButtonCaption']='折叠按钮标题',
  ['ClSelect']='选择颜色',
  ['ControlList']='控件列表',
  ['CurrentString']='当前字符串',
  ['CurrentLineColor']='当前行颜色',
  ['CursorColor']='光标颜色',
  ['EllipsisPosition']='省略号位置',
  ['ExpandButtonCaption']='展开按钮标题',
  ['ExpandedText']='展开文本',
  ['ExtraCharSpacing']='额外字符间距',
  ['ExtraLineSpacing']='额外行距',
  ['FlowLayout']='流式布局',['FlowStyle']='流式样式',
  ['FontHeight']='字体高度',
  ['InsertCaret']='插入光标',['InsertMode']='插入模式',
  ['ItemList']='项目列表',
  ['LinesInWindow']='窗口内行数',
  ['MaxLeftChar']='最大左侧字符',['MaxUndo']='最大撤销次数',
  ['NbLinesInWindow']='窗口内行数',
  ['LongLineHintType']='长行提示类型',
  ['LongLineHintTime']='长行提示时间',
  ['MaxExtraMarksColums']='最大额外标记列数',
  ['MouseOptions']='鼠标选项',['MouseWheelOption']='鼠标滚轮选项',
  ['Options2']='选项2',['OverwriteCaret']='覆盖光标',
  ['RightEdge']='右边界',['RightEdgeColor']='右边界颜色',
  ['SearchEngine']='搜索引擎',['TabWidth']='Tab 宽度',
  ['ScrollOnEditLeftOptions']='编辑时向左滚动选项',
  ['ShowOnlyLineNumbersMultiplesOf']='仅显示指定倍数行号',
  ['LineHighlightColor']='当前行高亮颜色',
  ['DrawBorderColor']='绘制边框颜色',
  ['DrawBorderWidth']='绘制边框宽度',
  ['DoubleClickSelects']='双击选择',
  ['FoldedCodeColor']='折叠代码颜色',
  ['BracketHighlightStyle']='括号高亮样式',
  ['BracketMatchColor']='匹配括号颜色',
  ['HighlightAllColor']='全部高亮颜色',
  ['ModifiedColor']='已修改颜色',['SavedColor']='已保存颜色',
  ['SelectedColor']='选中颜色',['DefaultColorColor']='默认颜色',
  ['TextSelectedColor']='选中文本颜色',
  ['NoneColorColor']='无颜色项颜色',
  ['ColorRectWidth']='颜色矩形宽度',['ColorRectOffset']='颜色矩形偏移',
  ['ColorDialog']='颜色对话框',
  ['DefaultCaption']='默认标题',['ShowBevel']='显示斜面',
  ['FrameColor']='框架颜色',['FramePriority']='框架优先级',
  ['FrameAlpha']='边框透明度',
  ['FrameEdges']='边框边缘',['FrameStyle']='边框样式',
  ['Foreground']='前景色',['ForePriority']='前景优先级',
  ['ForeAlpha']='前景透明度',
  ['Background']='背景色',['BackPriority']='背景优先级',
  ['BackAlpha']='背景透明度',
  ['BoldPriority']='粗体优先级',['ItalicPriority']='斜体优先级',
  ['StrikeOutPriority']='删除线优先级',
  ['UnderlinePriority']='下划线优先级',
  ['MaxFontSize']='最大字体大小',['MinFontSize']='最小字体大小',
  ['ColorSaved']='已保存颜色',
  ['MarkupInfoArea']='区域标记信息',
  ['MarkupInfoCurrent']='当前标记信息',
  ['MarkupInfoCurrentFold']='当前折叠标记信息',
  ['MarkupInfoCurrentLine']='当前行标记信息',
  ['MarkupInfoSync']='同步标记信息',
  ['StringBreakAppend']='字符串断行追加',
  ['StringBreakEnabled']='启用字符串断行',
  ['StringBreakPrefix']='字符串断行前缀',
  ['StyleMask']='样式掩码',
  ['Priority']='优先级',
  ['AnsiCommentIndent']='ANSI 注释缩进',
  ['AnsiCommentMode']='ANSI 注释模式',
  ['AnsiEolMatch']='ANSI 行尾匹配',
  ['AnsiEolMode']='ANSI 行尾模式',
  ['AnsiEolPostfix']='ANSI 行尾后缀',
  ['AnsiEolSkipLongerLine']='ANSI 行尾跳过较长行',
  ['AnsiIndentFirstLineExtra']='ANSI 首行额外缩进',
  ['AnsiIndentFirstLineMax']='ANSI 首行最大缩进',
  ['AnsiIndentMode']='ANSI 缩进模式',
  ['AnsiMatch']='ANSI 匹配',
  ['AnsiMatchLine']='ANSI 匹配行',
  ['AnsiMatchMode']='ANSI 匹配模式',
  ['AnsiPrefix']='ANSI 前缀',
  ['BorCommentIndent']='Borland 注释缩进',
  ['BorCommentMode']='Borland 注释模式',
  ['BorEolMatch']='Borland 行尾匹配',
  ['BorEolMode']='Borland 行尾模式',
  ['BorEolPostfix']='Borland 行尾后缀',
  ['BorEolSkipLongerLine']='Borland 行尾跳过较长行',
  ['BorIndentFirstLineExtra']='Borland 首行额外缩进',
  ['BorIndentFirstLineMax']='Borland 首行最大缩进',
  ['BorIndentMode']='Borland 缩进模式',
  ['BorMatch']='Borland 匹配',
  ['BorMatchLine']='Borland 匹配行',
  ['BorMatchMode']='Borland 匹配模式',
  ['BorPrefix']='Borland 前缀',
  ['SlashCommentIndent']='斜杠注释缩进',
  ['SlashCommentMode']='斜杠注释模式',
  ['SlashEolMatch']='斜杠行尾匹配',
  ['SlashEolMode']='斜杠行尾模式',
  ['SlashEolPostfix']='斜杠行尾后缀',
  ['SlashEolSkipLongerLine']='斜杠行尾跳过较长行',
  ['SlashIndentFirstLineExtra']='斜杠首行额外缩进',
  ['SlashIndentFirstLineMax']='斜杠首行最大缩进',
  ['SlashIndentMode']='斜杠缩进模式',
  ['SlashMatch']='斜杠匹配',
  ['SlashMatchLine']='斜杠匹配行',
  ['SlashMatchMode']='斜杠匹配模式',
  ['SlashPrefix']='斜杠前缀',
  ['ExtendSlashCommentMode']='扩展斜杠注释模式',
  ['eoAutoIndent']='自动缩进',['eoBracketHighlight']='括号高亮',
  ['eoGroupUndo']='分组撤销',['eoScrollPastEof']='滚动超过文件结尾',
  ['eoScrollPastEol']='滚动超过行尾',['eoShowScrollHint']='显示滚动提示',
  ['eoSmartTabs']='智能 Tab',['eoTabIndent']='Tab 缩进',
  ['eoTabsToSpaces']='Tab 转空格',['eoTrimTrailingSpaces']='修剪行尾空格',
  ['eoRightMouseMovesCursor']='右键移动光标',
  ['eoKeepCaretX']='保持光标 X 坐标',['eoEnhanceHomeKey']='增强 Home 键',
  ['eoEnhanceEndKey']='增强 End 键',['emcNone']='无鼠标命令',
  ['emcContextMenu']='上下文菜单',['emcSelectWord']='选择单词',
  ['emcSelectLine']='选择行',['emcSelectPara']='选择段落',
  ['emcStartSelections']='开始选择',['emcStartColumnSelections']='开始列选择',
  ['emcStartDragMove']='开始拖拽移动',['emcPasteSelection']='粘贴选择',
  ['emcMouseLink']='鼠标链接',['emcOnMainGutterClick']='主边栏点击',
  ['emcCodeFoldContextMenu']='代码折叠菜单',
  ['emcCodeFoldCollaps']='折叠代码',['emcCodeFoldExpand']='展开代码',

  -- CE 自定义训练器/控件属性
  ['AlwaysUseBigint']='始终使用大整数',
  ['AddClass']='添加类名',['Client']='客户控件',
  ['Container']='容器',['Controller']='控制器',
  ['ControllerClass']='控制器类',['DC']='设备上下文',
  ['DCOrigin']='设备上下文原点',['DCSize']='设备上下文大小',
  ['DragRect']='拖动矩形',['DrawRules']='绘制规则',
  ['FormOrigin']='窗体原点',['FormClientOrigin']='窗体客户区原点',
  ['Form']='窗体',['Handles']='手柄集合',
  ['HandleWidth']='手柄宽度',['IsControl']='是否控件',
  ['Messenger']='消息器',['MessengerClass']='消息器类',
  ['Owner']='所有者',['Resizeable']='可调整大小',
  ['SelectedContainer']='选中容器',
  ['Selector']='选择器',['SelectorClass']='选择器类',
  ['Surface']='设计表面',['UpdateCount']='更新计数',
  ['X']='X 坐标',['Y']='Y 坐标',
  ['Activated']='已激活',['Activationcolor']='激活颜色',
  ['AllocBy']='分配方式',['ArrowKeysTraverseList']='方向键遍历列表',
  ['AutoSelected']='自动选中',['AutoSort']='自动排序',
  ['beepOnActivate']='激活时蜂鸣',['Beveled']='斜面',
  ['BorderColor']='边框颜色',['BorderSize']='边框大小',
  ['CancelButton']='取消按钮',
  ['ButtonAnimationSpeed']='按钮动画速度',['ButtonColor']='按钮颜色',
  ['ButtonDownColor']='按钮按下颜色',
  ['ButtonHighlightedColor']='按钮高亮颜色',
  ['FaceColorUp']='正常表面颜色',['FaceColorHover']='悬停表面颜色',
  ['FaceColorDown']='按下表面颜色',
  ['FaceColorDisabled']='禁用表面颜色',
  ['InactiveBorderColor']='非活动边框颜色',
  ['InactiveFontColor']='非活动字体颜色',
  ['FontColor']='字体颜色',
  ['CheatNr']='作弊项编号',['Description']='描述',['descriptionleft']='描述左边距',
  ['DeleteButton']='删除按钮',
  ['Descriptionleft']='描述左边距',['DrawBorder']='绘制边框',
  ['DrawFocusRect']='绘制焦点框',['Editleft']='编辑框左边距',
  ['editleft']='编辑框左边距',['Editvalue']='编辑值',
  ['Editwidth']='编辑框宽度',['editwidth']='编辑框宽度',
  ['FocusedSize']='焦点大小',['FocusElipseColor']='焦点椭圆颜色',
  ['FindMoreButton']='查找更多按钮',
  ['FramesPerSecond']='每秒帧数',['framelist']='帧列表',
  ['FullRepaint']='完整重绘',['GlyphShowMode']='图标显示模式',
  ['GrabButton']='抓取按钮',['HelpButton']='帮助按钮',
  ['GrowFont']='放大字体',['HasCheckbox']='带复选框',
  ['HasEditBox']='带编辑框',['Hotkey']='热键',
  ['hotkeyleft']='热键左边距',['Hotkeyleft']='热键左边距',
  ['IconOptions']='图标选项',['InnerBorder']='内边框',
  ['LeadingZeros']='前导零',['LinesInWindow']='窗口内行数',
  ['LazData']='Lazarus 数据',['Textcolor']='文本颜色',
  ['MoveDownButton']='下移按钮',['MoveUpButton']='上移按钮',
  ['OKButton']='确定按钮',
  ['TextColor']='文本颜色',['TextHintFontColor']='文本提示字体颜色',
  ['TextHintFontStyle']='文本提示字体样式',
  ['ZeroStart']='从零开始',

  -- 标准 LCL 属性（CE 自身 LFM 中不一定出现）
  ['AutoAdvance']='自动前进',['AutoDisplay']='自动显示',
  ['AutoHide']='自动隐藏',['AutoPopup']='自动弹出',
  ['Accessibility']='辅助功能',['Appearance']='外观',
  ['Behavior']='行为',['Common']='常用',
  ['Drag Drop']='拖放',['Drag']='拖动',['Drop']='放下',
  ['Files']='文件',['Help']='帮助',['Hints']='提示',
  ['Help and Hints']='帮助和提示',['Input']='输入',
  ['Legacy']='兼容项',['Linkage']='链接',
  ['Locale']='区域设置',['Localizable']='可本地化',
  ['Misc']='杂项',['Tree']='树',['View']='视图',
  ['Visual']='视觉',['Window']='窗口',
  ['BevelColor']='斜面颜色',['BevelCut']='斜面切口',
  ['BevelLine']='斜面线',['BevelSpace']='斜面间距',
  ['BevelStyle']='斜面样式',
  ['CalendarDisplaySettings']='日历显示设置',
  ['ClassName']='类名',['ColorDepth']='颜色深度',
  ['Date']='日期',['DateFormat']='日期格式',
  ['Delay']='延迟',['DisplayFormat']='显示格式',
  ['FirstDayOfWeek']='每周第一天',
  ['EditLabel']='编辑标签',['EmptyValue']='空值',
  ['Expression']='表达式',['FullDrag']='完整拖动',
  ['Handle']='句柄',['LargeImages']='大图像列表',
  ['AlignWithMargins']='随边距对齐',['Margins']='边距',
  ['HotImageIndex']='热点图像索引',
  ['ImageAlignment']='图像对齐',
  ['LineWidth']='线宽',['Mask']='掩码',
  ['MaxDate']='最大日期',['MinDate']='最小日期',
  ['NumericOnly']='仅数字',['Shape']='形状',
  ['ShowSeparators']='显示分隔符',
  ['ShowShortCut']='显示快捷键',['ShowText']='显示文本',
  ['SimpleText']='简单文本',['SmallImages']='小图像列表',
  ['TextStyle']='文本样式',['ThumbPosition']='滑块位置',
  ['VisibleColCount']='可见列数',['VisibleRowCount']='可见行数',

  -- CE 7.7 RTTI/字符串标识符
  ['AdvancedOptions']='高级选项',
  ['AbsoluteIndex']='绝对索引',
  ['Address']='地址',
  ['address']='地址',
  ['AutoAssemblerVersion']='自动汇编版本',
  ['AutoCalcFields']='自动计算字段',
  ['AutoLineReduction']='自动减少行',
  ['AutoMerge']='自动合并',
  ['AutoOrManual']='自动或手动',
  ['AutoSideDistance']='自动侧边距离',
  ['AutoStartEvent']='自动开始事件',
  ['AutoEndEvent']='自动结束事件',
  ['AutoTrustChildren']='自动信任子项',
  ['BandBorderStyle']='带区边框样式',
  ['Bands']='带区',
  ['BlockReadSize']='块读取大小',
  ['BlockTabIndent']='块 Tab 缩进',
  ['ButtonCursor']='按钮光标',
  ['ButtonTextEditor']='按钮文本编辑器',
  ['CFDividerDrawLevel']='分隔线绘制层级',
  ['CharWidth']='字符宽度',
  ['CellAlignHorizontal']='单元格水平对齐',
  ['CellAlignVertical']='单元格垂直对齐',
  ['CheckedState']='勾选状态',
  ['CloseButton']='关闭按钮',
  ['ColRowDragIndicatorColor']='列行拖动指示颜色',
  ['ColSizingCursor']='列宽调整光标',
  ['ColumnClickSorts']='列点击排序',
  ['CompatibilityMode']='兼容模式',
  ['ComponentCount']='组件数量',
  ['ConstraintHeight']='约束高度',
  ['ConstraintWidth']='约束宽度',
  ['ControlCount']='控件数量',
  ['CType']='C 类型',
  ['DataType']='数据类型',
  ['Cells']='单元格',
  ['Character']='字符',
  ['Column']='列',
  ['CommentAttri']='注释属性',
  ['DefaultDrawing']='默认绘制',
  ['DefaultExpression']='默认表达式',
  ['DefaultHex']='默认十六进制',
  ['DefaultLibraryName']='默认库名称',
  ['DesignSize']='设计尺寸',
  ['DesignTime']='设计时',
  ['Direction']='方向',
  ['DirectiveAttri']='指令属性',
  ['DisabledImageIndex']='禁用图像索引',
  ['DisabledImages']='禁用图像列表',
  ['DisplayValue']='显示值',
  ['DisplayWidth']='显示宽度',
  ['DrawingStyle']='绘制样式',
  ['DropdownMenu']='下拉菜单',
  ['DropDownReadOnly']='下拉只读',
  ['DropDownValue']='下拉值',
  ['DropPosition']='放下位置',
  ['ElementSize']='元素大小',
  ['ElementType']='元素类型',
  ['EmptyListMessage']='空列表消息',
  ['EndCap']='线端样式',
  ['ExpandSignSize']='展开符号大小',
  ['ExplicitHeight']='显式高度',
  ['ExplicitWidth']='显式宽度',
  ['FadeColor']='淡出颜色',
  ['FavoritePage']='收藏页',
  ['FieldCount']='字段数量',
  ['FieldType']='字段类型',
  ['FieldValues']='字段值',
  ['Filtered']='已过滤',
  ['FocusRectVisible']='焦点框可见',
  ['FormState']='窗体状态',
  ['GutterParts']='边栏部分',
  ['Groups']='分组',
  ['HeaderBackgroundColor']='表头背景颜色',
  ['HeaderHotZones']='表头热点区域',
  ['HeaderPushZones']='表头按下区域',
  ['headers']='表头',
  ['HiddenRadioButton']='隐藏单选按钮',
  ['ImeMode']='输入法模式',
  ['IdentifierAttri']='标识符属性',
  ['IncrementalSearchDirection']='增量搜索方向',
  ['Index']='索引',
  ['LabelCaption']='标签标题',
  ['LabelImageIndex']='标签图像索引',
  ['LargeImagesWidth']='大图像宽度',
  ['Level']='层级',
  ['LineBreak']='换行',
  ['LineBreakStyle']='换行样式',
  ['LineEnding']='行尾',
  ['LineHeight']='行高',
  ['MarkupInfoLineNumber']='行号标记信息',
  ['MaxHeightPercent']='最大高度百分比',
  ['MaxIndexesCount']='最大索引数量',
  ['MaxWidthPercent']='最大宽度百分比',
  ['memrec']='内存记录',
  ['MinHeightPercent']='最小高度百分比',
  ['MinRepeatInterval']='最小重复间隔',
  ['MinWidthPercent']='最小宽度百分比',
  ['MouseHighlightedRecord']='鼠标高亮记录',
  ['NodeChildCount']='节点子项数量',
  ['NodeIndex']='节点索引',
  ['NodeParent']='节点父级',
  ['NumericalValue']='数值',
  ['ObjectType']='对象类型',
  ['ObjectTypeIndex']='对象类型索引',
  ['OperationCanceled']='操作已取消',
  ['OverlayImageIndex']='叠加图像索引',
  ['OverlayIndex']='叠加索引',
  ['PacketSize']='数据包大小',
  ['PageIndex']='页面索引',
  ['PanelButtons']='面板按钮',
  ['ParentBitmap']='继承父位图',
  ['ParentCustomHint']='继承父自定义提示',
  ['ParentPassword']='继承父密码',
  ['PixelFormat']='像素格式',
  ['PlotPointColor']='绘图点颜色',
  ['PressedImageIndex']='按下图像索引',
  ['ProcessID']='进程 ID',
  ['Progress']='进度',
  ['PreviewPriority']='预览优先级',
  ['RecordCount']='记录数',
  ['ScrollBarStyle']='滚动条样式',
  ['ScrollOnEditRightOptions']='编辑时向右滚动选项',
  ['SelectedImageIndex']='选中图像索引',
  ['SelectedRecord']='选中记录',
  ['SelectionColor']='选区颜色',
  ['SelectionFontColor']='选区字体颜色',
  ['SeparatorColor']='分隔符颜色',
  ['SeperaterColor']='分隔符颜色',
  ['StateImagesWidth']='状态图像宽度',
  ['TryExceptAttri']='Try/Except 属性',
  ['UseSystemFont']='使用系统字体',
  ['Value']='值',

  -- CE 7.7 运行时/对象检查器属性
  ['ScrolledTop']='已滚动顶部',
  ['LoadedTableVersion']='已加载表版本',
  ['checkboxActiveSelectedColor']='激活且选中复选框颜色',
  ['CheckboxActiveColor']='激活复选框颜色',
  ['CheckboxSelectedColor']='选中复选框颜色',
  ['CheckboxColor']='复选框颜色',
  ['SelectedBackgroundColor']='选中背景色',
  ['SelectedSecondaryBackgroundColor']='选中辅助背景色',
  ['ExpandSignColor']='展开符号颜色',
  ['IncreaseArrowColor']='增加箭头颜色',
  ['DecreaseArrowColor']='减少箭头颜色',
  ['count']='数量',['code']='代码',['entries']='条目',
  ['selected']='选中',['CodeList2']='代码列表 2',
  ['path']='路径',['POFile']='PO 文件',
  ['functiontypename']='函数类型名称',
  ['CustomTypeType']='自定义类型类别',
  ['script']='脚本',['scriptUsesFloat']='脚本使用浮点',
  ['scriptUsesString']='脚本使用字符串',
  ['offset']='偏移',['offsetText']='偏移文本',
  ['unparsed']='未解析',['invalid']='无效',
  ['OnlyUpdateWithReinterpret']='仅重新解释时更新',
  ['OnlyUpdateAfterInterval']='仅间隔后更新',
  ['UpdateInterval']='更新间隔',
  ['IsGroupHeader']='是分组标题',
  ['IsAddressGroupHeader']='是地址分组标题',
  ['IsReadableAddress']='是可读地址',
  ['IsReadable']='可读',
  ['Collapsed']='已折叠',
  ['AddressString']='地址字符串',
  ['VarType']='变量类型',
  ['CustomTypeName']='自定义类型名称',
  ['DontSave']='不保存',
  ['AllowDecrease']='允许减少',
  ['AllowIncrease']='允许增加',
  ['ShowAsHex']='显示为十六进制',
  ['ShowAsSigned']='显示为有符号',
  ['DropDownLinked']='下拉列表已关联',
  ['DropDownList']='下拉列表',
  ['DisplayAsDropDownListItem']='显示为下拉项',
  ['OffsetCount']='偏移数量',
  ['Async']='异步',
  ['AsyncProcessing']='异步处理中',
  ['AsyncProcessingTime']='异步处理时间',
  ['ScriptHotKey']='脚本热键',
  ['LastAAExecutionFailed']='上次自动汇编执行失败',
  ['LastAAExecutionFailedReason']='上次自动汇编失败原因',
  ['CachedAddress']='缓存地址',
  ['HasMouseFocus']='有鼠标焦点',
  ['ActivateSoundFlag']='激活声音标志',
  ['DeactivateSoundFlag']='停用声音标志',
  ['ActivateSound']='激活声音',
  ['DeactivateSound']='停用声音',
  ['OnlyWhileDown']='仅按下时',
  ['GUIScanner']='GUI 扫描器',
  ['inverseScan']='反向扫描',
  ['floatscanWithoutExponents']='浮点扫描不使用指数',
  ['OnlyOne']='仅一个',
  ['codePage']='代码页',
  ['LuaFormula']='Lua 公式',
  ['NewLuaState']='新 Lua 状态',
  ['isUnique']='唯一',
  ['lastScanWasRegionScan']='上次扫描是区域扫描',
  ['LastScanValue']='上次扫描值',
  ['LastScanType']='上次扫描类型',
  ['ScanresultFolder']='扫描结果文件夹',
  ['BusyformIsModal']='忙碌窗体为模态',
  ['ScanOption']='扫描选项',
  ['VariableType']='变量类型',
  ['Roundingtype']='舍入类型',
  ['Scanvalue']='扫描值',
  ['Scanvalue1']='扫描值 1',
  ['Scanvalue2']='扫描值 2',
  ['Startaddress']='起始地址',
  ['Stopaddress']='结束地址',
  ['Hexadecimal']='十六进制',
  ['BinaryStringAsDecimal']='二进制字符串按十进制',
  ['Unicode']='Unicode',
  ['UTF16']='UTF-16',
  ['Casesensitive']='区分大小写',
  ['Fastscanmethod']='快速扫描方法',
  ['Fastscanparameter']='快速扫描参数',
  ['Customtype']='自定义类型',
  ['WorkingSetOnly']='仅工作集',
  ['PresentOnly']='仅当前存在',
  ['Percentage']='百分比',
  ['CompareToSavedScan']='与已保存扫描比较',
  ['SavedScanName']='已保存扫描名称',
  ['SavedScanCount']='已保存扫描数量',
  ['scanWritable']='扫描可写内存',
  ['scanExecutable']='扫描可执行内存',
  ['scanCopyOnWrite']='扫描写时复制内存',
  ['HasSelection']='有选区',
  ['SelectionStart']='选择起点',
  ['SelectionStop']='选择终点',
  ['DisplayType']='显示类型',
  ['CharEncoding']='字符编码',
  ['BytesPerSeperator']='每个分隔符的字节数',
  ['LockedRowSize']='锁定行大小',
  ['spaceBetweenLines']='行间距',
  ['seperatorColor']='分隔符颜色',
  ['cursorcolor']='光标颜色',
  ['toplinecolor']='顶线颜色',
  ['normalFontColor']='普通字体颜色',
  ['normalBackgroundColor']='普通背景色',
  ['staticFontColor']='静态字体颜色',
  ['staticBackgroundColor']='静态背景色',
  ['highlightedFontColor']='高亮字体颜色',
  ['highlightedBackgroundColor']='高亮背景色',
  ['editingFontColor']='编辑字体颜色',
  ['editingBackgroundColor']='编辑背景色',
  ['secondaryeditingFontColor']='辅助编辑字体颜色',
  ['secondaryeditingBackgroundColor']='辅助编辑背景色',
  ['breakpointFontColor']='断点字体颜色',
  ['breakpointBackgroundColor']='断点背景色',
  ['differentFontColor']='差异字体颜色',
  ['differentBackgroundColor']='差异背景色',
  ['HideFocusRect']='隐藏焦点框',
  ['SpaceAboveLines']='行上方间距',
  ['SpaceBelowLines']='行下方间距',
  ['jlThickness']='跳转线粗细',
  ['jlSpacing']='跳转线间距',
  ['ShowJumplines']='显示跳转线',
  ['ShowJumplineState']='显示跳转线状态',
  ['TopAddress']='顶部地址',
  ['SelectedAddress']='选中地址',
  ['SelectedAddress2']='选中地址 2',
  ['CurrentDisassembler']='当前反汇编器',
  ['SelectionSize']='选择大小',
  ['RelativeBase']='相对基址',
  ['UseRelativeBase']='使用相对基址',
  ['CenterOnAddressChangeOutsideView']='视图外地址改变时居中',
  ['ZOrder']='Z 顺序',
  ['Alphablend']='Alpha 混合',
  ['CenterX']='中心 X',
  ['CenterY']='中心 Y',
  ['Rotation']='旋转',
  ['FontMap']='字体映射',
  ['Texture']='纹理',
  ['DisabledZBuffer']='禁用 Z 缓冲',
  ['WireframeMode']='线框模式',
  ['MouseClip']='鼠标裁剪',
  ['Processid']='进程 ID',
  ['ScrollX']='水平滚动',
  ['MaxScrollX']='最大水平滚动',
  ['ScrollY']='垂直滚动',
  ['MaxScrollY']='最大垂直滚动',
  ['ArrowSize']='箭头大小',
  ['DrawPlotPoints']='绘制绘图点',
  ['AllowUserToCreatePlotPoints']='允许用户创建绘图点',
  ['AllowUserToMovePlotPoints']='允许用户移动绘图点',
  ['AllowUserToResizeBlocks']='允许用户调整块大小',
  ['AllowUserToMoveBlocks']='允许用户移动块',
  ['AllowUserToChangeAttachPoints']='允许用户改变附着点',
  ['ArrowStyles']='箭头样式',
  ['BlockBackground']='块背景',
  ['BackGroundColor']='背景色',
  ['BlockCount']='块数量',
  ['LinkCount']='连接数量',
  ['UseOpenGL']='使用 OpenGL',
  ['Zoom']='缩放',
  ['AutoSide']='自动侧边',
  ['ShowHeader']='显示标题栏',
  ['DragBody']='拖动主体',
  ['OriginBlock']='起始块',
  ['DestinationBlock']='目标块',
  ['PointCount']='点数量',
  ['maxx']='最大 X',
  ['maxy']='最大 Y',
  ['syntaxhighlighting']='语法高亮',
  ['aggressivealignment']='激进对齐',
  ['CR3']='CR3',
  ['Attached']='已附加',
  ['SupportsDotNet4_5']='支持 .NET 4.5',
  ['SettingsTreeView']='设置树视图',
  ['SettingsPageControl']='设置分页控件',
  ['memscan']='内存扫描',
  ['vartype']='变量类型',
  ['CustomType']='自定义类型',
  ['isHexadecimal']='是十六进制',
  ['isSigned']='是有符号',
  ['isUnicode']='是 Unicode',
  ['isCodePage']='是代码页',
  ['isUnknownInitialValue']='是未知初始值',
  ['listName']='列表名称',
  ['ScriptMode']='脚本模式',
  ['isEditing']='正在编辑',
  ['TabCount']='标签数量',
  ['status']='状态',
  ['logsize']='日志大小',
  ['selectionCount']='选择数量',
  ['delayBetweenActivate']='激活间隔延迟',
  ['state']='状态',
  ['stream']='流',
  ['doNotSave']='不保存',
  ['connected']='已连接',
  ['Timeout']='超时',
  ['valid']='有效',
  ['Result']='结果',
  ['Terminated']='已终止',
  ['Finished']='已完成',
  ['BaseAddress']='基址',
  ['Loaded']='已加载',
  ['EntryPoint']='入口点',
  ['SymbolList']='符号列表',
  ['Offset']='偏移',
  ['DisplayMethod']='显示方法',
  ['Bytesize']='字节大小',
  ['ChildStruct']='子结构',
  ['ChildStructStart']='子结构起始',
  ['index']='索引',
  ['parent']='父级',
  ['ExpandChangesAddress']='展开时改变地址',
  ['NestedStructure']='嵌套结构',
  ['currentString']='当前字符串',
  ['groupname']='分组名称',
  ['box']='框',
  ['columnCount']='列数量',
  ['columns']='列',
  ['CompareValue']='比较值',
  ['GlobalIndex']='全局索引',
  ['AddressText']='地址文本',
  ['SavedState']='已保存状态',
  ['SavedStateSize']='已保存状态大小',
  ['DefaultColor']='默认颜色',
  ['MatchColor']='匹配颜色',
  ['NoMatchColor']='不匹配颜色',
  ['AllMatchColorSame']='全部匹配且颜色相同',
  ['AllMatchColorDiff']='全部匹配但颜色不同',
  ['mainStruct']='主结构',
  ['groupcount']='分组数量',
  ['group']='分组',
  ['ExtraSymbolDataList']='额外符号数据列表',
  ['PID']='进程 ID',
  ['internalname']='内部名称',
  ['refcount']='引用计数',
  ['OpcodeAttri']='操作码属性样式',
  ['RegisterAttri']='寄存器属性样式',
  ['CharAttri']='字符属性样式',
  ['PackageSource']='包源码',
  ['MinTabWidth']='最小标签宽度',
  ['SelectedTab']='选中标签',
  ['TabText']='标签文本',
  ['Initialized']='已初始化',
  ['IsPlaying']='正在播放',
  ['Category']='分类',
  ['Dialog']='对话框',
  ['Bevel']='斜面',
  ['MenuItem']='菜单项',
  ['EnableSets']='启用集合',
  ['ProgressBar']='进度条',
  ['name']='名称',
  ['height']='高度',
  ['defaultHeight']='默认高度',
  ['Osb']='滚动条对象',
  ['PaintBox']='绘图框',
  ['OSBitmap']='系统位图',
  ['HexFont']='十六进制字体',
  ['fadeColor']='淡出颜色',
  ['BitBtn1']='位图按钮 1',
  ['value']='值',
  ['KeySecondaryAttri']='二级关键字属性样式',
  ['KeyTertiaryAttri']='三级关键字属性样式',
  ['KeyQuaternaryAttri']='四级关键字属性样式',
  ['InternalFunctionAttri']='内部函数属性样式',
  ['LuaMStringAttri']='Lua 多行字符串属性样式',
  ['Progressbar1']='进度条 1',
  ['About1']='关于 1',
  ['Help1']='帮助 1',
  ['UseThreadToFreeze']='使用线程冻结',
  ['Run1']='运行 1',
  ['Step1']='步入 1',
  ['StepOver1']='步过 1',
  ['Executetillreturn1']='执行到返回 1',
  ['RunTill1']='运行到 1',
  ['miSetAddress']='设置地址菜单项',
  ['Setbreakpoint1']='设置断点 1',
  ['Showsymbols1']='显示符号 1',
  ['Kernelmodesymbols1']='内核模式符号 1',
  ['Showmoduleaddresses1']='显示模块地址 1',
  ['Symbolhandler1']='符号处理器 1',
  ['AccessedRegisterColor']='已访问寄存器颜色',
  ['ChangedRegisterColor']='已改变寄存器颜色',
  ['TabControl1']='标签控件 1',
  ['EditWidth']='编辑宽度',
  ['EditLeft']='编辑左边距',
  ['Focused']='已聚焦',
  ['item']='项目',
  ['caption']='标题',

  -- 对象检查器常见事件
  ['OnActionExecute']='动作执行事件',
  ['OnActionUpdate']='动作更新事件',
  ['OnActivationFailure']='激活失败事件',
  ['OnAddToSelection']='加入选择事件',
  ['OnAddressChange']='地址改变事件',
  ['OnAdvancedCustomDraw']='高级自定义绘制事件',
  ['OnAdvancedCustomDrawSubItem']='子项高级自定义绘制事件',
  ['OnAdvancedHeaderDraw']='高级表头绘制事件',
  ['OnAutoAssemblerEdit']='自动汇编编辑事件',
  ['OnByteSelect']='字节选择事件',
  ['OnClose2']='关闭事件 2',
  ['OnAdvancedCustomDrawItem']='项目高级自定义绘制事件',
  ['OnAfterFilter']='筛选后事件',
  ['OnAfterAutoFitColumn']='自动适应列后事件',
  ['OnAfterAutoFitColumns']='自动适应所有列后事件',
  ['OnAfterCellPaint']='单元格绘制后事件',
  ['OnAfterColumnExport']='列导出后事件',
  ['OnAfterColumnWidthTracking']='列宽拖动后事件',
  ['OnAfterGetMaxColumnWidth']='取得最大列宽后事件',
  ['OnAfterHeaderExport']='表头导出后事件',
  ['OnAfterHeaderHeightTracking']='表头高度拖动后事件',
  ['OnAfterItemErase']='项目擦除后事件',
  ['OnAfterItemPaint']='项目绘制后事件',
  ['OnAfterNodeExport']='节点导出后事件',
  ['OnAfterPaint']='绘制后事件',
  ['OnAfterSelection']='选择后事件',
  ['OnAfterTreeExport']='树导出后事件',
  ['OnAlignInsertBefore']='对齐前插入事件',
  ['OnAlignPosition']='对齐位置事件',
  ['OnApplyClicked']='应用按钮点击事件',
  ['OnArrowClick']='箭头点击事件',
  ['OnBeforeAutoFitColumn']='自动适应列前事件',
  ['OnBeforeAutoFitColumns']='自动适应所有列前事件',
  ['OnBeforeCellPaint']='单元格绘制前事件',
  ['OnBeforeColumnExport']='列导出前事件',
  ['OnBeforeColumnWidthTracking']='列宽拖动前事件',
  ['OnBeforeCommand']='命令前事件',
  ['OnBeforeDrawTreeLine']='绘制树线前事件',
  ['OnBeforeExecute']='执行前事件',
  ['OnBeforeGetMaxColumnWidth']='取得最大列宽前事件',
  ['OnBeforeHeaderExport']='表头导出前事件',
  ['OnBeforeHeaderHeightTracking']='表头高度拖动前事件',
  ['OnBeforeItemErase']='项目擦除前事件',
  ['OnBeforeItemPaint']='项目绘制前事件',
  ['OnBeforeNodeExport']='节点导出前事件',
  ['OnBeforePaint']='绘制前事件',
  ['OnBeforeSelection']='选择前事件',
  ['OnBeforeShow']='显示前事件',
  ['OnBeforeTreeExport']='树导出前事件',
  ['OnDoubleClickHeader']='双击标题事件',
  ['OnDoubleClickBody']='双击主体事件',
  ['OnDrag']='拖动事件',
  ['OnDragStart']='拖动开始事件',
  ['OnDragEnd']='拖动结束事件',
  ['OnEditorClose']='编辑器关闭事件',
  ['OnError']='错误事件',
  ['OnGameTick']='游戏计时事件',
  ['OnGameRender']='游戏渲染事件',
  ['OnBandDrag']='带区拖动事件',
  ['OnBandInfo']='带区信息事件',
  ['OnBandMove']='带区移动事件',
  ['OnBandPaint']='带区绘制事件',
  ['OnBeginEdit']='开始编辑事件',
  ['OnButtonClick']='按钮点击事件',
  ['OnButtonClicked']='按钮点击事件',
  ['OnCanClose']='可关闭事件',['OnCancel']='取消事件',
  ['OnCalcFields']='计算字段事件',
  ['OnCalcKey']='计算器按键事件',
  ['OnCanSplitterResizeColumn']='允许调整列分隔条事件',
  ['OnCanSplitterResizeHeader']='允许调整表头分隔条事件',
  ['OnCanSplitterResizeNode']='允许调整节点分隔条事件',
  ['OnChanged']='已改变事件',
  ['OnGuiUpdate']='界面更新事件',
  ['OnRenderHeader']='渲染标题事件',
  ['OnRenderBody']='渲染主体事件',
  ['OnScanDone']='扫描完成事件',
  ['OnScanStart']='扫描开始事件',
  ['OnTabChange']='标签改变事件',
  ['OnTabCreate']='标签创建事件',
  ['OnTimeout']='超时事件',
  ['OnValueRender']='值渲染事件',
  ['WarnOnMainThreadLockObtaining']='主线程锁获取警告',
  ['ErrorOnMainThreadLockObtaining']='主线程锁获取错误',
  ['OnChangedProperty']='属性已改变事件',
  ['OnChangeUpdating']='更新改变事件',
  ['OnDescriptionChange']='描述改变事件',
  ['OnChangingEx']='正在改变扩展事件',
  ['OnChangingProperty']='属性正在改变事件',
  ['OnCharacterRender']='字符渲染事件',
  ['OnClickCheck']='勾选点击事件',
  ['OnClickLink']='链接点击事件',
  ['OnClearBookmark']='清除书签事件',
  ['OnCloseUp']='收起事件',['OnCodeCompletion']='代码补全事件',
  ['OnCloseTabClicked']='关闭标签点击事件',
  ['OnColRowDeleted']='列行删除事件',
  ['OnColRowExchanged']='列行交换事件',
  ['OnColRowInserted']='列行插入事件',
  ['OnCollapsed']='已折叠事件',['OnCollapsing']='正在折叠事件',
  ['OnColumnDblClick']='列双击事件',
  ['OnColumnChange']='列改变事件',
  ['OnColumnExport']='列导出事件',
  ['OnColumnResize']='列调整大小事件',
  ['OnColumnWidthTracking']='列宽拖动事件',
  ['OnCommandProcessed']='命令处理后事件',
  ['OnCompare']='比较事件',['OnContextPopup']='上下文弹出事件',
  ['OnCompareCells']='比较单元格事件',
  ['OnCompareNodes']='比较节点事件',
  ['OnCreateHint']='创建提示事件',
  ['OnColumnClick']='列点击事件',['OnCreateNodeClass']='创建节点类事件',
  ['OnCreateDataObject']='创建数据对象事件',
  ['OnCreateEditor']='创建编辑器事件',
  ['OnCreatePanelClass']='创建面板类事件',
  ['OnCreateSectionClass']='创建分段类事件',
  ['OnCustomCreateItem']='自定义创建项目事件',
  ['OnCustomDraw']='自定义绘制事件',
  ['OnCustomDrawItem']='项目自定义绘制事件',
  ['OnCustomDrawSubItem']='子项自定义绘制事件',
  ['OnAddItem']='添加项目事件',
  ['OnChecked']='勾选事件',
  ['OnCheckItem']='勾选项目事件',
  ['OnCreateChild']='创建子项事件',
  ['OnCutCopy']='剪切复制事件',
  ['OnData']='数据事件',['OnDeletion']='删除事件',
  ['OnDataHint']='数据提示事件',
  ['OnDayChanged']='日期改变事件',
  ['OnDesignMessage']='设计器消息事件',
  ['OnDialogConstructed']='对话框构造事件',
  ['OnDialogCreated']='对话框创建事件',
  ['OnDialogDestroyed']='对话框销毁事件',
  ['OnDisassemble']='反汇编事件',
  ['OnDisassembleOverride']='反汇编覆盖事件',
  ['OnDisassemblerViewOverride']='反汇编视图覆盖事件',
  ['OnDisplayChange']='显示改变事件',
  ['OnDragResized']='拖拽调整大小事件',
  ['OnDrawCell']='绘制单元格事件',
  ['OnDrawHint']='绘制提示事件',
  ['OnDrawPanel']='绘制面板事件',
  ['OnDrawText']='绘制文本事件',
  ['OnDrawTab']='绘制标签事件',
  ['OnEditButtonClick']='编辑按钮点击事件',
  ['OnEditError']='编辑错误事件',
  ['OnEditCancelled']='取消编辑事件',
  ['OnEdited']='已编辑事件',['OnEditing']='正在编辑事件',
  ['OnEditingEnd']='编辑结束事件',
  ['OnEndSession']='会话结束事件',
  ['OnEndEdit']='结束编辑事件',
  ['OnExecute']='执行事件',
  ['OnExecuteCompletion']='执行补全事件',
  ['OnException']='异常事件',
  ['OnExpanded']='已展开事件',['OnExpanding']='正在展开事件',
  ['OnExtraLineRender']='额外行渲染事件',
  ['OnFilterItem']='过滤项目事件',
  ['OnFilterNode']='过滤节点事件',
  ['OnFind']='查找事件',['OnFolderChange']='文件夹改变事件',
  ['OnFocusChanged']='焦点已改变事件',
  ['OnFocusChanging']='焦点正在改变事件',
  ['OnFreeNode']='释放节点事件',
  ['OnGetAddClass']='获取添加类名事件',
  ['OnGetCellHint']='获取单元格提示事件',
  ['OnGetCellIsEmpty']='获取单元格为空事件',
  ['OnGetCheckboxState']='获取复选状态事件',
  ['OnGetCursor']='获取光标事件',
  ['OnGetDisplayValue']='获取显示值事件',
  ['OnGetDockCaption']='获取停靠标题事件',
  ['OnGetEditMask']='获取编辑掩码事件',
  ['OnGetEditText']='获取编辑文本事件',
  ['OnGetHint']='获取提示事件',
  ['OnGetMainFormHandle']='获取主窗体句柄事件',
  ['OnGetHeaderCursor']='获取表头光标事件',
  ['OnGetHelpContext']='获取帮助上下文事件',
  ['OnGetItems']='获取项目事件',
  ['OnGetImageIndex']='获取图像索引事件',
  ['OnGetImageIndexEx']='获取扩展图像索引事件',
  ['OnGetImageText']='获取图像文本事件',
  ['OnGetLineStyle']='获取线条样式事件',
  ['OnGetNodeDataSize']='获取节点数据大小事件',
  ['OnGetPopupMenu']='获取弹出菜单事件',
  ['OnGetSelectedIndex']='获取选中索引事件',
  ['OnGetSubItemImage']='获取子项图像事件',
  ['OnGetText']='获取文本事件',['OnGutterClick']='边栏点击事件',
  ['OnGetUserClipboardFormats']='获取用户剪贴板格式事件',
  ['OnGetWidthForPPI']='按 PPI 获取宽度事件',
  ['OnGutterPaint']='边栏绘制事件',
  ['OnHasChildren']='存在子节点事件',
  ['OnHeaderClick']='表头点击事件',
  ['OnHeaderDblClick']='表头双击事件',
  ['OnHeaderDragged']='表头拖动完成事件',
  ['OnHeaderDraggedOut']='表头拖出事件',
  ['OnHeaderDragging']='表头拖动中事件',
  ['OnHeaderDraw']='表头绘制事件',
  ['OnHeaderDrawQueryElements']='表头绘制元素查询事件',
  ['OnHeaderHeightDblClickResize']='表头高度双击调整事件',
  ['OnHeaderHeightTracking']='表头高度拖动事件',
  ['OnHeaderMouseDown']='表头鼠标按下事件',
  ['OnHeaderMouseMove']='表头鼠标移动事件',
  ['OnHeaderMouseUp']='表头鼠标释放事件',
  ['OnAddHeaderPopupItem']='添加表头弹出菜单项事件',
  ['OnHeaderSized']='表头已调整大小事件',
  ['OnHeaderSizing']='表头正在调整大小事件',
  ['OnHelpClicked']='帮助按钮点击事件',
  ['OnHotkey']='热键事件',
  ['OnHyperlinkClicked']='超链接点击事件',
  ['OnHint']='提示事件',
  ['OnIdle']='空闲事件',
  ['OnIdleEnd']='空闲结束事件',
  ['OnIncrementalSearch']='增量搜索事件',
  ['OnInitialScanDone']='初次扫描完成事件',
  ['OnInitChildren']='初始化子节点事件',
  ['OnItemChecked']='项目勾选事件',['OnMouseLink']='鼠标链接事件',
  ['OnItemClick']='项目点击事件',
  ['OnItemExit']='项目退出事件',
  ['OnKeyAction']='按键动作事件',
  ['OnKeyCompletePrefix']='按键补全前缀事件',
  ['OnKeyDelete']='按键删除事件',
  ['OnKeyNextChar']='下一个字符按键事件',
  ['OnKeyPrevChar']='上一个字符按键事件',
  ['OnFormatLineNumber']='格式化行号事件',
  ['OnLoadNode']='加载节点事件',
  ['OnLog']='日志事件',
  ['OnMeasureTextHeight']='测量文本高度事件',
  ['OnMeasureTextWidth']='测量文本宽度事件',
  ['OnMinimize']='最小化事件',
  ['OnModalBegin']='模态开始事件',
  ['OnModalEnd']='模态结束事件',
  ['OnMonthChanged']='月份改变事件',
  ['OnMouseCursor']='鼠标光标事件',
  ['OnNodeCopying']='节点复制中事件',
  ['OnNodeDblClick']='节点双击事件',
  ['OnNodeExport']='节点导出事件',
  ['OnNodeHeightDblClickResize']='节点高度双击调整事件',
  ['OnNodeHeightTracking']='节点高度拖动事件',
  ['OnPageChanged']='页面改变事件',
  ['OnPaintBackground']='绘制背景事件',
  ['OnPaintButton']='绘制按钮事件',
  ['OnPaintItem']='绘制项目事件',
  ['OnPaintText']='绘制文本事件',
  ['OnPaintTransient']='临时绘制事件',
  ['OnPaste']='粘贴事件',
  ['OnPlaceBookmark']='放置书签事件',
  ['OnPositionChanged']='位置改变事件',
  ['OnPrepareCanvas']='准备画布事件',
  ['OnProcessCommand']='处理命令事件',
  ['OnProcessOpened']='进程打开事件',
  ['OnProcessUserCommand']='处理用户命令事件',
  ['OnPostDisassemble']='反汇编后事件',
  ['OnPostHotkey']='热键后事件',
  ['OnQuadClick']='四击事件',
  ['OnQueryEndSession']='查询会话结束事件',
  ['OnRadioButtonClicked']='单选按钮点击事件',
  ['OnRenderOLEData']='渲染 OLE 数据事件',
  ['OnGetColors']='获取颜色事件',
  ['OnMoved']='移动事件',['OnPictureChanged']='图片改变事件',
  ['OnPopup']='弹出菜单事件',['OnReplace']='替换事件',
  ['OnItemChange']='项目改变事件',
  ['OnModeChange']='模式改变事件',
  ['OnColorForMark']='标记取色事件',
  ['OnReplaceText']='替换文本事件',
  ['OnRestore']='恢复事件',
  ['OnSave']='保存事件',
  ['OnSaveTree']='保存树事件',
  ['OnSaveNode']='保存节点事件',
  ['OnScanOptionChange']='扫描选项改变事件',
  ['OnSectionClick']='分段点击事件',
  ['OnSearchPosition']='搜索位置事件',
  ['OnSelectCell']='选择单元格事件',
  ['OnSetEditText']='设置编辑文本事件',
  ['OnShapeClick']='形状点击事件',
  ['OnShortenString']='缩短字符串事件',
  ['OnShowScrollBar']='显示滚动条事件',
  ['OnSectionResize']='分段调整大小事件',
  ['OnSectionSeparatorDblClick']='分段分隔符双击事件',
  ['OnSectionTrack']='分段拖动事件',
  ['OnSelection']='选择事件',
  ['OnSelectionChanged']='选择已改变事件',
  ['OnSelectItem']='选择项目事件',
  ['OnSetText']='设置文本事件',
  ['OnShapePoints']='形状点事件',
  ['OnSpecialLineColors']='特殊行颜色事件',
  ['OnSpecialLineMarkup']='特殊行标记事件',
  ['OnStartTimer']='启动计时器事件',
  ['OnStateChange']='状态改变事件',
  ['OnStatusChange']='状态改变事件',
  ['OnStatusbarUpdate']='状态栏更新事件',
  ['OnStopTimer']='停止计时器事件',
  ['OnStringsChanging']='字符串正在改变事件',
  ['OnTabDestroy']='标签销毁事件',
  ['OnStopDock']='停止停靠事件',['OnStopDrag']='停止拖动事件',
  ['OnTopLeftChanged']='左上角改变事件',
  ['OnTokenNotFound']='未找到词元事件',
  ['OnTripleClick']='三击事件',
  ['OnTypeChange']='类型改变事件',
  ['OnUpdateData']='更新数据事件',
  ['OnUserCheckboxBitmap']='用户复选框位图事件',
  ['OnUserCheckboxImage']='用户复选框图像事件',
  ['OnUserCommand']='用户命令事件',
  ['OnUserInput']='用户输入事件',
  ['OnValidate']='验证事件',
  ['OnValidateEntry']='验证条目事件',
  ['OnValueChange']='值改变事件',
  ['OnValueChanged']='值改变事件',
  ['OnValueChangedByUser']='用户改变值事件',
  ['OnVerificationClicked']='验证按钮点击事件',
  ['OnYearChanged']='年份改变事件',

  -- 数据感知控件、存储、Shell 控件、帮助和 SynEdit 高亮器
  ['ActiveDot']='活动点',['AfterOpen']='打开后事件',
  ['AllowedShifts']='允许的 Shift 状态',
  ['AndAttri']='AND 属性样式',['AnnotationAttri']='注解属性样式',
  ['AntiAliasingMode']='抗锯齿模式',
  ['AsmAttri']='汇编属性样式',['ASPAttri']='ASP 属性样式',
  ['AttributeAttri']='属性名样式',
  ['AttributeValueAttri']='属性值样式',
  ['AutoRegister']='自动注册',
  ['AutoSizeHeightIsEditHeight']='自动高度等于编辑高度',
  ['BaseDirectory']='基础目录',['BasePathObject']='基础路径对象',
  ['BaseURL']='基础 URL',['BeforeAction']='动作前事件',
  ['BeforeExecute']='执行前事件',
  ['BraceAttri']='大括号属性样式',
  ['BracketAttri']='方括号属性样式',
  ['BrowserParams']='浏览器参数',['BrowserPath']='浏览器路径',
  ['BuddyCaption']='伙伴标题',['BuddyCursor']='伙伴光标',
  ['BuddyHint']='伙伴提示',['BuddyWidth']='伙伴宽度',
  ['BuiltInBaseURL']='内置基础 URL',
  ['CaseLabelAttri']='case 标签属性样式',
  ['CDATAAttri']='CDATA 属性样式',
  ['ChunkMarkerAttri']='块标记属性样式',
  ['ChunkMixedAttri']='混合块属性样式',
  ['ChunkNewAttri']='新增块属性样式',
  ['ChunkOldAttri']='旧块属性样式',
  ['Comments']='注释',['CommentTypes']='注释类型',
  ['CompilerMode']='编译器模式',['ConfirmDelete']='确认删除',
  ['ConstantAttri']='常量属性样式',['Constants']='常量',
  ['Context']='上下文',
  ['ControlSequenceAttri']='控制序列属性样式',
  ['CreateHTMLFragment']='创建 HTML 片段',
  ['CustomEditMask']='自定义编辑掩码',
  ['D4syntax']='Delphi 4 语法',
  ['DataField']='数据字段',
  ['DataTypeAttri']='数据类型属性样式',
  ['DefaultHighlighter']='默认高亮器',
  ['DefaultLanguageName']='默认语言名',
  ['DefaultPackageAttri']='默认包属性样式',
  ['DetectPreprocessor']='检测预处理器',
  ['DirecAttri']='指令属性样式',
  ['DisplayEmpty']='显示空值',
  ['DocStringAttri']='文档字符串属性样式',
  ['DocTypeAttri']='DOCTYPE 属性样式',
  ['DOCTYPEAttri']='DOCTYPE 属性样式',
  ['DocumentAttri']='文档属性样式',
  ['DollarVariables']='美元变量',
  ['DotAttri']='点属性样式',
  ['ElementAttri']='元素属性样式',
  ['EndExpr']='结束表达式',
  ['Entity']='实体',['EntityAttri']='实体属性样式',
  ['EntityRefAttri']='实体引用属性样式',
  ['ErrorAttri']='错误属性样式',
  ['EventAttri']='事件属性样式',
  ['ExceptionAttri']='异常属性样式',
  ['ExpandCollapseMode']='展开折叠模式',
  ['ExtendedKeywordsMode']='扩展关键字模式',
  ['FileMask']='文件掩码',['Filename']='文件名',
  ['FileSortType']='文件排序类型',['FileType']='文件类型',
  ['FloatAttri']='浮点数属性样式',
  ['FocusOnBuddyClick']='点击伙伴时聚焦',
  ['Formatted']='格式化',
  ['FunctionAttri']='函数属性样式',
  ['HexAttri']='十六进制属性样式',
  ['HTMLFontSize']='HTML 字号',['ID']='ID',
  ['IDEDirectiveAttri']='IDE 指令属性样式',
  ['IdentifierChars']='标识符字符',
  ['IniFileName']='INI 文件名',['IniSection']='INI 节',
  ['InvalidAttri']='无效内容属性样式',
  ['InvalidSymbolAttri']='无效符号属性样式',
  ['JSONFileName']='JSON 文件名',
  ['Key']='键',['KeyAttri']='关键字属性样式',
  ['KeyField']='键字段',['KeyString']='键字符串',
  ['KeywordPrefix']='关键字前缀',['KeyWords']='关键字',
  ['LineAddedAttri']='新增行属性样式',
  ['LineChangedAttri']='修改行属性样式',
  ['LineContextAttri']='上下文行属性样式',
  ['LineRemovedAttri']='删除行属性样式',
  ['ListField']='列表字段',['ListFieldIndex']='列表字段索引',
  ['ListSource']='列表数据源',['LookupCache']='查找缓存',
  ['MarkerAttri']='标记属性样式',['Markup']='标记',
  ['MaskCaseSensitivity']='掩码区分大小写',
  ['MathmodeAttri']='数学模式属性样式',
  ['MeasurementUnitAttri']='计量单位属性样式',
  ['ModifierAttri']='修饰符属性样式',
  ['NamespaceAttributeAttri']='命名空间属性名样式',
  ['NamespaceAttributeValueAttri']='命名空间属性值样式',
  ['NestedComments']='嵌套注释',
  ['NewFileAttri']='新文件属性样式',
  ['Node']='节点',['NonKeyAttri']='非关键字属性样式',
  ['NonReservedKeyAttri']='非保留关键字属性样式',
  ['NullValueKey']='空值键',
  ['NumberAttri']='数字属性样式',
  ['ObjectAttri']='对象属性样式',
  ['Objects']='对象',['ObjectTypes']='对象类型',
  ['OctalAttri']='八进制属性样式',
  ['OnAccept']='接受事件',
  ['OnCheckEndMarker']='检查结束标记事件',
  ['OnCheckStartMarker']='检查开始标记事件',
  ['OnDBImageRead']='数据图像读取事件',
  ['OnDBImageWrite']='数据图像写入事件',
  ['OnFileAdded']='文件添加事件',
  ['OnFindComponentClass']='查找组件类事件',
  ['OnReadData']='读取数据事件',
  ['OnRestoreProperties']='恢复属性事件',
  ['OnRestoringProperties']='正在恢复属性事件',
  ['OnSaveProperties']='保存属性事件',
  ['OnSavingProperties']='正在保存属性事件',
  ['OnSortCompare']='排序比较事件',
  ['OnTerminate']='终止事件',
  ['OnValidationError']='验证错误事件',
  ['OperatorAttri']='运算符属性样式',
  ['OrigFileAttri']='原文件属性样式',
  ['PasDocKeyWord']='PasDoc 关键字样式',
  ['PasDocSymbol']='PasDoc 符号样式',
  ['PasDocUnknown']='PasDoc 未知样式',
  ['PLSQLAttri']='PL/SQL 属性样式',
  ['PragmaAttri']='Pragma 属性样式',
  ['PreprocessorAttri']='预处理器属性样式',
  ['ProcedureHeaderName']='过程头名称',
  ['ProcessingInstructionAttri']='处理指令属性样式',
  ['QuickDraw']='快速绘制',
  ['ReplaceWith']='替换为',
  ['Root']='根',['RootNodePath']='根节点路径',
  ['SchemeName']='方案名称',['Schemes']='方案',
  ['ScrollListDataset']='滚动列表数据集',
  ['SearchFind']='搜索查找',['SearchFor']='搜索',
  ['SecondKeyAttri']='第二关键字属性样式',
  ['SecondKeyWords']='第二关键字',
  ['SectionAttri']='节属性样式',
  ['SelectorAttri']='选择器属性样式',
  ['ShellListView']='Shell 列表视图',
  ['ShellTreeView']='Shell 树视图',
  ['ShiftButtons']='Shift 按钮',['ShiftState']='Shift 状态',
  ['SpaceAttri']='空白属性样式',['SpaceChar']='空格字符',
  ['SplitterX']='分隔条 X 坐标',
  ['SQLDialect']='SQL 方言',
  ['SQLPlusAttri']='SQL*Plus 属性样式',
  ['StartExpr']='开始表达式',
  ['StoredValues']='已存储值',
  ['StringAttri']='字符串属性样式',
  ['StringDelim']='字符串分隔符',
  ['StringKeywordMode']='字符串关键字模式',
  ['StringMultilineMode']='多行字符串模式',
  ['SymbolAttri']='符号属性样式',
  ['SystemAttri']='系统属性样式',
  ['TableNameAttri']='表名属性样式',
  ['TableNames']='表名',['Tabstop']='Tab 停靠',
  ['TextAttri']='文本属性样式',['TextFont']='文本字体',
  ['TypeHelpers']='类型助手',
  ['UndefKeyAttri']='未定义关键字属性样式',
  ['UnknownAttri']='未知属性样式',
  ['URL']='URL',['UseBackground']='使用背景',
  ['UseDefaultApp']='使用默认应用',
  ['ValidationErrorMode']='验证错误模式',
  ['ValueAttri']='值属性样式',['Values']='值',
  ['VarAttri']='变量属性样式',
  ['VariableAttri']='变量属性样式',
  ['VisibleButtons']='可见按钮',
  ['WantBracesParsed']='解析大括号',
  ['WithSubDirectories']='包含子目录',
  ['WriteHeader']='写入表头',
}

for source, translated in pairs(PROP_NAME_SUPPLEMENT) do
  if PROP_NAME[source] == nil then
    PROP_NAME[source] = translated
  end
  if PROP_NAME_NATIVE[source] == nil then
    PROP_NAME_NATIVE[source] = PROP_NAME[source] or translated
  end
end

local GLOBAL_STATE_KEY = '__CE_ZH_FORMDESIGNER_TRANSLATE_STATE'
local GLOBAL_STATE = rawget(_G, GLOBAL_STATE_KEY)
if type(GLOBAL_STATE) ~= 'table' then
  GLOBAL_STATE = {
    installed = false,
    nativeHookInstalled = false,
    nativeHookError = nil,
    oiMenuResourcePatchInstalled = false,
    oiMenuResourcePatchError = nil,
    oiMenuResourcePatchDataPopulated = false,
    oiStaticTextHooksInstalled = false,
    oiStaticResourcePatchInstalled = false,
    defaultNativeHooksInstalled = false,
  }
  rawset(_G, GLOBAL_STATE_KEY, GLOBAL_STATE)
end
GLOBAL_STATE.oiMenuResourcePatchInstalled = GLOBAL_STATE.oiMenuResourcePatchInstalled or false
GLOBAL_STATE.oiMenuResourcePatchDataPopulated = GLOBAL_STATE.oiMenuResourcePatchDataPopulated or false

-- 共享工具函数回退
local function zhCNNativeHooksEnabled()
  if _G.zhCNEnableNativeHooks == false then return false end
  return _G.zhCNFormDesignerEnableNativeHooks ~= false
end

-- 安全调用函数，防止对象检查器汉化步骤报错中断启动。
local function safeCall(fn, ...)
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then return a, b, c, d end
  return nil
end

-- 共享工具函数回退
local checkedCall = (_G.zhCNUtil and _G.zhCNUtil.checkedCall) or function(fn, ...)
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then return true, a, b, c, d end
  return false, nil
end

-- 判断写内存类调用是否真正成功。
local function writeSucceeded(fn, ...)
  local ok, result = checkedCall(fn, ...)
  return ok and result ~= false
end

-- 去掉菜单快捷键标记和首尾空白，用于稳定匹配文本。
local function stripHotkeyAndTrim(text)
  if type(text) ~= 'string' then return '' end
  text = text:gsub('&', '')
  return text:match('^%s*(.-)%s*$') or text
end

-- 判断文本是否包含指定片段。
local function containsText(text, needle)
  if type(text) ~= 'string' or type(needle) ~= 'string' then return false end
  return text:lower():find(needle:lower(), 1, true) ~= nil
end

-- 按 Name 从窗体里安全取得子组件。
local function getNamedComponent(owner, name)
  if not owner or type(name) ~= 'string' then return nil end
  local component = safeCall(function() return owner.findComponentByName(name) end)
  if component then return component end
  return safeCall(function() return owner.ComponentByName[name] end)
end

-- 识别窗体设计器的对象检查器窗口。
local function isObjectInspectorForm(form)
  if not form then return false end

  local className = safeCall(function() return form.getClassName() end) or ''
  if className == 'TObjectInspectorDlg' then return true end
  if containsText(className, 'objectinspector') or containsText(className, 'object inspector') then return true end

  local name = safeCall(function() return form.getName() end) or ''
  if containsText(name, 'objectinspector') or containsText(name, 'object inspector') then return true end

  local caption = stripHotkeyAndTrim(safeCall(getProperty, form, 'Caption'))
  if caption == 'Object Inspector' or caption == '对象检查器' or caption == '对象查看器' then return true end

  if safeCall(function() return form.PropertyGrid end) then return true end
  if safeCall(function() return form.EventGrid end) then return true end
  if safeCall(function() return form.GridControl[0] end) then return true end
  if getNamedComponent(form, 'PropertyGrid') or getNamedComponent(form, 'EventGrid') then return true end

  local noteBook = getNamedComponent(form, 'NoteBook')
  local propertyPanel = getNamedComponent(form, 'PropertyPanel')
  local componentTree = getNamedComponent(form, 'ComponentTree')
  local mainPopup = getNamedComponent(form, 'MainPopupMenu') or safeCall(function() return form.MainPopupMenu end)
  return noteBook and mainPopup and (propertyPanel or componentTree) and true or false
end

local function isFormDesignerAuxiliaryDialog(form)
  if not form then return false end
  local caption = stripHotkeyAndTrim(safeCall(getProperty, form, 'Caption'))
  if caption == 'Strings Editor Dialog' or caption == '字符串编辑器' then return true end
  if caption == 'Load Image Dialog' or caption == '加载图片' then return true end
  if caption == 'Select properties' or caption == '选择属性' then return true end
  if caption:match('^Load Image Dialog %- ') or caption:match('^加载图片 %- ') then return true end
  if caption:match('^Properties of ') or caption:match('^.+ 的属性$') then return true end
  return false
end

local function isFormDesignerStaticTextForm(form)
  return isObjectInspectorForm(form) or isFormDesignerAuxiliaryDialog(form)
end

local OI_STATIC_TEXT = {
  ['Object Inspector'] = '对象检查器',
  ['Strings Editor Dialog'] = '字符串编辑器',
  ['Load Image Dialog'] = '加载图片',
  ['Select properties'] = '选择属性',
  ['Components'] = '组件',
  ['Co&mponents'] = '组件(&M)',
  ['Properties'] = '属性',
  ['&Properties'] = '属性(&P)',
  ['Selected Properties'] = '已选属性',
  ['&Selected Properties'] = '已选属性(&S)',
  ['Picture'] = '图片',
  ['Sort'] = '排序',
  ['Clear'] = '清除',
  ['C&lear'] = '清除(&L)',
  ['Save'] = '保存',
  ['&Save'] = '保存(&S)',
  ['Load'] = '加载',
  ['&Load'] = '加载(&L)',
  ['Copy'] = '复制',
  ['&Copy'] = '复制(&C)',
  ['Paste'] = '粘贴',
  ['&Paste'] = '粘贴(&P)',
  ['Add'] = '添加',
  ['&Add'] = '添加(&A)',
  ['&Add Item'] = '添加项目(&A)',
  ['Delete'] = '删除',
  ['&Delete'] = '删除(&D)',
  ['OK'] = '确定',
  ['Ok'] = '确定',
  ['&OK'] = '确定(&O)',
  ['Cancel'] = '取消',
  ['&Help'] = '帮助(&H)',
  ['Events'] = '事件',
  ['Favorites'] = '收藏夹',
  ['Restricted'] = '受限',
  ['Restricted Properties'] = '受限属性',
  ['Component Tree'] = '组件树',
  ['Property Filter'] = '属性筛选器',
  ['Hints'] = '提示',
  ['Information Box'] = '信息框',
  ['Status Bar'] = '状态栏',
  ['(filter)'] = '(筛选)',
  ['View restricted properties'] = '查看受限属性',
  ['View Restricted Properties'] = '查看受限属性',
  ['Show Component Tree'] = '显示组件树',
  ['Show Property Filter'] = '显示属性筛选器',
  ['Show Hints'] = '显示提示',
  ['Show Information Box'] = '显示信息框',
  ['Show Status Bar'] = '显示状态栏',
  ['Show Boolean Checkboxes'] = '以布尔值复选框显示',
  ['Show Boolean as Checkbox'] = '以布尔值复选框显示',
}

local OI_STATIC_PATTERNS = {
  { '^Load Image Dialog %- (.+)$', '加载图片 - %1' },
  { '^Properties of (.+)$', '%1 的属性' },
  { '^(%d+) lines, (%d+) chars$', '%1 行，%2 字符' },
  { '^(%d+) line, (%d+) chars$', '%1 行，%2 字符' },
  { '^(%d+) lines, (%d+) char$', '%1 行，%2 字符' },
  { '^(%d+) line, (%d+) char$', '%1 行，%2 字符' },
}

-- 翻译对象检查器上的固定文本。
local function translateOIStaticText(text)
  if type(text) ~= 'string' or text == '' then return nil end
  local direct = OI_STATIC_TEXT[text]
  if direct then return direct end

  local compact = stripHotkeyAndTrim(text)
  direct = OI_STATIC_TEXT[compact]
  if direct then return direct end

  for i = 1, #OI_STATIC_PATTERNS do
    local mapped, count = compact:gsub(OI_STATIC_PATTERNS[i][1], OI_STATIC_PATTERNS[i][2], 1)
    if count > 0 then return mapped end
  end

  return PROP_NAME[compact]
end

-- 翻译对象的指定文本属性。
local function localizeKnownTextProperty(obj, prop)
  local text = safeCall(getProperty, obj, prop)
  if type(text) ~= 'string' then return end

  local translated = translateOIStaticText(text)
  if translated and translated ~= text then
    safeCall(setProperty, obj, prop, translated)
  end
end

local OI_STATIC_COMPONENT_NAMES = {
  'LComponents',
  'LProperties',
  'LLBSelected',
  'LBComponents',
  'LBProperties',
  'LBSelected',
  'BAdd',
  'BDelete',
  'BClear',
}

-- 翻译对象检查器里的菜单项标题。
local function localizeMenuItemCaption(item, seen)
  if not item then return end
  seen = seen or {}
  local key = tostring(item)
  if seen[key] then return end
  seen[key] = true

  localizeKnownTextProperty(item, 'Caption')

  local count = safeCall(function() return item.Count end)
  if type(count) == 'number' then
    for i = 0, count - 1 do
      local child = safeCall(function() return item.Item[i] end)
      if child then localizeMenuItemCaption(child, seen) end
    end
  end
end

-- 递归翻译对象检查器菜单。
local function localizeMenuCaptions(menu)
  if not menu then return end
  local items = safeCall(function() return menu.Items end)
  localizeMenuItemCaption(items or menu, {})
end

-- 翻译对象检查器页签标题。
local function localizePageCaptions(page)
  if not page then return end
  localizeKnownTextProperty(page, 'Caption')
  localizeKnownTextProperty(page, 'Text')

  local pageCount = safeCall(function() return page.PageCount end)
  if type(pageCount) == 'number' then
    for i = 0, pageCount - 1 do
      local tab = safeCall(function() return page.Page[i] end)
        or safeCall(function() return page.Pages[i] end)
      if tab then
        localizeKnownTextProperty(tab, 'Caption')
        localizeKnownTextProperty(tab, 'Text')
      end
    end
  end
end

-- 判断对象是否是菜单或弹出菜单。
local function isMenuObject(obj)
  local className = safeCall(function() return obj.getClassName() end)
  return type(className) == 'string' and className:find('Menu', 1, true) ~= nil
end

-- 遍历窗体拥有的组件并执行处理函数。
local function visitOwnedComponents(root, fn, seen)
  if not root then return end
  seen = seen or {}
  local key = tostring(root)
  if seen[key] then return end
  seen[key] = true

  safeCall(fn, root)

  local count = safeCall(function() return root.getComponentCount() end)
  if type(count) == 'number' then
    for i = 0, count - 1 do
      local child = safeCall(function() return root.Component[i] end)
      if child then visitOwnedComponents(child, fn, seen) end
    end
  end

  count = safeCall(function() return root.ControlCount end)
  if type(count) == 'number' then
    for i = 0, count - 1 do
      local child = safeCall(function() return root.Control[i] end)
        or safeCall(function() return root.Controls[i] end)
      if child then visitOwnedComponents(child, fn, seen) end
    end
  end
end

-- 汉化对象检查器窗口的静态控件、页签和菜单。
local function localizeObjectInspectorStaticUI(form)
  if not isFormDesignerStaticTextForm(form) then return end

  localizeKnownTextProperty(form, 'Caption')

  visitOwnedComponents(form, function(c)
    localizeKnownTextProperty(c, 'Caption')
    localizeKnownTextProperty(c, 'Text')
    localizeKnownTextProperty(c, 'SimpleText')
    localizeKnownTextProperty(c, 'Hint')
    localizeKnownTextProperty(c, 'TextHint')
    localizeKnownTextProperty(c, 'Title')
    localizePageCaptions(c)

    if isMenuObject(c) then
      localizeMenuCaptions(c)
    end

    local popup = safeCall(function() return c.PopupMenu end)
    if popup then localizeMenuCaptions(popup) end
  end)

  for i = 1, #OI_STATIC_COMPONENT_NAMES do
    local c = getNamedComponent(form, OI_STATIC_COMPONENT_NAMES[i])
    if c then
      localizeKnownTextProperty(c, 'Caption')
      localizeKnownTextProperty(c, 'Text')
      localizeKnownTextProperty(c, 'SimpleText')
    end
  end

  localizeMenuCaptions(safeCall(function() return form.MainPopupMenu end))
  localizeMenuCaptions(safeCall(function() return form.PopupMenu end))

  local tree = safeCall(function() return form.ComponentTree end)
    or safeCall(function() return form.findComponentByName('ComponentTree') end)
  if tree then
    localizeMenuCaptions(safeCall(function() return tree.PopupMenu end))
  end
end

local OI_STATIC_DELAYED_LOCALIZE_QUEUED = setmetatable({}, {__mode = 'k'})

local function queueObjectInspectorStaticTextRefresh(form)
  if not isFormDesignerStaticTextForm(form) then return end
  if OI_STATIC_DELAYED_LOCALIZE_QUEUED[form] then return end
  if type(createTimer) ~= 'function' then return end
  OI_STATIC_DELAYED_LOCALIZE_QUEUED[form] = true

  local attempts = 0
  safeCall(function()
    local timer = createTimer(form, false)
    timer.Interval = 100
    timer.OnTimer = function(t)
      attempts = attempts + 1
      safeCall(localizeObjectInspectorStaticUI, form)
      if attempts >= 6 then
        safeCall(function() t.destroy() end)
      end
    end
    timer.Enabled = true
  end)
end

local installFormDesignerDefaultNativeHooks

local function installObjectInspectorNativeHooksIfNeeded(form)
  if type(installFormDesignerDefaultNativeHooks) ~= 'function' then return false end
  if not zhCNNativeHooksEnabled() then return false end
  if not isObjectInspectorForm(form) then return false end
  return installFormDesignerDefaultNativeHooks()
end

-- 在对象检查器首次显示时补做静态文本汉化。
local function hookStaticTextFirstShow(form)
  if not form then return end
  if safeCall(function() return form._zhOIStaticFirstShowHooked end) then return end
  safeCall(function() form._zhOIStaticFirstShowHooked = true end)

  local register = safeCall(function() return form.registerFirstShowCallback end)
  if type(register) ~= 'function' then return end

  local cb
  cb = register(function(sender)
    safeCall(function() form.unregisterFirstShowCallback(cb) end)
    safeCall(installObjectInspectorNativeHooksIfNeeded, sender or form)
    safeCall(localizeObjectInspectorStaticUI, sender or form)
    safeCall(queueObjectInspectorStaticTextRefresh, sender or form)
  end)
end

-- 为已存在和新创建的对象检查器安装静态文本汉化。
local function installObjectInspectorStaticTextHooks()
  if GLOBAL_STATE.oiStaticTextHooksInstalled then return end
  GLOBAL_STATE.oiStaticTextHooksInstalled = true

  GLOBAL_STATE.oiStaticTextFormAddNotification = safeCall(function()
    return registerFormAddNotification(function(form)
      safeCall(installObjectInspectorNativeHooksIfNeeded, form)
      safeCall(hookStaticTextFirstShow, form)
      safeCall(localizeObjectInspectorStaticUI, form)
      safeCall(queueObjectInspectorStaticTextRefresh, form)
    end)
  end)

  safeCall(function()
    for i = 0, getFormCount() - 1 do
      local form = getForm(i)
      safeCall(installObjectInspectorNativeHooksIfNeeded, form)
      safeCall(hookStaticTextFirstShow, form)
      safeCall(localizeObjectInspectorStaticUI, form)
      safeCall(queueObjectInspectorStaticTextRefresh, form)
    end
  end)
end

-- 取得当前 CE 模块名，供 aobscanmodule 使用。
local function getSelfModuleForAOBScan()
  if type(GLOBAL_STATE.nativeSelfModuleName) == 'string' then
    return GLOBAL_STATE.nativeSelfModuleName
  end

  local moduleName = extractFileName(getApplication().ExeName)
  GLOBAL_STATE.nativeSelfModuleName = moduleName
  return moduleName
end

-- 安全读取当前进程内的 AA 符号地址。
local function getSelfAddressSafe(symbol)
  return safeCall(function() return getAddressSafe(symbol, true) end) or
         safeCall(function() return getAddressSafe(symbol) end)
end

-- 生成针对当前 CE 模块的 aobscanmodule 语句。
local function buildSelfAOBScanLine(symbol, pattern, moduleName)
  moduleName = moduleName or getSelfModuleForAOBScan()
  return 'aobscanmodule(' .. symbol .. ',"' .. moduleName .. '",' .. pattern .. ')'
end

-- 取得毫秒时间，用于统计 Hook 安装耗时。
local function nativeHookNowMs()
  local tick = safeCall(function()
    if type(getTickCount) == 'function' then return getTickCount() end
    if type(getTickCount64) == 'function' then return getTickCount64() end
  end)
  if type(tick) == 'number' then return tick end
  return math.floor((os.clock() or 0) * 1000)
end

-- 记录某个原生 Hook 步骤的耗时。
local function addNativeHookTiming(timings, name, started, extra)
  local elapsed = nativeHookNowMs() - started
  local part = tostring(name) .. '=' .. tostring(elapsed) .. 'ms'
  if extra ~= nil and extra ~= '' then
    part = part .. '(' .. tostring(extra) .. ')'
  end
  timings[#timings + 1] = part
  return elapsed
end

-- 输出原生 Hook 安装总耗时。
local function finishNativeHookTiming(_, timings, totalStart)
  local total = nativeHookNowMs() - totalStart
  timings[#timings + 1] = 'total=' .. tostring(total) .. 'ms'
  return table.concat(timings, ' | ')
end

-- 计算属性名查找表使用的哈希值。
local function propNameHash(text)
  local h = 0x811C9DC5
  for i = 1, #text do
    h = (h * 0x83 + string.byte(text, i)) % 0x100000000
  end
  return h
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

local PROP_DRAW_NAME_DATA_SIZE = 524288

-- 生成对象检查器属性名绘制 Hook 的 64 位 AA 脚本。
local function buildPropDrawNameHookAA64(moduleName)
  local entries = {}
  for source, translated in pairs(PROP_NAME_NATIVE) do
    if type(source) == 'string' and type(translated) == 'string' and source ~= '' and source ~= translated then
      entries[#entries + 1] = { source = source, translated = translated }
    end
  end
  table.sort(entries, function(a, b)
    if #a.source ~= #b.source then return #a.source < #b.source end
    return a.source < b.source
  end)

  local out = {}
  out[#out + 1] = buildSelfAOBScanLine('zhOIPropDrawNameAfterGetName', 'E8 ?? ?? ?? ?? 48 8B 45 C0 48 89 44 24 20 48 8B 45 F0 8B 00 67 44 8D 40 02 48 8B 45 F0 44 8B 48 04 48 8B 55 F0 48 8B 4D F8 48 8B 45 F8 48 8B 00 FF 90 E8 04 00 00', moduleName)
  out[#out + 1] = 'alloc(zhOIPropDrawNameMem,4096,zhOIPropDrawNameAfterGetName)'
  out[#out + 1] = 'alloc(zhOIPropDrawNameData,' .. tostring(PROP_DRAW_NAME_DATA_SIZE) .. ',zhOIPropDrawNameAfterGetName)'
  out[#out + 1] = 'alloc(zhOIPropDrawNameStats,96,zhOIPropDrawNameAfterGetName)'
  out[#out + 1] = 'label(zhOIPropDrawNameReturn)'
  out[#out + 1] = 'label(zhOIPropDrawNameOriginal)'
  out[#out + 1] = 'label(zhOIPropDrawNameMiss)'
  out[#out + 1] = 'label(zhOIPropDrawNameLoop)'
  out[#out + 1] = 'label(zhOIPropDrawNameCompareLoop)'
  out[#out + 1] = 'label(zhOIPropDrawNameMatched)'
  out[#out + 1] = 'label(zhOIPropDrawNameNextEntry)'
  out[#out + 1] = 'label(zhOIPropDrawNameHook)'

  out[#out + 1] = ''
  out[#out + 1] = 'zhOIPropDrawNameMem:'
  out[#out + 1] = '  inc qword ptr [zhOIPropDrawNameStats]'
  out[#out + 1] = '  mov rax,[rbp-40]'
  out[#out + 1] = '  test rax,rax'
  out[#out + 1] = '  je zhOIPropDrawNameOriginal'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+10],rax'
  out[#out + 1] = '  mov r10,[rax-8]'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+18],r10'
  out[#out + 1] = '  lea r11,[zhOIPropDrawNameData]'
  out[#out + 1] = 'zhOIPropDrawNameLoop:'
  out[#out + 1] = '  mov rcx,[r11]'
  out[#out + 1] = '  test rcx,rcx'
  out[#out + 1] = '  je zhOIPropDrawNameMiss'
  out[#out + 1] = '  cmp rcx,r10'
  out[#out + 1] = '  ja zhOIPropDrawNameMiss'
  out[#out + 1] = '  jne zhOIPropDrawNameNextEntry'
  out[#out + 1] = '  movzx edx,byte ptr [rax]'
  out[#out + 1] = '  cmp dl,byte ptr [r11+8]'
  out[#out + 1] = '  jne zhOIPropDrawNameNextEntry'
  out[#out + 1] = '  mov r8,[r11+10]'
  out[#out + 1] = '  xor r9,r9'
  out[#out + 1] = 'zhOIPropDrawNameCompareLoop:'
  out[#out + 1] = '  cmp r9,r10'
  out[#out + 1] = '  jae zhOIPropDrawNameMatched'
  out[#out + 1] = '  mov dl,byte ptr [rax+r9]'
  out[#out + 1] = '  cmp dl,byte ptr [r8+r9]'
  out[#out + 1] = '  jne zhOIPropDrawNameNextEntry'
  out[#out + 1] = '  inc r9'
  out[#out + 1] = '  jmp zhOIPropDrawNameCompareLoop'
  out[#out + 1] = 'zhOIPropDrawNameMatched:'
  out[#out + 1] = '  inc qword ptr [zhOIPropDrawNameStats+8]'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+20],rax'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+28],r11'
  out[#out + 1] = '  mov rax,[r11+18]'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+30],rax'
  out[#out + 1] = '  mov [rsp+20],rax'
  out[#out + 1] = '  jmp zhOIPropDrawNameReturn'
  out[#out + 1] = 'zhOIPropDrawNameNextEntry:'
  out[#out + 1] = '  add r11,20'
  out[#out + 1] = '  jmp zhOIPropDrawNameLoop'

  out[#out + 1] = 'zhOIPropDrawNameMiss:'
  out[#out + 1] = '  inc qword ptr [zhOIPropDrawNameStats+38]'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+40],rax'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+48],r10'
  out[#out + 1] = 'zhOIPropDrawNameOriginal:'
  out[#out + 1] = '  mov rax,[rbp-40]'
  out[#out + 1] = '  mov [rsp+20],rax'
  out[#out + 1] = '  jmp zhOIPropDrawNameReturn'
  out[#out + 1] = ''
  out[#out + 1] = 'zhOIPropDrawNameHook:'
  out[#out + 1] = '  dq zhOIPropDrawNameAfterGetName'
  out[#out + 1] = ''
  out[#out + 1] = 'zhOIPropDrawNameAfterGetName+5:'
  out[#out + 1] = '  jmp zhOIPropDrawNameMem'
  out[#out + 1] = '  nop 4'
  out[#out + 1] = 'zhOIPropDrawNameReturn:'
  out[#out + 1] = 'registersymbol(zhOIPropDrawNameHook)'
  out[#out + 1] = 'registersymbol(zhOIPropDrawNameData)'
  out[#out + 1] = 'registersymbol(zhOIPropDrawNameStats)'

  GLOBAL_STATE.nativePropDrawNameEntryCount = #entries
  GLOBAL_STATE.nativePropDrawNameCompareMode = 'exact'
  return table.concat(out, '\n'), entries, 0
end

-- 生成对象检查器属性名绘制 Hook 的 32 位 AA 脚本。
local function buildPropDrawNameHookAA32(moduleName)
  local entries = {}
  for source, translated in pairs(PROP_NAME_NATIVE) do
    if type(source) == 'string' and type(translated) == 'string' and source ~= '' and source ~= translated then
      entries[#entries + 1] = { source = source, translated = translated }
    end
  end
  table.sort(entries, function(a, b)
    if #a.source ~= #b.source then return #a.source < #b.source end
    return a.source < b.source
  end)

  local out = {}
  out[#out + 1] = buildSelfAOBScanLine('zhOIPropDrawNameHook', 'FF 75 DC 8D 45 E0 50 8B 45 F8 8B 00 8D 48 02 8B 55 F8 8B 45 FC 8B 5D FC 8B 1B FF 93 74 02 00 00', moduleName)
  out[#out + 1] = 'alloc(zhOIPropDrawNameMem,4096,zhOIPropDrawNameHook)'
  out[#out + 1] = 'alloc(zhOIPropDrawNameData,' .. tostring(PROP_DRAW_NAME_DATA_SIZE) .. ',zhOIPropDrawNameHook)'
  out[#out + 1] = 'alloc(zhOIPropDrawNameStats,96,zhOIPropDrawNameHook)'
  out[#out + 1] = 'label(zhOIPropDrawNameReturn)'
  out[#out + 1] = 'label(zhOIPropDrawNameOriginal)'
  out[#out + 1] = 'label(zhOIPropDrawNameMiss)'
  out[#out + 1] = 'label(zhOIPropDrawNameLoop)'
  out[#out + 1] = 'label(zhOIPropDrawNameCompareLoop)'
  out[#out + 1] = 'label(zhOIPropDrawNameMatched)'
  out[#out + 1] = 'label(zhOIPropDrawNameNextEntry)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhOIPropDrawNameMem:'
  out[#out + 1] = '  push ebx'
  out[#out + 1] = '  push esi'
  out[#out + 1] = '  push edi'
  out[#out + 1] = '  inc dword ptr [zhOIPropDrawNameStats]'
  out[#out + 1] = '  mov eax,[ebp-24]'
  out[#out + 1] = '  mov edx,eax'
  out[#out + 1] = '  test eax,eax'
  out[#out + 1] = '  je zhOIPropDrawNameOriginal'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+10],eax'
  out[#out + 1] = '  mov ecx,[eax-4]'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+14],ecx'
  out[#out + 1] = '  lea esi,[zhOIPropDrawNameData]'
  out[#out + 1] = 'zhOIPropDrawNameLoop:'
  out[#out + 1] = '  mov ebx,[esi]'
  out[#out + 1] = '  test ebx,ebx'
  out[#out + 1] = '  je zhOIPropDrawNameMiss'
  out[#out + 1] = '  cmp ebx,ecx'
  out[#out + 1] = '  ja zhOIPropDrawNameMiss'
  out[#out + 1] = '  jne zhOIPropDrawNameNextEntry'
  out[#out + 1] = '  movzx ebx,byte ptr [eax]'
  out[#out + 1] = '  cmp bl,byte ptr [esi+4]'
  out[#out + 1] = '  jne zhOIPropDrawNameNextEntry'
  out[#out + 1] = '  mov edi,[esi+8]'
  out[#out + 1] = '  xor ebx,ebx'
  out[#out + 1] = 'zhOIPropDrawNameCompareLoop:'
  out[#out + 1] = '  cmp ebx,ecx'
  out[#out + 1] = '  jae zhOIPropDrawNameMatched'
  out[#out + 1] = '  mov dl,byte ptr [eax+ebx]'
  out[#out + 1] = '  cmp dl,byte ptr [edi+ebx]'
  out[#out + 1] = '  jne zhOIPropDrawNameNextEntry'
  out[#out + 1] = '  inc ebx'
  out[#out + 1] = '  jmp zhOIPropDrawNameCompareLoop'
  out[#out + 1] = 'zhOIPropDrawNameMatched:'
  out[#out + 1] = '  inc dword ptr [zhOIPropDrawNameStats+4]'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+18],eax'
  out[#out + 1] = '  mov [zhOIPropDrawNameStats+1C],esi'
  out[#out + 1] = '  mov edx,[esi+0C]'
  out[#out + 1] = '  jmp zhOIPropDrawNameOriginal'
  out[#out + 1] = 'zhOIPropDrawNameNextEntry:'
  out[#out + 1] = '  add esi,10'
  out[#out + 1] = '  jmp zhOIPropDrawNameLoop'
  out[#out + 1] = 'zhOIPropDrawNameMiss:'
  out[#out + 1] = '  inc dword ptr [zhOIPropDrawNameStats+8]'
  out[#out + 1] = '  mov edx,eax'
  out[#out + 1] = 'zhOIPropDrawNameOriginal:'
  out[#out + 1] = '  pop edi'
  out[#out + 1] = '  pop esi'
  out[#out + 1] = '  pop ebx'
  out[#out + 1] = '  push edx'
  out[#out + 1] = '  lea eax,[ebp-20]'
  out[#out + 1] = '  jmp zhOIPropDrawNameReturn'
  out[#out + 1] = ''
  out[#out + 1] = 'zhOIPropDrawNameHook:'
  out[#out + 1] = '  jmp zhOIPropDrawNameMem'
  out[#out + 1] = '  nop 1'
  out[#out + 1] = 'zhOIPropDrawNameReturn:'
  out[#out + 1] = 'registersymbol(zhOIPropDrawNameHook)'
  out[#out + 1] = 'registersymbol(zhOIPropDrawNameData)'
  out[#out + 1] = 'registersymbol(zhOIPropDrawNameStats)'

  GLOBAL_STATE.nativePropDrawNameEntryCount = #entries
  GLOBAL_STATE.nativePropDrawNameCompareMode = 'exact32'
  return table.concat(out, '\n'), entries, 0
end

-- 生成对象检查器属性名绘制 Hook 的 AA 脚本。
local function buildPropDrawNameHookAA(moduleName)
  if ceIs64Bit() then return buildPropDrawNameHookAA64(moduleName) end
  return buildPropDrawNameHookAA32(moduleName)
end

-- 把字符串转换成字节数组，可选零结尾。
local function bytesOfString(text, zeroTerminate)
  local bytes = {}
  for i = 1, #text do
    bytes[#bytes + 1] = string.byte(text, i)
  end
  if zeroTerminate then
    bytes[#bytes + 1] = 0
  end
  return bytes
end

-- 把字节数组转换成 AA/AOB 使用的十六进制模式。
local function bytePattern(bytes)
  local out = {}
  for i = 1, #bytes do
    out[#out + 1] = string.format('%02X', bytes[i])
  end
  return table.concat(out, ' ')
end

-- 把字节数组转换成 AA 的 db 指令参数。
local function dbBytes(bytes)
  local out = {}
  for i = 1, #bytes do
    out[#out + 1] = string.format('%02X', bytes[i])
  end
  return table.concat(out, ' ')
end

-- 把数值格式化为 AA 可用的十六进制。
local function aaHex(value)
  return string.format('%02X', value or 0)
end

-- 把字节数组追加到目标数组。
local function appendBytes(target, bytes)
  for i = 1, #bytes do
    target[#target + 1] = bytes[i]
  end
end

-- 把 32 位整数转换为小端字节序。
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

-- 把 64 位整数转换为小端字节序。
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

-- 按当前 CE 位数生成指针宽度字节。
local function pointerBytes(value)
  if ceIs64Bit() then return qwordBytes(value) end
  return dwordBytes(value)
end

-- 兼容不同 CE 版本读取本进程指针值。
local function readPointerLocalCompat(address)
  if type(readPointerLocal) == 'function' then return readPointerLocal(address) end
  if ceIs64Bit() then return readQwordLocal(address) end
  return readIntegerLocal(address)
end

-- 兼容不同 CE 版本写入本进程指针值。
local function writePointerLocalCompat(address, value)
  if type(writePointerLocal) == 'function' then return writePointerLocal(address, value) end
  if ceIs64Bit() then return writeQwordLocal(address, value) end
  return writeIntegerLocal(address, value)
end

-- 取得当前 CE 主模块的基址和大小，用于在自身模块内定位 resourcestring 指针槽。
local function getSelfModuleRange(moduleName)
  moduleName = moduleName or getSelfModuleForAOBScan()
  local moduleNameLower = string.lower(moduleName)
  local modules = safeCall(function() return enumModules() end)
  if type(modules) == 'table' then
    for _, module in ipairs(modules) do
      local name = type(module.Name) == 'string' and module.Name or ''
      local path = type(module.PathToFile) == 'string' and module.PathToFile or ''
      local size = module.Size
      if (string.lower(name) == moduleNameLower or string.lower(extractFileName(path)) == moduleNameLower) and
         type(module.Address) == 'number' and type(size) == 'number' and size > 0 then
        return module.Address, size
      end
    end
  end

  local base = getSelfAddressSafe(moduleName)
  local size = safeCall(function() return getModuleSize(moduleName) end)
  if type(base) ~= 'number' or type(size) ~= 'number' or size <= 0 then
    return nil, nil
  end
  return base, size
end

local function getSelfModulePointerSearchRanges(moduleName, base, size)
  local ranges = {}
  local sections = safeCall(function() return enumSectionsOfModule(moduleName) end)
  if type(sections) == 'table' then
    for _, section in ipairs(sections) do
      local name = string.lower(type(section.Name) == 'string' and section.Name or '')
      if name == '.data' or name == 'data' then
        local sectionAddress = section.Address
        local sectionSize = section.Size
        if type(sectionAddress) == 'number' and type(sectionSize) == 'number' and sectionSize > 0 then
          ranges[#ranges + 1] = { address = sectionAddress, size = sectionSize }
        end
      end
    end
  end

  if #ranges == 0 and type(base) == 'number' and type(size) == 'number' and size > 0 then
    ranges[#ranges + 1] = { address = base, size = size }
  end

  return ranges
end

local function bytesMatchAt(bytes, index, needle)
  for i = 1, #needle do
    if bytes[index + i - 1] ~= needle[i] then return false end
  end
  return true
end

-- 在当前 CE 主模块里扫描“指向某个字符串的指针值”。
local function scanSelfModuleForPointerValue(moduleName, pointerValue, maxResults)
  local base, size = getSelfModuleRange(moduleName)
  if type(base) ~= 'number' or type(size) ~= 'number' then return {} end

  local needle = pointerBytes(pointerValue)
  local chunkSize = 0x100000
  local results = {}
  local searchedWholeModule = false

  local function scanRange(rangeBase, rangeSize)
    local offset = 0
    while offset < rangeSize do
      local readSize = math.min(chunkSize + #needle - 1, rangeSize - offset)
      local bytes = safeCall(function() return readBytesLocal(rangeBase + offset, readSize, true) end)
      if type(bytes) == 'table' then
        local maxIndex = #bytes - #needle + 1
        for i = 1, maxIndex do
          if bytesMatchAt(bytes, i, needle) then
            results[#results + 1] = rangeBase + offset + i - 1
            if type(maxResults) == 'number' and #results >= maxResults then
              return true
            end
          end
        end
      end
      offset = offset + chunkSize
    end
    return false
  end

  for _, range in ipairs(getSelfModulePointerSearchRanges(moduleName, base, size)) do
    if range.address == base and range.size == size then searchedWholeModule = true end
    if scanRange(range.address, range.size) then return results end
  end

  if #results == 0 and not searchedWholeModule then
    scanRange(base, size)
  end

  return results
end

-- 用 AA 的 aobscanmodule 在当前模块里直接定位第一个指针槽。
local function aobScanSelfModulePointerValue(moduleName, pointerValue, symbolName)
  moduleName = moduleName or getSelfModuleForAOBScan()
  local existing = getSelfAddressSafe(symbolName)
  if type(existing) == 'number' then return existing end

  local pattern = bytePattern(pointerBytes(pointerValue))
  local aa = table.concat({
    buildSelfAOBScanLine(symbolName, pattern, moduleName),
    'registersymbol(' .. symbolName .. ')',
  }, '\n')

  local ok, result = pcall(function() return autoAssemble(aa, true) end)
  if ok and result ~= false then
    return getSelfAddressSafe(symbolName)
  end
  return nil, result
end

-- 返回当前 CE 位数对应的 FPC AnsiString 头大小。
local function fpcAnsiStringHeaderSize()
  if ceIs64Bit() then return 0x18 end
  return 0x0C
end

-- 从 FPC AnsiString 文本地址读取长度字段。
local function readFpcAnsiStringLength(textAddress)
  if ceIs64Bit() then return readQwordLocal(textAddress - 8) end
  return readIntegerLocal(textAddress - 4)
end

-- 按 FPC AnsiString 结构生成字符串数据。
local function fpcAnsiStringBytes(text)
  local bytes
  if ceIs64Bit() then
    bytes = qwordBytes(0x10000)
    appendBytes(bytes, qwordBytes(-1))
    appendBytes(bytes, qwordBytes(#text))
  else
    bytes = dwordBytes(0x10000)
    appendBytes(bytes, dwordBytes(-1))
    appendBytes(bytes, dwordBytes(#text))
  end
  appendBytes(bytes, bytesOfString(text, true))
  return bytes
end

-- 把地址或大小向上对齐。
local function alignUp(value, alignment)
  alignment = alignment or 16
  return math.floor((value + alignment - 1) / alignment) * alignment
end

local function ensureByteBufferSize(buffer, size)
  for i = #buffer + 1, size do
    buffer[i] = 0
  end
end

local function writeBytesToBuffer(buffer, offset, bytes)
  ensureByteBufferSize(buffer, offset + #bytes)
  for i = 1, #bytes do
    buffer[offset + i] = bytes[i]
  end
end

-- 把属性名翻译表写入原生 Hook 数据区。
local function populatePropDrawNameData(entries)
  local base = getSelfAddressSafe('zhOIPropDrawNameData')
  if type(base) ~= 'number' then
    return false, 'missing zhOIPropDrawNameData symbol'
  end

  local is64 = ceIs64Bit()
  local entrySize = is64 and 0x20 or 0x10
  local entryAreaSize = alignUp((#entries + 1) * entrySize, 16)
  local cursorOffset = entryAreaSize
  local writtenBytes = entryAreaSize
  local buffer = {}
  ensureByteBufferSize(buffer, entryAreaSize)
  writeBytesToBuffer(buffer, #entries * entrySize, pointerBytes(0))

  local verifyChecked = 0
  local verifyFailed = 0
  local verifyEntries = {}

  for i, entry in ipairs(entries) do
    local entryAddress = base + ((i - 1) * entrySize)
    local sourceAddress = base + cursorOffset
    local sourceBytes = bytesOfString(entry.source, false)
    writeBytesToBuffer(buffer, cursorOffset, sourceBytes)
    cursorOffset = alignUp(cursorOffset + #sourceBytes, 16)

    local headerAddress = base + cursorOffset
    local textAddress = headerAddress + fpcAnsiStringHeaderSize()
    local textBytes = fpcAnsiStringBytes(entry.translated)

    local entryBytes
    if is64 then
      entryBytes = qwordBytes(#entry.source)
      appendBytes(entryBytes, dwordBytes(string.byte(entry.source, 1) or 0))
      appendBytes(entryBytes, dwordBytes(0))
      appendBytes(entryBytes, qwordBytes(sourceAddress))
      appendBytes(entryBytes, qwordBytes(textAddress))
    else
      entryBytes = dwordBytes(#entry.source)
      appendBytes(entryBytes, dwordBytes(string.byte(entry.source, 1) or 0))
      appendBytes(entryBytes, dwordBytes(sourceAddress))
      appendBytes(entryBytes, dwordBytes(textAddress))
    end

    writeBytesToBuffer(buffer, cursorOffset, textBytes)
    writeBytesToBuffer(buffer, (i - 1) * entrySize, entryBytes)

    if i <= 6 then
      verifyEntries[#verifyEntries + 1] = {
        entryAddress = entryAddress,
        sourceAddress = sourceAddress,
        textAddress = textAddress,
        sourceLen = #entry.source,
        translatedLen = #entry.translated,
      }
    end

    cursorOffset = alignUp(cursorOffset + #textBytes, 16)
    writtenBytes = cursorOffset
    if writtenBytes > PROP_DRAW_NAME_DATA_SIZE then
      return false, 'data block too small: ' .. tostring(writtenBytes) .. ' bytes'
    end
  end

  ensureByteBufferSize(buffer, writtenBytes)
  if not writeSucceeded(function() return writeBytesLocal(base, buffer) end) then
    return false, 'write failed for PropDrawName data block'
  end

  for _, verifyEntry in ipairs(verifyEntries) do
    verifyChecked = verifyChecked + 1
    local readLen = safeCall(function()
      if is64 then return readQwordLocal(verifyEntry.entryAddress) end
      return readIntegerLocal(verifyEntry.entryAddress)
    end)
    local readSourcePtr = safeCall(function()
      return readPointerLocalCompat(verifyEntry.entryAddress + (is64 and 0x10 or 0x08))
    end)
    local readTextPtr = safeCall(function()
      return readPointerLocalCompat(verifyEntry.entryAddress + (is64 and 0x18 or 0x0C))
    end)
    local readTextLen = type(readTextPtr) == 'number' and safeCall(function() return readFpcAnsiStringLength(readTextPtr) end) or nil
    if readLen ~= verifyEntry.sourceLen or
       readSourcePtr ~= verifyEntry.sourceAddress or
       readTextPtr ~= verifyEntry.textAddress or
       readTextLen ~= verifyEntry.translatedLen then
      verifyFailed = verifyFailed + 1
    end
  end

  GLOBAL_STATE.nativePropDrawNameDataBytes = writtenBytes
  GLOBAL_STATE.nativePropDrawNameDataVerify = tostring(verifyFailed) .. '/' .. tostring(verifyChecked)
  if verifyFailed > 0 then
    GLOBAL_STATE.nativePropDrawNameDataPopulated = false
    return false, 'verify failed: ' .. GLOBAL_STATE.nativePropDrawNameDataVerify
  end
  GLOBAL_STATE.nativePropDrawNameDataPopulated = true
  return true, writtenBytes
end

-- 安装原生 Hook 后刷新对象检查器显示。
local function refreshObjectInspectorsAfterNativeHook()
  safeCall(function()
    for i = 0, getFormCount() - 1 do
      local form = getForm(i)
      if isObjectInspectorForm(form) then
        safeCall(localizeObjectInspectorStaticUI, form)
        safeCall(function() form.invalidate() end)
        safeCall(function() form.repaint() end)
      end
    end
  end)
end

local OI_STATIC_RESOURCE_STRINGS = {
  { symbol = 'zhOIResViewRestrictedPropertiesText', source = 'View restricted properties', translated = '查看受限属性' },
  { symbol = 'zhOIResShowComponentTreeText', source = 'Show Component Tree', translated = '显示组件树' },
  { symbol = 'zhOIResShowPropertyFilterText', source = 'Show Property Filter', translated = '显示属性筛选' },
  { symbol = 'zhOIResShowHintsText', source = 'Show Hints', translated = '提示' },
  { symbol = 'zhOIResShowInfoBoxText', source = 'Show Information Box', translated = '显示信息框' },
  { symbol = 'zhOIResShowStatusBarText', source = 'Show Status Bar', translated = '显示状态栏' },
}

-- 生成对象检查器静态资源字符串修补 AA 脚本。
local function buildObjectInspectorStaticResourcePatchAA(moduleName)
  local out = {}
  local lenOffset = ceIs64Bit() and '-8' or '-4'
  local lenDirective = ceIs64Bit() and 'dq ' or 'dd '
  for _, entry in ipairs(OI_STATIC_RESOURCE_STRINGS) do
    out[#out + 1] = buildSelfAOBScanLine(entry.symbol, bytePattern(bytesOfString(entry.source, true)), moduleName)
  end
  out[#out + 1] = ''

  for _, entry in ipairs(OI_STATIC_RESOURCE_STRINGS) do
    local translatedBytes = bytesOfString(entry.translated, true)
    if #translatedBytes > #entry.source + 1 then
      return nil, 'translation too long for ' .. entry.source
    end
    while #translatedBytes < #entry.source + 1 do
      translatedBytes[#translatedBytes + 1] = 0
    end
    out[#out + 1] = entry.symbol .. lenOffset .. ':'
    out[#out + 1] = '  ' .. lenDirective .. aaHex(#entry.translated)
    out[#out + 1] = entry.symbol .. ':'
    out[#out + 1] = '  db ' .. dbBytes(translatedBytes)
    out[#out + 1] = ''
  end

  for _, entry in ipairs(OI_STATIC_RESOURCE_STRINGS) do
    out[#out + 1] = 'registersymbol(' .. entry.symbol .. ')'
  end

  return table.concat(out, '\n')
end

-- 安装对象检查器静态资源字符串修补。
local function installObjectInspectorStaticResourceStringPatch()
  if GLOBAL_STATE.oiStaticResourcePatchInstalled then return true end

  local moduleName = getSelfModuleForAOBScan()
  local aa, buildError = buildObjectInspectorStaticResourcePatchAA(moduleName)
  if not aa then
    GLOBAL_STATE.oiStaticResourcePatchError = buildError
    return false
  end

  local ok, result = pcall(function() return autoAssemble(aa, true) end)
  if ok and result ~= false then
    GLOBAL_STATE.oiStaticResourcePatchInstalled = true
    GLOBAL_STATE.oiStaticResourcePatchError = nil
    refreshObjectInspectorsAfterNativeHook()
    return true
  end

  GLOBAL_STATE.oiStaticResourcePatchInstalled = false
  GLOBAL_STATE.oiStaticResourcePatchError = result or 'aobscanmodule failed'
  return false
end

local OI_MENU_RESOURCE_DATA_SIZE = 4096
local OI_MENU_RESOURCE_STRINGS = {
  {
    source = 'Set to default: %s',
    translated = '设为默认值：%s',
    scanSymbol = 'zhOIResSetDefaultText',
    pattern = '53 65 74 20 74 6F 20 64 65 66 61 75 6C 74 3A 20 25 73 00',
    textToCurrentSlotDelta = 0x633548,
    textToCurrentSlotDeltas64 = { 0x633548, 0x634038 },
    textToCurrentSlotDeltas32 = { 0x4FBC74, 0x4FBC70 },
  },
  {
    source = 'Jump to declaration',
    translated = '跳转到声明',
    scanSymbol = 'zhOIResJumpDeclText',
    pattern = '4A 75 6D 70 20 74 6F 20 64 65 63 6C 61 72 61 74 69 6F 6E 00',
    textToCurrentSlotDelta = 0x6338A0,
    textToCurrentSlotDeltas64 = { 0x6338A0, 0x634390 },
    textToCurrentSlotDeltas32 = { 0x4FBF50, 0x4FBF4C },
  },
  {
    source = 'Jump to declaration of %s',
    translated = '跳转到属性声明%.0s',
    scanSymbol = 'zhOIResJumpDeclOfText',
    pattern = '4A 75 6D 70 20 74 6F 20 64 65 63 6C 61 72 61 74 69 6F 6E 20 6F 66 20 25 73 00',
    textToCurrentSlotDelta = 0x6338F0,
    textToCurrentSlotDeltas64 = { 0x6338F0, 0x6343E0 },
    textToCurrentSlotDeltas32 = { 0x4FBF90, 0x4FBF8C },
  },
}

-- 生成对象检查器菜单资源字符串修补 AA 脚本。
local function buildObjectInspectorMenuResourcePatchAA(moduleName)
  local out = {}
  for _, entry in ipairs(OI_MENU_RESOURCE_STRINGS) do
    out[#out + 1] = buildSelfAOBScanLine(entry.scanSymbol, entry.pattern, moduleName)
  end
  out[#out + 1] = 'alloc(zhOIResourceStringData,' .. tostring(OI_MENU_RESOURCE_DATA_SIZE) .. ',zhOIResSetDefaultText)'
  out[#out + 1] = 'label(zhOIResourceStringPatch)'
  out[#out + 1] = ''
  out[#out + 1] = 'zhOIResourceStringData:'
  out[#out + 1] = 'zhOIResourceStringPatch:'
  out[#out + 1] = (ceIs64Bit() and '  dq ' or '  dd ') .. 'zhOIResSetDefaultText'
  out[#out + 1] = ''
  out[#out + 1] = 'registersymbol(zhOIResourceStringPatch)'
  out[#out + 1] = 'registersymbol(zhOIResourceStringData)'
  for _, entry in ipairs(OI_MENU_RESOURCE_STRINGS) do
    out[#out + 1] = 'registersymbol(' .. entry.scanSymbol .. ')'
  end
  return table.concat(out, '\n')
end

-- 写入对象检查器菜单资源字符串修补数据。
local function populateObjectInspectorMenuResourcePatchData()
  local base = getSelfAddressSafe('zhOIResourceStringData')
  if type(base) ~= 'number' then
    return false, 'missing zhOIResourceStringData symbol'
  end

  local is64 = ceIs64Bit()
  local cursor = base + 0x20
  local writtenBytes = cursor - base
  local verifyChecked = 0
  local verifyFailed = 0
  GLOBAL_STATE.oiMenuResourcePatchSlotCounts = {}

  for i, entry in ipairs(OI_MENU_RESOURCE_STRINGS) do
    local sourcePtr = getSelfAddressSafe(entry.scanSymbol)
    if type(sourcePtr) ~= 'number' then
      return false, 'missing ' .. tostring(entry.scanSymbol) .. ' symbol'
    end

    local slotPtrs = {}
    local slotPtrSeen = {}
    local lastSlotError = nil

    local function addResourceSlotIfValid(slotPtr)
      if type(slotPtr) ~= 'number' or slotPtrSeen[slotPtr] then return false end
      local currentReadOk, currentPtr = checkedCall(function() return readPointerLocalCompat(slotPtr) end)
      if not currentReadOk or type(currentPtr) ~= 'number' then
        lastSlotError = 'cannot read resource pointer for ' .. tostring(entry.source) .. ' at ' .. string.format('%X', slotPtr)
        return false
      elseif currentPtr == sourcePtr then
        slotPtrs[#slotPtrs + 1] = slotPtr
        slotPtrSeen[slotPtr] = true
        return true
      else
        local currentLen = safeCall(function() return readFpcAnsiStringLength(currentPtr) end)
        if type(currentLen) ~= 'number' or currentLen <= 0 or currentLen > 512 then
          currentLen = math.max(#entry.source, #entry.translated)
        end
        local currentText = safeCall(function() return readStringLocal(currentPtr, currentLen, false) end)
        if currentText == entry.source or currentText == entry.translated then
          slotPtrs[#slotPtrs + 1] = slotPtr
          slotPtrSeen[slotPtr] = true
          return true
        else
          lastSlotError = string.format('unexpected resource pointer for %s at %X -> %X', entry.source, slotPtr, currentPtr)
          return false
        end
      end
    end

    local slotDeltas = is64 and (entry.textToCurrentSlotDeltas64 or { entry.textToCurrentSlotDelta }) or entry.textToCurrentSlotDeltas32
    if type(slotDeltas) == 'table' then
      for _, delta in ipairs(slotDeltas) do
        addResourceSlotIfValid(sourcePtr - delta)
      end
    end

    if #slotPtrs == 0 then
      local moduleName = GLOBAL_STATE.nativeHookModule or getSelfModuleForAOBScan()
      local slotPtr = aobScanSelfModulePointerValue(moduleName, sourcePtr, entry.scanSymbol .. 'Slot')
      addResourceSlotIfValid(slotPtr)
    end

    if #slotPtrs == 0 and _G.zhCNFormDesignerScanResourceSlots == true then
      local moduleName = GLOBAL_STATE.nativeHookModule or getSelfModuleForAOBScan()
      local scannedSlots = scanSelfModuleForPointerValue(moduleName, sourcePtr, 16)
      for _, slotPtr in ipairs(scannedSlots) do
        addResourceSlotIfValid(slotPtr)
      end
    end

    if #slotPtrs == 0 then
      return false, lastSlotError or ('no matching resource pointer slot for ' .. tostring(entry.source))
    end
    GLOBAL_STATE.oiMenuResourcePatchSlotCounts[entry.source] = #slotPtrs

    cursor = base + alignUp(cursor - base, 16)
    local headerAddress = cursor
    local textAddress = headerAddress + fpcAnsiStringHeaderSize()
    local textBytes = fpcAnsiStringBytes(entry.translated)
    local writeTextOk = writeSucceeded(function() return writeBytesLocal(headerAddress, textBytes) end)
    local writeSlotsOk = writeTextOk
    for _, slotPtr in ipairs(slotPtrs) do
      writeSlotsOk = writeSlotsOk and writeSucceeded(function() return writePointerLocalCompat(slotPtr, textAddress) end)
    end
    if not writeTextOk or not writeSlotsOk then
      return false, 'write failed at resource entry ' .. tostring(i) .. ' (' .. tostring(entry.source) .. ')'
    end

    verifyChecked = verifyChecked + #slotPtrs
    local readLen = safeCall(function() return readFpcAnsiStringLength(textAddress) end)
    local readText = safeCall(function() return readStringLocal(textAddress, #entry.translated, false) end)
    for _, slotPtr in ipairs(slotPtrs) do
      local readSlot = safeCall(function() return readPointerLocalCompat(slotPtr) end)
      if readSlot ~= textAddress or readLen ~= #entry.translated or readText ~= entry.translated then
        verifyFailed = verifyFailed + 1
      end
    end

    cursor = base + alignUp((headerAddress + #textBytes) - base, 16)
    writtenBytes = cursor - base
    if writtenBytes > OI_MENU_RESOURCE_DATA_SIZE then
      return false, 'resource data block too small: ' .. tostring(writtenBytes) .. ' bytes'
    end
  end

  GLOBAL_STATE.oiMenuResourcePatchDataBytes = writtenBytes
  GLOBAL_STATE.oiMenuResourcePatchDataVerify = tostring(verifyFailed) .. '/' .. tostring(verifyChecked)
  if verifyFailed > 0 then
    GLOBAL_STATE.oiMenuResourcePatchDataPopulated = false
    return false, 'verify failed: ' .. GLOBAL_STATE.oiMenuResourcePatchDataVerify
  end
  GLOBAL_STATE.oiMenuResourcePatchDataPopulated = true
  return true, writtenBytes
end

-- 安装对象检查器菜单资源字符串修补。
local function installObjectInspectorMenuResourceStringPatch()
  local totalStart = nativeHookNowMs()
  local timings = {}
  local stepStart

  stepStart = nativeHookNowMs()
  if getSelfAddressSafe('zhOIResourceStringPatch') then
    addNativeHookTiming(timings, 'symbol-check', stepStart, 'already installed')
    if not GLOBAL_STATE.oiMenuResourcePatchDataPopulated then
      stepStart = nativeHookNowMs()
      local dataOk, dataResult = populateObjectInspectorMenuResourcePatchData()
      addNativeHookTiming(timings, 'data-write', stepStart,
        'ok=' .. tostring(dataOk == true) ..
        ',bytes=' .. tostring(dataResult) ..
        ',verifyFailed=' .. tostring(GLOBAL_STATE.oiMenuResourcePatchDataVerify or '?'))
      if not dataOk then
        GLOBAL_STATE.oiMenuResourcePatchInstalled = false
        GLOBAL_STATE.oiMenuResourcePatchError = dataResult
        finishNativeHookTiming('ObjectInspectorMenuResources data failed', timings, totalStart)
        return false
      end
    end

    GLOBAL_STATE.oiMenuResourcePatchInstalled = true
    refreshObjectInspectorsAfterNativeHook()
    finishNativeHookTiming('ObjectInspectorMenuResources', timings, totalStart)
    return true
  end
  addNativeHookTiming(timings, 'symbol-check', stepStart, 'not installed')

  stepStart = nativeHookNowMs()
  local moduleName = getSelfModuleForAOBScan()
  addNativeHookTiming(timings, 'module-detect', stepStart, moduleName)

  stepStart = nativeHookNowMs()
  local aa = buildObjectInspectorMenuResourcePatchAA(moduleName)
  addNativeHookTiming(timings, 'aa-build', stepStart,
    'module=' .. tostring(moduleName) ..
    ',bytes=' .. tostring(#aa) ..
    ',entries=' .. tostring(#OI_MENU_RESOURCE_STRINGS))

  stepStart = nativeHookNowMs()
  local ok, result = pcall(function() return autoAssemble(aa, true) end)
  addNativeHookTiming(timings, 'autoAssemble', stepStart,
    'module=' .. tostring(moduleName) ..
    ',ok=' .. tostring(ok and result ~= false))

  if ok and result ~= false then
    stepStart = nativeHookNowMs()
    local dataOk, dataResult = populateObjectInspectorMenuResourcePatchData()
    addNativeHookTiming(timings, 'data-write', stepStart,
      'ok=' .. tostring(dataOk == true) ..
      ',bytes=' .. tostring(dataResult) ..
      ',verifyFailed=' .. tostring(GLOBAL_STATE.oiMenuResourcePatchDataVerify or '?'))
    if not dataOk then
      GLOBAL_STATE.oiMenuResourcePatchInstalled = false
      GLOBAL_STATE.oiMenuResourcePatchError = dataResult
      finishNativeHookTiming('ObjectInspectorMenuResources data failed', timings, totalStart)
      return false
    end

    GLOBAL_STATE.nativeHookModule = moduleName
    GLOBAL_STATE.oiMenuResourcePatchInstalled = true
    GLOBAL_STATE.oiMenuResourcePatchError = nil
    refreshObjectInspectorsAfterNativeHook()
    finishNativeHookTiming('ObjectInspectorMenuResources', timings, totalStart)
    return true
  end

  GLOBAL_STATE.oiMenuResourcePatchInstalled = false
  GLOBAL_STATE.oiMenuResourcePatchError = result
  finishNativeHookTiming('ObjectInspectorMenuResources failed', timings, totalStart)
  return false
end

-- 安装对象检查器属性名绘制层原生 Hook。
local function installNativePropDrawNameHook()
  local totalStart = nativeHookNowMs()
  local timings = {}
  local stepStart

  stepStart = nativeHookNowMs()
  if getSelfAddressSafe('zhOIPropDrawNameHook') then
    addNativeHookTiming(timings, 'symbol-check', stepStart, 'already installed')
    if not GLOBAL_STATE.nativePropDrawNameDataPopulated then
      stepStart = nativeHookNowMs()
      local _, entries = buildPropDrawNameHookAA(GLOBAL_STATE.nativeHookModule or getSelfModuleForAOBScan())
      addNativeHookTiming(timings, 'aa-build-for-data', stepStart,
        'entries=' .. tostring(GLOBAL_STATE.nativePropDrawNameEntryCount or '?') ..
        ',mode=' .. tostring(GLOBAL_STATE.nativePropDrawNameCompareMode or '?'))

      stepStart = nativeHookNowMs()
      local dataOk, dataResult = populatePropDrawNameData(entries or {})
      addNativeHookTiming(timings, 'data-write', stepStart,
        'ok=' .. tostring(dataOk == true) ..
        ',bytes=' .. tostring(dataResult) ..
        ',verifyFailed=' .. tostring(GLOBAL_STATE.nativePropDrawNameDataVerify or '?'))
      if not dataOk then
        GLOBAL_STATE.nativeHookInstalled = false
        GLOBAL_STATE.nativeHookError = dataResult
        finishNativeHookTiming('PropDrawName data failed', timings, totalStart)
        return false
      end
    end

    GLOBAL_STATE.nativeHookInstalled = true
    refreshObjectInspectorsAfterNativeHook()
    finishNativeHookTiming('PropDrawName', timings, totalStart)
    return true
  end
  addNativeHookTiming(timings, 'symbol-check', stepStart, 'not installed')

  stepStart = nativeHookNowMs()
  local moduleName = getSelfModuleForAOBScan()
  addNativeHookTiming(timings, 'module-detect', stepStart, moduleName)

  stepStart = nativeHookNowMs()
  local aa, entries = buildPropDrawNameHookAA(moduleName)
  addNativeHookTiming(timings, 'aa-build', stepStart,
    'module=' .. tostring(moduleName) ..
    ',bytes=' .. tostring(#aa) ..
    ',entries=' .. tostring(GLOBAL_STATE.nativePropDrawNameEntryCount or '?') ..
    ',mode=' .. tostring(GLOBAL_STATE.nativePropDrawNameCompareMode or '?'))

  stepStart = nativeHookNowMs()
  local ok, result = pcall(function() return autoAssemble(aa, true) end)
  addNativeHookTiming(timings, 'autoAssemble', stepStart,
    'module=' .. tostring(moduleName) ..
    ',ok=' .. tostring(ok and result ~= false))

  if ok and result ~= false then
    stepStart = nativeHookNowMs()
    local dataOk, dataResult = populatePropDrawNameData(entries or {})
    addNativeHookTiming(timings, 'data-write', stepStart,
      'ok=' .. tostring(dataOk == true) ..
      ',bytes=' .. tostring(dataResult) ..
      ',verifyFailed=' .. tostring(GLOBAL_STATE.nativePropDrawNameDataVerify or '?'))
    if not dataOk then
      GLOBAL_STATE.nativeHookInstalled = false
      GLOBAL_STATE.nativeHookError = dataResult
      finishNativeHookTiming('PropDrawName data failed', timings, totalStart)
      return false
    end

    GLOBAL_STATE.nativeHookInstalled = true
    GLOBAL_STATE.nativeHookError = nil
    GLOBAL_STATE.nativeHookModule = moduleName
    refreshObjectInspectorsAfterNativeHook()
    finishNativeHookTiming('PropDrawName', timings, totalStart)
    return true
  end

  GLOBAL_STATE.nativeHookInstalled = false
  GLOBAL_STATE.nativeHookError = result or 'aobscanmodule failed'
  finishNativeHookTiming('PropDrawName failed', timings, totalStart)
  return GLOBAL_STATE.nativeHookInstalled
end

-- 安装轻量级窗体设计器汉化入口。
local function installFormDesignerLightTranslator()
  GLOBAL_STATE.installed = true
  installObjectInspectorStaticTextHooks()
end

-- 安装默认启用的窗体设计器原生 Hook。
installFormDesignerDefaultNativeHooks = function()
  if not zhCNNativeHooksEnabled() then return false end
  if GLOBAL_STATE.defaultNativeHooksInstalled and
     GLOBAL_STATE.nativeHookInstalled and
     GLOBAL_STATE.oiMenuResourcePatchInstalled then
    return true
  end
  GLOBAL_STATE.defaultNativeHooksInstalled = true

  local nameOk = installNativePropDrawNameHook()
  local staticResourceOk = installObjectInspectorStaticResourceStringPatch()
  local menuResourceOk = installObjectInspectorMenuResourceStringPatch()
  return nameOk == true and staticResourceOk == true and menuResourceOk == true
end

-- 对外暴露的窗体设计器原生 Hook 安装入口。
local function installFormDesignerNativeHooks()
  return installFormDesignerDefaultNativeHooks()
end

-- 安装窗体设计器完整汉化逻辑。
local function installFormDesignerTranslator()
  installFormDesignerLightTranslator()
  installFormDesignerDefaultNativeHooks()
end

-- 启动时安装窗体设计器汉化。
local function installFormDesignerTranslatorOnStartup()
  if GLOBAL_STATE.startupInstallScheduled then return end
  GLOBAL_STATE.startupInstallScheduled = true
  local ok, err = pcall(installFormDesignerLightTranslator)
  if not ok then
    GLOBAL_STATE.startupInstallScheduled = false
    error(err)
  end
end

_G.zhCNFormDesignerInstallLightTranslator = installFormDesignerLightTranslator
_G.zhCNFormDesignerInstallNativeNameHook = installNativePropDrawNameHook
_G.zhCNFormDesignerInstallMenuResourceStringPatch = installObjectInspectorMenuResourceStringPatch
_G.zhCNFormDesignerInstallDefaultNativeHooks = installFormDesignerDefaultNativeHooks
_G.zhCNFormDesignerInstallNativeHooks = installFormDesignerNativeHooks
_G.zhCNFormDesignerInstallTranslator = installFormDesignerTranslator

installFormDesignerTranslatorOnStartup()
