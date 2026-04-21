if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface CanvasPage_Params {
    settings?: RenderingContextSettings;
    canvasContext?: CanvasRenderingContext2D;
    drawModel?: DrawModel;
    screenWidth?: number;
    screenHeight?: number;
    rotateDegree?: number;
    enableFlag?: boolean;
    prizeData?: PrizeData;
    dialogController?: CustomDialogController;
    currentLang?: string;
    lastLang?: string;
    subscriber?: commonEventManager.CommonEventSubscriber | null;
}
import window from "@ohos:window";
import Logger from "@bundle:com.example.canvascomponent/entry/ets/common/utils/Logger";
import DrawModel from "@bundle:com.example.canvascomponent/entry/ets/viewmodel/DrawModel";
import PrizeDialog from "@bundle:com.example.canvascomponent/entry/ets/view/PrizeDialog";
import PrizeData from "@bundle:com.example.canvascomponent/entry/ets/viewmodel/PrizeData";
import StyleConstants from "@bundle:com.example.canvascomponent/entry/ets/common/constants/StyleConstants";
import CommonConstants from "@bundle:com.example.canvascomponent/entry/ets/common/constants/CommonConstants";
import type { Context } from "@ohos:abilityAccessCtrl";
import type { BusinessError } from "@ohos:base";
import commonEventManager from "@ohos:commonEventManager";
import i18n from "@ohos:i18n";
// Get context.
const uiContext: UIContext | undefined = AppStorage.get('uiContext');
let context: Context = uiContext!.getHostContext()!;
class CanvasPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.settings = new RenderingContextSettings(true);
        this.canvasContext = new CanvasRenderingContext2D(this.settings);
        this.__drawModel = new ObservedPropertyObjectPU(new DrawModel(), this, "drawModel");
        this.__screenWidth = new ObservedPropertySimplePU(0, this, "screenWidth");
        this.__screenHeight = new ObservedPropertySimplePU(0, this, "screenHeight");
        this.__rotateDegree = new ObservedPropertySimplePU(0, this, "rotateDegree");
        this.__enableFlag = new ObservedPropertySimplePU(true, this, "enableFlag");
        this.__prizeData = new ObservedPropertyObjectPU(new PrizeData(), this, "prizeData");
        this.dialogController = new CustomDialogController({
            builder: () => {
                let jsDialog = new PrizeDialog(this, {
                    prizeData: this.__prizeData,
                    enableFlag: this.__enableFlag
                }, undefined, -1, () => { }, { page: "entry/src/main/ets/pages/CanvasPage.ets", line: 43, col: 14 });
                jsDialog.setController(this.dialogController);
                ViewPU.create(jsDialog);
                let paramsLambda = () => {
                    return {
                        prizeData: this.__prizeData,
                        enableFlag: this.__enableFlag
                    };
                };
                jsDialog.paramsGenerator_ = paramsLambda;
            },
            autoCancel: false,
            alignment: DialogAlignment.Center,
            cancel: () => {
                this.enableFlag = !this.enableFlag;
            }
        }, this);
        this.currentLang = 'zh-Hans';
        this.lastLang = 'zh-Hans';
        this.subscriber = null;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: CanvasPage_Params) {
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.canvasContext !== undefined) {
            this.canvasContext = params.canvasContext;
        }
        if (params.drawModel !== undefined) {
            this.drawModel = params.drawModel;
        }
        if (params.screenWidth !== undefined) {
            this.screenWidth = params.screenWidth;
        }
        if (params.screenHeight !== undefined) {
            this.screenHeight = params.screenHeight;
        }
        if (params.rotateDegree !== undefined) {
            this.rotateDegree = params.rotateDegree;
        }
        if (params.enableFlag !== undefined) {
            this.enableFlag = params.enableFlag;
        }
        if (params.prizeData !== undefined) {
            this.prizeData = params.prizeData;
        }
        if (params.dialogController !== undefined) {
            this.dialogController = params.dialogController;
        }
        if (params.currentLang !== undefined) {
            this.currentLang = params.currentLang;
        }
        if (params.lastLang !== undefined) {
            this.lastLang = params.lastLang;
        }
        if (params.subscriber !== undefined) {
            this.subscriber = params.subscriber;
        }
    }
    updateStateVars(params: CanvasPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__drawModel.purgeDependencyOnElmtId(rmElmtId);
        this.__screenWidth.purgeDependencyOnElmtId(rmElmtId);
        this.__screenHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__rotateDegree.purgeDependencyOnElmtId(rmElmtId);
        this.__enableFlag.purgeDependencyOnElmtId(rmElmtId);
        this.__prizeData.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__drawModel.aboutToBeDeleted();
        this.__screenWidth.aboutToBeDeleted();
        this.__screenHeight.aboutToBeDeleted();
        this.__rotateDegree.aboutToBeDeleted();
        this.__enableFlag.aboutToBeDeleted();
        this.__prizeData.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private settings: RenderingContextSettings;
    private canvasContext: CanvasRenderingContext2D;
    private __drawModel: ObservedPropertyObjectPU<DrawModel>;
    get drawModel() {
        return this.__drawModel.get();
    }
    set drawModel(newValue: DrawModel) {
        this.__drawModel.set(newValue);
    }
    private __screenWidth: ObservedPropertySimplePU<number>;
    get screenWidth() {
        return this.__screenWidth.get();
    }
    set screenWidth(newValue: number) {
        this.__screenWidth.set(newValue);
    }
    private __screenHeight: ObservedPropertySimplePU<number>;
    get screenHeight() {
        return this.__screenHeight.get();
    }
    set screenHeight(newValue: number) {
        this.__screenHeight.set(newValue);
    }
    private __rotateDegree: ObservedPropertySimplePU<number>;
    get rotateDegree() {
        return this.__rotateDegree.get();
    }
    set rotateDegree(newValue: number) {
        this.__rotateDegree.set(newValue);
    }
    private __enableFlag: ObservedPropertySimplePU<boolean>;
    get enableFlag() {
        return this.__enableFlag.get();
    }
    set enableFlag(newValue: boolean) {
        this.__enableFlag.set(newValue);
    }
    private __prizeData: ObservedPropertyObjectPU<PrizeData>;
    get prizeData() {
        return this.__prizeData.get();
    }
    set prizeData(newValue: PrizeData) {
        this.__prizeData.set(newValue);
    }
    private dialogController: CustomDialogController;
    private currentLang: string;
    private lastLang: string;
    private subscriber: commonEventManager.CommonEventSubscriber | null;
    aboutToAppear() {
        // Obtains the width and height of the screen, excluding the height of the navigation view.
        window.getLastWindow(context)
            .then((windowClass: window.Window) => {
            windowClass.setWindowLayoutFullScreen(true);
            let windowProperties = windowClass.getWindowProperties();
            this.screenWidth = this.getUIContext().px2vp(windowProperties.windowRect.width);
            this.screenHeight = this.getUIContext().px2vp(windowProperties.windowRect.height);
        })
            .catch((error: Error) => {
            Logger.error('Failed to obtain the window size. Cause: ' + JSON.stringify(error));
        });
        let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
            events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
        };
        commonEventManager.createSubscriber(subscribeInfo)
            .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
            this.subscriber = commonEventSubscriber;
            commonEventManager.subscribe(this.subscriber, (err) => {
                if (err) {
                    Logger.error(`Failed to subscribe common event. errorCode=${err.code}, errorMessage=${err.message}`);
                    return;
                }
                this.currentLang = i18n.System.getSystemLanguage();
            });
        })
            .catch((err: BusinessError) => {
            Logger.error(`CreateSubscriber failed, errorCode=${err.code}, errorMessage=${err.message}}`);
        });
    }
    onPageShow(): void {
        if (this.lastLang != this.currentLang) {
            this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
        }
    }
    onPageHide(): void {
        this.lastLang = i18n.System.getSystemLanguage();
    }
    aboutToDisappear(): void {
        if (this.subscriber) {
            commonEventManager.unsubscribe(this.subscriber, (err: BusinessError) => {
                if (!err) {
                    this.subscriber = null;
                }
            });
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create({ alignContent: Alignment.Center });
            Stack.width(StyleConstants.FULL_PERCENT);
            Stack.height(StyleConstants.FULL_PERCENT);
            Stack.backgroundImage({ "id": 16777239, "type": 20000, params: [], "bundleName": "com.example.canvascomponent", "moduleName": "entry" }, ImageRepeat.NoRepeat);
            Stack.backgroundImageSize({
                width: StyleConstants.FULL_PERCENT,
                height: StyleConstants.BACKGROUND_IMAGE_SIZE
            });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.canvasContext);
            Canvas.width(StyleConstants.FULL_PERCENT);
            Canvas.height(StyleConstants.FULL_PERCENT);
            Canvas.onReady(() => {
                this.drawModel.draw(this.canvasContext, this.screenWidth, this.screenHeight);
            });
            Canvas.rotate({
                x: 0,
                y: 0,
                z: 1,
                angle: this.rotateDegree,
                centerX: this.screenWidth / CommonConstants.TWO,
                centerY: this.screenHeight / CommonConstants.TWO
            });
        }, Canvas);
        Canvas.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777241, "type": 20000, params: [], "bundleName": "com.example.canvascomponent", "moduleName": "entry" });
            Image.width(StyleConstants.CENTER_IMAGE_WIDTH);
            Image.height(StyleConstants.CENTER_IMAGE_HEIGHT);
            Image.enabled(this.enableFlag);
            Image.onClick(() => {
                this.enableFlag = !this.enableFlag;
                this.startAnimator();
            });
        }, Image);
        Stack.pop();
    }
    /**
     * Start animator.
     */
    startAnimator() {
        let randomAngle = Math.round(Math.random() * CommonConstants.CIRCLE);
        // Obtaining prize information.
        this.prizeData = this.drawModel.showPrizeData(randomAngle);
        this.getUIContext().animateTo({
            duration: CommonConstants.DURATION,
            curve: Curve.Ease,
            delay: 0,
            iterations: 1,
            playMode: PlayMode.Normal,
            onFinish: () => {
                this.rotateDegree = CommonConstants.ANGLE - randomAngle;
                // Display prize information pop-up window.
                this.dialogController.open();
            }
        }, () => {
            this.rotateDegree = CommonConstants.CIRCLE * CommonConstants.FIVE +
                CommonConstants.ANGLE - randomAngle;
        });
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "CanvasPage";
    }
}
registerNamedRoute(() => new CanvasPage(undefined, {}), "", { bundleName: "com.example.canvascomponent", moduleName: "entry", pagePath: "pages/CanvasPage", pageFullPath: "entry/src/main/ets/pages/CanvasPage", integratedHsp: "false", moduleType: "followWithHap" });
