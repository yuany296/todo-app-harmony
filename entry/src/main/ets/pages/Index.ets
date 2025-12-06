// Index.ets (请用此代码替换全部内容)
import { Constants } from '../common/Constants';
import { TodoPage } from './TodoPage';
import { FocusTimerPage } from './FocusTimerPage';
import { StatisticsPage } from './StatisticsPage';
import { TodoItem } from '../Types/ToDoItem'; // 引入 TodoItem
import router from '@ohos.router';

@Entry
@Component
struct MainTabPage {
  @State currentIndex: number = Constants.TAB_INDEX_ZERO;
  private tabsController: TabsController = new TabsController();
  // 🚨 状态提升：将 planList 移动到最外层页面
  @State planList: TodoItem[] = [
    { id: 1, plan: '单机完成', isFinished: false },
    { id: 2, plan: '双击设置', isFinished: false },
    { id: 3, plan: '添加更多功能', isFinished: true },
    { id: 4, plan: '优化界面设计', isFinished: false }
  ];

  // 🚨 新增：处理路由返回参数和添加逻辑
  onPageShow() {
    console.log('MainTabPage页面显示，检查是否有返回的新待办事项');

    interface RouterParams {
      newTodoPlan?: string;
      operation?: string;
      timestamp?: number;
    }

    const params = router.getParams() as RouterParams;

    if (params && params.newTodoPlan && params.operation === 'add') {
      console.log('接收到新待办内容:', params.newTodoPlan);

      this.addTodoToList(params.newTodoPlan); // 调用新增方法

      // 清空路由参数，避免重复添加
      setTimeout(() => {
        console.log('清空路由参数');
        router.replaceUrl({
          url: 'pages/Index',
          params: {}
        });
      }, 100);
    } else {
      console.log('没有新待办数据或不是添加操作');
    }
  }

  // 🚨 新增：添加待办到列表的逻辑
  private addTodoToList(planText: string): void {
    let maxId = 0;
    if (this.planList && this.planList.length > 0) {
      maxId = this.planList.reduce((max, item) => item.id > max ? item.id : max, 0);
    }

    const finalTodo: TodoItem = {
      id: maxId + 1,
      plan: planText,
      isFinished: false
    };

    // 更新状态，触发 UI 刷新
    this.planList = [...this.planList, finalTodo];
    console.log('添加成功，当前列表长度（添加后）:', this.planList.length);
  }

  @Builder
  PageBuilder(index: number) {
    if (index === Constants.TAB_INDEX_ZERO) {
      // 🚨 核心修复：将 planList 传给 TodoPage
      TodoPage({ planList: this.planList })
    } else if (index === Constants.TAB_INDEX_ONE) {
      FocusTimerPage()
    } else {
      StatisticsPage()
    }
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
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      // 这里的 TabContent 是系统组件
      TabContent() {
        this.PageBuilder(Constants.TAB_INDEX_ZERO)
      }
      .tabBar(this.TabBarBuilder('待办', Constants.TAB_INDEX_ZERO,
        $r('app.media.todo_active'), $r('app.media.todo_active')))

      TabContent() {
        this.PageBuilder(Constants.TAB_INDEX_ONE)
      }
      .tabBar(this.TabBarBuilder('专注', Constants.TAB_INDEX_ONE,
        $r('app.media.timer'), $r('app.media.timer')))

      TabContent() {
        this.PageBuilder(Constants.TAB_INDEX_TWO)
      }
      .tabBar(this.TabBarBuilder('统计', Constants.TAB_INDEX_TWO,
        $r('app.media.stats'), $r('app.media.stats')))
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
}