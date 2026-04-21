# Custom Prize Wheel

### Introduction

Learn how to customize a prize wheel based on the canvas component. Example:

<img src="./screenshots/device/canvas_en.gif" width="320">

### Concepts

- Stack: a component that allows child components to be successively stacked, with the latter one overwriting the previous one.
- Canvas: a component that is used to customize drawings.
- CanvasRenderingContext2D: a component that uses **RenderingContext** to draw rectangles, text, images, and other objects on a canvas.
- Explicit animation (**animateTo**): a transition animation when the status changes due to the closure code.
- Custom dialog box: a custom dialog box that is displayed by using the **CustomDialogController** class.

### How to Use

1. Tap the Start icon on the round wheel to start the lucky draw.
2. After the prize wheel stops spinning, the lucky draw ends, with its text and images displayed.

### Project Directory
```
├──entry/src/main/ets	            // Code area
│  ├──common
│  │  ├──constants
│  │  │  ├──ColorConstants.ets      // Color constant class
│  │  │  ├──CommonConstants.ets     // Public constant class
│  │  │  └──StyleConstants.ets      // Style constant class
│  │  └──utils
│  │     ├──CheckEmptyUtils.ets     // Data null detection tool class
│  │     └──Logger.ets              // Log printing class
│  ├──entryability
│  │  └──EntryAbility.ts            // Program entrance class
│  ├──pages
│  │  └──CanvasPage.ets             // Main Interface	
│  ├──view
│  │  └──PrizeDialog.ets            // Winning information pop-up category
│  └──viewmodel
│     ├──DrawModel.ets              // Canvas related method classes
│     ├──FillArcData.ets            // Draw arc data entity class
│     └──PrizeData.ets              // Winning information entity class
└──entry/src/main/resources         // Application resources
```

### Permissions

N/A

### Constraints

1. The sample is only supported on Huawei phones with standard systems.
2. HarmonyOS: HarmonyOS 5.0.5 Release or later.
3. DevEco Studio: DevEco Studio 6.0.2 Release or later.
4. HarmonyOS SDK: HarmonyOS 6.0.2 Release SDK or later.