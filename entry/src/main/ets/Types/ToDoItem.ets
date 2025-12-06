// Types/ToDoItem.ts
export interface TodoItem {
  id: number; // 唯一ID
  plan: string; // 待办内容
  isFinished: boolean; // 是否完成
  createTime?: string; // 创建时间（可选）
}

export interface RouterParams {
  planList?: string;
  newTodo?: string;
  operation?: string;
  timestamp?: number;
}