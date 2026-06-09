/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    this.initStorage();
    this.restoreContinueData(want);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/CanvasPage', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      AppStorage.setOrCreate('uiContext', windowStage.getMainWindowSync().getUIContext());
    });
  }

  onNewWant(want: Want) {
    this.restoreContinueData(want);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onNewWant');
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    wantParam['currentIndex'] = AppStorage.get<number>('currentIndex') || 0;
    wantParam['wheelHistory'] = AppStorage.get<string>('wheel_history') || '';
    wantParam['lastCheckIn'] = AppStorage.get<string>('last_checkin') || '';
    wantParam['checkInStreak'] = AppStorage.get<number>('checkin_streak') || 0;
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onContinue');
    return AbilityConstant.OnContinueResult.AGREE;
  }

  private initStorage(): void {
    AppStorage.setOrCreate('currentIndex', AppStorage.get<number>('currentIndex') || 0);
    PersistentStorage.persistProp('wheel_history', '');
    PersistentStorage.persistProp('last_checkin', '');
    PersistentStorage.persistProp('checkin_streak', 0);
  }

  private restoreContinueData(want: Want): void {
    if (want === undefined || want.parameters === undefined) {
      return;
    }
    const params = want.parameters;
    if (params['currentIndex'] !== undefined) {
      AppStorage.setOrCreate('currentIndex', params['currentIndex'] as number);
    }
    if (params['wheelHistory'] !== undefined) {
      AppStorage.setOrCreate('wheel_history', params['wheelHistory'] as string);
    }
    if (params['lastCheckIn'] !== undefined) {
      AppStorage.setOrCreate('last_checkin', params['lastCheckIn'] as string);
    }
    if (params['checkInStreak'] !== undefined) {
      AppStorage.setOrCreate('checkin_streak', params['checkInStreak'] as number);
    }
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
