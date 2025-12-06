@Entry
@Component
export struct FocusTimerPage {
  @State message: string = '专注界面';

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('FocusHelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = '开始';
        })
    }
    .height('100%')
    .width('100%')
  }
}