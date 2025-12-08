// FileStorageHelper.ets
import { TodoItem } from '../Types/ToDoItem';
import fs from '@ohos.file.fs';

interface ContextWithFiles {
  filesDir?: string;
  getFilesDir?: () => string;
}

const PLAN_FILE = 'files/planList.json';

function ensureDirExists(dirPath: string) {
  try {
    if (!fs.accessSync(dirPath)) {
      fs.mkdirSync(dirPath);
    }
  } catch (e) {
    try {
      fs.mkdirSync(dirPath);
    } catch (err) {
      console.error('ensureDirExists mkdir error:', err);
    }
  }
}

function getBaseDir(): string {
  try {
    const ctx = getContext();
    if (ctx) {
      // 某些运行时提供 filesDir 或 getFilesDir
      const ctxWithFiles = ctx as ContextWithFiles;
      if (ctxWithFiles.filesDir) {
        return ctxWithFiles.filesDir;
      }
      if (typeof ctxWithFiles.getFilesDir === 'function') {
        return ctxWithFiles.getFilesDir!();
      }
    }
  } catch (e) {
    // ignore
  }
  // 回退到相对 files 目录
  return '.';
}

function resolvePath(relPath: string): string {
  const base = getBaseDir();
  if (base === '.' || relPath.startsWith('/')) {
    return relPath;
  }
  // 简单拼接
  if (base.endsWith('/')) {
    return base + relPath;
  }
  return base + '/' + relPath;
}

export async function savePlanListToFile(planList: TodoItem[]): Promise<void> {
  try {
    const path = resolvePath(PLAN_FILE);
    // 创建父目录
    const dir = path.substring(0, path.lastIndexOf('/'));
    ensureDirExists(dir);

    const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    const data = JSON.stringify(planList || []);
    fs.writeSync(file.fd, data, { encoding: 'utf-8' });
    fs.closeSync(file);
    console.info('FileStorage: saved planList to', path);
  } catch (err) {
    console.error('savePlanListToFile error:', err);
    throw new Error(`保存文件失败: ${err}`);
  }
}

export async function loadPlanListFromFile(): Promise<TodoItem[] | null> {
  try {
    const path = resolvePath(PLAN_FILE);
    if (!fs.accessSync(path)) {
      // file exists
    } else {
      // accessSync returns true if exists
    }
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(path);
    const size = stat.size || 0;
    let content = '';
    if (size > 0) {
      content = fs.readTextSync(path);
    }
    fs.closeSync(file);
    return content ? JSON.parse(content) as TodoItem[] : null;
  } catch (err) {
    // 不存在或读取失败
    console.warn('loadPlanListFromFile warning:', err);
    return null;
  }
}
