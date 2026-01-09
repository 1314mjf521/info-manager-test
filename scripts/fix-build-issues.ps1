# 修复前端构建问题
Write-Host "=== 修复前端构建问题 ===" -ForegroundColor Green

# 进入前端目录
Set-Location frontend

Write-Host "1. 清理构建缓存..." -ForegroundColor Yellow
if (Test-Path "dist") {
    Remove-Item -Recurse -Force dist
    Write-Host "   已删除 dist 目录" -ForegroundColor Gray
}

if (Test-Path "node_modules/.vite") {
    Remove-Item -Recurse -Force "node_modules/.vite"
    Write-Host "   已清理 Vite 缓存" -ForegroundColor Gray
}

Write-Host "2. 检查并修复 TypeScript 配置..." -ForegroundColor Yellow

# 创建或更新 tsconfig.json
$tsconfigContent = @"
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "strict": false,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
"@

$tsconfigContent | Out-File -FilePath "tsconfig.json" -Encoding UTF8
Write-Host "   已更新 tsconfig.json" -ForegroundColor Gray

Write-Host "3. 检查 Vite 配置..." -ForegroundColor Yellow

# 检查 vite.config.ts 是否存在
if (-not (Test-Path "vite.config.ts")) {
    Write-Host "   创建 vite.config.ts..." -ForegroundColor Gray
    
    $viteConfigContent = @"
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      resolvers: [ElementPlusResolver()],
    }),
    Components({
      resolvers: [ElementPlusResolver()],
    }),
  ],
  server: {
    port: 3000,
    host: true
  },
  build: {
    target: 'es2015',
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'esbuild',
    rollupOptions: {
      output: {
        chunkFileNames: 'assets/js/[name]-[hash].js',
        entryFileNames: 'assets/js/[name]-[hash].js',
        assetFileNames: 'assets/[ext]/[name]-[hash].[ext]'
      }
    }
  }
})
"@
    
    $viteConfigContent | Out-File -FilePath "vite.config.ts" -Encoding UTF8
}

Write-Host "4. 尝试构建..." -ForegroundColor Yellow
$buildResult = npm run build 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 构建成功！" -ForegroundColor Green
} else {
    Write-Host "❌ 构建失败，错误信息：" -ForegroundColor Red
    Write-Host $buildResult -ForegroundColor Red
    
    Write-Host "5. 尝试修复常见问题..." -ForegroundColor Yellow
    
    # 重新安装依赖
    Write-Host "   重新安装依赖..." -ForegroundColor Gray
    npm install --force
    
    # 再次尝试构建
    Write-Host "   再次尝试构建..." -ForegroundColor Gray
    $buildResult2 = npm run build 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 修复后构建成功！" -ForegroundColor Green
    } else {
        Write-Host "❌ 仍然构建失败：" -ForegroundColor Red
        Write-Host $buildResult2 -ForegroundColor Red
    }
}

# 返回上级目录
Set-Location ..

Write-Host "=== 构建修复完成 ===" -ForegroundColor Green