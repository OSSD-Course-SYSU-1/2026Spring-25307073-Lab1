# 基于Canvas实现抽奖转盘功能

### 简介

基于画布组件，实现自定义抽奖转盘功能。效果如图所示：

<img src="./screenshots/device/canvas.gif" width="320">

### 相关概念

- Stack组件：堆叠容器，子组件按照顺序依次入栈，后一个子组件覆盖前一个子组件。
- Canvas：画布组件，用于自定义绘制图形。
- CanvasRenderingContext2D对象：使用RenderingContext在Canvas组件上进行绘制，绘制对象可以是矩形、文本、图片等。
- 显式动画：提供全局animateTo显式动画接口来指定由于闭包代码导致的状态变化插入过渡动效。
- 自定义弹窗： 通过CustomDialogController类显示自定义弹窗。

### 使用说明

1. 点击圆形转盘中**开始**抽奖图标，圆形转盘开始转动抽奖。
2. 转盘停止转动后，抽奖结束，弹出抽中的文本和图片信息。

### 工程目录
```
├──entry/src/main/ets	            // 代码区
│  ├──common
│  │  ├──constants
│  │  │  ├──ColorConstants.ets      // 颜色常量类
│  │  │  ├──CommonConstants.ets     // 公共常量类 
│  │  │  └──StyleConstants.ets      // 样式常量类 
│  │  └──utils
│  │     ├──CheckEmptyUtils.ets     // 数据判空工具类
│  │     └──Logger.ets              // 日志打印类
│  ├──entryability
│  │  └──EntryAbility.ts            // 程序入口类
│  ├──pages
│  │  └──CanvasPage.ets             // 主界面	
│  ├──view
│  │  └──PrizeDialog.ets            // 中奖信息弹窗类
│  └──viewmodel
│     ├──DrawModel.ets              // 画布相关方法类
│     ├──FillArcData.ets            // 绘制圆弧数据实体类
│     └──PrizeData.ets              // 中奖信息实体类
└──entry/src/main/resources         // 资源文件目录
```

### 相关权限

不涉及

### 约束与限制

1. 本示例仅支持标准系统上运行，支持设备：直板机。
2. HarmonyOS系统：HarmonyOS 5.0.5 Release及以上。
3. DevEco Studio版本：DevEco Studio 6.0.2 Release及以上。
4. HarmonyOS SDK版本：HarmonyOS 6.0.2 Release SDK及以上。
