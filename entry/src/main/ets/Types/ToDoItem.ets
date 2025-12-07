// Types/ToDoItem.ts
export interface TodoItem {
  id: number; // 唯一ID
  name: string; // 待办名称
  deadline: string; // 截止时间（ISO格式字符串）
  total_time: number; // 总计时长（秒）
  isFinished: boolean; // 是否完成
}

export interface RouterParams {
  planList?: string;
  newTodo?: string;
  operation?: string;
  timestamp?: number;
}