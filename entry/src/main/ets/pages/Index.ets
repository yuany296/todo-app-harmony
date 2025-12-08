// Index.ets
import { Constants } from '../common/Constants';
import { TodoPage } from './TodoPage';
import { FocusTimerPage } from './FocusTimerPage';
import { StatisticsPage } from './StatisticsPage';
import { TodoItem } from '../Types/ToDoItem';
import { AddTodoDialog } from './AddTodoDialog'; // 引入弹窗组件
import { savePlanList, loadPlanList } from '../common/PreferenceHelper';

@Entry
@Component
struct MainTabPage {
  @State currentIndex: number = Constants.TAB_INDEX_ZERO;
  private tabsController: TabsController = new TabsController();
  // 待办事项列表
  @State planList: TodoItem[] = [
    {
      id: 1,
      name: '练字',
      deadline: new Date(Date.now() + 86400000).toISOString(),
      total_time: 0,
      isFinished: false
    },
    {
      id: 2,
      name: '写作业',
      deadline: new Date(Date.now() + 172800000).toISOString(),
      total_time: 0,
      isFinished: false
    },
    {
      id: 3,
      name: '读书',
      deadline: new Date(Date.now() + 259200000).toISOString(),
      total_time: 0,
      isFinished: true
    },
    {
      id: 4,
      name: '学习',
      deadline: new Date(Date.now() + 345600000).toISOString(),
      total_time: 0,
      isFinished: false
    }
  ];
  // 弹窗控制状态
  @State isAddDialogVisible: boolean = false;

  @Builder
  PageBuilder(index: number) {
    if (index === Constants.TAB_INDEX_ZERO) {
      TodoPage({
        planList: $planList, // 传递双向绑定
        onAddButtonClick: this.openAddDialog.bind(this),
        onUpdate: this.handleUpdateFromChild.bind(this),
        onDelete: this.handleDeleteFromChild.bind(this),
        onToggle: this.handleToggleFromChild.bind(this)
      })
    } else if (index === Constants.TAB_INDEX_ONE) {
      FocusTimerPage({
        planList: $planList // 传递双向绑定，使两个页面共享待办列表
      })
    } else {
      StatisticsPage({
        planList: $planList
      })
    }
  }

  // 添加待办事项
  private addTodoToList(item: TodoItem): void {
    // 更新状态，触发 UI 刷新
    this.planList = [...this.planList, item];
    // 保存到偏好存储
    savePlanList(this.planList);
    console.log('添加成功，当前列表长度:', this.planList.length);
  }

  // 来自子组件的更新回调（编辑保存）
  private handleUpdateFromChild(updatedItem: TodoItem): void {
    console.log('handleUpdateFromChild called for id:', updatedItem.id, 'name:', updatedItem.name);
    const idx = this.planList.findIndex(item => item.id === updatedItem.id);
    if (idx >= 0) {
      const newList = this.planList.slice();
      newList[idx] = updatedItem;
      this.planList = newList;
      // 保存修改
      savePlanList(this.planList);
    }
  }

  // 来自子组件的删除回调
  private handleDeleteFromChild(id: number): void {
    console.log('handleDeleteFromChild called for id:', id);
    this.planList = this.planList.filter(item => item.id !== id);
    savePlanList(this.planList);
  }

  // 来自子组件的完成切换回调
  private handleToggleFromChild(id: number): void {
    console.log('handleToggleFromChild called for id:', id);
    // 虽然子组件已经通过 @Link 更新了，但为了确保状态同步，这里也更新一次
    const idx = this.planList.findIndex(item => item.id === id);
    if (idx >= 0) {
      // 创建新数组和新对象，确保触发更新
      const newList = this.planList.map((item, index) => {
        if (index === idx) {
          return {
            id: item.id,
            name: item.name,
            deadline: item.deadline,
            total_time: item.total_time,
            isFinished: !item.isFinished
          };
        }
        return item;
      });
      this.planList = [...newList];
      savePlanList(this.planList);
    }
  }

  aboutToAppear() {
    // 尝试从偏好加载已保存的待办列表（若存在）
    loadPlanList().then((list) => {
      if (list && Array.isArray(list) && list.length > 0) {
        this.planList = list as TodoItem[];
        console.log('Loaded planList from preferences, length=', this.planList.length);
      }
    }).catch((e: Error) => {
      console.warn('Failed to load preferences planList', e);
    });
  }

  // 打开添加弹窗
  private openAddDialog(): void {
    this.isAddDialogVisible = true;
  }

  // 关闭添加弹窗
  private closeAddDialog(): void {
    this.isAddDialogVisible = false;
  }

  @Builder
  TabBarBuilder(title: string, index: number, selectedIcon: Resource, normalIcon: Resource) {
    Column() {
      Image(this.currentIndex === index ? selectedIcon : normalIcon)
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)

      Text(title)
        .margin({ top: 4 })
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#666666')
    }
    .justifyContent(FlexAlign.Center)
    .height(52)
    .width('100%')
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(this.currentIndex);
    })
  }

  build() {
    Stack() {
      Column() {
        Tabs({
          barPosition: BarPosition.End,
          controller: this.tabsController
        }) {
          TabContent() {
            this.PageBuilder(Constants.TAB_INDEX_ZERO)
          }
          .tabBar(this.TabBarBuilder('待办', Constants.TAB_INDEX_ZERO,
            $r('app.media.todo_active'), $r('app.media.todo')))

          TabContent() {
            this.PageBuilder(Constants.TAB_INDEX_ONE)
          }
          .tabBar(this.TabBarBuilder('专注', Constants.TAB_INDEX_ONE,
            $r('app.media.timer_active'), $r('app.media.timer')))

          TabContent() {
            this.PageBuilder(Constants.TAB_INDEX_TWO)
          }
          .tabBar(this.TabBarBuilder('统计', Constants.TAB_INDEX_TWO,
            $r('app.media.stats_active'), $r('app.media.stats')))
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .barHeight(52)
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      }
      .width('100%')
      .height('100%')

      // 添加待办弹窗
      if (this.isAddDialogVisible) {
        AddTodoDialog({
          onConfirm: (item: TodoItem) => {
            this.addTodoToList(item);
            this.closeAddDialog();
          },
          onCancel: () => {
            this.closeAddDialog();
          }
        })
      }
    }
  }
}