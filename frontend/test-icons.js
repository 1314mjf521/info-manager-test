// 测试 Element Plus 图标
import * as Icons from '@element-plus/icons-vue'

console.log('可用的图标:', Object.keys(Icons).filter(name => name.includes('Circle')))
console.log('CheckCircle 存在:', 'CheckCircle' in Icons)
console.log('CircleCheck 存在:', 'CircleCheck' in Icons)
console.log('XCircle 存在:', 'XCircle' in Icons) 
console.log('CircleClose 存在:', 'CircleClose' in Icons)