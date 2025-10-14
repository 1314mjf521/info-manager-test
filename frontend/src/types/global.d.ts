// 全局类型声明文件

// 解决Record类型冲突
declare global {
  type StringRecord = { [key: string]: string }
  type AnyRecord = { [key: string]: any }
  
  // 扩展Window接口
  interface Window {
    // 可以在这里添加全局的window属性
  }
}

// 确保这个文件被当作模块处理
export {}